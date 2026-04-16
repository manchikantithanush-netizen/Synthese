import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/ui/components/universalbutton.dart';

class MindfulnessOnboarding extends StatelessWidget {
  final VoidCallback onContinue;
  const MindfulnessOnboarding({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = isDark
        ? const Color(0xFF009688)
        : const Color(0xFF33BEBE);

    return Scaffold(
      body: SafeArea(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedTextScale.toDouble()),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 760;
              final horizontalPadding = constraints.maxWidth < 370
                  ? 20.0
                  : 28.0;
              final titleSize = isCompact ? 30.0 : 34.0;
              final iconSize = isCompact ? 30.0 : 35.0;
              final featureGap = isCompact ? 14.0 : 20.0;
              final bottomSpacing = isCompact ? 12.0 : 24.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isCompact ? 10 : 16,
                  horizontalPadding,
                  bottomSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isCompact ? 12 : 32),
                    Text(
                      'Welcome to Mindfulness',
                      style: TextStyle(
                        color: textColor,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Spacer(),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.moon_stars,
                        size: iconSize,
                        color: const Color(0xFF5E5CE6),
                      ),
                      title: 'Guided Meditations',
                      subtitle:
                          'Relax and refocus with science-backed sessions.',
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.bell,
                        size: iconSize,
                        color: const Color(0xFFFF9F0A),
                      ),
                      title: 'Mindful Reminders',
                      subtitle:
                          'Gentle nudges to help you stay present throughout your day.',
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.heart_fill,
                        size: iconSize,
                        color: const Color(0xFFFF453A),
                      ),
                      title: 'Mood & Reflection',
                      subtitle:
                          'Track your mood and reflect on your mental well-being.',
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.chart_bar_fill,
                        size: iconSize,
                        color: const Color(0xFF32ADE6),
                      ),
                      title: 'Progress Insights',
                      subtitle:
                          'See your mindfulness journey and growth over time.',
                      compact: isCompact,
                    ),
                    const Spacer(),
                    PremiumButton(
                      text: 'Begin',
                      onPressed: onContinue,
                      color: accentColor,
                    ),
                  ],
                ),
              );
            },
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
  final bool compact;
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: compact ? 48 : 56,
          child: Padding(padding: const EdgeInsets.only(top: 2.0), child: icon),
        ),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: compact ? 14 : 15,
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
