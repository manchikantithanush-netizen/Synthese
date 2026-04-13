import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/mindfulness/mindfulness_page.dart';
import 'package:synthese/ui/components/universalbutton.dart';

class MindfulnessOnboarding extends StatelessWidget {
  final VoidCallback onContinue;
  const MindfulnessOnboarding({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = isDark
        ? const Color(0xFF009688)
        : const Color(0xFF33BEBE);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'Welcome to Mindfulness',
                style: TextStyle(
                  color: textColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -1.0,
                ),
              ),
              const Spacer(),
              _FeatureRow(
                icon: const Icon(
                  CupertinoIcons.moon_stars,
                  size: 35,
                  color: Color(0xFF5E5CE6),
                ), // Indigo
                title: 'Guided Meditations',
                subtitle: 'Relax and refocus with science-backed sessions.',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: const Icon(
                  CupertinoIcons.bell,
                  size: 35,
                  color: Color(0xFFFF9F0A),
                ), // Orange
                title: 'Mindful Reminders',
                subtitle:
                    'Gentle nudges to help you stay present throughout your day.',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: const Icon(
                  CupertinoIcons.heart_fill,
                  size: 35,
                  color: Color(0xFFFF453A),
                ), // Red
                title: 'Mood & Reflection',
                subtitle:
                    'Track your mood and reflect on your mental well-being.',
              ),
              const SizedBox(height: 20),
              _FeatureRow(
                icon: const Icon(
                  CupertinoIcons.chart_bar_fill,
                  size: 35,
                  color: Color(0xFF32ADE6),
                ), // Light Blue
                title: 'Progress Insights',
                subtitle: 'See your mindfulness journey and growth over time.',
              ),
              const Spacer(),
              PremiumButton(
                text: 'Begin',
                onPressed: onContinue,
                color: accentColor,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Padding(padding: const EdgeInsets.only(top: 2.0), child: icon),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
