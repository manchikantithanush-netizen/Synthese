import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/adaptive_onboarding_slide.dart';

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
    final t = AppLocalizations.of(context);
    final isCompact = mediaQuery.size.height < 760;
    final titleSize = isCompact ? 30.0 : 34.0;
    final iconSize = isCompact ? 30.0 : 35.0;
    final featureGap = isCompact ? 14.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedTextScale.toDouble()),
          ),
          child: AdaptiveOnboardingSlide(
            children: [
                    SizedBox(height: isCompact ? 12 : 32),
                    Text(
                      t.mindfulnessOnboardingTitle,
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
                      title: t.mindfulnessOnboardingFeature1Title,
                      subtitle: t.mindfulnessOnboardingFeature1Desc,
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.bell,
                        size: iconSize,
                        color: const Color(0xFFFF9F0A),
                      ),
                      title: t.mindfulnessOnboardingFeature2Title,
                      subtitle: t.mindfulnessOnboardingFeature2Desc,
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.heart_fill,
                        size: iconSize,
                        color: const Color(0xFFFF453A),
                      ),
                      title: t.mindfulnessOnboardingFeature3Title,
                      subtitle: t.mindfulnessOnboardingFeature3Desc,
                      compact: isCompact,
                    ),
                    SizedBox(height: featureGap),
                    _FeatureRow(
                      icon: Icon(
                        CupertinoIcons.chart_bar_fill,
                        size: iconSize,
                        color: const Color(0xFF32ADE6),
                      ),
                      title: t.mindfulnessOnboardingFeature4Title,
                      subtitle: t.mindfulnessOnboardingFeature4Desc,
                      compact: isCompact,
                    ),
                    const Spacer(),
                    PremiumButton(
                      text: t.mindfulnessOnboardingBegin,
                      onPressed: onContinue,
                      color: accentColor,
                    ),
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
