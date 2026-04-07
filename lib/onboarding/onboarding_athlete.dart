import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';

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

  static const List<String> athleteTypes =[
    'Student Athlete',
    'Club Athlete',
    'Casual Athlete',
    'Competitive Athlete',
  ];

  static const List<String> experienceLevels =[
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    // Generate the CNPopupMenuItem lists
    final athleteItems = athleteTypes
        .map((type) => CNPopupMenuItem(label: type))
        .toList();
        
    final experienceItems = experienceLevels
        .map((level) => CNPopupMenuItem(label: level))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(
            "Athlete Profile",
            style: TextStyle(
                color: textColor, // DYNAMIC
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            "What type of athlete are you?",
            style: TextStyle(
              color: textColor.withOpacity(0.5), // DYNAMIC: Was Colors.white38
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          // Wrapped in a container to match your beautiful UI inputs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // DYNAMIC: Dark gray in dark mode, light gray in light mode
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CNPopupMenuButton(
                buttonLabel: athleteType ?? 'Select Athlete Type',
                items: athleteItems,
                onSelected: (index) {
                  onAthleteTypeSelect(athleteTypes[index]);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            "What is your experience level?",
            style: TextStyle(
              color: textColor.withOpacity(0.5), // DYNAMIC: Was Colors.white38
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // DYNAMIC: Dark gray in dark mode, light gray in light mode
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CNPopupMenuButton(
                buttonLabel: experienceLevel ?? 'Select Experience Level',
                items: experienceItems,
                onSelected: (index) {
                  onExperienceSelect(experienceLevels[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}