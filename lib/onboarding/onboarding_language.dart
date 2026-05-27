import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/locale_service.dart';

class OnboardingLanguage extends StatelessWidget {
  const OnboardingLanguage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, currentLocale, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.onboardingLanguageTitle,
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
                t.onboardingLanguageBody,
                style: TextStyle(
                  color: textColor.withOpacity(0.55),
                  fontSize: 16,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 32),
              ...LocaleService.languages.map(
                (lang) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LanguageTile(
                    nativeLabel: lang.nativeLabel,
                    englishLabel: lang.englishLabel,
                    selected: currentLocale.languageCode ==
                        lang.locale.languageCode,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      LocaleService.setLocale(lang.locale);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String nativeLabel;
  final String englishLabel;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.nativeLabel,
    required this.englishLabel,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeLabel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    englishLabel,
                    style: TextStyle(
                      color: textColor.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : textColor.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
