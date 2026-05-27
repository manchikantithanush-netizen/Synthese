import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class OnboardingStage2 extends StatelessWidget {
  final int goalSteps;
  final int goalCaloriesBurnt;
  final int goalCaloriesEaten;
  final int goalExerciseMinutes;
  final double goalSleepHours;
  final Function(int) onStepsChange;
  final Function(int) onCaloriesBurntChange;
  final Function(int) onCaloriesEatenChange;
  final Function(int) onExerciseChange;
  final Function(double) onSleepChange;

  const OnboardingStage2({
    super.key,
    required this.goalSteps,
    required this.goalCaloriesBurnt,
    required this.goalCaloriesEaten,
    required this.goalExerciseMinutes,
    required this.goalSleepHours,
    required this.onStepsChange,
    required this.onCaloriesBurntChange,
    required this.onCaloriesEatenChange,
    required this.onExerciseChange,
    required this.onSleepChange,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final t = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.onboardingStage2Title,
            style: TextStyle(
              color: textColor,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.onboardingStage2Body,
            style: TextStyle(
              color: textColor.withOpacity(0.55),
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 28),

          _GoalPicker(
            label: t.goalDailySteps,
            icon: Icons.directions_walk_rounded,
            accent: const Color(0xFF6C63FF),
            min: 1000,
            step: 500,
            count: 59, // 1000 .. 30000
            initialValue: goalSteps,
            formatter: (v) => "$v",
            unit: t.unitSteps,
            onChange: onStepsChange,
          ),
          const SizedBox(height: 18),

          _GoalPicker(
            label: t.goalCaloriesBurnt,
            icon: Icons.local_fire_department_rounded,
            accent: const Color(0xFFFF9500),
            min: 100,
            step: 50,
            count: 79, // 100 .. 4000
            initialValue: goalCaloriesBurnt,
            formatter: (v) => "$v",
            unit: t.unitKcal,
            onChange: onCaloriesBurntChange,
          ),
          const SizedBox(height: 18),

          _GoalPicker(
            label: t.goalCaloriesEaten,
            icon: Icons.restaurant_rounded,
            accent: const Color(0xFF34C759),
            min: 1000,
            step: 50,
            count: 61, // 1000 .. 4000
            initialValue: goalCaloriesEaten,
            formatter: (v) => "$v",
            unit: t.unitKcal,
            onChange: onCaloriesEatenChange,
          ),
          const SizedBox(height: 18),

          _GoalPicker(
            label: t.goalExerciseTime,
            icon: Icons.timer_rounded,
            accent: const Color(0xFF5E5CE6),
            min: 15,
            step: 5,
            count: 34, // 15 .. 180
            initialValue: goalExerciseMinutes,
            formatter: (v) => "$v",
            unit: t.unitMin,
            onChange: onExerciseChange,
          ),
          const SizedBox(height: 18),

          _GoalPicker.decimal(
            label: t.goalSleep,
            icon: Icons.nightlight_round,
            accent: const Color(0xFF32ADE6),
            minDecimal: 5.0,
            stepDecimal: 0.5,
            count: 15, // 5.0 .. 12.0
            initialDecimalValue: goalSleepHours,
            decimalFormatter: (v) => v.toStringAsFixed(1),
            unit: t.unitHrs,
            onDecimalChange: onSleepChange,
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _GoalPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final String unit;

  // Integer mode
  final int? min;
  final int? step;
  final int? initialValue;
  final String Function(int)? formatter;
  final Function(int)? onChange;

  // Decimal mode
  final double? minDecimal;
  final double? stepDecimal;
  final double? initialDecimalValue;
  final String Function(double)? decimalFormatter;
  final Function(double)? onDecimalChange;

  final int count;
  final bool isDecimal;

  const _GoalPicker({
    required this.label,
    required this.icon,
    required this.accent,
    required this.unit,
    required this.min,
    required this.step,
    required this.count,
    required this.initialValue,
    required this.formatter,
    required this.onChange,
  })  : minDecimal = null,
        stepDecimal = null,
        initialDecimalValue = null,
        decimalFormatter = null,
        onDecimalChange = null,
        isDecimal = false;

  const _GoalPicker.decimal({
    required this.label,
    required this.icon,
    required this.accent,
    required this.unit,
    required this.minDecimal,
    required this.stepDecimal,
    required this.count,
    required this.initialDecimalValue,
    required this.decimalFormatter,
    required this.onDecimalChange,
  })  : min = null,
        step = null,
        initialValue = null,
        formatter = null,
        onChange = null,
        isDecimal = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final initialIndex = isDecimal
        ? ((initialDecimalValue! - minDecimal!) / stepDecimal!).round()
        : ((initialValue! - min!) ~/ step!);
    final controller =
        FixedExtentScrollController(initialItem: initialIndex.clamp(0, count - 1));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 120,
            child: CupertinoPicker(
              itemExtent: 40,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: controller,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: accent.withOpacity(0.12),
              ),
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                if (isDecimal) {
                  onDecimalChange!(minDecimal! + (i * stepDecimal!));
                } else {
                  onChange!(min! + (i * step!));
                }
              },
              children: List.generate(count, (i) {
                final display = isDecimal
                    ? decimalFormatter!(minDecimal! + (i * stepDecimal!))
                    : formatter!(min! + (i * step!));
                return Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: display,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: " $unit",
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
