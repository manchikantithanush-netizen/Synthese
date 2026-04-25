import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_utils.dart';

class OnboardingLifestyle extends StatefulWidget {
  final double sleepDuration;
  final Function(double) onSleepDurationChange;
  
  final int sleepQualityIndex;
  final Function(int) onSleepQualitySelect;
  
  final double waterIntake;
  final Function(double) onWaterIntakeChange;
  
  final String? caffeineIntake;
  final Function(String) onCaffeineSelect;
  
  final double screenTime;
  final Function(double) onScreenTimeChange;
  
  final TextEditingController injuryHistoryController;

  const OnboardingLifestyle({
    super.key,
    required this.sleepDuration,
    required this.onSleepDurationChange,
    required this.sleepQualityIndex,
    required this.onSleepQualitySelect,
    required this.waterIntake,
    required this.onWaterIntakeChange,
    required this.caffeineIntake,
    required this.onCaffeineSelect,
    required this.screenTime,
    required this.onScreenTimeChange,
    required this.injuryHistoryController,
  });

  @override
  State<OnboardingLifestyle> createState() => _OnboardingLifestyleState();
}

class _OnboardingLifestyleState extends State<OnboardingLifestyle> {
  // Track previous integer values for the sliders to trigger precise tick haptics
  int? _lastSleepInt;
  int? _lastWaterInt;
  int? _lastScreenInt;

  @override
  void initState() {
    super.initState();
    _lastSleepInt = widget.sleepDuration.toInt();
    _lastWaterInt = widget.waterIntake.toInt();
    _lastScreenInt = widget.screenTime.toInt();
  }

  // Animated Pill design matching Training & Sports sections
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

  // Formatting helpers for sliders
  String _formatSleep(double val) {
    int v = val.toInt();
    if (v <= 4) return '< 5 hours';
    if (v >= 8) return '8+ hours';
    return '$v hours';
  }

  String _formatWater(double val) {
    int v = val.toInt();
    if (v >= 5) return '5+ L';
    return '$v L';
  }

  String _formatScreenTime(double val) {
    int v = val.toInt();
    if (v == 0) return '0 hours';
    if (v == 1) return '1 hour';
    if (v == 2) return '2 hours';
    return '2+ hours';
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            "Lifestyle",
            style: TextStyle(
              color: textColor, // DYNAMIC
              fontSize: 32, 
              fontWeight: FontWeight.w700, 
              letterSpacing: -1
            ),
          ),

          const SizedBox(height: 32),

          // --- AVERAGE SLEEP DURATION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text("Average Sleep Duration", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
              Text(
                _formatSleep(widget.sleepDuration),
                style: const TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Slider(
              value: widget.sleepDuration,
              min: 4,
              max: 8,
              divisions: 4,
              activeColor: const Color(0xFF4CD964),
              onChanged: (val) {
                int currentInt = val.toInt();
                if (_lastSleepInt != currentInt) {
                  HapticFeedback.selectionClick();
                  _lastSleepInt = currentInt;
                }
                widget.onSleepDurationChange(val);
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- SLEEP QUALITY ---
          Text("Sleep Quality", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          ...['Poor', 'Fair', 'Good', 'Excellent'].asMap().entries.map((e) =>
              _buildSelectionPill(
                e.value,
                widget.sleepQualityIndex == e.key,
                () => widget.onSleepQualitySelect(e.key),
              )),

          const SizedBox(height: 32),

          // --- DAILY WATER INTAKE ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text("Daily Water Intake", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
              Text(
                _formatWater(widget.waterIntake),
                style: const TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Slider(
              value: widget.waterIntake,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: const Color(0xFF4CD964),
              onChanged: (val) {
                int currentInt = val.toInt();
                if (_lastWaterInt != currentInt) {
                  HapticFeedback.selectionClick();
                  _lastWaterInt = currentInt;
                }
                widget.onWaterIntakeChange(val);
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- CAFFEINE INTAKE ---
          Text("Caffeine Intake", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          ...[
            'None',
            '1 cup',
            '2-3 cups',
            '3+ cups',
          ].map((caffeine) => _buildSelectionPill(
                caffeine,
                widget.caffeineIntake == caffeine,
                () => widget.onCaffeineSelect(caffeine),
              )),

          const SizedBox(height: 20),

          // --- SCREEN TIME BEFORE SLEEP ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text("Screen Time Before Sleep", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
              Text(
                _formatScreenTime(widget.screenTime),
                style: const TextStyle(color: Color(0xFF4CD964), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Slider(
              value: widget.screenTime,
              min: 0,
              max: 3,
              divisions: 3,
              activeColor: const Color(0xFF4CD964),
              onChanged: (val) {
                int currentInt = val.toInt();
                if (_lastScreenInt != currentInt) {
                  HapticFeedback.selectionClick();
                  _lastScreenInt = currentInt;
                }
                widget.onScreenTimeChange(val);
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- INJURY AND HEALTH HISTORY ---
          Text("Injury & Health History", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)), // DYNAMIC
          const SizedBox(height: 12),
          TextField(
            controller: widget.injuryHistoryController,
            style: TextStyle(color: textColor), // DYNAMIC
            cursorColor: textColor, // DYNAMIC
            // Follows the same visual standard used in physical step (Passed Context)
            decoration: OnboardingUtils.iosInput(context, "Describe past injuries or conditions", Icons.medical_services_outlined),
          ),

          const SizedBox(height: 140),
        ],
      ),
    );
  }
}