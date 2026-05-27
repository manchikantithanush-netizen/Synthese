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
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class CaloriesDetailPage extends StatefulWidget {
  final int activeCalories;
  final int eatenCalories;
  final int burnGoal;
  final int eatGoal;
  final ValueChanged<int>? onManualBurnedCaloriesAdded;

  const CaloriesDetailPage({
    super.key,
    required this.activeCalories,
    this.eatenCalories = 0,
    this.burnGoal = 500,
    this.eatGoal = 2000,
    this.onManualBurnedCaloriesAdded,
  });

  @override
  State<CaloriesDetailPage> createState() => _CaloriesDetailPageState();
}

class _CaloriesDetailPageState extends State<CaloriesDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late int _activeCalories;

  int get _burnGoal => widget.burnGoal;
  int get _eatGoal => widget.eatGoal;

  // Weekly trend: Mon–Sun (index 0=Mon)
  List<int> _weeklyBurned = List.filled(7, 0);
  List<int> _weeklyEaten = List.filled(7, 0);

  // Monthly heatmap: day → net calories (positive=surplus, negative=deficit)
  Map<int, int> _monthlyNet = {};
  bool _loadingMonthly = true;

  @override
  void initState() {
    super.initState();
    _activeCalories = widget.activeCalories;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    _fetchWeeklyData();
    _fetchMonthlyData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime get _thisMonday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addManualBurnedCalories({
    required DateTime when,
    required int calories,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final key = _dateKey(when);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(key)
        .set({
          'activeCalories': FieldValue.increment(calories),
          'dateKey': key,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      if (_isSameDay(when, DateTime.now())) {
        _activeCalories += calories;
      }
      final idx = (when.weekday - 1).clamp(0, 6);
      _weeklyBurned[idx] += calories;
      if (when.year == DateTime.now().year &&
          when.month == DateTime.now().month) {
        final day = when.day;
        _monthlyNet[day] = (_monthlyNet[day] ?? 0) - calories;
      }
    });
    if (_isSameDay(when, DateTime.now())) {
      widget.onManualBurnedCaloriesAdded?.call(calories);
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
      builder: (_) => _CaloriesAddSheet(
        isDark: isDark,
        textColor: textColor,
        onSaveBurned: (when, cal) =>
            _addManualBurnedCalories(when: when, calories: cal),
      ),
    );
  }

  Future<void> _fetchWeeklyData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final monday = _thisMonday;
      final int daysSinceMonday = now.weekday - 1;

      final List<int> burned = List.filled(7, 0);
      final List<int> eaten = List.filled(7, 0);

      final futures = <Future<void>>[];
      for (int i = 0; i <= daysSinceMonday; i++) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        // Burned from dashboardDaily
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dashboardDaily')
              .doc(key)
              .get()
              .then((d) {
                burned[i] = (d.data()?['activeCalories'] as num?)?.toInt() ?? 0;
              }),
        );
        // Eaten from dailyAgg
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dailyAgg')
              .doc(key)
              .get()
              .then((d) {
                eaten[i] = (d.data()?['caloriesLogged'] as num?)?.toInt() ?? 0;
              }),
        );
      }
      await Future.wait(futures);
      if (mounted)
        setState(() {
          _weeklyBurned = burned;
          _weeklyEaten = eaten;
        });
    } catch (_) {
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchMonthlyData() async {
    setState(() => _loadingMonthly = true);
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
        int burned = 0, eaten = 0;
        futures.add(
          Future.wait([
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('dashboardDaily')
                .doc(key)
                .get()
                .then((d) {
                  burned = (d.data()?['activeCalories'] as num?)?.toInt() ?? 0;
                }),
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('dailyAgg')
                .doc(key)
                .get()
                .then((d) {
                  eaten = (d.data()?['caloriesLogged'] as num?)?.toInt() ?? 0;
                }),
          ]).then((_) {
            result[day] = eaten - burned;
          }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _monthlyNet = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  ({String prefix, String keyword, String suffix}) _buildInsight(
    AppLocalizations t,
  ) {
    final int burned = _activeCalories;
    final int eaten = widget.eatenCalories;
    final int net = eaten - burned;
    final double pct = _burnGoal > 0 ? burned / _burnGoal : 0;

    if (burned == 0 && eaten == 0) {
      return (
        prefix: t.calDetInsNoneP,
        keyword: t.calDetInsNoneK,
        suffix: t.calDetInsNoneS,
      );
    }
    if (burned == 0) {
      return (
        prefix: t.calDetInsNoBurnP,
        keyword: t.calDetInsNoBurnK,
        suffix: t.calDetInsNoBurnS,
      );
    }
    if (pct >= 1.0) {
      return (
        prefix: t.calDetInsGoalP,
        keyword: t.calDetInsGoalK,
        suffix: t.calDetInsGoalS,
      );
    }
    if (net < -500) {
      return (
        prefix: t.calDetInsDeficitP,
        keyword: t.calDetInsDeficitK,
        suffix: t.calDetInsDeficitS,
      );
    }
    if (net > 500) {
      return (
        prefix: t.calDetInsSurplusP,
        keyword: t.calDetInsSurplusK,
        suffix: t.calDetInsSurplusS,
      );
    }
    if (net >= -200 && net <= 200) {
      return (
        prefix: t.calDetInsMaintP,
        keyword: t.calDetInsMaintK,
        suffix: t.calDetInsMaintS,
      );
    }
    if (pct >= 0.5) {
      return (
        prefix: t.calDetInsHalfP,
        keyword: t.calDetInsHalfK,
        suffix: t.calDetInsHalfS,
      );
    }
    return (
      prefix: t.calDetInsKeepP,
      keyword: t.calDetInsKeepK,
      suffix: t.calDetInsKeepS,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final int burned = _activeCalories;
    final int eaten = widget.eatenCalories;
    final int net = eaten - burned;
    final double burnProgress = (burned / _burnGoal).clamp(0.0, 1.0);
    final double eatProgress = (eaten / _eatGoal).clamp(0.0, 1.0);

    final Color netColor;
    final String netLabel;
    if (net < -1000 || net > 200) {
      netColor = const Color(0xFFFF453A);
      netLabel = net > 200 ? t.calDetSurplus : t.calDetExtremeDeficit;
    } else if (net >= -200 && net <= 200) {
      netColor = const Color(0xFFFFD60A);
      netLabel = t.calDetMaintenance;
    } else {
      netColor = const Color(0xFF30D158);
      netLabel = t.calDetDeficit;
    }
    final String netStr = net >= 0 ? '+$net' : '$net';

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
                        // Back button
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
                              final insight = _buildInsight(t);
                              return RichText(
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
                                      style: TextStyle(
                                        color: Colors.orange.shade400,
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

                        // Ring dial card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 28,
                              horizontal: 24,
                            ),
                            child: AnimatedBuilder(
                              animation: _anim,
                              builder: (_, __) => SizedBox(
                                width: double.infinity,
                                height: 220,
                                child: CustomPaint(
                                  painter: _SegmentedRingPainter(
                                    progress: _anim.value * burnProgress,
                                    isDark: isDark,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '$burned',
                                                style: font(
                                                  fontSize: 44,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                  height: 1.0,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' ${t.dashKcal}',
                                                style: font(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor.withValues(
                                                    alpha: 0.55,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.calDetBurnGoalOf(_burnGoal),
                                          style: font(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textColor.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Detailed breakdown card
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
                                Text(
                                  t.calDetBalanceTitle,
                                  style: font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Burned row
                                _CalRow(
                                  label: t.dashBurned,
                                  sublabel: t.calDetActiveEnergyToday,
                                  value: burned,
                                  goal: _burnGoal,
                                  color: Colors.orange,
                                  progress: burnProgress,
                                  isDark: isDark,
                                  textColor: textColor,
                                ),

                                const SizedBox(height: 6),

                                // Burned sparkline
                                _Sparkline(
                                  values: _weeklyBurned,
                                  color: Colors.orange,
                                  isDark: isDark,
                                ),

                                const SizedBox(height: 16),

                                // Eaten row
                                _CalRow(
                                  label: t.dashEaten,
                                  sublabel: t.calDetCaloriesConsumedToday,
                                  value: eaten,
                                  goal: _eatGoal,
                                  color: const Color(0xFF30A2FF),
                                  progress: eatProgress,
                                  isDark: isDark,
                                  textColor: textColor,
                                ),

                                const SizedBox(height: 6),

                                // Eaten sparkline
                                _Sparkline(
                                  values: _weeklyEaten,
                                  color: const Color(0xFF30A2FF),
                                  isDark: isDark,
                                ),

                                const SizedBox(height: 20),

                                // Divider
                                Container(
                                  height: 1,
                                  color: textColor.withValues(alpha: 0.08),
                                ),

                                const SizedBox(height: 20),

                                // Net row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.dashNet,
                                            style: font(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            netLabel,
                                            style: font(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: netColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: netStr,
                                            style: font(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: netColor,
                                              height: 1.0,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' ${t.dashKcal}',
                                            style: font(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: netColor.withValues(
                                                alpha: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Net bidirectional bar
                                _NetBar(net: net, isDark: isDark),

                                const SizedBox(height: 8),

                                // Scale labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '−2000',
                                      style: font(
                                        fontSize: 10,
                                        color: textColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Text(
                                      '0',
                                      style: font(
                                        fontSize: 10,
                                        color: textColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    Text(
                                      '+2000',
                                      style: font(
                                        fontSize: 10,
                                        color: textColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Monthly heatmap card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _CalHeatmap(
                            monthlyNet: _monthlyNet,
                            isLoading: _loadingMonthly,
                            cardColor: cardColor,
                            textColor: textColor,
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
// Sparkline — 7-day mini line chart
// ─────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  final List<int> values; // 7 values Mon–Sun
  final Color color;
  final bool isDark;

  const _Sparkline({
    required this.values,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return const SizedBox(height: 36);

    return SizedBox(
      height: 36,
      child: CustomPaint(
        size: const Size(double.infinity, 36),
        painter: _SparklinePainter(
          values: values,
          color: color,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;
  final bool isDark;

  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(math.max).toDouble();
    if (maxVal <= 0) return;

    final int todayIdx = DateTime.now().weekday - 1;
    final points = <Offset>[];

    for (int i = 0; i <= todayIdx && i < values.length; i++) {
      final x = i / math.max(todayIdx, 1) * size.width;
      final y = size.height - (values[i] / maxVal) * size.height * 0.85;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // Fill area
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i + 1].dy,
      );
      fillPath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) / 2,
        points[i + 1].dy,
      );
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // End dot
    canvas.drawCircle(points.last, 3, Paint()..color = color);
    canvas.drawCircle(
      points.last,
      1.5,
      Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}

// ─────────────────────────────────────────────
// Calorie Heatmap — net per day (green=deficit, red=surplus)
// ─────────────────────────────────────────────

class _CalHeatmap extends StatelessWidget {
  final Map<int, int> monthlyNet; // day → net (eaten - burned)
  final bool isLoading;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const _CalHeatmap({
    required this.monthlyNet,
    required this.isLoading,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  // Green for deficit, red for surplus, opacity by magnitude
  Color _cellColor(int? net) {
    if (net == null) return Colors.transparent;
    if (net == 0)
      return (isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06));
    final bool surplus = net > 0;
    final double magnitude = (net.abs() / 1000).clamp(0.0, 1.0);
    final double opacity = 0.15 + magnitude * 0.85;
    return surplus
        ? const Color(0xFFFF453A).withValues(alpha: opacity)
        : const Color(0xFF30D158).withValues(alpha: opacity);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final font = GoogleFonts.plusJakartaSans;
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final monthLabel = DateFormat('MMMM yyyy', localeName).format(now);
    final int firstWeekday = (DateTime(year, month, 1).weekday - 1).clamp(0, 6);
    final int totalCells = firstWeekday + daysInMonth;
    final int rows = (totalCells / 7).ceil();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayLabels = List.generate(
      7,
      (i) => DateFormat('EEEEE', localeName).format(monday.add(Duration(days: i))),
    );
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
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30D158).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(t.calDetDeficit, style: font(fontSize: 11, color: labelColor)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(t.calDetSurplus, style: font(fontSize: 11, color: labelColor)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
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
                          child: Text(
                            dayLabels[i],
                            style: font(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  isLoading
                      ? const SizedBox(
                          height: 80,
                          child: Center(child: BouncingDotsLoader()),
                        )
                      : Column(
                          children: List.generate(
                            rows,
                            (row) => Padding(
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
                                      width: cellSize,
                                      height: cellSize,
                                    );
                                  }

                                  final net = monthlyNet[day];
                                  final Color cellColor = isFuture
                                      ? emptyColor
                                      : (net == null
                                            ? emptyColor
                                            : _cellColor(net));
                                  final bool isToday = day == now.day;

                                  return Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(5),
                                      border: isToday
                                          ? Border.all(
                                              color: textColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
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

// ─────────────────────────────────────────────
// Calorie row with label + progress bar
// ─────────────────────────────────────────────

class _CalRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final int value;
  final int goal;
  final Color color;
  final double progress;
  final bool isDark;
  final Color textColor;

  const _CalRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.goal,
    required this.color,
    required this.progress,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: font(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: font(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$value',
                    style: font(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: ' / $goal',
                    style: font(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            color: trackColor,
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: AlignmentDirectional.centerStart,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Net bidirectional bar
// ─────────────────────────────────────────────

class _NetBar extends StatelessWidget {
  final int net;
  final bool isDark;

  const _NetBar({required this.net, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const int range = 2000;
    final double ratio = (net / range).clamp(-1.0, 1.0);
    final bool isPositive = net >= 0;

    final Color barColor;
    if (net < -1000 || net > 200) {
      barColor = const Color(0xFFFF453A);
    } else if (net >= -200 && net <= 200) {
      barColor = const Color(0xFFFFD60A);
    } else {
      barColor = const Color(0xFF30D158);
    }

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalW = constraints.maxWidth;
        final double centerX = totalW / 2;
        final double barW = (ratio.abs() * centerX).clamp(2.0, centerX);

        return SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                left: centerX - 0.5,
                top: 0,
                bottom: 0,
                width: 1,
                child: Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.15),
                ),
              ),
              Positioned(
                left: isPositive ? centerX : centerX - barW,
                top: 1,
                bottom: 1,
                width: barW,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Segmented ring painter
// ─────────────────────────────────────────────

class _SegmentedRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  static const Color _filledColor = Color(0xFFF5A623);
  static const int _totalSegments = 28;
  static const double _gapAngle = 0.04;

  const _SegmentedRingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = math.min(size.width, size.height) / 2 - 4;
    const segmentWidth = 22.0;
    final innerR = outerR - segmentWidth;

    final double totalAngle = 2 * math.pi;
    final double segAngle = (totalAngle / _totalSegments) - _gapAngle;
    final double filledCount = progress * _totalSegments;
    final int fullFilled = filledCount.floor();
    final double partial = filledCount - fullFilled;

    for (int i = 0; i < _totalSegments; i++) {
      final double startAngle =
          -math.pi / 2 + i * (totalAngle / _totalSegments);
      final double endAngle = startAngle + segAngle;
      final double segHalfAngle = (endAngle - startAngle) / 2;

      final Color color;
      if (i < fullFilled) {
        color = _filledColor;
      } else if (i == fullFilled && partial > 0) {
        color = Color.lerp(_emptyColor(isDark), _filledColor, partial)!;
      } else {
        color = _emptyColor(isDark);
      }

      final outerStart =
          center +
          Offset(
            outerR * math.cos(startAngle + 0.02),
            outerR * math.sin(startAngle + 0.02),
          );
      final innerEnd =
          center +
          Offset(
            innerR * math.cos(endAngle - 0.03),
            innerR * math.sin(endAngle - 0.03),
          );

      final path = Path()
        ..moveTo(outerStart.dx, outerStart.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          startAngle + 0.02,
          segHalfAngle * 2 - 0.04,
          false,
        )
        ..lineTo(innerEnd.dx, innerEnd.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          endAngle - 0.03,
          -(segHalfAngle * 2 - 0.06),
          false,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  Color _emptyColor(bool isDark) =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  @override
  bool shouldRepaint(_SegmentedRingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}


// ─────────────────────────────────────────────
// Calories Add Sheet — Burned + Gained inputs
// ─────────────────────────────────────────────

class _CaloriesAddSheet extends StatefulWidget {
  final bool isDark;
  final Color textColor;
  final Future<void> Function(DateTime when, int calories) onSaveBurned;

  const _CaloriesAddSheet({
    required this.isDark,
    required this.textColor,
    required this.onSaveBurned,
  });

  @override
  State<_CaloriesAddSheet> createState() => _CaloriesAddSheetState();
}

class _CaloriesAddSheetState extends State<_CaloriesAddSheet> {
  late DateTime _selectedDateTime;
  final TextEditingController _burnedCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _burnedCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        picked.year, picked.month, picked.day,
        _selectedDateTime.hour, _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
        picked.hour, picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    final burned = int.tryParse(_burnedCtrl.text.trim());
    if (burned == null || burned <= 0) {
      setState(() => _error = AppLocalizations.of(context).calDetErrorAmount);
      return;
    }
    setState(() { _error = null; _saving = true; });
    try {
      await widget.onSaveBurned(_selectedDateTime, burned);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).detailSaveFailed;
        _saving = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', localeName).format(dt);
  }

  String _formatTime(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat.jm(localeName).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = widget.textColor;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final pillBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final divColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07);
    final font = GoogleFonts.plusJakartaSans;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.93,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── top bar (fixed) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CalSheetTopButton(
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: textColor),
                      ),
                      _CalSheetTopButton(
                        isDark: isDark,
                        onTap: _saving ? null : _submit,
                        child: _saving
                            ? SizedBox(
                                width: 24,
                                height: 12,
                                child: BouncingDotsLoader.compact(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              )
                            : Icon(Icons.check_rounded,
                                size: 18, color: textColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

              // ── icon ──
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 34,
                    color: Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── title ──
              Center(
                child: Text(
                  t.calDetCaloriesTitle,
                  style: font(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── rows card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Date
                      _CalSheetRow(
                        label: t.detailDate,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDate(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, color: divColor),
                      // Time
                      _CalSheetRow(
                        label: t.detailTime,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatTime(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, color: divColor),
                      // Burned input
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.dashBurned,
                                    style: font(fontSize: 16, color: subColor)),
                                Text(t.dashKcal,
                                    style: font(
                                        fontSize: 11,
                                        color: Colors.orange.withValues(alpha: 0.8))),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _burnedCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                autofocus: true,
                                textAlign: TextAlign.right,
                                onChanged: (_) {
                                  if (_error != null) setState(() => _error = null);
                                },
                                onSubmitted: (_) => _submit(),
                                style: font(fontSize: 16, color: textColor),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '',
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── gained note ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  t.calDetGainedNote,
                  style: font(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // inline error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _error!,
                    style: font(fontSize: 13, color: Colors.redAccent),
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
    );
  }
}

class _CalSheetTopButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _CalSheetTopButton({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CalSheetRow extends StatelessWidget {
  final String label;
  final Color subColor;
  final Color textColor;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) font;
  final Widget trailing;

  const _CalSheetRow({
    required this.label,
    required this.subColor,
    required this.textColor,
    required this.font,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: font(fontSize: 16, color: subColor)),
          trailing,
        ],
      ),
    );
  }
}

ThemeData _pickerTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) return Theme.of(context);
  const bg = Color(0xFF252528);
  return Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      surface: bg,
      surfaceContainerHigh: bg,
      surfaceContainerHighest: bg,
      surfaceContainer: bg,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: bg),
    datePickerTheme: const DatePickerThemeData(backgroundColor: bg),
    timePickerTheme: const TimePickerThemeData(backgroundColor: bg),
  );
}
