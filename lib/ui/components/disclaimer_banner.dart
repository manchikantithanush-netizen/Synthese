import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

/// Disclaimer banners used throughout the app.
///
/// Two flavours:
/// - [DisclaimerBanner.general] / [DisclaimerBanner.generalShort]
///   Used on dashboard, finance, cycles, mindfulness, onboarding, start page.
///   No mention of AI — the app uses pre-configured algorithms there.
///
/// - [DisclaimerBanner.ai] / [DisclaimerBanner.aiShort]
///   Used ONLY in the nutrition/diet section, where AI estimates calories
///   and macros from photos or text descriptions.
enum _DisclaimerVariant { general, generalShort, ai, aiShort }

class DisclaimerBanner extends StatelessWidget {
  final _DisclaimerVariant _variant;

  const DisclaimerBanner._({required _DisclaimerVariant variant})
      : _variant = variant;

  /// Full general disclaimer — start page, onboarding finish slide.
  const DisclaimerBanner.general() : _variant = _DisclaimerVariant.general;

  /// Compact general disclaimer — dashboard, finance, cycles, mindfulness.
  const DisclaimerBanner.generalShort()
      : _variant = _DisclaimerVariant.generalShort;

  /// Full AI disclaimer — diet section (expanded placement).
  const DisclaimerBanner.ai() : _variant = _DisclaimerVariant.ai;

  /// Compact AI disclaimer — inside individual food result cards.
  const DisclaimerBanner.aiShort() : _variant = _DisclaimerVariant.aiShort;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const red = Color(0xFFFF3B30);
    const redBg = Color(0x1AFF3B30);

    final bool isAi =
        _variant == _DisclaimerVariant.ai || _variant == _DisclaimerVariant.aiShort;
    final bool isShort =
        _variant == _DisclaimerVariant.generalShort || _variant == _DisclaimerVariant.aiShort;

    final String title = isAi ? t.disclaimerAiTitle : t.disclaimerTitle;
    final String bodyText = isAi ? t.disclaimerAiBody : t.disclaimerBody;
    final String shortText = isAi ? t.disclaimerAiShort : t.disclaimerShort;

    if (isShort) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: redBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: red.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shortText,
                style: const TextStyle(
                  color: red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Full version
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: redBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: red.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: red,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: const TextStyle(
              color: red,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
