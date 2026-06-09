import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen, non-dismissible block shown when the Play Age Signals API
/// reports that the current user is a minor (or a supervised account whose
/// parent denied approval). Synthese Health is an adults-only (18+) app, so
/// these users may not proceed.
///
/// Strings are intentionally hard-coded in English: this is a rarely-shown
/// legal/safety gate and must render even if localization fails to load.
class MinorRestrictionScreen extends StatelessWidget {
  const MinorRestrictionScreen({super.key});

  static const _red = Color(0xFFFF3B30);
  static const _redBg = Color(0x1AFF3B30);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final subColor = textColor.withValues(alpha: 0.6);

    // Block the system back button — there is no way past this screen.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big warning icon
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _redBg,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: _red,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Adults only',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: _red,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Synthese Health is intended only for people aged 18 and '
                    'over.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Based on the age information provided by Google Play, this '
                    'account does not meet the minimum age requirement, so access '
                    'is not available.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: subColor,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
