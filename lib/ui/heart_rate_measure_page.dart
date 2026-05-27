import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';

/// Full-screen page that uses the rear camera + torch as a PPG sensor to
/// estimate heart rate. The user places a fingertip gently over the lens and
/// flash; we sample the average red/luminance of each frame, detrend it,
/// detect peaks, and convert peak spacing into BPM.
class HeartRateMeasurePage extends StatefulWidget {
  const HeartRateMeasurePage({super.key});

  @override
  State<HeartRateMeasurePage> createState() => _HeartRateMeasurePageState();
}

enum _Phase { idle, waiting, measuring, done }

const int _kHeartTipsCount = 14;

List<String> _heartTips(AppLocalizations t) => [
  t.hrTip1,
  t.hrTip2,
  t.hrTip3,
  t.hrTip4,
  t.hrTip5,
  t.hrTip6,
  t.hrTip7,
  t.hrTip8,
  t.hrTip9,
  t.hrTip10,
  t.hrTip11,
  t.hrTip12,
  t.hrTip13,
  t.hrTip14,
];

class _HeartRateMeasurePageState extends State<HeartRateMeasurePage>
    with TickerProviderStateMixin {
  static const Duration _measurementDuration = Duration(seconds: 30);
  static const int _maxSamples = 900; // 30s at 30fps
  static const int _waveformSamples = 180; // ~6s visible
  static const int _fingerRequiredMs = 1500; // sustained detection to start
  static const int _maxFingerOffMs = 4000; // give up if lifted this long

  CameraController? _camera;
  bool _initializing = true;
  String? _initError;

  // Sample buffer: (timeMs, value)
  final List<_Sample> _samples = [];
  // Detrended values for peak detection + waveform.
  final List<double> _detrended = [];
  // Detected peak times (ms since start).
  final List<int> _peakTimes = [];

  _Phase _phase = _Phase.idle;
  DateTime? _measureStartedAt;
  DateTime? _fingerOnSince;
  DateTime? _fingerOffSince;
  int _measuredMs = 0; // accumulated measuring time (paused while finger off)
  DateTime? _lastTickAt;
  Timer? _ticker;
  bool _completed = false;
  bool _fingerDetected = false;
  int? _liveBpm;
  int? _finalBpm;
  // Exponentially-smoothed BPM. Each frame produces a noisy instantaneous
  // estimate; EMA convergence is what makes the displayed value stable.
  double? _emaBpm;
  String? _failureReason;
  double _progress = 0.0;
  int _totalFrames = 0;
  int _goodFrames = 0;

  // Rotating tip shown while we wait for / collect the reading. The user
  // sits still for ~30s, so a fact every few seconds gives them something
  // to read instead of staring at the timer.
  int _tipIndex = 0;
  Timer? _tipTimer;

  bool get _measuring =>
      _phase == _Phase.waiting || _phase == _Phase.measuring;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        rear,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = '$e';
      });
    }
  }

  Future<void> _start() async {
    final cam = _camera;
    if (cam == null || _measuring) return;

    HapticFeedback.mediumImpact();
    _samples.clear();
    _detrended.clear();
    _peakTimes.clear();
    _liveBpm = null;
    _finalBpm = null;
    _emaBpm = null;
    _failureReason = null;
    _fingerDetected = false;
    _fingerOnSince = null;
    _fingerOffSince = null;
    _progress = 0.0;
    _measuredMs = 0;
    _lastTickAt = null;
    _measureStartedAt = null;
    _completed = false;
    _totalFrames = 0;
    _goodFrames = 0;

    try {
      await cam.setFlashMode(FlashMode.torch);
    } catch (_) {}
    try {
      await cam.setFocusMode(FocusMode.locked);
    } catch (_) {}
    try {
      await cam.setExposureMode(ExposureMode.locked);
    } catch (_) {}

    await cam.startImageStream(_onFrame);

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _onTick();
    });

    _startTipRotation();

    setState(() => _phase = _Phase.waiting);
  }

  void _startTipRotation() {
    _tipTimer?.cancel();
    _tipIndex = math.Random().nextInt(_kHeartTipsCount);
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % _kHeartTipsCount;
      });
    });
  }

  void _stopTipRotation() {
    _tipTimer?.cancel();
    _tipTimer = null;
  }

  void _onTick() {
    if (!mounted || _completed) return;
    final now = DateTime.now();
    final lastTick = _lastTickAt ?? now;
    final deltaMs = now.difference(lastTick).inMilliseconds;
    _lastTickAt = now;

    if (_phase == _Phase.waiting) {
      // Don't start the 30s clock until we've seen a sustained finger
      // signal — this is what stops "pointing at air" from ever counting.
      if (_fingerDetected) {
        _fingerOnSince ??= now;
        final sustained = now.difference(_fingerOnSince!).inMilliseconds;
        if (sustained >= _fingerRequiredMs) {
          // Transition to measuring: discard startup samples and reset
          // the sample-time origin so peak detection starts clean.
          _samples.clear();
          _detrended.clear();
          _peakTimes.clear();
          _measureStartedAt = now;
          _measuredMs = 0;
          _fingerOffSince = null;
          HapticFeedback.lightImpact();
          setState(() => _phase = _Phase.measuring);
        }
      } else {
        _fingerOnSince = null;
      }
      return;
    }

    if (_phase == _Phase.measuring) {
      if (_fingerDetected) {
        _fingerOffSince = null;
        _measuredMs += deltaMs;
      } else {
        _fingerOffSince ??= now;
        final offMs = now.difference(_fingerOffSince!).inMilliseconds;
        if (offMs >= _maxFingerOffMs) {
          // User lifted their finger too long — fail outright.
          _failMeasurement(
            AppLocalizations.of(context).hrMeasFailLifted,
          );
          return;
        }
        // Otherwise just freeze _measuredMs and progress.
      }

      final p = (_measuredMs / _measurementDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      setState(() => _progress = p);

      if (_measuredMs >= _measurementDuration.inMilliseconds) {
        _finish();
      }
    }
  }

  Future<void> _failMeasurement(String reason) async {
    if (_completed) return;
    _completed = true;
    _ticker?.cancel();
    _ticker = null;
    _stopTipRotation();
    await _stopCameraStream();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _phase = _Phase.done;
      _finalBpm = null;
      _failureReason = reason;
      _liveBpm = null;
    });
  }

  Future<void> _stopCameraStream() async {
    final cam = _camera;
    if (cam == null) return;
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {}
    try {
      await cam.setFlashMode(FlashMode.off);
    } catch (_) {}
  }

  Future<void> _finish() async {
    if (_completed) return;
    _completed = true;
    _ticker?.cancel();
    _ticker = null;
    _stopTipRotation();
    await _stopCameraStream();

    final result = _computeFinalBpm();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _Phase.done;
      _finalBpm = result.bpm;
      _failureReason = result.error;
      if (result.bpm == null) _liveBpm = null;
    });
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    _ticker = null;
    _stopTipRotation();
    await _stopCameraStream();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.idle;
      _completed = false;
      _samples.clear();
      _detrended.clear();
      _peakTimes.clear();
      _liveBpm = null;
      _finalBpm = null;
      _emaBpm = null;
      _failureReason = null;
      _fingerDetected = false;
      _fingerOnSince = null;
      _fingerOffSince = null;
      _progress = 0.0;
      _measuredMs = 0;
      _measureStartedAt = null;
      _lastTickAt = null;
      _totalFrames = 0;
      _goodFrames = 0;
    });
  }

  void _onFrame(CameraImage image) {
    if (!mounted || !_measuring || _completed) return;

    final stats = _frameStats(image);
    final value = stats.intensity;
    final redness = stats.redness;
    if (value <= 0) return;

    // Finger-on-lens gate: with the torch lit AND a fingertip pressed
    // against the lens, the frame is dim-to-medium AND red-dominant.
    // Without a finger the torch reflection is bright/white (high Y,
    // low redness). This rejects pointing the phone at air, a desk,
    // a red mouse, etc.
    final bool covered = value > 35 && value < 200 && redness > 0.18;
    if (covered != _fingerDetected && mounted) {
      setState(() => _fingerDetected = covered);
    }

    // Only count frames during the measuring phase.
    if (_phase != _Phase.measuring) return;
    final started = _measureStartedAt;
    if (started == null) return;

    final tMs = DateTime.now().difference(started).inMilliseconds;
    if (tMs > _measurementDuration.inMilliseconds + 2000) return;

    _totalFrames++;
    if (!covered) return;

    _goodFrames++;
    _samples.add(_Sample(tMs, value));
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }

    _recomputeSignal();
  }

  /// Extracts per-frame mean intensity AND a red-dominance score in [0, 1].
  /// Supports YUV420 (3-plane Android, 2-plane iOS NV12) and BGRA8888.
  ///   - intensity: mean of the Y/luminance (or red) channel. Used as the
  ///     PPG signal source.
  ///   - redness:   strength of red dominance. ~0 for white/grey scenes,
  ///     close to 1 for a fingertip-on-lens with the torch lit.
  _FrameStats _frameStats(CameraImage image) {
    try {
      final isBgra = image.format.group == ImageFormatGroup.bgra8888;

      if (isBgra) {
        final plane = image.planes[0];
        final bytes = plane.bytes;
        final rowStride = plane.bytesPerRow;
        int sR = 0, sG = 0, sB = 0, count = 0;
        const step = 8;
        for (int y = 0; y < image.height; y += step) {
          final rowStart = y * rowStride;
          for (int x = 0; x < image.width; x += step) {
            final i = rowStart + x * 4;
            if (i + 2 >= bytes.length) break;
            sB += bytes[i];
            sG += bytes[i + 1];
            sR += bytes[i + 2];
            count++;
          }
        }
        if (count == 0) return const _FrameStats(0, 0);
        final r = sR / count;
        final g = sG / count;
        final b = sB / count;
        final maxOther = math.max(g, b);
        // Red intensity for PPG (red channel best reflects blood pulsation).
        final intensity = r;
        // Redness score: how much R dominates the other channels.
        final redness = ((r - maxOther) / 96.0).clamp(0.0, 1.0);
        return _FrameStats(intensity, redness);
      }

      // YUV420 — Y plane for intensity.
      final yPlane = image.planes[0];
      final yBytes = yPlane.bytes;
      final yStride = yPlane.bytesPerRow;
      int ySum = 0, yCount = 0;
      const step = 8;
      for (int y = 0; y < image.height; y += step) {
        final rowStart = y * yStride;
        for (int x = 0; x < image.width; x += step) {
          final i = rowStart + x;
          if (i >= yBytes.length) break;
          ySum += yBytes[i];
          yCount++;
        }
      }
      final yMean = yCount == 0 ? 0.0 : ySum / yCount;

      // Redness from V (Cr) plane. On Android yuv420 we get 3 planes
      // (Y, U, V). On iOS NV12 we get 2 planes — plane[1] is interleaved
      // CbCr (Cb at even bytes, Cr at odd bytes within each chroma sample
      // pair).
      double redness = 0;
      if (image.planes.length >= 3) {
        final vBytes = image.planes[2].bytes;
        if (vBytes.isNotEmpty) {
          int sum = 0, count = 0;
          final s = math.max(1, vBytes.length ~/ 512);
          for (int i = 0; i < vBytes.length; i += s) {
            sum += vBytes[i];
            count++;
          }
          final meanV = count > 0 ? sum / count : 128.0;
          // V centered at 128; strong red typically pushes V past 170.
          redness = ((meanV - 140) / 50.0).clamp(0.0, 1.0);
        }
      } else if (image.planes.length >= 2) {
        final uvBytes = image.planes[1].bytes;
        if (uvBytes.isNotEmpty) {
          // Sample odd-indexed bytes (Cr in NV12). If the platform happens
          // to use NV21 (V then U), even bytes would be Cr — take the max
          // of the two so we work either way.
          int sumEven = 0, sumOdd = 0, countEven = 0, countOdd = 0;
          final s = math.max(2, uvBytes.length ~/ 512);
          for (int i = 0; i < uvBytes.length; i += s) {
            if (i.isEven) {
              sumEven += uvBytes[i];
              countEven++;
            } else {
              sumOdd += uvBytes[i];
              countOdd++;
            }
          }
          final meanEven = countEven > 0 ? sumEven / countEven : 128.0;
          final meanOdd = countOdd > 0 ? sumOdd / countOdd : 128.0;
          final meanV = math.max(meanEven, meanOdd);
          redness = ((meanV - 140) / 50.0).clamp(0.0, 1.0);
        }
      }

      return _FrameStats(yMean, redness);
    } catch (_) {
      return const _FrameStats(0, 0);
    }
  }

  /// Rebuilds the detrended signal and re-detects peaks. Called once per
  /// frame. We only operate on the tail of the buffer to keep it cheap.
  void _recomputeSignal() {
    if (_samples.length < 10) return;

    // Smoothing window ≈ 5 samples; baseline window ≈ 30 samples (~1s).
    // Smoothing window ≈ 7 samples (~230ms at 30fps) blurs the dicrotic
    // notch (the small secondary bump after each pulse) so it doesn't get
    // mistaken for an extra peak.
    const int smoothWin = 7;
    // Baseline window must be > 2× the pulse period or we'd attenuate the
    // very signal we're trying to detect. 60 samples ≈ 2s covers heart
    // rates down to 60 BPM safely.
    const int baselineWin = 60;

    final n = _samples.length;
    final List<double> smoothed = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      int from = math.max(0, i - smoothWin ~/ 2);
      int to = math.min(n - 1, i + smoothWin ~/ 2);
      double s = 0;
      for (int j = from; j <= to; j++) {
        s += _samples[j].value;
      }
      smoothed[i] = s / (to - from + 1);
    }

    final List<double> detrended = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      int from = math.max(0, i - baselineWin ~/ 2);
      int to = math.min(n - 1, i + baselineWin ~/ 2);
      double s = 0;
      for (int j = from; j <= to; j++) {
        s += smoothed[j];
      }
      final baseline = s / (to - from + 1);
      detrended[i] = smoothed[i] - baseline;
    }

    _detrended
      ..clear()
      ..addAll(detrended);

    // Peak detection: a sample is a peak if it is a local maximum within
    // a window of ±3 neighbors AND it sits above 0 (above baseline).
    // Enforce a minimum spacing of 350ms (≈ 170 BPM max).
    final List<int> peaks = [];
    const int neigh = 3;
    const int minSpacingMs = 350;
    for (int i = neigh; i < n - neigh; i++) {
      final v = detrended[i];
      if (v <= 0) continue;
      bool isPeak = true;
      for (int k = 1; k <= neigh; k++) {
        if (detrended[i - k] >= v || detrended[i + k] > v) {
          isPeak = false;
          break;
        }
      }
      if (!isPeak) continue;
      final t = _samples[i].t;
      if (peaks.isNotEmpty && t - peaks.last < minSpacingMs) continue;
      peaks.add(t);
    }

    _peakTimes
      ..clear()
      ..addAll(peaks);

    // Instantaneous BPM from the median peak-interval in the last ~8 s,
    // fed into an exponential moving average. The EMA is what stabilises
    // the displayed value — individual frames are noisy, but the smoothed
    // output converges toward the true rate. This mirrors what consumer
    // PPG apps do (incl. the heart_bpm package) and avoids fail-hard
    // "irregular" rejections on real readings.
    if (peaks.length >= 3) {
      final lastT = peaks.last;
      final recent = peaks.where((t) => t > lastT - 8000).toList();
      if (recent.length >= 3) {
        final intervals = <int>[];
        for (int i = 1; i < recent.length; i++) {
          intervals.add(recent[i] - recent[i - 1]);
        }
        final sortedIv = List<int>.from(intervals)..sort();
        final medianMs = sortedIv[sortedIv.length ~/ 2];
        if (medianMs > 300 && medianMs < 1500) {
          final instBpm = 60000.0 / medianMs;
          if (instBpm >= 40 && instBpm <= 200) {
            // EMA smoothing. α = 0.15 ≈ 5-sample horizon — fast enough
            // to converge in the first ~10 s of measurement, slow enough
            // to ride out one bad frame.
            const alpha = 0.15;
            final prev = _emaBpm;
            final next = prev == null ? instBpm : alpha * instBpm + (1 - alpha) * prev;
            final rounded = next.round();
            if (rounded != _liveBpm && mounted) {
              setState(() {
                _emaBpm = next;
                _liveBpm = rounded;
              });
            } else {
              _emaBpm = next;
            }
          }
        }
      }
    }

    // Trigger a paint update for the waveform.
    if (mounted) setState(() {});
  }

  _BpmResult _computeFinalBpm() {
    final t = AppLocalizations.of(context);
    // 1. Coverage gate — was the finger actually on the lens?
    if (_totalFrames == 0) {
      return _BpmResult(null, t.hrMeasFailNoFrames);
    }
    final coverage = _goodFrames / _totalFrames;
    if (coverage < 0.5) {
      return _BpmResult(null, t.hrMeasFailNoFinger);
    }

    // 2. Amplitude gate — the detrended signal must actually pulsate.
    //    This is what rejects pointing the phone at air (where the redness
    //    gate might briefly pass but there's no real pulse signal).
    if (_detrended.length >= 30) {
      double mean = 0;
      for (final v in _detrended) {
        mean += v;
      }
      mean /= _detrended.length;
      double variance = 0;
      for (final v in _detrended) {
        final d = v - mean;
        variance += d * d;
      }
      final std = math.sqrt(variance / _detrended.length);
      if (std < 0.25) {
        return _BpmResult(null, t.hrMeasFailNoSignal);
      }
    }

    // 3. Need an EMA-converged BPM and at least a handful of peaks for it
    //    to mean anything.
    final ema = _emaBpm;
    if (ema == null || _peakTimes.length < 5) {
      return _BpmResult(null, t.hrMeasFailNoSteady);
    }
    final bpm = ema.round();
    if (bpm < 40 || bpm > 200) {
      return _BpmResult(null, t.hrMeasFailLockOn);
    }
    return _BpmResult(bpm, null);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tipTimer?.cancel();
    _pulseCtrl.dispose();
    () async {
      await _stopCameraStream();
      await _camera?.dispose();
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final subColor = textColor.withValues(alpha: 0.55);
    final dimColor = textColor.withValues(alpha: 0.4);
    final font = GoogleFonts.plusJakartaSans;

    return ValueListenableBuilder<Color>(
      valueListenable: AccentColor.notifier,
      builder: (context, accentColor, _) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 260,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.redAccent
                                .withValues(alpha: isDark ? 0.55 : 0.40),
                            Colors.redAccent
                                .withValues(alpha: isDark ? 0.30 : 0.18),
                            Colors.redAccent.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                        child: Row(
                          children: [
                            UniversalBackButton(
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                await _cancel();
                                if (mounted) nav.pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _finalBpm != null
                              ? t.hrMeasYourHeartRate
                              : _failureReason != null
                                  ? t.hrMeasCouldntRead
                                  : _phase == _Phase.waiting
                                      ? t.hrMeasWaitingFinger
                                      : _phase == _Phase.measuring
                                          ? (_fingerDetected
                                              ? t.hrMeasHoldStill
                                              : t.hrMeasPaused)
                                          : t.hrMeasReadYourHeart,
                          style: font(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _finalBpm != null
                              ? t.hrMeasSubDone
                              : _failureReason != null
                                  ? _failureReason!
                                  : _phase == _Phase.waiting
                                      ? t.hrMeasSubWaiting
                                      : _phase == _Phase.measuring
                                          ? (_fingerDetected
                                              ? t.hrMeasSubMeasuring
                                              : t.hrMeasSubPaused)
                                          : t.hrMeasSubIdle,
                          style: font(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: _initializing
                                      ? const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: BouncingDotsLoader(),
                                        )
                                      : _initError != null
                                          ? Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 24),
                                              child: Text(
                                                t.hrMeasCameraUnavailable(
                                                  _initError!,
                                                ),
                                                textAlign: TextAlign.center,
                                                style: font(
                                                  fontSize: 14,
                                                  color: subColor,
                                                ),
                                              ),
                                            )
                                          : _buildVisual(
                                              accentColor: accentColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                              cardColor: cardColor,
                                              subColor: subColor,
                                              dimColor: dimColor,
                                              maxWidth: constraints.maxWidth,
                                              maxHeight:
                                                  constraints.maxHeight,
                                            ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: _buildActions(textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisual({
    required Color accentColor,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
    required Color subColor,
    required Color dimColor,
    required double maxWidth,
    required double maxHeight,
  }) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;

    // Scale everything off the available space so the page fits on small
    // phones (SE-class, foldable inner panels, accessibility text scales)
    // without overflowing. The waveform + tip card claim ~180pt of vertical
    // budget; the ring gets the rest, capped at 260pt.
    const double waveformReservedH = 180;
    final double widthBudget = math.max(0, maxWidth - 24);
    final double heightBudget =
        math.max(160, maxHeight - waveformReservedH);
    final double ringSize =
        math.min(260.0, math.min(widthBudget, heightBudget));
    final double innerSize = ringSize * 0.70;
    final double iconSize = (ringSize * 0.125).clamp(20.0, 32.0);
    final double bpmFontSize = (ringSize * 0.18).clamp(28.0, 48.0);
    final double bpmLabelFontSize = (ringSize * 0.046).clamp(9.0, 12.0);

    final double waveformH = (maxHeight * 0.10).clamp(40.0, 56.0);
    final double sideGap = (maxWidth * 0.08).clamp(20.0, 32.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: _progress,
                    activeColor: Colors.redAccent,
                    trackColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.02).animate(
                  CurvedAnimation(
                    parent: _pulseCtrl,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_measuring &&
                            _camera != null &&
                            _camera!.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _camera!.value.previewSize?.height ?? 1,
                              height: _camera!.value.previewSize?.width ?? 1,
                              child: CameraPreview(_camera!),
                            ),
                          )
                        else
                          Container(color: cardColor),

                        if (_measuring)
                          Container(
                            color: Colors.black.withValues(alpha: 0.30),
                          ),

                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: innerSize * 0.08,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  color: _measuring
                                      ? Colors.white
                                      : Colors.redAccent,
                                  size: iconSize,
                                ),
                                SizedBox(height: iconSize * 0.13),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    (_finalBpm ?? _liveBpm)?.toString() ??
                                        '--',
                                    style: font(
                                      fontSize: bpmFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: _measuring
                                          ? Colors.white
                                          : textColor,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.hrDetBpm,
                                  style: font(
                                    fontSize: bpmLabelFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: _measuring
                                        ? Colors.white
                                            .withValues(alpha: 0.85)
                                        : subColor,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: (maxHeight * 0.04).clamp(16.0, 24.0)),
        if (_measuring)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sideGap),
            child: SizedBox(
              height: waveformH,
              child: CustomPaint(
                size: Size(double.infinity, waveformH),
                painter: _WaveformPainter(
                  values: _detrended.length > _waveformSamples
                      ? _detrended.sublist(_detrended.length - _waveformSamples)
                      : List<double>.from(_detrended),
                  color: Colors.redAccent,
                ),
              ),
            ),
          )
        else
          SizedBox(height: waveformH),
        const SizedBox(height: 12),
        if (_measuring)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sideGap),
            child: !_fingerDetected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: dimColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          t.hrMeasCoverCamera,
                          textAlign: TextAlign.center,
                          style: font(
                            fontSize: 12,
                            color: dimColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildTipCard(
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    cardColor: cardColor,
                  ),
          ),
      ],
    );
  }

  Widget _buildTipCard({
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color cardColor,
  }) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    final tip = _heartTips(t)[_tipIndex % _kHeartTipsCount];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_tipIndex),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.hrMeasDidYouKnow,
                    style: font(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip,
                    style: font(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Color textColor) {
    final t = AppLocalizations.of(context);
    if (_completed && _finalBpm == null) {
      // Measurement failed — only offer Retry.
      return UniversalButton(
        text: t.hrMeasTryAgain,
        onPressed: () async {
          await _cancel();
          if (!mounted) return;
          await _start();
        },
      );
    }

    if (_finalBpm != null) {
      final bpm = _finalBpm!;
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                HapticFeedback.selectionClick();
                await _cancel();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: textColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                t.hrMeasRetry,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: UniversalButton(
              text: t.hrMeasSave(bpm),
              onPressed: () {
                Navigator.of(context).pop<int>(bpm);
              },
            ),
          ),
        ],
      );
    }

    if (_measuring) {
      return OutlinedButton(
        onPressed: _cancel,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(
            color: textColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          t.hrMeasCancel,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      );
    }

    return UniversalButton(
      text: _initializing ? t.hrMeasPreparing : t.hrMeasStart,
      onPressed: () {
        if (!_initializing && _initError == null) _start();
      },
      isLoading: _initializing,
    );
  }
}

class _Sample {
  final int t;
  final double value;
  const _Sample(this.t, this.value);
}

class _FrameStats {
  final double intensity;
  final double redness;
  const _FrameStats(this.intensity, this.redness);
}

class _BpmResult {
  final int? bpm;
  final String? error;
  const _BpmResult(this.bpm, this.error);
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const strokeW = 8.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.activeColor != activeColor;
}

class _WaveformPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _WaveformPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    double maxAbs = 0.0;
    for (final v in values) {
      final a = v.abs();
      if (a > maxAbs) maxAbs = a;
    }
    if (maxAbs < 0.5) maxAbs = 0.5;

    final path = Path();
    final dx = size.width / (values.length - 1);
    final midY = size.height / 2;
    for (int i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = midY - (values[i] / maxAbs) * (size.height / 2 - 4);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.values.length != values.length || old.color != color;
}
