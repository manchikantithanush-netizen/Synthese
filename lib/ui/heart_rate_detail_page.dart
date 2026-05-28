import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/metric_add_data_sheet.dart';
import 'package:synthese/ui/heart_rate_measure_page.dart';

class HeartRateDetailPage extends StatefulWidget {
  final int currentBpm;
  final ValueChanged<int>? onManualHeartRateAdded;

  const HeartRateDetailPage({
    super.key,
    required this.currentBpm,
    this.onManualHeartRateAdded,
  });

  @override
  State<HeartRateDetailPage> createState() => _HeartRateDetailPageState();
}

class _HeartRateDetailPageState extends State<HeartRateDetailPage> {
  int _tab = 0; // 0 = Daily, 1 = Weekly
  late int _currentBpm;

  // Daily: full intraday readings for today
  List<({int bpm, DateTime time})> _dailyHistory = [];
  bool _loadingDaily = true;

  // Weekly: Mon–Sun *max* BPM per day (index 0 = Mon)
  List<int> _weeklyMax = List.filled(7, 0);
  bool _loadingWeekly = true;

  @override
  void initState() {
    super.initState();
    _currentBpm = widget.currentBpm;
    _fetchDailyHr();
    _fetchWeeklyHr();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addManualHeartRate({
    required DateTime when,
    required int bpm,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final dayKey = _dateKey(when);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(dayKey)
        .set({
          'heartRate': bpm,
          'hrHistory': FieldValue.arrayUnion([
            {'bpm': bpm, 'time': Timestamp.fromDate(when)},
          ]),
          'dateKey': dayKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      if (_isSameDay(when, DateTime.now())) {
        _currentBpm = bpm;
      }
      _dailyHistory.add((bpm: bpm, time: when));
      _dailyHistory.sort((a, b) => a.time.compareTo(b.time));
      final idx = (when.weekday - 1).clamp(0, 6);
      _weeklyMax[idx] = math.max(_weeklyMax[idx], bpm);
    });
    if (_isSameDay(when, DateTime.now())) {
      widget.onManualHeartRateAdded?.call(bpm);
    }
  }

  Future<void> _measureHeartRateLive() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const HeartRateMeasurePage(),
        fullscreenDialog: true,
      ),
    );
    if (result != null && result > 0) {
      await _addManualHeartRate(when: DateTime.now(), bpm: result);
    }
  }

  Future<void> _showAddDataSheet({
    required Color accentColor,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => MetricAddDataSheet(
        title: AppLocalizations.of(context).dashHeartRate,
        valueLabel: AppLocalizations.of(context).hrDetBpm,
        valueHint: AppLocalizations.of(context).hrDetEnterBpm,
        accentColor: accentColor,
        isDark: isDark,
        textColor: textColor,
        cardColor: cardColor,
        icon: Icons.favorite_border,
        iconColor: Colors.redAccent,
        onSave: ({required when, required value}) =>
            _addManualHeartRate(when: when, bpm: value),
      ),
    );
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
  // Loads persisted readings from Firestore (survives restarts)

  Future<void> _fetchDailyHr() async {
    setState(() => _loadingDaily = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final dayKey = _dateKey(now);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .get();
      final raw = doc.data()?['hrHistory'] as List<dynamic>?;
      if (raw != null) {
        final stored = raw
            .map((e) {
              final bpm = (e['bpm'] as num?)?.toInt() ?? 0;
              final ts = (e['time'] as Timestamp?)?.toDate() ?? now;
              return (bpm: bpm, time: ts);
            })
            .where((r) => r.bpm > 0 && !r.time.isBefore(todayStart))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        if (mounted) setState(() => _dailyHistory = stored);
      }
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
      final List<int> maxes = List.filled(7, 0);

      // Seed today's slot with currentBpm immediately so it always shows
      maxes[daysSinceMonday] = _currentBpm;

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
                // Compute peak BPM from hrHistory (preferred — full picture)
                final raw = data['hrHistory'] as List<dynamic>?;
                if (raw != null && raw.isNotEmpty) {
                  final bpms = raw
                      .map((e) => (e['bpm'] as num?)?.toInt() ?? 0)
                      .where((b) => b > 0)
                      .toList();
                  if (bpms.isNotEmpty) {
                    maxes[i] = bpms.reduce(math.max);
                    return;
                  }
                }
                // Fallback to stored heartRate field
                final hr = (data['heartRate'] as num?)?.toInt();
                if (hr != null && hr > 0) {
                  maxes[i] = hr;
                }
              }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _weeklyMax = maxes);
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
    AppLocalizations t,
    List<({int bpm, DateTime time})> history,
    int avg,
    int lowest,
    int highest,
  ) {
    if (history.isEmpty) {
      return (
        prefix: t.hrDetInsNoneP,
        keyword: t.hrDetInsNoneK,
        suffix: t.hrDetInsNoneS,
      );
    }

    final int spread = highest - lowest;
    final int spikeCount = history.where((r) => r.bpm > 100).length;
    final double spikeRatio = spikeCount / history.length;

    // Elevated average
    if (avg > 100) {
      return (
        prefix: t.hrDetInsElevatedP,
        keyword: t.hrDetInsElevatedK,
        suffix: t.hrDetInsElevatedS,
      );
    }

    // Lots of spikes
    if (spikeRatio > 0.3) {
      return (
        prefix: t.hrDetInsManyP,
        keyword: t.hrDetInsManyK,
        suffix: t.hrDetInsManyS,
      );
    }

    // A few spikes
    if (spikeRatio > 0.1) {
      return (
        prefix: t.hrDetInsFewP,
        keyword: t.hrDetInsFewK,
        suffix: t.hrDetInsFewS,
      );
    }

    // Wide range but calm avg
    if (spread > 40) {
      return (
        prefix: t.hrDetInsWideP,
        keyword: t.hrDetInsWideK,
        suffix: t.hrDetInsWideS,
      );
    }

    // Low resting
    if (avg < 60) {
      return (
        prefix: t.hrDetInsCalmP,
        keyword: t.hrDetInsCalmK,
        suffix: t.hrDetInsCalmS,
      );
    }

    // Normal calm
    if (avg <= 75 && spread < 25) {
      return (
        prefix: t.hrDetInsSteadyP,
        keyword: t.hrDetInsSteadyK,
        suffix: t.hrDetInsSteadyS,
      );
    }

    // Default
    return (
      prefix: t.hrDetInsNormalP,
      keyword: t.hrDetInsNormalK,
      suffix: t.hrDetInsNormalS,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final validHistory = _dailyHistory.where((r) => r.bpm > 0).toList();
    final int avg = validHistory.isEmpty
        ? _currentBpm
        : validHistory.map((r) => r.bpm).reduce((a, b) => a + b) ~/
              validHistory.length;
    final int lowest = validHistory.isEmpty
        ? _currentBpm
        : validHistory.map((r) => r.bpm).reduce(math.min);
    final int highest = validHistory.isEmpty
        ? _currentBpm
        : validHistory.map((r) => r.bpm).reduce(math.max);

    final dimColor = textColor.withValues(alpha: 0.4);
    final subColor = textColor.withValues(alpha: 0.55);
    final bool isDaily = _tab == 0;
    final bool isLoading = isDaily ? _loadingDaily : _loadingWeekly;

    // Weekly bar data
    final mondayLabel = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekLabels = List.generate(
      7,
      (i) => DateFormat('EEE', localeName).format(mondayLabel.add(Duration(days: i))),
    );
    final int weekMax = math.max(
      _weeklyMax.reduce(math.max),
      math.max(_currentBpm, 1),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                          child: Row(
                            children: [
                              UniversalBackButton(
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () => _showAddDataSheet(
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  cardColor: cardColor,
                                ),
                                icon: Icon(Icons.add_rounded,
                                    size: 16, color: textColor),
                                label: Text(
                                  t.detailAddData,
                                  style: font(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.15),
                                  ),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Insight
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Builder(
                            builder: (_) {
                              final insight = _buildInsight(
                                t,
                                validHistory,
                                avg,
                                lowest,
                                highest,
                              );
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
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                    TextSpan(text: insight.suffix),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Segmented control
                                UniversalSegmentedControl<int>(
                                  items: const [0, 1],
                                  labels: [t.detailDaily, t.detailWeekly],
                                  selectedItem: _tab,
                                  onSelectionChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _tab = v);
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Header: Heart Rate | Avg today
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.dashHeartRate,
                                            style: font(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _currentBpm > 0
                                                    ? '$_currentBpm'
                                                    : '--',
                                                style: font(
                                                  fontSize: 52,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                  height: 1.0,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                  left: 4,
                                                ),
                                                child: Text(
                                                  t.hrDetBpm,
                                                  style: font(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: subColor,
                                                  ),
                                                ),
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
                                        Text(
                                          t.hrDetAvgToday,
                                          style: font(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: dimColor,
                                          ),
                                        ),
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
                                                height: 1.0,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                                left: 3,
                                              ),
                                              child: Text(
                                                t.hrDetBpm,
                                                style: font(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: subColor,
                                                ),
                                              ),
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
                                                  t.hrDetNoDataToday,
                                                  style: font(
                                                    fontSize: 13,
                                                    color: dimColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _HrRangeChart(
                                              history: validHistory,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ))
                                    : _WeeklyHrChart(
                                        weeklyMax: _weeklyMax,
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

                        // Read your heart now CTA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ReadHeartNowButton(
                            onPressed: _measureHeartRateLive,
                            isDark: isDark,
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
                                  label: t.hrDetLowest,
                                  value: lowest > 0 ? '$lowest' : '--',
                                  unit: t.hrDetBpm,
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
                                  label: t.hrDetHighest,
                                  value: highest > 0 ? '$highest' : '--',
                                  unit: t.hrDetBpm,
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
  final List<int> weeklyMax;
  final int weekMax;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final List<String> weekLabels;

  const _WeeklyHrChart({
    required this.weeklyMax,
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
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
    final labelColor = widget.textColor.withValues(alpha: 0.55);
    final scaleColor = widget.textColor.withValues(alpha: 0.35);
    final axisColor = widget.textColor.withValues(alpha: 0.12);
    final int todayIdx = DateTime.now().weekday - 1;

    // Reserved column on the right for Y-axis BPM labels so the last bar
    // (Sunday) doesn't share horizontal space with them.
    const double yLabelInset = 28.0;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _WeeklyHrPainter(
                bars: widget.weeklyMax,
                roundedMax: widget.weekMax,
                accentColor: widget.accentColor,
                gridColor: axisColor,
                scaleColor: scaleColor,
                progress: _anim.value,
                todayIdx: todayIdx,
                rightInset: yLabelInset,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: yLabelInset),
          child: Container(height: 1, color: axisColor),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: yLabelInset),
          child: Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Text(
                  widget.weekLabels[i],
                  textAlign: TextAlign.center,
                  style: font(
                    fontSize: 11,
                    fontWeight:
                        i == todayIdx ? FontWeight.w700 : FontWeight.w500,
                    color: i == todayIdx ? widget.accentColor : labelColor,
                  ),
                ),
              ),
            ),
          ),
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
  final Color scaleColor;
  final double progress;
  final int todayIdx;
  final double rightInset;

  const _WeeklyHrPainter({
    required this.bars,
    required this.roundedMax,
    required this.accentColor,
    required this.gridColor,
    required this.scaleColor,
    required this.progress,
    required this.todayIdx,
    required this.rightInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bars + grid live in the left portion; Y-axis labels in the right inset.
    final double chartW = (size.width - rightInset).clamp(0.0, size.width);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
    }

    // Y-axis BPM scale labels (right column)
    if (roundedMax > 0) {
      final labelStyle = GoogleFonts.plusJakartaSans(
        fontSize: 10,
        color: scaleColor,
        fontWeight: FontWeight.w500,
      );
      for (final yVal in [0, roundedMax ~/ 2, roundedMax]) {
        final y = size.height * (1 - yVal / roundedMax);
        final tp = TextPainter(
          text: TextSpan(text: '$yVal', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        // Center the label vertically on the grid line, and place it inside
        // the reserved right column so it never overlaps the last bar.
        tp.paint(
          canvas,
          Offset(chartW + 6, y - tp.height / 2),
        );
      }
    }

    final double slotW = chartW / bars.length;
    for (int i = 0; i < bars.length; i++) {
      if (bars[i] <= 0) continue;
      final double ratio = roundedMax > 0
          ? (bars[i] / roundedMax).clamp(0.0, 1.0)
          : 0.0;
      final double barH = size.height * ratio * progress;
      if (barH < 1) continue;

      final double left = slotW * i + slotW * 0.2;
      final double right = slotW * (i + 1) - slotW * 0.2;
      final color = i == todayIdx
          ? accentColor
          : accentColor.withValues(alpha: 0.5);

      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          size.height - barH,
          right,
          size.height,
          const Radius.circular(5),
        ),
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
          Text(
            label,
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dimColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: font(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4, start: 3),
                child: Text(
                  unit,
                  style: font(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dimColor,
                  ),
                ),
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
        buckets.add(
          _HourBucket(
            hour: h,
            min: readings.reduce(math.min),
            max: readings.reduce(math.max),
            avg: readings.reduce((a, b) => a + b) ~/ readings.length,
          ),
        );
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
    final localeName = Localizations.localeOf(context).toString();
    final labelColor = widget.textColor.withValues(alpha: 0.4);
    final buckets = _buildBuckets();
    const xLabels = <int>[0, 6, 12, 18];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reserved tooltip slot
        LayoutBuilder(
          builder: (context, constraints) {
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
          },
        ),

        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
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
          },
        ),

        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: xLabels.map((h) {
            final label = DateFormat('h a', localeName)
                .format(DateTime(2020, 1, 1, h));
            return Text(
              label,
              style: font(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            );
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

  String _hourLabel(BuildContext context, int h) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('h a', localeName).format(DateTime(2020, 1, 1, h));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final dimColor = textColor.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.hrDetRange,
                style: font(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: dimColor,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _hourLabel(context, bucket.hour),
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: dimColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bucket.min}–${bucket.max}',
                style: font(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 2, start: 3),
                child: Text(
                  t.hrDetBpm,
                  style: font(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dimColor,
                  ),
                ),
              ),
            ],
          ),
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
  const _HourBucket({
    required this.hour,
    required this.min,
    required this.max,
    required this.avg,
  });
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
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35),
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
          ..color = (isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.25,
          )
          ..strokeWidth = 1.0,
      );
    }

    for (final b in buckets) {
      final double cx = slotW * b.hour + slotW / 2;
      final double yTop = size.height - (b.max - yMin) / yRange * size.height;
      final double yBottom =
          size.height - (b.min - yMin) / yRange * size.height;

      canvas.drawRRect(
        RRect.fromLTRBR(
          cx - barW / 2,
          yTop,
          cx + barW / 2,
          yBottom,
          const Radius.circular(barRadius),
        ),
        Paint()..color = _barColor,
      );

      final double yAvg = size.height - (b.avg - yMin) / yRange * size.height;
      canvas.drawCircle(Offset(cx, yAvg), dotR, Paint()..color = _barColor);
      canvas.drawCircle(
        Offset(cx, yAvg),
        dotR * 0.45,
        Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_HrRangePainter old) =>
      old.buckets.length != buckets.length || old.selectedHour != selectedHour;
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
    final t = AppLocalizations.of(context);
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
          label: t.hrDetZoneResting,
          count: resting,
          total: total,
          color: const Color(0xFF5AC8FA), // blue
        ),
      _ZoneData(
        label: t.hrDetZoneNormal,
        count: normal,
        total: total,
        color: const Color(0xFF34C759), // green
      ),
      _ZoneData(
        label: t.hrDetZoneElevated,
        count: elevated,
        total: total,
        color: const Color(0xFFFF9500), // orange
      ),
      _ZoneData(
        label: t.hrDetZoneHigh,
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
          t.hrDetZonesTitle,
          style: font(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 14),
        ...zones.map(
          (z) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ZoneRow(
              zone: z,
              isDark: isDark,
              textColor: textColor,
              dimColor: dimColor,
            ),
          ),
        ),
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
                  Text(
                    z.label,
                    style: font(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                  ),
                  Text(
                    '${z.pct}%',
                    style: font(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                  ),
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
                      alignment: AlignmentDirectional.centerStart,
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
  bool shouldRepaint(_MiniRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// Read-your-heart-now CTA
// ─────────────────────────────────────────────

class _ReadHeartNowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDark;

  const _ReadHeartNowButton({
    required this.onPressed,
    required this.isDark,
  });

  @override
  State<_ReadHeartNowButton> createState() => _ReadHeartNowButtonState();
}

class _ReadHeartNowButtonState extends State<_ReadHeartNowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.30 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF5C70),
                Color(0xFFFF2D55),
              ],
            ),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                    CurvedAnimation(
                      parent: _pulseCtrl,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.hrDetReadNow,
                              style: font(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BETA',
                              style: font(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.hrDetReadNowSub,
                        style: font(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
