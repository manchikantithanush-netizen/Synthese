import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';

class OnboardingTraining extends StatefulWidget {
  final double trainingDays;
  final Function(double) onTrainingDaysChange;
  
  final String? averageDuration;
  final Function(String) onDurationSelect;
  
  final int intensityIndex;
  final Function(int) onIntensitySelect;
  
  final List<String> primaryGoals;
  final Function(String) onPrimaryGoalToggle;
  
  final List<String> secondaryGoals;
  final Function(String) onSecondaryGoalToggle;

  const OnboardingTraining({
    super.key,
    required this.trainingDays,
    required this.onTrainingDaysChange,
    required this.averageDuration,
    required this.onDurationSelect,
    required this.intensityIndex,
    required this.onIntensitySelect,
    required this.primaryGoals,
    required this.onPrimaryGoalToggle,
    required this.secondaryGoals,
    required this.onSecondaryGoalToggle,
  });

  @override
  State<OnboardingTraining> createState() => _OnboardingTrainingState();
}

class _OnboardingTrainingState extends State<OnboardingTraining> {
  // Used to track when the slider crosses an integer threshold to trigger a crisp haptic
  int? _lastTrainingDaysInt;

  @override
  void initState() {
    super.initState();
    _lastTrainingDaysInt = widget.trainingDays.toInt();
  }

  Widget _buildSelectionPill(String title, bool isSelected, VoidCallback onTap) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // CRISP HAPTIC ADDED HERE
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          // DYNAMIC: Dark gray in dark mode, light gray in light mode
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CD964) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Text(
              title,
              style: TextStyle(
                color: textColor, // DYNAMIC
                fontSize: 16, 
                fontWeight: FontWeight.w600
              ),
            ),
            // ANIMATED CHECKMARK ADDED HERE
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 22, key: ValueKey('checked'))
                  : const SizedBox(width: 22, height: 22, key: ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final difficultyItems =[
      const CNPopupMenuItem(label: 'Easy'),
      const CNPopupMenuItem(label: 'Medium'),
      const CNPopupMenuItem(label: 'Hard'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            "Training Schedule",
            style: TextStyle(
              color: textColor, // DYNAMIC
              fontSize: 32, 
              fontWeight: FontWeight.w700, 
              letterSpacing: -1
            ),
          ),

          const SizedBox(height: 32),

          // --- TRAINING DAYS SLIDER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text("Training Days per Week", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
              Text(
                "${widget.trainingDays.toInt()} Days",
                style: const TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: CNSlider(
              value: widget.trainingDays,
              min: 0,
              max: 7,
              onChanged: (val) {
                // Trigger a tick haptic only when the integer value changes
                int currentInt = val.toInt();
                if (_lastTrainingDaysInt != currentInt) {
                  HapticFeedback.selectionClick();
                  _lastTrainingDaysInt = currentInt;
                }
                widget.onTrainingDaysChange(val);
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- AVERAGE DURATION ---
          Text("Average Session Duration", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          ...[
            'Less than 30 minutes',
            '30 to 60 minutes',
            'Two hours',
            'More than two hours',
          ].map((duration) => _buildSelectionPill(
                duration,
                widget.averageDuration == duration,
                () => widget.onDurationSelect(duration),
              )),

          const SizedBox(height: 20),

          // --- TRAINING INTENSITY ---
          Text("Training Intensity", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              // DYNAMIC: Dark gray in dark mode, light gray in light mode
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:[
                Text("Difficulty Level", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)), // DYNAMIC
                CNPopupMenuButton(
                  key: ValueKey(widget.intensityIndex),
                  buttonLabel: difficultyItems[widget.intensityIndex].label,
                  items: difficultyItems,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    widget.onIntensitySelect(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- PRIMARY GOALS ---
          Text("Primary Goals", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          ...[
            'Endurance',
            'Improve Recovery',
            'Gain Muscle',
            'Prevent Injuries',
            'Build Strength',
            'Lose Fat',
            'Improve Speed',
          ].map((goal) => _buildSelectionPill(
                goal,
                widget.primaryGoals.contains(goal),
                () => widget.onPrimaryGoalToggle(goal),
              )),

          const SizedBox(height: 20),

          // --- SECONDARY GOALS ---
          Text("Secondary Goals (Optional)", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          ...[
            'Better Sleep',
            'Higher Stamina',
            'Training Consistency',
          ].map((goal) => _buildSelectionPill(
                goal,
                widget.secondaryGoals.contains(goal),
                () => widget.onSecondaryGoalToggle(goal),
              )),

          const SizedBox(height: 140),
        ],
      ),
    );
  }
}