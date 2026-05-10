import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class ExerciseDetailPage extends StatefulWidget {
  final int exerciseMinutes;
  final int goalMinutes;
  final ValueChanged<int>? onManualExerciseMinutesAdded;

  const ExerciseDetailPage({
    super.key,
    this.exerciseMinutes = 0,
    this.goalMinutes = 60,
    this.onManualExerciseMinutesAdded,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late int _exerciseMinutes;

  // Monthly heatmap: day → minutes
  Map<int, int> _monthlyMinutes = {};
  bool _loadingMonthly = true;

  int get _goalMinutes => widget.goalMinutes;

  @override
  void initState() {
    super.initState();
    _exerciseMinutes = widget.exerciseMinutes;
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addManualExerciseMinutes({
    required DateTime when,
    required int minutes,
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
          'exerciseMinutes': FieldValue.increment(minutes),
          'dateKey': key,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      if (_isSameDay(when, DateTime.now())) {
        _exerciseMinutes += minutes;
      }
      if (when.year == DateTime.now().year &&
          when.month == DateTime.now().month) {
        final day = when.day;
        _monthlyMinutes[day] = (_monthlyMinutes[day] ?? 0) + minutes;
      }
    });
    if (_isSameDay(when, DateTime.now())) {
      widget.onManualExerciseMinutesAdded?.call(minutes);
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
      builder: (_) => _ExerciseAddSheet(
        isDark: isDark,
        textColor: textColor,
        onSave: (when, minutes) =>
            _addManualExerciseMinutes(when: when, minutes: minutes),
      ),
    );
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
    final int mins = _exerciseMinutes;
    final double pct = mins / _goalMinutes;

    if (mins == 0) {
      return (
        prefix: 'No exercise ',
        keyword: 'recorded',
        suffix: ' yet today.',
      );
    }
    if (pct >= 1.0) {
      return (prefix: 'You\'ve ', keyword: 'hit your goal', suffix: ' today!');
    }
    if (pct >= 0.75) {
      return (prefix: 'Almost there — ', keyword: 'keep going', suffix: '.');
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

    final double progress = (_exerciseMinutes / _goalMinutes).clamp(0.0, 1.0);
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
                                  'Add data',
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
                                    color: Color(0xFFFF4B4B),
                                  ),
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
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: _fmt(
                                                      widget.exerciseMinutes,
                                                    ),
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
                                                            alpha: 0.4,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Exercise today',
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Just starting',
                                      style: font(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Goal reached',
                                      style: font(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
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
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
                                      width: cellSize,
                                      height: cellSize,
                                    );
                                  }

                                  final mins = monthlyMinutes[day];
                                  final Color cellColor = isFuture
                                      ? emptyColor
                                      : accentColor.withValues(
                                          alpha: _cellOpacity(mins),
                                        );
                                  final bool isToday = day == now.day;

                                  return Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(5),
                                      border: isToday
                                          ? Border.all(
                                              color: accentColor,
                                              width: 1.5,
                                            )
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
            },
          ),
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
      final double dashStart = slotStart + slotAngle * (dashGapFraction / 2);
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
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  Color _emptyColor() =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  @override
  bool shouldRepaint(_SemiGaugePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

// ─────────────────────────────────────────────
// Exercise Add Sheet
// ─────────────────────────────────────────────

class _ExerciseAddSheet extends StatefulWidget {
  final bool isDark;
  final Color textColor;
  final Future<void> Function(DateTime when, int minutes) onSave;

  const _ExerciseAddSheet({
    required this.isDark,
    required this.textColor,
    required this.onSave,
  });

  @override
  State<_ExerciseAddSheet> createState() => _ExerciseAddSheetState();
}

class _ExerciseAddSheetState extends State<_ExerciseAddSheet> {
  late DateTime _selectedDateTime;
  final TextEditingController _minsCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _minsCtrl.dispose();
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
    final mins = int.tryParse(_minsCtrl.text.trim());
    if (mins == null || mins <= 0) {
      setState(() => _error = 'Enter a valid number of minutes greater than 0.');
      return;
    }
    setState(() { _error = null; _saving = true; });
    try {
      await widget.onSave(_selectedDateTime, mins);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to save. Please try again.'; _saving = false; });
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
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
                      _ExSheetTopButton(
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: textColor),
                      ),
                      _ExSheetTopButton(
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
                    Icons.timer,
                    size: 34,
                    color: Color(0xFFFF4B4B),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── title ──
              Center(
                child: Text(
                  'Exercise Time',
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
                      _ExSheetRow(
                        label: 'Date',
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
                      _ExSheetRow(
                        label: 'Time',
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
                      // Minutes input
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Minutes',
                                    style: font(fontSize: 16, color: subColor)),
                                Text('min',
                                    style: font(
                                        fontSize: 11,
                                        color: const Color(0xFFFF4B4B)
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _minsCtrl,
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

class _ExSheetTopButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _ExSheetTopButton({
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

class _ExSheetRow extends StatelessWidget {
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

  const _ExSheetRow({
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
