import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/ui/heart_rate_measure_page.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

/// Key used to persist the "don't show again" preference.
const String _kDismissedKey = 'hr_warn_dismissed_v1';

/// Entry point — push this instead of [HeartRateMeasurePage] directly.
/// Shows the warning page on first use; skips it once the user has dismissed it.
Future<int?> pushHeartRateMeasure(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final dismissed = prefs.getBool(_kDismissedKey) ?? false;

  if (!context.mounted) return null;

  if (dismissed) {
    return Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const HeartRateMeasurePage(),
        fullscreenDialog: true,
      ),
    );
  }

  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) => const HeartRateMeasureWarningPage(),
      fullscreenDialog: true,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning page
// ─────────────────────────────────────────────────────────────────────────────
class HeartRateMeasureWarningPage extends StatefulWidget {
  const HeartRateMeasureWarningPage({super.key});

  @override
  State<HeartRateMeasureWarningPage> createState() =>
      _HeartRateMeasureWarningPageState();
}

class _HeartRateMeasureWarningPageState
    extends State<HeartRateMeasureWarningPage> {
  bool _dontShowAgain = false;

  Future<void> _continue() async {
    HapticFeedback.mediumImpact();
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDismissedKey, true);
    }
    if (!mounted) return;
    // Replace this page so back from measurement goes to the detail page,
    // not back here.
    await Navigator.of(context).pushReplacement<int, void>(
      MaterialPageRoute(
        builder: (_) => const HeartRateMeasurePage(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final subColor = textColor.withValues(alpha: 0.55);
    final dimColor = textColor.withValues(alpha: 0.35);
    final font = GoogleFonts.plusJakartaSans;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: UniversalBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Illustration ─────────────────────────────────────
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          maxWidth: 300,
                        ),
                        child: Image.asset(
                          'assets/heartfinger.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      t.hrWarnTitle,
                      style: font(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.hrWarnSubtitle,
                      style: font(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Warning cards ─────────────────────────────────────
                    _WarningCard(
                      icon: Icons.medical_information_outlined,
                      iconColor: const Color(0xFF007AFF),
                      title: t.hrWarnAccuracy,
                      body: t.hrWarnAccuracyBody,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _WarningCard(
                      icon: Icons.thermostat_outlined,
                      iconColor: const Color(0xFFFF9F0A),
                      title: t.hrWarnHeat,
                      body: t.hrWarnHeatBody,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _WarningCard(
                      icon: Icons.touch_app_outlined,
                      iconColor: const Color(0xFF34C759),
                      title: t.hrWarnHowTo,
                      body: t.hrWarnHowToBody,
                      cardColor: cardColor,
                      textColor: textColor,
                      subColor: subColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 28),

                    // ── Don't show again ──────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _dontShowAgain = !_dontShowAgain);
                      },
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _dontShowAgain
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _dontShowAgain
                                    ? Colors.redAccent
                                    : dimColor,
                                width: 1.5,
                              ),
                            ),
                            child: _dontShowAgain
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.hrWarnDismiss,
                            style: font(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: dimColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Continue button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          t.hrWarnContinue,
                          style: font(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning card
// ─────────────────────────────────────────────────────────────────────────────
class _WarningCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const _WarningCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: font(
                    fontSize: 13,
                    color: subColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
