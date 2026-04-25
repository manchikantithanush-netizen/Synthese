import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingAthlete extends StatelessWidget {
  final String? athleteType;
  final String? experienceLevel;
  final Function(String) onAthleteTypeSelect;
  final Function(String) onExperienceSelect;

  const OnboardingAthlete({
    super.key,
    required this.athleteType,
    required this.experienceLevel,
    required this.onAthleteTypeSelect,
    required this.onExperienceSelect,
  });

  static const List<String> athleteTypes = [
    'Student Athlete',
    'Club Athlete',
    'Casual Athlete',
    'Competitive Athlete',
  ];

  static const List<String> experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  Widget _pill(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CD964) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: isSelected
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF4CD964), size: 22, key: ValueKey('on'))
                  : const SizedBox(width: 22, height: 22, key: ValueKey('off')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Athlete Profile",
              style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1)),
          const SizedBox(height: 32),
          Text("What type of athlete are you?",
              style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          ...athleteTypes.map((t) =>
              _pill(context, t, athleteType == t, () => onAthleteTypeSelect(t))),
          const SizedBox(height: 20),
          Text("What is your experience level?",
              style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 12),
          ...experienceLevels.map((l) =>
              _pill(context, l, experienceLevel == l, () => onExperienceSelect(l))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
