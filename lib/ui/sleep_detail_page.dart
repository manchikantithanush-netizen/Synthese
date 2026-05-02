import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class SleepDetailPage extends StatefulWidget {
  const SleepDetailPage({super.key});

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

// Sleep stage breakdown
class _SleepData {
  final int totalMinutes;
  final int remMinutes;
  final int coreMinutes;
  final int deepMinutes;
  final int awakeMinutes;

  const _SleepData({
    this.totalMinutes = 0,
    this.remMinutes = 0,
    this.coreMinutes = 0,
    this.deepMinutes = 0,
    this.awakeMinutes = 0,
  });

  bool get hasData => totalMinutes > 0;
}

// A single timed sleep segment
class _SleepSegment {
  final DateTime from;
  final DateTime to;
  final String stage; // 'rem','light','deep','awake','sleeping'

  const _SleepSegment({
    required this.from,
    required this.to,
    required this.stage,
  });

  int get minutes => to.difference(from).inMinutes;
}

class _SleepDetailPageState extends State<SleepDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  _SleepData _data = const _SleepData();
  bool _loading = true;
  List<_SleepSegment> _segments = [];

  // Goal: 8 hours
  static const int _goalMinutes = 480;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fetchSleepData();
    _loadSegmentsFromFirestore();
    _cleanupYesterdaySleepSegments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSleepData() async {
    setState(() {
      _loading = true;
      // Don't clear segments here — keep existing data visible while loading
    });
    try {
      final health = Health();
      await health.configure();

      // Types to request
      final types = [
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_AWAKE,
      ];
      final perms = List.filled(types.length, HealthDataAccess.READ);

      bool canRead = false;
      if (Platform.isAndroid) {
        final avail = await health.isHealthConnectAvailable();
        if (avail) {
          final hasPerm = await health.hasPermissions(types, permissions: perms);
          if (hasPerm != true) {
            await health.requestAuthorization(types, permissions: perms);
          }
          canRead = true;
        }
      } else {
        final hasPerm = await health.hasPermissions(types, permissions: perms);
        if (hasPerm != true) {
          await health.requestAuthorization(types, permissions: perms);
        }
        canRead = true;
      }

      if (!canRead) return;

      final now = DateTime.now();
      // Look back 24h to catch last night's sleep
      final start = now.subtract(const Duration(hours: 24));

      final points = await health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );
      final deduped = health.removeDuplicates(points);

      int total = 0, rem = 0, core = 0, deep = 0, awake = 0;
      final List<_SleepSegment> segments = [];

      for (final p in deduped) {
        final mins = p.dateTo.difference(p.dateFrom).inMinutes;
        if (mins <= 0) continue;
        switch (p.type) {
          case HealthDataType.SLEEP_SESSION:
            total += mins;
            break;
          case HealthDataType.SLEEP_REM:
            rem += mins;
            segments.add(_SleepSegment(from: p.dateFrom, to: p.dateTo, stage: 'rem'));
            break;
          case HealthDataType.SLEEP_LIGHT:
            core += mins;
            segments.add(_SleepSegment(from: p.dateFrom, to: p.dateTo, stage: 'light'));
            break;
          case HealthDataType.SLEEP_DEEP:
            deep += mins;
            segments.add(_SleepSegment(from: p.dateFrom, to: p.dateTo, stage: 'deep'));
            break;
          case HealthDataType.SLEEP_AWAKE:
            awake += mins;
            segments.add(_SleepSegment(from: p.dateFrom, to: p.dateTo, stage: 'awake'));
            break;
          default:
            break;
        }
      }

      // If no session data but we have stage data, sum stages as total
      if (total == 0 && (rem + core + deep) > 0) {
        total = rem + core + deep + awake;
      }

      // Only use segments if they have meaningful time spread (>= 30 min total)
      final validSegments = segments.where((s) => s.minutes >= 1).toList()
        ..sort((a, b) => a.from.compareTo(b.from));
      final int segSpread = validSegments.isEmpty
          ? 0
          : validSegments.last.to
              .difference(validSegments.first.from)
              .inMinutes;

      if (mounted) {
        setState(() {
          _data = _SleepData(
            totalMinutes: total,
            remMinutes: rem,
            coreMinutes: core,
            deepMinutes: deep,
            awakeMinutes: awake,
          );
          // Only show timeline if segments span at least 2 hours
          _segments = segSpread >= 120 ? validSegments : [];
        });
        _ctrl.forward(from: 0);
      }    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtHours(int mins) {
    if (mins == 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _fmtDecimal(int mins) {
    if (mins == 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    final dec = (m / 60 * 100).round();
    return '${h}.${dec.toString().padLeft(2, '0')}h';
  }

  Future<void> _saveSegmentsToFirestore(List<_SleepSegment> segs) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final dayKey = '${now.year}-$m-$d';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .set({
        'sleepSegments': segs.map((s) => {
          'from': Timestamp.fromDate(s.from),
          'to': Timestamp.fromDate(s.to),
          'stage': s.stage,
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _loadSegmentsFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final dayKey = '${now.year}-$m-$d';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .get();
      final raw = doc.data()?['sleepSegments'] as List<dynamic>?;
      if (raw == null || raw.isEmpty) return;
      final loaded = raw.map((e) => _SleepSegment(
        from: (e['from'] as Timestamp).toDate(),
        to: (e['to'] as Timestamp).toDate(),
        stage: e['stage'] as String? ?? 'light',
      )).toList()..sort((a, b) => a.from.compareTo(b.from));

      final spread = loaded.last.to.difference(loaded.first.from).inMinutes;
      if (spread >= 120 && loaded.length >= 3 && mounted) {
        setState(() => _segments = loaded);
      }
    } catch (_) {}
  }

  Future<void> _cleanupYesterdaySleepSegments() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final m = yesterday.month.toString().padLeft(2, '0');
      final d = yesterday.day.toString().padLeft(2, '0');
      final dayKey = '${yesterday.year}-$m-$d';
      // Remove only the sleepSegments field from yesterday's doc — keep other metrics
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .update({'sleepSegments': FieldValue.delete()});
    } catch (_) {
      // Doc may not exist — that's fine
    }
  }

  ({String prefix, String keyword, String suffix}) _buildInsight() {
    final int mins = _data.totalMinutes;
    if (mins == 0) {
      return (prefix: 'No sleep data ', keyword: 'recorded', suffix: ' yet.');
    }
    final double hrs = mins / 60;
    if (hrs >= 8) {
      return (prefix: 'You got a ', keyword: 'great night\'s sleep', suffix: '.');
    }
    if (hrs >= 7) {
      return (prefix: 'You slept ', keyword: 'well', suffix: ' last night.');
    }
    if (hrs >= 6) {
      return (prefix: 'You got ', keyword: 'decent sleep', suffix: ' last night.');
    }
    if (hrs >= 4) {
      return (prefix: 'You had a ', keyword: 'short night', suffix: ' — try to rest more.');
    }
    return (prefix: 'You need ', keyword: 'more sleep', suffix: ' tonight.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;
    final insight = _buildInsight();

    // Ring colors — matching the reference image style
    const Color remColor   = Color(0xFF5B8A5F);  // green
    const Color coreColor  = Color(0xFFE07B39);  // orange
    const Color deepColor  = Color(0xFF6B6B6B);  // grey
    const Color awakeColor = Color(0xFFB0A090);  // light tan

    final int total = _data.totalMinutes;
    final double remRatio   = total > 0 ? _data.remMinutes   / total : 0;
    final double coreRatio  = total > 0 ? _data.coreMinutes  / total : 0;
    final double deepRatio  = total > 0 ? _data.deepMinutes  / total : 0;
    final double totalProgress = (total / _goalMinutes).clamp(0.0, 1.0);

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
                // Accent glow
                Positioned(
                  top: 0, left: 0, right: 0, height: 260,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(alpha: isDark ? 0.60 : 0.45),
                            accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
                            accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                            accentColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.40, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: UniversalBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Insight text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: RichText(
                            text: TextSpan(
                              style: font(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(text: insight.prefix),
                                TextSpan(
                                  text: insight.keyword,
                                  style: TextStyle(color: accentColor),
                                ),
                                TextSpan(text: insight.suffix),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: _loading
                                ? const SizedBox(
                                    height: 200,
                                    child: Center(child: BouncingDotsLoader()),
                                  )
                                : Column(
                                    children: [
                                      // "You slept for X.XXh" header
                                      Column(
                                        children: [
                                          Text('You slept for',
                                              style: font(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor.withValues(alpha: 0.5))),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(children: [
                                              TextSpan(
                                                text: total > 0
                                                    ? _fmtDecimal(total)
                                                    : '--',
                                                style: font(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ]),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 28),

                                      // Concentric rings
                                      AnimatedBuilder(
                                        animation: _anim,
                                        builder: (_, __) => SizedBox(
                                          width: 220,
                                          height: 220,
                                          child: CustomPaint(
                                            painter: _SleepRingsPainter(
                                              progress: _anim.value,
                                              totalProgress: totalProgress,
                                              remRatio: remRatio,
                                              coreRatio: coreRatio,
                                              deepRatio: deepRatio,
                                              remColor: remColor,
                                              coreColor: coreColor,
                                              deepColor: deepColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Stage breakdown row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (_data.remMinutes > 0)
                                            _StageChip(
                                              label: 'REM',
                                              value: _fmtDecimal(_data.remMinutes),
                                              color: remColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.coreMinutes > 0)
                                            _StageChip(
                                              label: 'Core',
                                              value: _fmtDecimal(_data.coreMinutes),
                                              color: coreColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.deepMinutes > 0)
                                            _StageChip(
                                              label: 'Deep',
                                              value: _fmtHours(_data.deepMinutes),
                                              color: deepColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.awakeMinutes > 0)
                                            _StageChip(
                                              label: 'Awake',
                                              value: _fmtHours(_data.awakeMinutes),
                                              color: awakeColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          // If no stage data, show total only
                                          if (_data.remMinutes == 0 &&
                                              _data.coreMinutes == 0 &&
                                              _data.deepMinutes == 0 &&
                                              total > 0)
                                            _StageChip(
                                              label: 'Total',
                                              value: _fmtDecimal(total),
                                              color: accentColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sleep stage timeline chart
                        if (_segments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                              child: _SleepTimeline(
                                segments: _segments,
                                isDark: isDark,
                                textColor: textColor,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Sleep heatmap
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SleepHeatmap(
                            cardColor: cardColor,
                            textColor: textColor,
                            accentColor: accentColor,
                            isDark: isDark,
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Stage chip
// ─────────────────────────────────────────────

class _StageChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final Color textColor;

  const _StageChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    return Column(
      children: [
        Text(label,
            style: font(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.45))),
        const SizedBox(height: 4),
        Text(value,
            style: font(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0)),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Concentric sleep rings painter
// ─────────────────────────────────────────────

class _SleepRingsPainter extends CustomPainter {
  final double progress;       // animation 0→1
  final double totalProgress;  // total sleep / goal
  final double remRatio;
  final double coreRatio;
  final double deepRatio;
  final Color remColor;
  final Color coreColor;
  final Color deepColor;
  final bool isDark;

  const _SleepRingsPainter({
    required this.progress,
    required this.totalProgress,
    required this.remRatio,
    required this.coreRatio,
    required this.deepRatio,
    required this.remColor,
    required this.coreColor,
    required this.deepColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double strokeW = 18.0;
    const double gap = 10.0;

    // 3 rings: outer=total, middle=REM, inner=core
    final double r1 = size.width / 2 - strokeW / 2;
    final double r2 = r1 - strokeW - gap;
    final double r3 = r2 - strokeW - gap;

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    void drawRing(double radius, double ratio, Color color) {
      // Track
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      // Arc
      if (ratio > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * ratio * progress,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Outer ring: total sleep progress
    drawRing(r1, totalProgress, deepColor);
    // Middle ring: REM
    drawRing(r2, remRatio, remColor);
    // Inner ring: core/light
    drawRing(r3, coreRatio, coreColor);
  }

  @override
  bool shouldRepaint(_SleepRingsPainter old) =>
      old.progress != progress ||
      old.totalProgress != totalProgress ||
      old.remRatio != remRatio ||
      old.coreRatio != coreRatio;
}

// ─────────────────────────────────────────────
// Sleep Timeline — horizontal Gantt-style
// ─────────────────────────────────────────────

class _SleepTimeline extends StatelessWidget {
  final List<_SleepSegment> segments;
  final bool isDark;
  final Color textColor;

  const _SleepTimeline({
    required this.segments,
    required this.isDark,
    required this.textColor,
  });

  // Stage depth level: higher = deeper sleep (drawn lower on chart)
  static int _stageLevel(String stage) {
    switch (stage) {
      case 'awake':   return 0;
      case 'light':   return 1;
      case 'rem':     return 2;
      case 'deep':    return 3;
      default:        return 1;
    }
  }

  static Color _stageColor(String stage) {
    switch (stage) {
      case 'awake':   return const Color(0xFF5B8DEF); // blue
      case 'light':   return const Color(0xFF9B59B6); // purple
      case 'rem':     return const Color(0xFFE74C8B); // pink
      case 'deep':    return const Color(0xFF2ECC71); // green
      default:        return const Color(0xFF9B59B6);
    }
  }

  static String _stageLabel(String stage) {
    switch (stage) {
      case 'awake':   return 'Awake';
      case 'light':   return 'Light';
      case 'rem':     return 'REM';
      case 'deep':    return 'Deep';
      default:        return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final labelColor = textColor.withValues(alpha: 0.4);

    if (segments.isEmpty) return const SizedBox.shrink();

    final DateTime start = segments.first.from;
    final DateTime end = segments.last.to;
    final int totalMins = end.difference(start).inMinutes;
    // Only render if segments span at least 2 hours and have 3+ distinct blocks
    if (totalMins < 120 || segments.length < 3) return const SizedBox.shrink();

    // Unique stages in data
    final usedStages = segments.map((s) => s.stage).toSet().toList();

    // X-axis hour labels
    final List<String> xLabels = [];
    final List<double> xPositions = [];
    final int startHour = start.hour;
    final int endHour = end.hour + (end.minute > 0 ? 1 : 0);
    for (int h = startHour; h <= endHour; h++) {
      final hh = h % 24;
      String label;
      if (hh == 0) label = '12a';
      else if (hh < 12) label = '${hh}a';
      else if (hh == 12) label = '12p';
      else label = '${hh - 12}p';
      xLabels.add(label);
      final mins = DateTime(start.year, start.month, start.day, h)
          .difference(start)
          .inMinutes
          .toDouble();
      xPositions.add((mins / totalMins).clamp(0.0, 1.0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep Stages',
            style: font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor)),

        const SizedBox(height: 16),

        // Chart
        LayoutBuilder(builder: (context, constraints) {
          final double w = constraints.maxWidth;
          return Column(
            children: [
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: Size(w, 120),
                  painter: _SleepGanttPainter(
                    segments: segments,
                    totalMins: totalMins,
                    start: start,
                    isDark: isDark,
                  ),
                ),
              ),
              Container(height: 1,
                  color: textColor.withValues(alpha: 0.08)),
              const SizedBox(height: 6),
              // X-axis labels
              SizedBox(
                height: 16,
                width: double.infinity,
                child: LayoutBuilder(builder: (ctx, bc) {
                  const double leftMargin = 36.0;
                  const double rightPad = 8.0;
                  final double chartW = bc.maxWidth - leftMargin - rightPad;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(xLabels.length, (i) {
                      if (xLabels.length > 8 && i % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      final double x = leftMargin + xPositions[i] * chartW;
                      return Positioned(
                        left: (x - 14).clamp(0.0, bc.maxWidth - 28),
                        top: 0,
                        child: SizedBox(
                          width: 28,
                          child: Text(xLabels[i],
                              textAlign: TextAlign.center,
                              style: font(
                                  fontSize: 9,
                                  color: labelColor,
                                  fontWeight: FontWeight.w500)),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          );
        }),

        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: usedStages.map((stage) {
            final mins = segments
                .where((s) => s.stage == stage)
                .fold(0, (a, s) => a + s.minutes);
            final h = mins ~/ 60;
            final m = mins % 60;
            final timeStr = h > 0
                ? '${h}h${m > 0 ? ' ${m}m' : ''}'
                : '${m}m';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _SleepTimeline._stageColor(stage),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('$timeStr  ${_SleepTimeline._stageLabel(stage)}',
                    style: font(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.7))),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SleepGanttPainter extends CustomPainter {
  final List<_SleepSegment> segments;
  final int totalMins;
  final DateTime start;
  final bool isDark;

  const _SleepGanttPainter({
    required this.segments,
    required this.totalMins,
    required this.start,
    required this.isDark,
  });

  static const int _levels = 4; // awake=0, light=1, rem=2, deep=3
  static const double _barH = 18.0;
  static const double _barR = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalMins <= 0) return;

    // Reserve left margin for Y labels, right padding
    const double leftMargin = 36.0;
    const double rightPad = 8.0;
    final double chartW = size.width - leftMargin - rightPad;

    final double levelH = size.height / _levels;

    // Draw faint horizontal lane lines
    final lanePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 0; i < _levels; i++) {
      final y = levelH * i + levelH / 2;
      canvas.drawLine(
          Offset(leftMargin, y), Offset(leftMargin + chartW, y), lanePaint);
    }

    // Y-axis stage labels on the LEFT, vertically centered in each lane
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 9,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
      fontWeight: FontWeight.w600,
    );
    // Top→bottom: Deep(0), REM(1), Light(2), Awake(3)
    const stageNames = ['Deep', 'REM', 'Light', 'Awake'];
    for (int i = 0; i < _levels; i++) {
      final double cy = levelH * i + levelH / 2;
      final tp = TextPainter(
        text: TextSpan(text: stageNames[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftMargin - 6);
      tp.paint(canvas,
          Offset(leftMargin - tp.width - 6, cy - tp.height / 2));
    }

    // Draw each segment as a rounded rect
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i];
      final double xStart = leftMargin +
          s.from.difference(start).inMinutes / totalMins * chartW;
      final double xEnd = leftMargin +
          s.to.difference(start).inMinutes / totalMins * chartW;
      final double segW = (xEnd - xStart).clamp(2.0, chartW);

      final int level = _SleepTimeline._stageLevel(s.stage);
      // level 3=deep → row 0 (top), level 0=awake → row 3 (bottom)
      final double cy = levelH * (3 - level) + levelH / 2;

      final rrect = RRect.fromLTRBR(
        xStart, cy - _barH / 2,
        xStart + segW, cy + _barH / 2,
        const Radius.circular(_barR),
      );
      canvas.drawRRect(
          rrect, Paint()..color = _SleepTimeline._stageColor(s.stage));

      // Connecting line to next segment
      if (i < segments.length - 1) {
        final next = segments[i + 1];
        final int nextLevel = _SleepTimeline._stageLevel(next.stage);
        final double nextCy = levelH * (3 - nextLevel) + levelH / 2;
        final double gapX = xStart + segW;
        final double nextX = leftMargin +
            next.from.difference(start).inMinutes / totalMins * chartW;

        if (nextX > gapX + 1) {
          canvas.drawLine(
            Offset(gapX, cy),
            Offset(nextX, nextCy),
            Paint()
              ..color = _SleepTimeline._stageColor(next.stage)
                  .withValues(alpha: 0.35)
              ..strokeWidth = 1.2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SleepGanttPainter old) =>
      old.segments.length != segments.length;
}

// ─────────────────────────────────────────────
// Sleep Heatmap — monthly, goal = 8h (480 min)
// ─────────────────────────────────────────────

class _SleepHeatmap extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final bool isDark;

  const _SleepHeatmap({
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_SleepHeatmap> createState() => _SleepHeatmapState();
}

class _SleepHeatmapState extends State<_SleepHeatmap> {
  Map<int, int> _monthlyMinutes = {};
  bool _loading = true;

  static const int _goalMinutes = 480; // 8 hours

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _fetchData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final Map<int, int> result = {};

      final futures = <Future<void>>[];
      for (int day = 1; day <= math.min(now.day, daysInMonth); day++) {
        final date = DateTime(now.year, now.month, day);
        final key = _dateKey(date);
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dashboardDaily')
              .doc(key)
              .get()
              .then((doc) {
            // sleepData is a 7-element list [Mon..Sun] of minutes
            final sleepList = doc.data()?['sleepData'] as List<dynamic>?;
            if (sleepList != null) {
              final idx = (date.weekday - 1).clamp(0, 6);
              result[day] = (sleepList[idx] as num?)?.toInt() ?? 0;
            }
          }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _monthlyMinutes = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _cellOpacity(int? mins) {
    if (mins == null || mins <= 0) return 0.08;
    final ratio = (mins / _goalMinutes).clamp(0.0, 1.0);
    return 0.12 + ratio * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = '${monthNames[month]} $year';
    final int firstWeekday =
        (DateTime(year, month, 1).weekday - 1).clamp(0, 6);
    final int rows = ((firstWeekday + daysInMonth) / 7).ceil();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final labelColor = widget.textColor.withValues(alpha: 0.4);
    final emptyColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel,
                  style: font(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor)),
              Row(
                children: [
                  Text('Less',
                      style: font(
                          fontSize: 11,
                          color: labelColor,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final opacity = 0.12 + (i / 4) * 0.88;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text('8h',
                      style: font(
                          fontSize: 11,
                          color: labelColor,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          LayoutBuilder(builder: (context, constraints) {
            const int cols = 7;
            const double gap = 4.0;
            final double cellSize =
                (constraints.maxWidth - gap * (cols - 1)) / cols;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    cols,
                    (i) => SizedBox(
                      width: cellSize,
                      child: Center(
                        child: Text(dayLabels[i],
                            style: font(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: labelColor)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _loading
                    ? const SizedBox(
                        height: 80,
                        child: Center(child: BouncingDotsLoader()))
                    : Column(
                        children: List.generate(rows, (row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: gap),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: List.generate(cols, (col) {
                                final cellIndex = row * cols + col;
                                final day = cellIndex - firstWeekday + 1;
                                final isValid =
                                    day >= 1 && day <= daysInMonth;
                                final isFuture = day > now.day;

                                if (!isValid) {
                                  return SizedBox(
                                      width: cellSize, height: cellSize);
                                }

                                final mins = _monthlyMinutes[day];
                                final Color cellColor = isFuture
                                    ? emptyColor
                                    : widget.accentColor.withValues(
                                        alpha: _cellOpacity(mins));
                                final bool isToday = day == now.day;

                                return Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(5),
                                    border: isToday
                                        ? Border.all(
                                            color: widget.accentColor,
                                            width: 1.5)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
