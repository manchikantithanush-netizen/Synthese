import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:synthese/ui/components/app_toast.dart';

/// Water tracker section with animated water tank
class WaterTrackerSection extends StatefulWidget {
  final int waterGlasses;
  final int dailyGoal;
  final Function(int) onWaterChanged;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final double baselineWaterIntakeLitres; // From first onboarding
  final List<double> weeklyIntakeLitres; // Last 7 days in litres

  const WaterTrackerSection({
    super.key,
    required this.waterGlasses,
    required this.dailyGoal,
    required this.onWaterChanged,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.baselineWaterIntakeLitres,
    required this.weeklyIntakeLitres,
  });

  @override
  State<WaterTrackerSection> createState() => _WaterTrackerSectionState();
}

class _WaterTrackerSectionState extends State<WaterTrackerSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  // Water theme colors
  static const Color waterColor = Color(0xFF4FC3F7);
  static const Color waterColorDark = Color(0xFF0288D1);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterPercentage = (widget.waterGlasses / widget.dailyGoal).clamp(
      0.0,
      1.0,
    );
    final glassesRemaining = widget.dailyGoal - widget.waterGlasses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Water Intake",
              style: TextStyle(
                color: widget.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${widget.waterGlasses} / ${widget.dailyGoal} glasses",
              style: TextStyle(color: widget.subTextColor, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Water Tank Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Water Tank Visual
              Row(
                children: [
                  // Tank
                  Expanded(child: _buildWaterTank(waterPercentage)),

                  const SizedBox(width: 24),

                  // Stats and Controls
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Percentage Display (animated)
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: waterPercentage,
                            end: waterPercentage,
                          ),
                          builder: (context, animatedPercentage, child) {
                            return Text(
                              "${(animatedPercentage * 100).toInt()}%",
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "of daily goal",
                          style: TextStyle(
                            color: widget.subTextColor,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Status Message
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getWaterStatusColor(
                              waterPercentage,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getWaterStatusMessage(glassesRemaining),
                            style: TextStyle(
                              color: _getWaterStatusColor(waterPercentage),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Add/Remove Buttons
                        Row(
                          children: [
                            // Remove Button
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: widget.waterGlasses > 0 ? 1.0 : 0.45,
                                child: IgnorePointer(
                                  ignoring: widget.waterGlasses <= 0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GestureDetector(
  onTap: widget.waterGlasses > 0
      ? () {
          HapticFeedback.lightImpact();
          widget.onWaterChanged(widget.waterGlasses - 1);
        }
      : null,
  child: Container(
    color: Colors.transparent,
    child: Icon(
      CupertinoIcons.minus,
      color: widget.waterGlasses > 0
          ? waterColor
          : widget.subTextColor.withOpacity(0.3),
      size: 20,
    ),
  ),
),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Add Button
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    final newCount = widget.waterGlasses + 1;
                                    widget.onWaterChanged(newCount);
                                    if (newCount >= widget.dailyGoal) {
                                      AppToast.success(
                                        context,
                                        'Water goal reached! 💧',
                                        icon: Icons.water_drop_rounded,
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: waterColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "+ Add Glass",
                                        style: TextStyle(
                                          color: waterColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Glass indicators row
              _buildGlassIndicators(),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Water Intake Trend Graph
        _buildWaterTrendGraph(),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWaterTrendGraph() {
    // Calculate current average from weekly data
    final currentAverage = widget.weeklyIntakeLitres.isEmpty
        ? widget.baselineWaterIntakeLitres
        : widget.weeklyIntakeLitres.reduce((a, b) => a + b) /
              widget.weeklyIntakeLitres.length;

    final percentageChange = widget.baselineWaterIntakeLitres > 0
        ? ((currentAverage - widget.baselineWaterIntakeLitres) /
              widget.baselineWaterIntakeLitres *
              100)
        : 0.0;

    final isIncrease = percentageChange > 0;
    final changeColor = isIncrease
        ? const Color(0xFF4FC3F7)
        : const Color(0xFFFF9500);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Trend",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncrease
                          ? CupertinoIcons.arrow_up
                          : CupertinoIcons.arrow_down,
                      color: changeColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${percentageChange.abs().toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: WaterTrendGraphPainter(
                weeklyData: widget.weeklyIntakeLitres,
                baseline: widget.baselineWaterIntakeLitres,
                isDark: widget.isDark,
                textColor: widget.textColor,
                lineColor: const Color(0xFF4FC3F7),
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTank(double fillPercentage) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: fillPercentage, end: fillPercentage),
      builder: (context, animatedFill, child) {
        return AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return SizedBox(
              height: 200,
              child: CustomPaint(
                painter: WaterTankPainter(
                  fillPercentage: animatedFill,
                  isDark: widget.isDark,
                  waterColor: waterColor,
                  waterColorDark: waterColorDark,
                  wavePhase: _waveController.value,
                ),
                size: Size.infinite,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassIndicators() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(widget.dailyGoal, (index) {
        final isFilled = index < widget.waterGlasses;
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isFilled
                ? waterColor.withOpacity(0.9)
                : (widget.isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFilled
                  ? waterColor
                  : (widget.isDark
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.1)),
              width: 1.5,
            ),
          ),
          child: Icon(
            CupertinoIcons.drop_fill,
            size: 16,
            color: isFilled
                ? Colors.white
                : (widget.isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.15)),
          ),
        );
      }),
    );
  }

  Color _getWaterStatusColor(double percentage) {
    if (percentage >= 1.0) return const Color(0xFF30D158);
    if (percentage >= 0.75) return const Color(0xFFFFCC00);
    if (percentage >= 0.5) return waterColor;
    return const Color(0xFFFF9500);
  }

  String _getWaterStatusMessage(int remaining) {
    if (remaining <= 0) return "Goal reached!";
    if (remaining == 1) return "1 glass to go!";
    if (remaining <= 3) return "Almost there!";
    return "$remaining glasses to go";
  }
}

/// Custom Painter for the Water Tank
class WaterTankPainter extends CustomPainter {
  final double fillPercentage;
  final bool isDark;
  final Color waterColor;
  final Color waterColorDark;
  final double wavePhase;

  WaterTankPainter({
    required this.fillPercentage,
    required this.isDark,
    required this.waterColor,
    required this.waterColorDark,
    this.wavePhase = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 10.0;

    final bottleWidth = size.width - padding * 2;
    final bottleHeight = size.height - padding * 2;
    final bottleLeft = padding;
    final bottleTop = padding;
    final cornerRadius = bottleWidth / 2;

    final bottleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bottleLeft, bottleTop, bottleWidth, bottleHeight),
      Radius.circular(cornerRadius),
    );

    // Glass background
    final glassPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.grey.withOpacity(0.08);
    canvas.drawRRect(bottleRect, glassPaint);

    // Water fill
    if (fillPercentage > 0) {
      canvas.save();
      canvas.clipRRect(bottleRect);

      final waterMaxHeight = bottleHeight - 8;
      final waterHeight = waterMaxHeight * fillPercentage;
      final waterTop = bottleTop + bottleHeight - waterHeight - 4;

      // Seamless waves
      final wavePath = Path();
      final waveAmplitude = fillPercentage > 0.08 ? 2.0 : 0.0;
      final phase = wavePhase * 2 * pi;

      wavePath.moveTo(bottleLeft, bottleTop + bottleHeight);
      wavePath.lineTo(bottleLeft, waterTop);

      double getWaveY(double normalizedX) {
        final wave1 = sin(normalizedX * 2 * pi * 2 + phase) * waveAmplitude;
        final wave2 =
            sin(normalizedX * 2 * pi * 3 - phase) * (waveAmplitude * 0.35);
        return waterTop + wave1 + wave2;
      }

      for (double x = bottleLeft; x <= bottleLeft + bottleWidth; x += 1) {
        final normalizedX = (x - bottleLeft) / bottleWidth;
        wavePath.lineTo(x, getWaveY(normalizedX));
      }

      wavePath.lineTo(bottleLeft + bottleWidth, bottleTop + bottleHeight);
      wavePath.close();

      // Water solid color (no gradient)
      final waterPaint = Paint()..color = waterColor.withOpacity(0.85);

      canvas.drawPath(wavePath, waterPaint);

      // Surface highlight
      final highlightPath = Path();
      highlightPath.moveTo(bottleLeft, waterTop + 12);
      for (double x = bottleLeft; x <= bottleLeft + bottleWidth; x += 1) {
        final normalizedX = (x - bottleLeft) / bottleWidth;
        highlightPath.lineTo(x, getWaveY(normalizedX));
      }
      highlightPath.lineTo(bottleLeft + bottleWidth, waterTop + 12);
      highlightPath.close();

      final highlightPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.0),
              ],
            ).createShader(
              Rect.fromLTWH(bottleLeft, waterTop - 5, bottleWidth, 18),
            );
      canvas.drawPath(highlightPath, highlightPaint);

      canvas.restore();
    }

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = isDark
          ? Colors.white.withOpacity(0.15)
          : Colors.grey.withOpacity(0.25);
    canvas.drawRRect(bottleRect, borderPaint);

    // Left reflection
    final reflectionPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(isDark ? 0.08 : 0.2),
              Colors.white.withOpacity(isDark ? 0.02 : 0.05),
              Colors.white.withOpacity(isDark ? 0.08 : 0.2),
            ],
          ).createShader(
            Rect.fromLTWH(
              bottleLeft + 6,
              bottleTop + cornerRadius,
              3,
              bottleHeight - cornerRadius * 2,
            ),
          );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bottleLeft + 6,
          bottleTop + cornerRadius,
          3,
          bottleHeight - cornerRadius * 2,
        ),
        const Radius.circular(1.5),
      ),
      reflectionPaint,
    );
  }

  @override
  bool shouldRepaint(WaterTankPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.isDark != isDark ||
        oldDelegate.wavePhase != wavePhase;
  }
}

/// Custom painter for water trend line graph
class WaterTrendGraphPainter extends CustomPainter {
  final List<double> weeklyData; // 7 days of data in litres
  final double baseline;
  final bool isDark;
  final Color textColor;
  final Color lineColor;

  WaterTrendGraphPainter({
    required this.weeklyData,
    required this.baseline,
    required this.isDark,
    required this.textColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;

    final padding = const EdgeInsets.only(
      left: 8,
      right: 8,
      top: 16,
      bottom: 20,
    );
    final graphWidth = size.width - padding.left - padding.right;
    final graphHeight = size.height - padding.top - padding.bottom;

    // Find min and max for scaling
    final allValues = [...weeklyData, baseline];
    final maxValue = allValues.reduce((a, b) => a > b ? a : b) * 1.1;
    final minValue = allValues.reduce((a, b) => a < b ? a : b) * 0.9;
    final valueRange = maxValue - minValue;

    // Draw baseline dashed line
    final baselineY =
        padding.top +
        graphHeight -
        ((baseline - minValue) / valueRange * graphHeight);
    final baselinePaint = Paint()
      ..color = textColor.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 5.0;
    final dashSpace = 3.0;
    double startX = padding.left;
    while (startX < size.width - padding.right) {
      canvas.drawLine(
        Offset(startX, baselineY),
        Offset(
          (startX + dashWidth).clamp(0, size.width - padding.right),
          baselineY,
        ),
        baselinePaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw data line
    if (weeklyData.length >= 2) {
      final path = Path();
      final dataPoints = <Offset>[];

      for (int i = 0; i < weeklyData.length; i++) {
        final x = padding.left + (i / (weeklyData.length - 1)) * graphWidth;
        final y =
            padding.top +
            graphHeight -
            ((weeklyData[i] - minValue) / valueRange * graphHeight);
        dataPoints.add(Offset(x, y));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Draw line
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);

      // Draw gradient fill under line
      final fillPath = Path.from(path);
      fillPath.lineTo(dataPoints.last.dx, size.height - padding.bottom);
      fillPath.lineTo(dataPoints.first.dx, size.height - padding.bottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, padding.top, size.width, graphHeight));

      canvas.drawPath(fillPath, fillPaint);

      // Draw data points
      for (final point in dataPoints) {
        final pointPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point, 3.5, pointPaint);

        final ringPaint = Paint()
          ..color = isDark ? const Color(0xFF1C1C1E) : Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(point, 2, ringPaint);
      }
    }

    // Draw day labels
    final textStyle = TextStyle(
      color: textColor.withOpacity(0.4),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 0; i < min(weeklyData.length, days.length); i++) {
      final x = padding.left + (i / (weeklyData.length - 1)) * graphWidth;
      final textPainter = TextPainter(
        text: TextSpan(text: days[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding.bottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(WaterTrendGraphPainter oldDelegate) {
    return oldDelegate.weeklyData != weeklyData ||
        oldDelegate.baseline != baseline ||
        oldDelegate.isDark != isDark;
  }
}
