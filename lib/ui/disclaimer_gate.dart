import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/ui/start_page.dart';

/// Shown once on first launch before the start page.
/// After tapping "I Understand", the flag is persisted and the user
/// never sees this screen again.
class DisclaimerGate extends StatefulWidget {
  const DisclaimerGate({super.key});

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  static const _prefKey = 'disclaimer_accepted_v1';
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_prefKey) ?? false;
    if (accepted && mounted) {
      // Already accepted — go straight to start page
      _goToStart();
      return;
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _accept() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) _goToStart();
  }

  void _goToStart() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const StartPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = isDark ? const Color(0xFF111111) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final subColor = textColor.withValues(alpha: 0.6);
    const red = Color(0xFFFF3B30);
    const redBg = Color(0x1AFF3B30);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: redBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  t.disclaimerGateTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.disclaimerGateSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: subColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Points list
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _Point(
                          icon: Icons.monitor_heart_outlined,
                          color: red,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          title: t.disclaimerGatePoint1Title,
                          body: t.disclaimerGatePoint1Body,
                        ),
                        const SizedBox(height: 12),
                        _Point(
                          icon: Icons.psychology_outlined,
                          color: red,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          title: t.disclaimerGatePoint2Title,
                          body: t.disclaimerGatePoint2Body,
                        ),
                        const SizedBox(height: 12),
                        _Point(
                          icon: Icons.restaurant_outlined,
                          color: red,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          title: t.disclaimerGatePoint3Title,
                          body: t.disclaimerGatePoint3Body,
                        ),
                        const SizedBox(height: 12),
                        _Point(
                          icon: Icons.account_balance_wallet_outlined,
                          color: red,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          title: t.disclaimerGatePoint4Title,
                          body: t.disclaimerGatePoint4Body,
                        ),
                        const SizedBox(height: 12),
                        // AI-specific note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: redBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: red.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: red, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t.disclaimerGateAiNote,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // I Understand button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed: _accept,
                    style: FilledButton.styleFrom(
                      backgroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      t.disclaimerGateAccept,
                      style: GoogleFonts.plusJakartaSans(
                        color: bgColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  t.disclaimerGateFooter,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: subColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final String title;
  final String body;

  const _Point({
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    color: subColor,
                    fontSize: 13,
                    height: 1.45,
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
