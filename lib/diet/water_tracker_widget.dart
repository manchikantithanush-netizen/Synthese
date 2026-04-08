import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Water tracker section with animated water tank
class WaterTrackerSection extends StatefulWidget {
  final int waterGlasses;
  final int dailyGoal;
  final Function(int) onWaterChanged;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;

  const WaterTrackerSection({
    super.key,
    required this.waterGlasses,
    required this.dailyGoal,
    required this.onWaterChanged,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
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
    final waterPercentage = (widget.waterGlasses / widget.dailyGoal).clamp(0.0, 1.0);
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
              style: TextStyle(
                color: widget.subTextColor,
                fontSize: 14,
              ),
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
                  Expanded(
                    child: _buildWaterTank(waterPercentage),
                  ),

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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getWaterStatusColor(waterPercentage).withOpacity(0.15),
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
                            GestureDetector(
                              onTap: widget.waterGlasses > 0
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      widget.onWaterChanged(widget.waterGlasses - 1);
                                    }
                                  : null,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: widget.waterGlasses > 0
                                      ? waterColor.withOpacity(0.15)
                                      : (widget.isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CupertinoIcons.minus,
                                  color: widget.waterGlasses > 0
                                      ? waterColor
                                      : widget.subTextColor.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Add Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  widget.onWaterChanged(widget.waterGlasses + 1);
                                },
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: waterColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.plus, color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        "Add Glass",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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

        const SizedBox(height: 40),
      ],
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
        final wave2 = sin(normalizedX * 2 * pi * 3 - phase) * (waveAmplitude * 0.35);
        return waterTop + wave1 + wave2;
      }

      for (double x = bottleLeft; x <= bottleLeft + bottleWidth; x += 1) {
        final normalizedX = (x - bottleLeft) / bottleWidth;
        wavePath.lineTo(x, getWaveY(normalizedX));
      }

      wavePath.lineTo(bottleLeft + bottleWidth, bottleTop + bottleHeight);
      wavePath.close();

      // Water solid color (no gradient)
      final waterPaint = Paint()
        ..color = waterColor.withOpacity(0.85);

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
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(bottleLeft, waterTop - 5, bottleWidth, 18));
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(isDark ? 0.08 : 0.2),
          Colors.white.withOpacity(isDark ? 0.02 : 0.05),
          Colors.white.withOpacity(isDark ? 0.08 : 0.2),
        ],
      ).createShader(Rect.fromLTWH(
          bottleLeft + 6, bottleTop + cornerRadius, 3, bottleHeight - cornerRadius * 2));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bottleLeft + 6, bottleTop + cornerRadius, 3, bottleHeight - cornerRadius * 2),
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
