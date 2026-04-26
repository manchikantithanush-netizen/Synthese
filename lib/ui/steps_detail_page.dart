import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health/health.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';

class StepsDetailPage extends StatefulWidget {
  final int todaySteps;

  const StepsDetailPage({super.key, required this.todaySteps});

  @override
  State<StepsDetailPage> createState() => _StepsDetailPageState();
}

class _StepsDetailPageState extends State<StepsDetailPage> {
  String _firstName = '';
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly

  // Daily: 24 hourly buckets
  List<int> _hourlySteps = List.filled(24, 0);
  bool _loadingDaily = true;

  // Weekly: Mon–Sun steps (index 0 = Mon)
  List<int> _weeklySteps = List.filled(7, 0);
  bool _loadingWeekly = true;

  // Monthly heatmap: day-of-month → steps (1-indexed)
  Map<int, int> _monthlySteps = {};
  bool _loadingMonthly = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchHourlySteps();
    _fetchWeeklySteps();
    _fetchMonthlySteps();
  }

  Future<void> _fetchUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final fullName = doc.data()?['fullName'] as String? ?? '';
        setState(() => _firstName = fullName.trim().split(' ').first);
      }
    } catch (_) {}
  }

  /// Fetch today's hourly steps from HealthKit (iOS) or Health Connect (Android).
  Future<void> _fetchHourlySteps() async {
    setState(() => _loadingDaily = true);
    try {
      final health = Health();
      await health.configure();

      const types = [HealthDataType.STEPS];
      const perms = [HealthDataAccess.READ];

      bool granted = false;
      if (Platform.isAndroid) {
        final available = await health.isHealthConnectAvailable();
        if (!available) return;
      }

      final hasPerm = await health.hasPermissions(types, permissions: perms);
      if (hasPerm != true) {
        granted = await health.requestAuthorization(types, permissions: perms);
        if (!granted) return;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final points = await health.getHealthDataFromTypes(
        startTime: todayStart,
        endTime: now,
        types: types,
      );
      final deduped = health.removeDuplicates(points);

      final List<int> hourly = List.filled(24, 0);
      for (final p in deduped) {
        if (p.type != HealthDataType.STEPS) continue;
        final hour = p.dateFrom.hour.clamp(0, 23);
        final val = p.value is NumericHealthValue
            ? (p.value as NumericHealthValue).numericValue.round()
            : 0;
        hourly[hour] += val;
      }

      if (mounted) setState(() => _hourlySteps = hourly);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  Future<void> _fetchWeeklySteps() async {
    setState(() => _loadingWeekly = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final List<int> steps = List.filled(7, 0);

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = _dateKey(day);
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dashboardDaily')
            .doc(key)
            .get();
        final daySteps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
        final idx = (day.weekday - 1).clamp(0, 6);
        steps[idx] = daySteps;
      }

      if (mounted) setState(() => _weeklySteps = steps);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  Future<void> _fetchMonthlySteps() async {
    setState(() => _loadingMonthly = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final Map<int, int> result = {};

      // Batch fetch all days of current month up to today
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
            final steps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
            result[day] = steps;
          }),
        );
      }
      await Future.wait(futures);

      if (mounted) setState(() => _monthlySteps = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  String _dateKey(DateTime date) {    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatLarge(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final bool isDaily = _selectedTab == 0;
    final bool isLoading = isDaily ? _loadingDaily : _loadingWeekly;

    // Daily: trim to last active hour, min 8 bars
    int lastNonZero = 7;
    for (int i = 23; i >= 0; i--) {
      if (_hourlySteps[i] > 0) { lastNonZero = i; break; }
    }
    final int hourCount = math.max(lastNonZero + 1, 8);
    final List<int> dailyBars = _hourlySteps.sublist(0, hourCount);

    final List<int> bars = isDaily ? dailyBars : _weeklySteps;
    final int maxVal = bars.isEmpty ? 1 : math.max(bars.reduce(math.max), 1);

    final nonZero = bars.where((v) => v > 0).toList();
    final int avg = nonZero.isEmpty
        ? 0
        : nonZero.reduce((a, b) => a + b) ~/ nonZero.length;

    final int displayNum = isDaily ? widget.todaySteps : avg;
    final String displayLabel = isDaily ? "Today's steps" : 'Avg. daily steps';

    const weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
              children: [
                // Accent glow
                Positioned(
                  top: 0, left: 0, right: 0, height: 260,
                  child: IgnorePointer(
                    child: DecoratedBox(
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
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: UniversalBackButton(
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        // Greeting
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: RichText(
                            text: TextSpan(
                              style: font(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.25,
                              ),
                              children: [
                                if (_firstName.isNotEmpty)
                                  TextSpan(text: 'Hey $_firstName,\n'),
                                const TextSpan(text: 'You walked '),
                                TextSpan(
                                  text: _formatLarge(widget.todaySteps),
                                  style: font(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                TextSpan(
                                  text: ' steps today',
                                  style: font(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Chart card
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
                                UniversalSegmentedControl<int>(
                                  items: const [0, 1],
                                  labels: const ['Daily', 'Weekly'],
                                  selectedItem: _selectedTab,
                                  onSelectionChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedTab = v);
                                  },
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  _formatLarge(displayNum),
                                  style: font(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayLabel,
                                  style: font(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                isLoading
                                    ? SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: accentColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : _StepsBarChart(
                                        bars: bars,
                                        maxVal: maxVal,
                                        accentColor: accentColor,
                                        isDark: isDark,
                                        textColor: textColor,
                                        isDaily: isDaily,
                                        weekLabels: weekLabels,
                                      ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Heatmap card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _MonthHeatmap(
                            monthlySteps: _monthlySteps,
                            isLoading: _loadingMonthly,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            stepGoal: 10000,
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
// Bar Chart
// ─────────────────────────────────────────────

class _StepsBarChart extends StatefulWidget {
  final List<int> bars;
  final int maxVal;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final bool isDaily;
  final List<String> weekLabels;

  const _StepsBarChart({
    required this.bars,
    required this.maxVal,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.isDaily,
    required this.weekLabels,
  });

  @override
  State<_StepsBarChart> createState() => _StepsBarChartState();
}

class _StepsBarChartState extends State<_StepsBarChart>
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
  void didUpdateWidget(_StepsBarChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars || old.isDaily != widget.isDaily) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _hourLabel(int hour) {
    if (hour == 0) return '12a';
    if (hour < 12) return '${hour}a';
    if (hour == 12) return '12p';
    return '${hour - 12}p';
  }

  String _fmtAxis(int n) {
    if (n >= 1000) return '${(n / 1000).round()}K';
    return n.toString();
  }

  int _roundMax(int val) {
    if (val <= 0) return 5000;
    final magnitude =
        math.pow(10, (math.log(val) / math.ln10).floor()).toInt();
    return ((val / magnitude).ceil()) * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final int roundedMax = _roundMax(widget.maxVal);
    final yLabels = [
      0,
      (roundedMax * 0.25).round(),
      (roundedMax * 0.5).round(),
      (roundedMax * 0.75).round(),
      roundedMax,
    ];

    final axisColor = widget.textColor.withValues(alpha: 0.15);
    final labelColor = widget.textColor.withValues(alpha: 0.45);
    final font = GoogleFonts.plusJakartaSans;

    final int barCount = widget.bars.length;
    final bool manyBars = barCount > 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels
              SizedBox(
                width: 32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels.reversed
                      .map((v) => Text(
                            _fmtAxis(v),
                            style: font(
                              color: labelColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Chart area — CustomPaint draws grid + bars together
              Expanded(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    painter: _BarChartPainter(
                      bars: widget.bars,
                      roundedMax: roundedMax,
                      accentColor: widget.accentColor,
                      gridColor: axisColor,
                      progress: _anim.value,
                      gridLevels: 4,
                      barSpacing: manyBars ? 2.0 : 4.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Baseline
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Container(height: 1, color: axisColor),
        ),
        const SizedBox(height: 6),

        // X-axis labels
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: List.generate(barCount, (i) {
              final label = widget.isDaily
                  ? _hourLabel(i)
                  : (i < widget.weekLabels.length ? widget.weekLabels[i] : '');
              final show = widget.isDaily ? (i % 3 == 0) : true;
              return Expanded(
                child: show
                    ? Text(
                        label,
                        textAlign: TextAlign.center,
                        style: font(
                          color: labelColor,
                          fontSize: manyBars ? 9 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainter — draws grid lines THEN solid bars on top
// ─────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<int> bars;
  final int roundedMax;
  final Color accentColor;
  final Color gridColor;
  final double progress; // 0.0 → 1.0 animation
  final int gridLevels;
  final double barSpacing;

  const _BarChartPainter({
    required this.bars,
    required this.roundedMax,
    required this.accentColor,
    required this.gridColor,
    required this.progress,
    required this.gridLevels,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    // 1. Draw grid lines first (behind bars)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 1; i <= gridLevels; i++) {
      final y = size.height * (1 - i / gridLevels);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw bars on top — solid, no transparency issues
    final int count = bars.length;
    final double slotW = size.width / count;
    const double cornerRadius = 6.0;

    for (int i = 0; i < count; i++) {
      if (bars[i] <= 0) continue;

      final double ratio =
          roundedMax > 0 ? (bars[i] / roundedMax).clamp(0.0, 1.0) : 0.0;
      final double barH = size.height * ratio * progress;
      if (barH < 1) continue;

      final double left = slotW * i + barSpacing;
      final double right = slotW * (i + 1) - barSpacing;
      final double top = size.height - barH;
      final double bottom = size.height;

      final rect = RRect.fromLTRBR(
        left, top, right, bottom,
        const Radius.circular(cornerRadius),
      );

      final barPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.bars != bars ||
      old.accentColor != accentColor ||
      old.roundedMax != roundedMax;
}

// ─────────────────────────────────────────────
// Monthly Heatmap
// ─────────────────────────────────────────────

class _MonthHeatmap extends StatelessWidget {
  final Map<int, int> monthlySteps; // day (1-indexed) → steps
  final bool isLoading;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final int stepGoal;

  const _MonthHeatmap({
    required this.monthlySteps,
    required this.isLoading,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.stepGoal,
  });

  /// Returns opacity 0.0–1.0 based on steps vs goal.
  /// 0 steps → 0.08 (barely visible ghost)
  /// goal met → 1.0 (full accent color)
  double _cellOpacity(int? steps) {
    if (steps == null || steps <= 0) return 0.08;
    final ratio = (steps / stepGoal).clamp(0.0, 1.0);
    // Map 0→0.12, 0.25→0.35, 0.5→0.55, 0.75→0.75, 1.0→1.0
    return 0.12 + ratio * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final font = GoogleFonts.plusJakartaSans;

    // Month name
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel = '${monthNames[month]} $year';

    // First weekday of month: Mon=0 … Sun=6
    final int firstWeekday = (DateTime(year, month, 1).weekday - 1).clamp(0, 6);

    // Total cells = leading empty + days
    final int totalCells = firstWeekday + daysInMonth;
    // Rows of 7
    final int rows = (totalCells / 7).ceil();

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final labelColor = textColor.withValues(alpha: 0.4);
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              // Legend
              Row(
                children: [
                  Text(
                    'Less',
                    style: font(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final opacity = 0.12 + (i / 4) * 0.88;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: font(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day-of-week header + grid — fills full card width
          LayoutBuilder(
            builder: (context, constraints) {
              const int cols = 7;
              const double gap = 4.0;
              final double cellSize =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              Widget buildCell(Color color, {bool isToday = false}) {
                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: accentColor, width: 1.5)
                        : null,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(cols, (i) => SizedBox(
                      width: cellSize,
                      child: Center(
                        child: Text(
                          dayLabels[i],
                          style: font(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                      ),
                    )),
                  ),

                  const SizedBox(height: 6),

                  // Grid rows
                  isLoading
                      ? SizedBox(
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 2,
                            ),
                          ),
                        )
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

                                  final steps = monthlySteps[day];
                                  final Color cellColor = isFuture
                                      ? emptyColor
                                      : accentColor.withValues(
                                          alpha: _cellOpacity(steps));

                                  return buildCell(
                                    cellColor,
                                    isToday: day == now.day,
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
