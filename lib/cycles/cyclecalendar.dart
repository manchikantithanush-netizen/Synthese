import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DayStatus { none, period, predictedPeriod, ovulation, fertile }

class CycleCalendar extends StatefulWidget {
  final DateTime simulatedToday;
  final DateTime lastPeriodStart;
  final int avgCycleLength;
  final int avgPeriodLength;
  final List<Map<String, dynamic>> recentCycles;

  const CycleCalendar({
    super.key,
    required this.simulatedToday,
    required this.lastPeriodStart,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.recentCycles,
  });

  @override
  State<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<CycleCalendar> {
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getStartOfWeek(widget.simulatedToday);
  }

  @override
  void didUpdateWidget(CycleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.simulatedToday.isAtSameMomentAs(widget.simulatedToday)) {
      _currentWeekStart = _getStartOfWeek(widget.simulatedToday);
    }
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday == 7 ? 0 : date.weekday;
    return _dateOnly(date).subtract(Duration(days: daysToSubtract));
  }

  void _shiftWeek(int days) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: days));
    });
  }

  // --- SYNCED WITH CYCLES ENGINE ---
  DayStatus _getDayStatus(DateTime date) {
    DateTime target = _dateOnly(date);
    DateTime today = _dateOnly(widget.simulatedToday);

    // 1. Check EXACT past logged cycles (Reality Check)
    for (var cycle in widget.recentCycles) {
      if (cycle['startDate'] == null || cycle['startDate'] == '') continue;
      
      DateTime start = _dateOnly((cycle['startDate'] as Timestamp).toDate());
      int pLen = cycle['periodLength'] ?? widget.avgPeriodLength;
      DateTime end = start.add(Duration(days: pLen));
      
      if ((target.isAtSameMomentAs(start) || target.isAfter(start)) && target.isBefore(end)) {
        return target.isAfter(today) ? DayStatus.predictedPeriod : DayStatus.period;
      }
    }

    // 2. Extrapolate using the main Engine's logic
    DateTime baseDate = _dateOnly(widget.lastPeriodStart);
    
    // Find how many cycles have theoretically passed since the last real period
    int diffDays = target.difference(baseDate).inDays;
    int cyclesPassed = (diffDays / widget.avgCycleLength).floor();
    
    // Calculate the start date of the cycle this date belongs to
    DateTime theoreticalCycleStart = baseDate.add(Duration(days: cyclesPassed * widget.avgCycleLength));
    
    // EXTACT MATCH to engine's: cycleDayToday = dateOnly(simulatedToday).difference(dateOnly(lastPeriodStart)).inDays + 1;
    int cycleDay = target.difference(theoreticalCycleStart).inDays + 1;

    // EXACT MATCH to engine's: int estimatedOvulationDay = avgCycleLength - 14;
    int ovulationDay = widget.avgCycleLength - 14; 

    // Apply the engine's rules to the calendar days
    if (cycleDay <= widget.avgPeriodLength) {
      return target.isAfter(today) ? DayStatus.predictedPeriod : DayStatus.period;
    } else if (cycleDay == ovulationDay) {
      return DayStatus.ovulation;
    } else if (cycleDay >= ovulationDay - 4 && cycleDay <= ovulationDay + 1) {
      return DayStatus.fertile;
    }

    return DayStatus.none;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedTextColor = isDark ? Colors.white54 : Colors.black54;
    final arrowTint = isDark ? Colors.white60 : Colors.black54;

    const periodColor = Color(0xFFEC548A);
    const ovulationColor = Color(0xFFFF2D55);
    final fertileBgColor = isDark ? const Color(0xFF2C1924) : const Color(0xFFFFF0F5);
    final fertileBorderColor = isDark ? const Color(0xFF8B2954) : const Color(0xFFFFB3D1);
    
    final subtleHighlight = isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF0F0F0);

    DateTime thursday = _currentWeekStart.add(const Duration(days: 4));
    String monthYearStr = DateFormat('MMMM yyyy').format(thursday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CNButton.icon(
                icon: const CNSymbol('chevron.left'),
                style: CNButtonStyle.plain, 
                tint: arrowTint,
                onPressed: () => _shiftWeek(-7),
              ),
              Text(
                monthYearStr,
                style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              CNButton.icon(
                icon: const CNSymbol('chevron.right'),
                style: CNButtonStyle.plain, 
                tint: arrowTint,
                onPressed: () => _shiftWeek(7),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              DateTime cellDate = _currentWeekStart.add(Duration(days: index));
              DayStatus status = _getDayStatus(cellDate);
              
              bool isSimulatedToday = _dateOnly(cellDate).isAtSameMomentAs(_dateOnly(widget.simulatedToday));
              String dayName = DateFormat('E').format(cellDate).toUpperCase(); 
              String dayNum = DateFormat('d').format(cellDate); 

              BoxDecoration? decoration;
              CustomPainter? painter;
              Color currentTextColor = textColor;
              Color currentDayNameColor = mutedTextColor;

              switch (status) {
                case DayStatus.period:
                  decoration = BoxDecoration(color: periodColor, borderRadius: BorderRadius.circular(16));
                  currentTextColor = Colors.white;
                  currentDayNameColor = Colors.white70;
                  break;
                case DayStatus.ovulation:
                  decoration = BoxDecoration(color: ovulationColor, borderRadius: BorderRadius.circular(16));
                  currentTextColor = Colors.white;
                  currentDayNameColor = Colors.white70;
                  break;
                case DayStatus.fertile:
                  decoration = BoxDecoration(
                    color: fertileBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fertileBorderColor, width: 1.5),
                  );
                  break;
                case DayStatus.predictedPeriod:
                  painter = DashedBorderPainter(color: periodColor, borderRadius: 16);
                  currentTextColor = periodColor;
                  break;
                case DayStatus.none:
                default:
                  if (isSimulatedToday) {
                    decoration = BoxDecoration(color: subtleHighlight, borderRadius: BorderRadius.circular(16));
                  }
                  break;
              }

              Widget cellContent = Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(color: currentDayNameColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayNum,
                      style: TextStyle(
                        color: currentTextColor, 
                        fontSize: 18, 
                        fontWeight: isSimulatedToday ? FontWeight.w800 : FontWeight.w600
                      ),
                    ),
                  ],
                ),
              );

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: decoration,
                  child: painter != null
                      ? CustomPaint(painter: painter, child: cellContent)
                      : cellContent,
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // --- REDESIGNED ULTRA-SIMPLE LEGEND ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Wrap(
            spacing: 24, // Wider spacing for a cleaner, breathable look
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem(
                "Period", 
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: periodColor, shape: BoxShape.circle)),
              ),
              _buildLegendItem(
                "Predicted", 
                CustomPaint(size: const Size(10, 10), painter: DashedCirclePainter(color: periodColor)),
              ),
              _buildLegendItem(
                "Ovulation", 
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: ovulationColor, shape: BoxShape.circle)),
              ),
              _buildLegendItem(
                "Fertile", 
                Container(
                  width: 10, height: 10, 
                  decoration: BoxDecoration(color: fertileBgColor, border: Border.all(color: fertileBorderColor, width: 1.5), shape: BoxShape.circle)
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated to accept a pre-built icon widget
  Widget _buildLegendItem(String label, Widget icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legendTextColor = isDark ? Colors.white60 : Colors.black54;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: legendTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// --- PAINTER FOR THE CALENDAR CELLS ---
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    
    final Path path = Path()..addRRect(rrect);
    for (var pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final extractLength = dashWidth;
        canvas.drawPath(pathMetric.extractPath(distance, distance + extractLength), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- NEW PAINTER FOR THE LEGEND DOT ---
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashWidth = 3.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    for (var pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}