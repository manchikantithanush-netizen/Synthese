import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class CaloriesDetailPage extends StatefulWidget {
  final int activeCalories;
  final int eatenCalories;

  const CaloriesDetailPage({
    super.key,
    required this.activeCalories,
    this.eatenCalories = 0,
  });

  @override
  State<CaloriesDetailPage> createState() => _CaloriesDetailPageState();
}

class _CaloriesDetailPageState extends State<CaloriesDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const int _burnGoal = 500;
  static const int _eatGoal = 2000;

  // Weekly trend: Mon–Sun (index 0=Mon)
  List<int> _weeklyBurned = List.filled(7, 0);
  List<int> _weeklyEaten = List.filled(7, 0);

  // Monthly heatmap: day → net calories (positive=surplus, negative=deficit)
  Map<int, int> _monthlyNet = {};
  bool _loadingMonthly = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _fetchWeeklyData() async {
    setState(() => _loadingWeekly = true);
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
        futures.add(FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('dashboardDaily').doc(key).get()
            .then((d) {
          burned[i] = (d.data()?['activeCalories'] as num?)?.toInt() ?? 0;
        }));
        // Eaten from dailyAgg
        futures.add(FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('dailyAgg').doc(key).get()
            .then((d) {
          eaten[i] = (d.data()?['caloriesLogged'] as num?)?.toInt() ?? 0;
        }));
      }
      await Future.wait(futures);
      if (mounted) setState(() { _weeklyBurned = burned; _weeklyEaten = eaten; });
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
        futures.add(Future.wait([
          FirebaseFirestore.instance
              .collection('users').doc(uid)
              .collection('dashboardDaily').doc(key).get()
              .then((d) { burned = (d.data()?['activeCalories'] as num?)?.toInt() ?? 0; }),
          FirebaseFirestore.instance
              .collection('users').doc(uid)
              .collection('dailyAgg').doc(key).get()
              .then((d) { eaten = (d.data()?['caloriesLogged'] as num?)?.toInt() ?? 0; }),
        ]).then((_) { result[day] = eaten - burned; }));
      }
      await Future.wait(futures);
      if (mounted) setState(() => _monthlyNet = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  ({String prefix, String keyword, String suffix}) _buildInsight() {    final int burned = widget.activeCalories;
    final int eaten = widget.eatenCalories;
    final int net = eaten - burned;
    final double pct = _burnGoal > 0 ? burned / _burnGoal : 0;

    if (burned == 0 && eaten == 0) {
      return (prefix: 'No activity ', keyword: 'recorded', suffix: ' yet today.');
    }
    if (burned == 0) {
      return (prefix: 'You\'ve eaten but haven\'t ', keyword: 'burned any calories', suffix: ' yet.');
    }
    if (pct >= 1.0) {
      return (prefix: 'You\'ve ', keyword: 'hit your burn goal', suffix: ' today!');
    }
    if (net < -500) {
      return (prefix: 'You\'re in a ', keyword: 'solid deficit', suffix: ' today.');
    }
    if (net > 500) {
      return (prefix: 'You\'re in a ', keyword: 'calorie surplus', suffix: ' today.');
    }
    if (net >= -200 && net <= 200) {
      return (prefix: 'You\'re close to ', keyword: 'maintenance', suffix: ' today.');
    }
    if (pct >= 0.5) {
      return (prefix: 'You\'re ', keyword: 'halfway to your burn goal', suffix: '.');
    }
    return (prefix: 'Keep moving to ', keyword: 'reach your goal', suffix: ' today.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final int burned = widget.activeCalories;
    final int eaten = widget.eatenCalories;
    final int net = eaten - burned;
    final double burnProgress = (burned / _burnGoal).clamp(0.0, 1.0);
    final double eatProgress = (eaten / _eatGoal).clamp(0.0, 1.0);

    final Color netColor;
    final String netLabel;
    if (net < -1000 || net > 200) {
      netColor = const Color(0xFFFF453A);
      netLabel = net > 200 ? 'Surplus' : 'Extreme deficit';
    } else if (net >= -200 && net <= 200) {
      netColor = const Color(0xFFFFD60A);
      netLabel = 'Maintenance';
    } else {
      netColor = const Color(0xFF30D158);
      netLabel = 'Deficit';
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

                        // Insight
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Builder(builder: (_) {
                            final insight = _buildInsight();
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
                                    style: TextStyle(color: Colors.orange.shade400),
                                  ),
                                  TextSpan(text: insight.suffix),
                                ],
                              ),
                            );
                          }),
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
                                vertical: 28, horizontal: 24),
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
                                          text: TextSpan(children: [
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
                                              text: ' kcal',
                                              style: font(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: textColor.withValues(alpha: 0.55),
                                              ),
                                            ),
                                          ]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'of $_burnGoal burn goal',
                                          style: font(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textColor.withValues(alpha: 0.4),
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
                                Text('Calorie Balance',
                                    style: font(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textColor)),

                                const SizedBox(height: 20),

                                // Burned row
                                _CalRow(
                                  label: 'Burned',
                                  sublabel: 'Active energy today',
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
                                  label: 'Eaten',
                                  sublabel: 'Calories consumed today',
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Net',
                                              style: font(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor)),
                                          const SizedBox(height: 2),
                                          Text(netLabel,
                                              style: font(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: netColor)),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(children: [
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
                                          text: ' kcal',
                                          style: font(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: netColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Net bidirectional bar
                                _NetBar(net: net, isDark: isDark),

                                const SizedBox(height: 8),

                                // Scale labels
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('−2000',
                                        style: font(
                                            fontSize: 10,
                                            color: textColor.withValues(alpha: 0.3))),
                                    Text('0',
                                        style: font(
                                            fontSize: 10,
                                            color: textColor.withValues(alpha: 0.3))),
                                    Text('+2000',
                                        style: font(
                                            fontSize: 10,
                                            color: textColor.withValues(alpha: 0.3))),
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
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy,
          points[i + 1].dx, points[i + 1].dy);
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
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy,
          points[i + 1].dx, points[i + 1].dy);
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
      Paint()
        ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
    if (net == 0) return (isDark
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
    final int firstWeekday = (DateTime(year, month, 1).weekday - 1).clamp(0, 6);
    final int totalCells = firstWeekday + daysInMonth;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel,
                  style: font(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30D158).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text('Deficit', style: font(fontSize: 11, color: labelColor)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF453A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text('Surplus', style: font(fontSize: 11, color: labelColor)),
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
                  children: List.generate(cols, (i) => SizedBox(
                    width: cellSize,
                    child: Center(
                      child: Text(dayLabels[i],
                          style: font(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: labelColor)),
                    ),
                  )),
                ),
                const SizedBox(height: 6),
                isLoading
                    ? const SizedBox(
                        height: 80,
                        child: Center(child: BouncingDotsLoader()))
                    : Column(
                        children: List.generate(rows, (row) => Padding(
                          padding: const EdgeInsets.only(bottom: gap),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(cols, (col) {
                              final cellIndex = row * cols + col;
                              final day = cellIndex - firstWeekday + 1;
                              final isValid = day >= 1 && day <= daysInMonth;
                              final isFuture = day > now.day;

                              if (!isValid) {
                                return SizedBox(width: cellSize, height: cellSize);
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
                                          color: textColor.withValues(alpha: 0.4),
                                          width: 1.5)
                                      : null,
                                ),
                              );
                            }),
                          ),
                        )),
                      ),
              ],
            );
          }),
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
                  Text(label,
                      style: font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  Text(sublabel,
                      style: font(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.4))),
                ],
              ),
            ),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$value',
                  style: font(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0),
                ),
                TextSpan(
                  text: ' / $goal',
                  style: font(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.35)),
                ),
              ]),
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
              alignment: Alignment.centerLeft,
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

    return LayoutBuilder(builder: (context, constraints) {
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
    });
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

      final outerStart = center +
          Offset(outerR * math.cos(startAngle + 0.02),
              outerR * math.sin(startAngle + 0.02));
      final innerEnd = center +
          Offset(innerR * math.cos(endAngle - 0.03),
              innerR * math.sin(endAngle - 0.03));

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
          path, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  Color _emptyColor(bool isDark) =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  @override
  bool shouldRepaint(_SegmentedRingPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
