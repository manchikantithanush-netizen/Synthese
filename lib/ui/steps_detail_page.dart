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
      // Find this week's Monday
      final int daysSinceMonday = now.weekday - 1; // Mon=0, Sun=6
      final DateTime monday = DateTime(
          now.year, now.month, now.day - daysSinceMonday);

      final List<int> steps = List.filled(7, 0);

      for (int i = 0; i <= daysSinceMonday; i++) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dashboardDaily')
            .doc(key)
            .get();
        final daySteps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
        steps[i] = daySteps; // i=0 is Mon, i=6 is Sun
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

                                // Energy bar
                                _EnergyBar(
                                  progress: (widget.todaySteps / 10000.0).clamp(0.0, 1.0),
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                ),

                                const SizedBox(height: 16),

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

                        // Distance card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _DistanceCard(
                            steps: widget.todaySteps,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Weekly rings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _WeeklyRings(
                            weeklySteps: _weeklySteps,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            stepGoal: 10000,
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
// Weekly Rings
// ─────────────────────────────────────────────

class _WeeklyRings extends StatelessWidget {
  final List<int> weeklySteps; // index 0=Mon … 6=Sun
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final int stepGoal;

  const _WeeklyRings({
    required this.weeklySteps,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.stepGoal,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final dimColor = textColor.withValues(alpha: 0.35);
    // Today's weekday index: Mon=0 … Sun=6
    final int todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final steps = weeklySteps.length > i ? weeklySteps[i] : 0;
          final double progress = (steps / stepGoal).clamp(0.0, 1.0);
          final bool isToday = i == todayIdx;
          // Future days (after today this week) — no data yet
          final bool isFuture = i > todayIdx;

          return Column(
            children: [
              _RingCircle(
                progress: isFuture ? 0.0 : progress,
                accentColor: accentColor,
                isDark: isDark,
                isToday: isToday,
                isFuture: isFuture,
                textColor: textColor,
              ),
              const SizedBox(height: 6),
              Text(
                isToday ? 'Today' : labels[i],
                style: font(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? accentColor : dimColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RingCircle extends StatefulWidget {
  final double progress;
  final Color accentColor;
  final bool isDark;
  final bool isToday;
  final bool isFuture;
  final Color textColor;

  const _RingCircle({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.isToday,
    required this.isFuture,
    required this.textColor,
  });

  @override
  State<_RingCircle> createState() => _RingCircleState();
}

class _RingCircleState extends State<_RingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Stagger by index isn't available here, just forward
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(38, 38),
        painter: _RingPainter(
          progress: _anim.value * widget.progress,
          accentColor: widget.accentColor,
          isDark: widget.isDark,
          isToday: widget.isToday,
          isFuture: widget.isFuture,
          textColor: widget.textColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isDark;
  final bool isToday;
  final bool isFuture;
  final Color textColor;

  const _RingPainter({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.isToday,
    required this.isFuture,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;
    const strokeW = 3.5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: isFuture ? 0.06 : 0.10)
            : Colors.black.withValues(alpha: isFuture ? 0.06 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center dot — solid for today, small dim for others
    if (isToday) {
      canvas.drawCircle(
        center,
        4,
        Paint()..color = accentColor,
      );
      canvas.drawCircle(
        center,
        2,
        Paint()
          ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
      );
    } else if (!isFuture && progress >= 1.0) {
      // Goal met — small filled dot
      canvas.drawCircle(
        center,
        3,
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accentColor != accentColor ||
      old.isToday != isToday;
}

// ─────────────────────────────────────────────
// Distance Card
// ─────────────────────────────────────────────

class _DistanceCard extends StatelessWidget {
  final int steps;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  // Average stride length ~0.762 m
  static const double _strideM = 0.762;

  const _DistanceCard({
    required this.steps,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double km = (steps * _strideM) / 1000.0;
    final String distStr = km >= 10
        ? km.toStringAsFixed(1)
        : km.toStringAsFixed(2);

    final font = GoogleFonts.plusJakartaSans;
    final dimColor = textColor.withValues(alpha: 0.35);
    final subColor = textColor.withValues(alpha: 0.55);

    // Progress along a 5 km "daily route" goal
    final double routeProgress = (km / 5.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: number + label + splits ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distance',
                  style: font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dimColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distStr,
                      style: font(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 5),
                      child: Text(
                        'km',
                        style: font(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '≈ ${(steps * _strideM).round()} m  ·  ${steps.toString()} steps',
                  style: font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: dimColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── Right: vertical route track ──
          SizedBox(
            width: 48,
            height: 110,
            child: CustomPaint(
              painter: _RoutePainter(
                progress: routeProgress,
                accentColor: accentColor,
                dimColor: dimColor,
                isDark: isDark,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Far right: 0 km / 5 km labels ──
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '5 km',
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dimColor,
                ),
              ),
              SizedBox(height: 80),
              Text(
                '0',
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dimColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color accentColor;
  final Color dimColor;
  final bool isDark;

  const _RoutePainter({
    required this.progress,
    required this.accentColor,
    required this.dimColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cx = 24;
    const double dotR = 5.0;
    const double endDotR = 4.0;
    const double dashLen = 5.0;
    const double dashGap = 4.0;

    final trackPaint = Paint()
      ..color = dimColor.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final filledPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double topY = dotR;
    final double bottomY = size.height - dotR;
    final double progressY = bottomY - (bottomY - topY) * progress;

    // Draw dashed track — unfilled portion (above progress dot)
    double y = topY;
    while (y < progressY - dotR) {
      final end = math.min(y + dashLen, progressY - dotR);
      canvas.drawLine(Offset(cx, y), Offset(cx, end), trackPaint);
      y += dashLen + dashGap;
    }

    // Draw solid filled track — below progress dot to bottom
    canvas.drawLine(
      Offset(cx, progressY + dotR),
      Offset(cx, bottomY),
      filledPaint,
    );

    // Bottom dot (start)
    canvas.drawCircle(
      Offset(cx, bottomY),
      endDotR,
      Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.black,
    );

    // Progress dot (current position)
    canvas.drawCircle(
      Offset(cx, progressY),
      dotR,
      Paint()..color = accentColor,
    );
    // Inner white dot
    canvas.drawCircle(
      Offset(cx, progressY),
      dotR * 0.45,
      Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

// ─────────────────────────────────────────────
// Energy Bar
// ─────────────────────────────────────────────

class _EnergyBar extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final Color accentColor;
  final bool isDark;
  final Color textColor;

  const _EnergyBar({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_EnergyBar> createState() => _EnergyBarState();
}

class _EnergyBarState extends State<_EnergyBar>
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
    final pct = (widget.progress * 100).round();
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Label
          Text(
            'Daily Goal',
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.textColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 12),
          // Bar track
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: _anim.value * widget.progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Percentage
          Text(
            '$pct%',
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.accentColor,
            ),
          ),
        ],
      ),
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
