import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class HeartRateDetailPage extends StatefulWidget {
  final int currentBpm;

  const HeartRateDetailPage({super.key, required this.currentBpm});

  @override
  State<HeartRateDetailPage> createState() => _HeartRateDetailPageState();
}

class _HeartRateDetailPageState extends State<HeartRateDetailPage> {
  int _tab = 0; // 0 = Daily, 1 = Weekly

  // Daily: full intraday readings for today
  List<({int bpm, DateTime time})> _dailyHistory = [];
  bool _loadingDaily = true;

  // Weekly: Mon–Sun avg BPM (index 0 = Mon)
  List<int> _weeklyAvg = List.filled(7, 0);
  bool _loadingWeekly = true;


  @override
  void initState() {
    super.initState();
    _fetchDailyHr();
    _fetchWeeklyHr();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime get _thisMonday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  // ── Daily fetch ───────────────────────────────────────────────────────────
  // 1. Load persisted readings from Firestore (survives restarts)
  // 2. Merge with fresh HealthKit/Health Connect readings
  // 3. Save merged result back

  Future<void> _fetchDailyHr() async {
    setState(() => _loadingDaily = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final dayKey = _dateKey(now);

      // 1. Load from Firestore
      List<({int bpm, DateTime time})> stored = [];
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dashboardDaily')
            .doc(dayKey)
            .get();
        final raw = doc.data()?['hrHistory'] as List<dynamic>?;
        if (raw != null) {
          stored = raw.map((e) {
            final bpm = (e['bpm'] as num?)?.toInt() ?? 0;
            final ts = (e['time'] as Timestamp?)?.toDate() ?? now;
            return (bpm: bpm, time: ts);
          }).where((r) => r.bpm > 0 && !r.time.isBefore(todayStart)).toList();
        }
      }

      // 2. Fetch fresh from health platform
      List<({int bpm, DateTime time})> fresh = [];
      try {
        final health = Health();
        await health.configure();
        bool canRead = false;
        if (Platform.isAndroid) {
          final avail = await health.isHealthConnectAvailable();
          if (avail) {
            final hasPerm = await health.hasPermissions(
                [HealthDataType.HEART_RATE],
                permissions: [HealthDataAccess.READ]);
            canRead = hasPerm == true;
          }
        } else {
          final hasPerm = await health.hasPermissions(
              [HealthDataType.HEART_RATE],
              permissions: [HealthDataAccess.READ]);
          if (hasPerm != true) {
            await health.requestAuthorization([HealthDataType.HEART_RATE],
                permissions: [HealthDataAccess.READ]);
          }
          canRead = true;
        }
        if (canRead) {
          final points = await health.getHealthDataFromTypes(
            startTime: todayStart,
            endTime: now,
            types: [HealthDataType.HEART_RATE],
          );
          final deduped = health.removeDuplicates(points);
          fresh = deduped
              .where((p) => p.type == HealthDataType.HEART_RATE)
              .map((p) => (
                    bpm: p.value is NumericHealthValue
                        ? (p.value as NumericHealthValue).numericValue.round()
                        : 0,
                    time: p.dateFrom,
                  ))
              .where((r) => r.bpm > 0)
              .toList();
        }
      } catch (_) {}

      // 3. Merge: combine stored + fresh, deduplicate by minute
      final Map<int, ({int bpm, DateTime time})> merged = {};
      for (final r in [...stored, ...fresh]) {
        final minuteKey = r.time.millisecondsSinceEpoch ~/ 60000;
        merged[minuteKey] = r;
      }
      final result = merged.values.toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // 4. Persist merged back to Firestore
      if (uid != null && result.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dashboardDaily')
            .doc(dayKey)
            .set({
          'hrHistory': result
              .map((r) => {
                    'bpm': r.bpm,
                    'time': Timestamp.fromDate(r.time),
                  })
              .toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) setState(() => _dailyHistory = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  // ── Weekly fetch ──────────────────────────────────────────────────────────
  // Only this week (Mon → today). On a new week, old data is simply not
  // fetched — Firestore docs from last week are left to expire naturally
  // (or can be cleaned up later). This week's slots default to 0.

  Future<void> _fetchWeeklyHr() async {
    setState(() => _loadingWeekly = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final monday = _thisMonday;
      final int daysSinceMonday = now.weekday - 1;
      final List<int> avgs = List.filled(7, 0);

      // Seed today's slot with currentBpm immediately so it always shows
      avgs[daysSinceMonday] = widget.currentBpm;

      final futures = <Future<void>>[];
      for (int i = 0; i <= daysSinceMonday; i++) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dashboardDaily')
              .doc(key)
              .get()
              .then((doc) {
            final data = doc.data();
            if (data == null) return;
            // Try stored heartRate field first (fast path)
            final hr = (data['heartRate'] as num?)?.toInt();
            if (hr != null && hr > 0) {
              avgs[i] = hr;
              return;
            }
            // Fall back to computing avg from hrHistory
            final raw = data['hrHistory'] as List<dynamic>?;
            if (raw != null && raw.isNotEmpty) {
              final bpms = raw
                  .map((e) => (e['bpm'] as num?)?.toInt() ?? 0)
                  .where((b) => b > 0)
                  .toList();
              if (bpms.isNotEmpty) {
                avgs[i] = bpms.reduce((a, b) => a + b) ~/ bpms.length;
              }
            }
          }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _weeklyAvg = avgs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Insight ───────────────────────────────────────────────────────────────

  /// Returns a ({prefix, keyword, suffix}) insight based on today's HR data.
  ({String prefix, String keyword, String suffix}) _buildInsight(
    List<({int bpm, DateTime time})> history,
    int avg,
    int lowest,
    int highest,
  ) {
    if (history.isEmpty) {
      return (
        prefix: 'No heart rate data recorded ',
        keyword: 'yet today',
        suffix: '.',
      );
    }

    final int spread = highest - lowest;
    final int spikeCount = history.where((r) => r.bpm > 100).length;
    final double spikeRatio = spikeCount / history.length;

    // Elevated average
    if (avg > 100) {
      return (
        prefix: 'Your average rate has been ',
        keyword: 'elevated',
        suffix: ' today.',
      );
    }

    // Lots of spikes
    if (spikeRatio > 0.3) {
      return (
        prefix: 'You had ',
        keyword: 'several active spikes',
        suffix: ' today.',
      );
    }

    // A few spikes
    if (spikeRatio > 0.1) {
      return (
        prefix: 'You had a few ',
        keyword: 'active spikes',
        suffix: ' today.',
      );
    }

    // Wide range but calm avg
    if (spread > 40) {
      return (
        prefix: 'Your heart rate had a ',
        keyword: 'wide range',
        suffix: ' today.',
      );
    }

    // Low resting
    if (avg < 60) {
      return (
        prefix: 'You have been ',
        keyword: 'very calm',
        suffix: ' today.',
      );
    }

    // Normal calm
    if (avg <= 75 && spread < 25) {
      return (
        prefix: 'Your heart rate has been ',
        keyword: 'steady',
        suffix: ' today.',
      );
    }

    // Default
    return (
      prefix: 'Your average rate is in a ',
      keyword: 'normal range',
      suffix: ' today.',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final validHistory = _dailyHistory.where((r) => r.bpm > 0).toList();
    final int avg = validHistory.isEmpty
        ? widget.currentBpm
        : validHistory.map((r) => r.bpm).reduce((a, b) => a + b) ~/
            validHistory.length;
    final int lowest = validHistory.isEmpty
        ? widget.currentBpm
        : validHistory.map((r) => r.bpm).reduce(math.min);
    final int highest = validHistory.isEmpty
        ? widget.currentBpm
        : validHistory.map((r) => r.bpm).reduce(math.max);

    final dimColor = textColor.withValues(alpha: 0.4);
    final subColor = textColor.withValues(alpha: 0.55);
    final bool isDaily = _tab == 0;
    final bool isLoading = isDaily ? _loadingDaily : _loadingWeekly;

    // Weekly bar data
    const weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final int weekMax = math.max(
      _weeklyAvg.reduce(math.max),
      math.max(widget.currentBpm, 1),
    );

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
                            accentColor.withValues(
                                alpha: isDark ? 0.60 : 0.45),
                            accentColor.withValues(
                                alpha: isDark ? 0.32 : 0.22),
                            accentColor.withValues(
                                alpha: isDark ? 0.10 : 0.06),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: UniversalBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Insight
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Builder(builder: (_) {
                            final insight = _buildInsight(
                                validHistory, avg, lowest, highest);
                            return RichText(
                              text: TextSpan(
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  height: 1.3,
                                ),
                                children: [
                                  TextSpan(text: insight.prefix),
                                  TextSpan(
                                    text: insight.keyword,
                                    style: TextStyle(
                                        color: Colors.red.shade400),
                                  ),
                                  TextSpan(text: insight.suffix),
                                ],
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Segmented control
                                UniversalSegmentedControl<int>(
                                  items: const [0, 1],
                                  labels: const ['Daily', 'Weekly'],
                                  selectedItem: _tab,
                                  onSelectionChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _tab = v);
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Header: Heart Rate | Avg today
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Heart Rate',
                                              style: font(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor)),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                widget.currentBpm > 0
                                                    ? '${widget.currentBpm}'
                                                    : '--',
                                                style: font(
                                                    fontSize: 52,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: textColor,
                                                    height: 1.0),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        bottom: 8, left: 4),
                                                child: Text('BPM',
                                                    style: font(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: subColor)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('Avg today',
                                            style: font(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: dimColor)),
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              avg > 0 ? '$avg' : '--',
                                              style: font(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor,
                                                  height: 1.0),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4, left: 3),
                                              child: Text('BPM',
                                                  style: font(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: subColor)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Chart
                                isLoading
                                    ? const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: BouncingDotsLoader(),
                                        ),
                                      )
                                    : isDaily
                                        ? (validHistory.isEmpty
                                            ? SizedBox(
                                                height: 160,
                                                child: Center(
                                                  child: Text(
                                                    'No heart rate data today',
                                                    style: font(
                                                        fontSize: 13,
                                                        color: dimColor),
                                                  ),
                                                ),
                                              )
                                            : _HrRangeChart(
                                                history: validHistory,
                                                isDark: isDark,
                                                textColor: textColor,
                                              ))
                                        : _WeeklyHrChart(
                                            weeklyAvg: _weeklyAvg,
                                            weekMax: weekMax,
                                            accentColor: accentColor,
                                            isDark: isDark,
                                            textColor: textColor,
                                            weekLabels: weekLabels,
                                          ),

                                const SizedBox(height: 20),

                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Heart Rate Zones card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: _HrZones(
                              history: validHistory,
                              isDark: isDark,
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Lowest / Highest
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  label: 'Lowest',
                                  value: lowest > 0 ? '$lowest' : '--',
                                  unit: 'BPM',
                                  cardColor: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                  textColor: textColor,
                                  dimColor: dimColor,
                                  accentColor: Colors.blue.shade300,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatTile(
                                  label: 'Highest',
                                  value: highest > 0 ? '$highest' : '--',
                                  unit: 'BPM',
                                  cardColor: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                  textColor: textColor,
                                  dimColor: dimColor,
                                  accentColor: Colors.redAccent,
                                ),
                              ),
                            ],
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
// Weekly HR bar chart (avg BPM per day)
// ─────────────────────────────────────────────

class _WeeklyHrChart extends StatefulWidget {
  final List<int> weeklyAvg;
  final int weekMax;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final List<String> weekLabels;

  const _WeeklyHrChart({
    required this.weeklyAvg,
    required this.weekMax,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.weekLabels,
  });

  @override
  State<_WeeklyHrChart> createState() => _WeeklyHrChartState();
}

class _WeeklyHrChartState extends State<_WeeklyHrChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final labelColor = widget.textColor.withValues(alpha: 0.45);
    final axisColor = widget.textColor.withValues(alpha: 0.12);
    final int todayIdx = DateTime.now().weekday - 1;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _WeeklyHrPainter(
                bars: widget.weeklyAvg,
                roundedMax: widget.weekMax,
                accentColor: widget.accentColor,
                gridColor: axisColor,
                progress: _anim.value,
                todayIdx: todayIdx,
              ),
            ),
          ),
        ),
        Container(height: 1, color: axisColor),
        const SizedBox(height: 6),
        Row(
          children: List.generate(7, (i) => Expanded(
            child: Text(
              widget.weekLabels[i],
              textAlign: TextAlign.center,
              style: font(
                fontSize: 10,
                fontWeight: i == todayIdx
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: i == todayIdx
                    ? widget.accentColor
                    : labelColor,
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _WeeklyHrPainter extends CustomPainter {
  final List<int> bars;
  final int roundedMax;
  final Color accentColor;
  final Color gridColor;
  final double progress;
  final int todayIdx;

  const _WeeklyHrPainter({
    required this.bars,
    required this.roundedMax,
    required this.accentColor,
    required this.gridColor,
    required this.progress,
    required this.todayIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double slotW = size.width / bars.length;
    for (int i = 0; i < bars.length; i++) {
      if (bars[i] <= 0) continue;
      final double ratio =
          roundedMax > 0 ? (bars[i] / roundedMax).clamp(0.0, 1.0) : 0.0;
      final double barH = size.height * ratio * progress;
      if (barH < 1) continue;

      final double left = slotW * i + slotW * 0.2;
      final double right = slotW * (i + 1) - slotW * 0.2;
      final color = i == todayIdx
          ? accentColor
          : accentColor.withValues(alpha: 0.5);

      canvas.drawRRect(
        RRect.fromLTRBR(left, size.height - barH, right, size.height,
            const Radius.circular(5)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_WeeklyHrPainter old) =>
      old.progress != progress || old.bars != bars;
}

// ─────────────────────────────────────────────
// Stat tile
// ─────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color cardColor;
  final Color textColor;
  final Color dimColor;
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.cardColor,
    required this.textColor,
    required this.dimColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: font(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dimColor)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: font(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.0)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 3),
                child: Text(unit,
                    style: font(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dimColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Daily HR range chart
// ─────────────────────────────────────────────

class _HrRangeChart extends StatefulWidget {
  final List<({int bpm, DateTime time})> history;
  final bool isDark;
  final Color textColor;

  const _HrRangeChart({
    required this.history,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_HrRangeChart> createState() => _HrRangeChartState();
}

class _HrRangeChartState extends State<_HrRangeChart> {
  _HourBucket? _selected;

  List<_HourBucket> _buildBuckets() {
    final Map<int, List<int>> byHour = {};
    for (final r in widget.history) {
      byHour.putIfAbsent(r.time.hour, () => []).add(r.bpm);
    }
    final List<_HourBucket> buckets = [];
    for (int h = 0; h < 24; h++) {
      final readings = byHour[h];
      if (readings != null && readings.isNotEmpty) {
        buckets.add(_HourBucket(
          hour: h,
          min: readings.reduce(math.min),
          max: readings.reduce(math.max),
          avg: readings.reduce((a, b) => a + b) ~/ readings.length,
        ));
      }
    }
    return buckets;
  }

  void _handlePos(Offset localPos, double chartWidth) {
    final buckets = _buildBuckets();
    final double slotW = chartWidth / 24;
    final int tappedHour = (localPos.dx / slotW).floor().clamp(0, 23);
    final hit = buckets.where((b) => b.hour == tappedHour).firstOrNull;
    setState(() => _selected = hit);
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final labelColor = widget.textColor.withValues(alpha: 0.4);
    final buckets = _buildBuckets();
    const xLabels = <int>[0, 6, 12, 18];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reserved tooltip slot
        LayoutBuilder(builder: (context, constraints) {
          final chartWidth = constraints.maxWidth;
          const tooltipW = 160.0;
          double? left;
          if (_selected != null) {
            final slotW = chartWidth / 24;
            final barCx = slotW * _selected!.hour + slotW / 2;
            left = (barCx - tooltipW / 2).clamp(0.0, chartWidth - tooltipW);
          }
          return SizedBox(
            height: 56,
            child: _selected == null
                ? null
                : Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 0,
                        width: tooltipW,
                        child: _TooltipBubble(
                          key: ValueKey(_selected!.hour),
                          bucket: _selected!,
                          isDark: widget.isDark,
                          textColor: widget.textColor,
                        ),
                      ),
                    ],
                  ),
          );
        }),

        const SizedBox(height: 8),

        LayoutBuilder(builder: (context, constraints) {
          final chartWidth = constraints.maxWidth;
          return GestureDetector(
            onTapDown: (d) => _handlePos(d.localPosition, chartWidth),
            onHorizontalDragUpdate: (d) =>
                _handlePos(d.localPosition, chartWidth),
            onTapUp: (_) => setState(() => _selected = null),
            onHorizontalDragEnd: (_) => setState(() => _selected = null),
            child: SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _HrRangePainter(
                  buckets: buckets,
                  isDark: widget.isDark,
                  selectedHour: _selected?.hour,
                ),
                size: Size(chartWidth, 150),
              ),
            ),
          );
        }),

        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: xLabels.map((h) {
            String label;
            if (h == 0) {
              label = '12 AM';
            } else if (h == 12) {
              label = '12 PM';
            } else {
              label = '$h';
            }
            return Text(label,
                style: font(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: labelColor));
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Tooltip bubble
// ─────────────────────────────────────────────

class _TooltipBubble extends StatelessWidget {
  final _HourBucket bucket;
  final bool isDark;
  final Color textColor;

  const _TooltipBubble({
    super.key,
    required this.bucket,
    required this.isDark,
    required this.textColor,
  });

  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final dimColor = textColor.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RANGE',
                  style: font(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: dimColor,
                      letterSpacing: 0.8)),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${bucket.min}–${bucket.max}',
                      style: font(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.0)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 3),
                    child: Text('BPM',
                        style: font(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: dimColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(_hourLabel(bucket.hour),
              style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: dimColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hour bucket model
// ─────────────────────────────────────────────

class _HourBucket {
  final int hour, min, max, avg;
  const _HourBucket(
      {required this.hour,
      required this.min,
      required this.max,
      required this.avg});
}

// ─────────────────────────────────────────────
// Range bar painter
// ─────────────────────────────────────────────

class _HrRangePainter extends CustomPainter {
  final List<_HourBucket> buckets;
  final bool isDark;
  final int? selectedHour;

  static const Color _barColor = Color(0xFFFF375F);

  const _HrRangePainter({
    required this.buckets,
    required this.isDark,
    this.selectedHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    final int dataMax = buckets.map((b) => b.max).reduce(math.max);
    final int yMax = ((dataMax + 20) / 20).ceil() * 20;
    const int yMin = 0;
    final double yRange = (yMax - yMin).toDouble();

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10,
      color:
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
      fontWeight: FontWeight.w500,
    );

    for (final yVal in [0, yMax ~/ 2, yMax]) {
      final y = size.height - (yVal - yMin) / yRange * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '$yVal', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height - 1));
    }

    final double slotW = size.width / 24;
    const double barW = 4.0;
    const double dotR = 3.0;
    const double barRadius = 3.0;

    if (selectedHour != null) {
      final double cx = slotW * selectedHour! + slotW / 2;
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, size.height),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.25)
          ..strokeWidth = 1.0,
      );
    }

    for (final b in buckets) {
      final double cx = slotW * b.hour + slotW / 2;
      final double yTop =
          size.height - (b.max - yMin) / yRange * size.height;
      final double yBottom =
          size.height - (b.min - yMin) / yRange * size.height;

      canvas.drawRRect(
        RRect.fromLTRBR(cx - barW / 2, yTop, cx + barW / 2, yBottom,
            const Radius.circular(barRadius)),
        Paint()..color = _barColor,
      );

      final double yAvg =
          size.height - (b.avg - yMin) / yRange * size.height;
      canvas.drawCircle(Offset(cx, yAvg), dotR, Paint()..color = _barColor);
      canvas.drawCircle(
        Offset(cx, yAvg),
        dotR * 0.45,
        Paint()
          ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_HrRangePainter old) =>
      old.buckets.length != buckets.length ||
      old.selectedHour != selectedHour;
}

// ─────────────────────────────────────────────
// Heart Rate Zones
// ─────────────────────────────────────────────

// Standard HR zones (resting HR ~60, max ~200 for general adult)
// Resting:  < 60
// Normal:   60–99
// Elevated: 100–119
// High:     ≥ 120

class _HrZones extends StatelessWidget {
  final List<({int bpm, DateTime time})> history;
  final bool isDark;
  final Color textColor;
  final Color cardColor;

  const _HrZones({
    required this.history,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final total = history.length;

    if (total == 0) return const SizedBox.shrink();

    // Count readings per zone
    int resting = 0, normal = 0, elevated = 0, high = 0;
    for (final r in history) {
      if (r.bpm < 60) {
        resting++;
      } else if (r.bpm < 100) {
        normal++;
      } else if (r.bpm < 120) {
        elevated++;
      } else {
        high++;
      }
    }

    final zones = [
      if (resting > 0)
        _ZoneData(
          label: 'Resting',
          count: resting,
          total: total,
          color: const Color(0xFF5AC8FA), // blue
        ),
      _ZoneData(
        label: 'Normal',
        count: normal,
        total: total,
        color: const Color(0xFF34C759), // green
      ),
      _ZoneData(
        label: 'Elevated',
        count: elevated,
        total: total,
        color: const Color(0xFFFF9500), // orange
      ),
      _ZoneData(
        label: 'High',
        count: high,
        total: total,
        color: const Color(0xFFFF375F), // red-pink
      ),
    ];

    final dimColor = textColor.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heart Rate Zones',
          style: font(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 14),
        ...zones.map((z) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ZoneRow(
                zone: z,
                isDark: isDark,
                textColor: textColor,
                dimColor: dimColor,
              ),
            )),
      ],
    );
  }
}

class _ZoneData {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ZoneData({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  double get ratio => total > 0 ? count / total : 0.0;
  int get pct => (ratio * 100).round();
}

class _ZoneRow extends StatefulWidget {
  final _ZoneData zone;
  final bool isDark;
  final Color textColor;
  final Color dimColor;

  const _ZoneRow({
    required this.zone,
    required this.isDark,
    required this.textColor,
    required this.dimColor,
  });

  @override
  State<_ZoneRow> createState() => _ZoneRowState();
}

class _ZoneRowState extends State<_ZoneRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Slight stagger based on zone index isn't available here, just forward
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final z = widget.zone;
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mini ring
        SizedBox(
          width: 32,
          height: 32,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _MiniRingPainter(
                progress: _anim.value * z.ratio,
                color: z.color,
                trackColor: trackColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Label + bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(z.label,
                      style: font(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor)),
                  Text('${z.pct}%',
                      style: font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.textColor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 8,
                  color: trackColor,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => FractionallySizedBox(
                      widthFactor: _anim.value * z.ratio,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: z.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const strokeW = 3.0;

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
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress;
}
