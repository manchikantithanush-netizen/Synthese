import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class ExerciseDetailPage extends StatefulWidget {
  final int exerciseMinutes;

  const ExerciseDetailPage({super.key, this.exerciseMinutes = 0});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  // Monthly heatmap: day → minutes
  Map<int, int> _monthlyMinutes = {};
  bool _loadingMonthly = true;

  static const int _goalMinutes = 60;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
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
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dashboardDaily')
              .doc(key)
              .get()
              .then((doc) {
            final mins =
                (doc.data()?['exerciseMinutes'] as num?)?.toInt() ?? 0;
            result[day] = mins;
          }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _monthlyMinutes = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  ({String prefix, String keyword, String suffix}) _buildInsight() {
    final int mins = widget.exerciseMinutes;
    final double pct = mins / _goalMinutes;

    if (mins == 0) {
      return (
        prefix: 'No exercise ',
        keyword: 'recorded',
        suffix: ' yet today.',
      );
    }
    if (pct >= 1.0) {
      return (
        prefix: 'You\'ve ',
        keyword: 'hit your goal',
        suffix: ' today!',
      );
    }
    if (pct >= 0.75) {
      return (
        prefix: 'Almost there — ',
        keyword: 'keep going',
        suffix: '.',
      );
    }
    if (pct >= 0.5) {
      return (
        prefix: 'You\'re ',
        keyword: 'halfway to your goal',
        suffix: ' today.',
      );
    }
    if (mins >= 10) {
      return (
        prefix: 'You\'ve made a ',
        keyword: 'solid start',
        suffix: ' today.',
      );
    }
    return (
      prefix: 'Every minute ',
      keyword: 'counts',
      suffix: ' — keep moving.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final double progress =
        (widget.exerciseMinutes / _goalMinutes).clamp(0.0, 1.0);
    final insight = _buildInsight();

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
                                  style: const TextStyle(
                                      color: Color(0xFFFF4B4B)),
                                ),
                                TextSpan(text: insight.suffix),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Gauge card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding:
                                const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _anim,
                                  builder: (_, __) => SizedBox(
                                    width: double.infinity,
                                    height: 200,
                                    child: CustomPaint(
                                      painter: _SemiGaugePainter(
                                        progress: _anim.value * progress,
                                        isDark: isDark,
                                        accentColor: accentColor,
                                      ),
                                      child: Align(
                                        alignment: const Alignment(0, 0.6),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                  text: _fmt(widget
                                                      .exerciseMinutes),
                                                  style: font(
                                                    fontSize: 38,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: textColor,
                                                    height: 1.0,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' / ${_fmt(_goalMinutes)}',
                                                  style: font(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: textColor
                                                        .withValues(
                                                            alpha: 0.4),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Exercise today',
                                              style: font(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: textColor.withValues(
                                                    alpha: 0.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Just starting',
                                        style: font(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textColor.withValues(
                                                alpha: 0.35))),
                                    Text('Goal reached',
                                        style: font(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: textColor.withValues(
                                                alpha: 0.35))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Heatmap card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ExerciseHeatmap(
                            monthlyMinutes: _monthlyMinutes,
                            isLoading: _loadingMonthly,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            goalMinutes: _goalMinutes,
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
// Exercise Heatmap
// ─────────────────────────────────────────────

class _ExerciseHeatmap extends StatelessWidget {
  final Map<int, int> monthlyMinutes;
  final bool isLoading;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final int goalMinutes;

  const _ExerciseHeatmap({
    required this.monthlyMinutes,
    required this.isLoading,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.goalMinutes,
  });

  double _cellOpacity(int? mins) {
    if (mins == null || mins <= 0) return 0.08;
    final ratio = (mins / goalMinutes).clamp(0.0, 1.0);
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
                        color: accentColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text('More',
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
                isLoading
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

                                final mins = monthlyMinutes[day];
                                final Color cellColor = isFuture
                                    ? emptyColor
                                    : accentColor.withValues(
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
                                            color: accentColor, width: 1.5)
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

// ─────────────────────────────────────────────
// Semicircle gauge painter
// ─────────────────────────────────────────────

class _SemiGaugePainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color accentColor;

  static const int _totalDashes = 13;
  static const double _startAngle = math.pi;
  static const double _sweepTotal = math.pi;

  const _SemiGaugePainter({
    required this.progress,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.82;
    final radius = math.min(cx, cy) * 0.92;

    const double dashGapFraction = 0.18;
    final double slotAngle = _sweepTotal / _totalDashes;
    final double dashAngle = slotAngle * (1 - dashGapFraction);
    const double dashWidth = 22.0;
    final double innerRadius = radius - dashWidth;

    final int filledCount = (progress * _totalDashes).floor();
    final double partial = (progress * _totalDashes) - filledCount;

    for (int i = 0; i < _totalDashes; i++) {
      final double slotStart = _startAngle + i * slotAngle;
      final double dashStart =
          slotStart + slotAngle * (dashGapFraction / 2);
      final double dashEnd = dashStart + dashAngle;
      final double halfAngle = dashAngle / 2;

      final Color color;
      if (i < filledCount) {
        color = accentColor;
      } else if (i == filledCount && partial > 0.05) {
        color = Color.lerp(_emptyColor(), accentColor, partial)!;
      } else {
        color = _emptyColor();
      }

      final outerStart = Offset(
        cx + radius * math.cos(dashStart + 0.015),
        cy + radius * math.sin(dashStart + 0.015),
      );
      final innerEnd = Offset(
        cx + innerRadius * math.cos(dashEnd - 0.015),
        cy + innerRadius * math.sin(dashEnd - 0.015),
      );

      final path = Path()
        ..moveTo(outerStart.dx, outerStart.dy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          dashStart + 0.015,
          halfAngle * 2 - 0.03,
          false,
        )
        ..lineTo(innerEnd.dx, innerEnd.dy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius),
          dashEnd - 0.015,
          -(halfAngle * 2 - 0.03),
          false,
        )
        ..close();

      canvas.drawPath(
          path, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  Color _emptyColor() =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  @override
  bool shouldRepaint(_SemiGaugePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}
