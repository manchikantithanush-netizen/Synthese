import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OnboardingStage1 extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? dob;
  final VoidCallback onDateTap;
  final String? gender;
  final Function(String) onGenderSelect;
  final List<String> selectedGoals;
  final Function(String) onGoalToggle;
  final bool? isAthlete;
  final Function(bool) onAthleteSelect;

  const OnboardingStage1({
    super.key,
    required this.nameController,
    required this.dob,
    required this.onDateTap,
    required this.gender,
    required this.onGenderSelect,
    required this.selectedGoals,
    required this.onGoalToggle,
    required this.isAthlete,
    required this.onAthleteSelect,
  });

  static const List<_Goal> _goals = [
    _Goal('Endurance', Icons.directions_run_rounded),
    _Goal('Strength', Icons.fitness_center_rounded),
    _Goal('Lose Fat', Icons.local_fire_department_rounded),
    _Goal('Gain Muscle', Icons.sports_gymnastics_rounded),
    _Goal('Speed', Icons.bolt_rounded),
    _Goal('Recovery', Icons.healing_rounded),
    _Goal('Better Sleep', Icons.nightlight_round),
    _Goal('Consistency', Icons.calendar_month_rounded),
  ];

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  InputDecoration _iosInput(BuildContext context, String hint, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isMinor = dob != null && _calculateAge(dob!) < 16;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's get\nstarted",
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
            "Just the basics so we can personalize your experience.",
            style: TextStyle(
              color: textColor.withOpacity(0.55),
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: nameController,
            cursorColor: textColor,
            style: TextStyle(color: textColor),
            decoration: _iosInput(context, "Full name", Icons.person_outline),
          ),

          const SizedBox(height: 24),

          Text(
            "Date of birth",
            style:
                TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined,
                      color: Color(0xFF8E8E93), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    dob == null
                        ? "Select date"
                        : DateFormat('MMMM dd, yyyy').format(dob!),
                    style: TextStyle(
                      color: dob == null
                          ? const Color(0xFF8E8E93)
                          : textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F0A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF9F0A).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFFF9F0A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You're under 16. Parental guidance is required when using this app.",
                        style: TextStyle(
                          color: textColor.withOpacity(0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: isMinor
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeInOut,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
          ),

          const SizedBox(height: 28),

          Text(
            "Gender",
            style:
                TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Used to enable cycle tracking for female users.",
            style: TextStyle(
              color: textColor.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectablePill(
                  label: 'Male',
                  selected: gender == 'Male',
                  onTap: () => onGenderSelect('Male'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectablePill(
                  label: 'Female',
                  selected: gender == 'Female',
                  onTap: () => onGenderSelect('Female'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            "Your goals",
            style:
                TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Pick all that apply",
            style: TextStyle(
              color: textColor.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, i) {
              final goal = _goals[i];
              final selected = selectedGoals.contains(goal.label);
              return _GoalTile(
                goal: goal,
                selected: selected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onGoalToggle(goal.label);
                },
              );
            },
          ),

          const SizedBox(height: 28),

          Text(
            "Are you an athlete?",
            style:
                TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectablePill(
                  label: 'Yes',
                  selected: isAthlete == true,
                  onTap: () => onAthleteSelect(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SelectablePill(
                  label: 'No',
                  selected: isAthlete == false,
                  onTap: () => onAthleteSelect(false),
                ),
              ),
            ],
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD964).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CD964).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF4CD964),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Add your sport, experience level and training details from Account → Athlete Details after onboarding.",
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: isAthlete == true
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeInOut,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeIn,
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _Goal {
  final String label;
  final IconData icon;
  const _Goal(this.label, this.icon);
}

class _GoalTile extends StatelessWidget {
  final _Goal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    const accent = Color(0xFF4CD964);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              goal.icon,
              size: 22,
              color: selected ? accent : textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                goal.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectablePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? textColor
              : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).scaffoldBackgroundColor
                  : textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
