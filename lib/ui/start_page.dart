import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synthese/services/guest_session_service.dart';
import 'package:synthese/services/session_guard_service.dart';
import 'package:synthese/ui/components/app_toast.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/auth/login_page.dart';
import 'package:synthese/ui/auth/signup_page.dart';
import 'package:synthese/onboarding/onboarding_intro.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // --- TEXT CONSTANTS ---
  final String _introText = 'Hello,\nWelcome to Synthese';

  // Dictionary parts broken down for dynamic styling during typing
  final String _defWord = 'Synthese\n';
  final String _defPron = '/ˈsɪnθɪsiːz/\n';
  final String _defPos = 'noun\n\n';
  final String _defMeaning =
      "The synthesis of an athlete's performance, recovery, and lifestyle data into clear, intuitive insights — built for the next generation of athletes.\n\n";
  final String _defOrigin =
      'From Greek: synthesis — a bringing together of distinct elements into a unified whole.';

  late final String _dictText;

  // --- STATE ---
  String _displayedText = '';
  int _phase = 0; // 0: Typing Intro, 1: Backspacing Intro, 2: Typing Dictionary, 3: Backspacing Dictionary
  bool _showLogo = false;
  bool _logoVisible = false;
  bool _isGuestLoading = false;

  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _dictText = '$_defWord$_defPron$_defPos$_defMeaning$_defOrigin';
    _startSequence();
    // If we landed here because the account was logged in on another device,
    // let the user know why they were signed out.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final superseded =
          await SessionGuardService.instance.consumeSupersededFlag();
      if (superseded && mounted) {
        AppToast.info(
          context,
          AppLocalizations.of(context).sessionSignedOutOtherDevice,
          icon: Icons.devices_other,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  Future<void> _startSequence() async {
    // PHASE 0: Type Intro
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < _introText.length; i++) {
      if (!mounted) return;
      setState(() => _displayedText = _introText.substring(0, i + 1));

      String char = _introText[i];
      if (_route?.isCurrent == true && char != ' ' && char != '\n') {
        HapticFeedback.lightImpact();
      }

      int delay = (char == ',' || char == '\n') ? 520 : 75;
      await Future.delayed(Duration(milliseconds: delay));
    }

    await Future.delayed(const Duration(milliseconds: 2200));

    // PHASE 1: Backspace Intro
    _phase = 1;
    for (int i = _introText.length; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _displayedText = _introText.substring(0, i));

      if (_route?.isCurrent == true && i > 0) {
        HapticFeedback.selectionClick();
      }
      await Future.delayed(const Duration(milliseconds: 20));
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // PHASE 2: Type Dictionary
    _phase = 2;
    for (int i = 0; i < _dictText.length; i++) {
      if (!mounted) return;
      setState(() => _displayedText = _dictText.substring(0, i + 1));

      String char = _dictText[i];
      if (_route?.isCurrent == true && char != ' ' && char != '\n') {
        HapticFeedback.lightImpact();
      }

      int delay = 28;
      if (char == '.' || char == ',')
        delay = 220;
      else if (char == '\n')
        delay = 300;

      await Future.delayed(Duration(milliseconds: delay));
    }

    await Future.delayed(const Duration(milliseconds: 1400));

    // PHASE 3: Backspace Dictionary
    _phase = 3;
    for (int i = _dictText.length; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _displayedText = _dictText.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (!mounted) return;
    setState(() => _showLogo = true);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _logoVisible = true);
  }

  List<InlineSpan> _buildTextSpans(double scale) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final introSize = (40 * scale).clamp(32.0, 52.0);
    final wordSize = (34 * scale).clamp(26.0, 44.0);
    final pronSize = (18 * scale).clamp(14.0, 24.0);
    final posSize = (16 * scale).clamp(13.0, 21.0);
    final meaningSize = (18 * scale).clamp(14.0, 23.0);
    final originSize = (14 * scale).clamp(12.0, 18.0);
    final cursorSize = (18 * scale).clamp(14.0, 24.0);

    if (_phase < 2) {
      return [
        TextSpan(
          text: _displayedText,
          style: TextStyle(
            color: textColor,
            fontSize: introSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),
        TextSpan(
          text: '|',
          style: TextStyle(
            color: textColor,
            fontSize: introSize,
            fontWeight: FontWeight.w300,
          ),
        ),
      ];
    } else {
      List<InlineSpan> spans = [];
      int currentIndex = 0;

      void addPart(String partText, TextStyle style) {
        if (currentIndex >= _displayedText.length) return;
        int endIndex = currentIndex + partText.length;
        if (endIndex > _displayedText.length) endIndex = _displayedText.length;

        spans.add(
          TextSpan(
            text: _displayedText.substring(currentIndex, endIndex),
            style: style,
          ),
        );
        currentIndex += partText.length;
      }

      addPart(
        _defWord,
        TextStyle(
          color: textColor,
          fontSize: wordSize,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      );
      addPart(
        _defPron,
        TextStyle(
          color: textColor.withOpacity(0.7),
          fontSize: pronSize,
          fontStyle: FontStyle.italic,
        ),
      );
      addPart(
        _defPos,
        TextStyle(
          color: textColor.withOpacity(0.5),
          fontSize: posSize,
          fontStyle: FontStyle.italic,
        ),
      );
      addPart(
        _defMeaning,
        TextStyle(
          color: textColor.withOpacity(0.95),
          fontSize: meaningSize,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      );
      addPart(
        _defOrigin,
        TextStyle(
          color: textColor.withOpacity(0.5),
          fontSize: originSize,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      );

      spans.add(
        TextSpan(
          text: '|',
          style: TextStyle(
            color: textColor,
            fontSize: cursorSize,
            fontWeight: FontWeight.w300,
          ),
        ),
      );

      return spans;
    }
  }

  /// Explain the guest-mode limitations, then continue only if confirmed.
  Future<void> _showGuestDialog() async {
    if (_isGuestLoading) return;
    HapticFeedback.lightImpact();
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dialogBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final subColor = textColor.withOpacity(0.65);

    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: textColor.withOpacity(0.55)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.4,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: Text(
          t.guestDialogTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.guestDialogIntro,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.45,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            point(Icons.cloud_off_rounded, t.guestDialogPoint1),
            point(Icons.devices_rounded, t.guestDialogPoint2),
            point(Icons.timer_outlined, t.guestDialogPoint3),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.guestDialogCancel,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.guestDialogConfirm,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _continueAsGuest();
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isGuestLoading) return;
    setState(() => _isGuestLoading = true);
    try {
      HapticFeedback.lightImpact();

      // Reuse an existing anonymous session if one is already active (e.g. a
      // repeated tap, or an earlier attempt that signed in but didn't finish),
      // otherwise create a fresh one. This stops multiple taps from minting
      // duplicate anonymous accounts.
      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      if (user == null || !user.isAnonymous) {
        user = (await auth.signInAnonymously()).user;
      }
      if (user == null) {
        throw Exception(mounted
            ? AppLocalizations.of(context).startAnonFailed
            : 'Anonymous sign-in failed');
      }
      final uid = user.uid;

      // Make sure the freshly-minted anonymous auth token has actually reached
      // the Firestore SDK's credential provider before we attempt the first
      // write. Without this, the write below can race ahead of token
      // propagation and come back as `unauthenticated` / `permission-denied`,
      // which is what made the guest button "not work" on real devices.
      await user.getIdToken();

      // Minimal profile doc so the rest of the app has a users/{uid} to read.
      // The guest label is derived from the uid — there's no global counter, so
      // no shared-document contention to slow this down or make it fail under
      // load. _runWithAuthRetry covers the brief window before the freshly
      // issued auth token reaches the Firestore client.
      await _runWithAuthRetry<void>(() {
        return FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': 'GUEST#${uid.substring(0, 6).toUpperCase()}',
          'isGuest': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // Anchor the local 3-day guest session timer.
      await GuestSessionService.instance.startSession();

      if (!mounted) return;
      Navigator.pushReplacement(context, _fadeRoute(const OnboardingIntro()));
    } catch (e) {
      if (mounted) {
        setState(() => _isGuestLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).startGuestFailed(
                      _friendlyGuestError(e)))),
        );
      }
    }
  }

  /// Retry a Firestore call a few times if it fails with a transient auth
  /// error (`permission-denied` or `unauthenticated`) — both can happen while
  /// the auth token is still propagating to the Firestore SDK right after
  /// anonymous sign-in. Other errors are rethrown immediately.
  Future<T> _runWithAuthRetry<T>(Future<T> Function() op) async {
    const retryableCodes = {'permission-denied', 'unauthenticated'};
    const delays = [
      Duration(milliseconds: 250),
      Duration(milliseconds: 600),
      Duration(milliseconds: 1200),
    ];
    Object? lastError;
    for (var i = 0; i <= delays.length; i++) {
      try {
        return await op();
      } on FirebaseException catch (e) {
        lastError = e;
        if (!retryableCodes.contains(e.code) || i == delays.length) rethrow;
        await Future.delayed(delays[i]);
      }
    }
    throw lastError ?? Exception('Unknown error');
  }

  /// Map common Firebase failures to a short, user-readable message instead
  /// of dumping the raw `[cloud_firestore/...]` exception into a snackbar.
  String _friendlyGuestError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return 'Something went wrong setting up guest access. Please try again.';
        case 'unavailable':
        case 'deadline-exceeded':
        case 'network-request-failed':
          return 'Network is unstable. Check your connection and try again.';
        case 'aborted':
        case 'failed-precondition':
          return 'Please try again in a moment.';
      }
    }
    return 'Couldn\'t continue as guest. Please try again.';
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : null,
      body: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final widthScale = (constraints.maxWidth / 390).clamp(0.9, 1.2);
            final heightScale = (constraints.maxHeight / 800).clamp(0.85, 1.15);
            final textScale = ((widthScale + heightScale) / 2).toDouble();
            final horizontalPadding = constraints.maxWidth < 360 ? 20.0 : 28.0;
            final topSpacing = constraints.maxHeight < 700 ? 8.0 : 18.0;
            final animationVPadding = constraints.maxHeight < 700 ? 8.0 : 20.0;
            final privacyBottomSpacing = constraints.maxHeight < 700
                ? 10.0
                : 24.0;
            final logoWidth =
                (constraints.maxWidth * 0.68).clamp(160.0, 300.0).toDouble();
            final logoMaxHeight =
                (constraints.maxHeight * 0.24).clamp(80.0, 170.0).toDouble();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topSpacing,
                horizontalPadding,
                0,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: animationVPadding,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: _showLogo
                              ? AnimatedOpacity(
                                  opacity: _logoVisible ? 1 : 0,
                                  duration: const Duration(milliseconds: 550),
                                  curve: Curves.easeInOut,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: logoWidth,
                                        maxHeight: logoMaxHeight,
                                      ),
                                      child: Image.asset(
                                        isDark
                                            ? 'assets/logotextdark.png'
                                            : 'assets/logotextlight.png',
                                        fit: BoxFit.contain,
                                        width: logoWidth,
                                      ),
                                    ),
                                  ),
                                )
                              : Text.rich(
                                  TextSpan(children: _buildTextSpans(textScale)),
                                  textAlign: _phase < 2
                                      ? TextAlign.center
                                      : TextAlign.left,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumButton(
                        text: t.startSignUp,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            _fadeRoute(const SignupPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              _fadeRoute(const LoginPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03),
                            side: BorderSide(
                              color: textColor.withOpacity(isDark ? 0.30 : 0.22),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            t.startSignIn,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed:
                              _isGuestLoading ? null : _showGuestDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: textColor,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: _isGuestLoading
                              // Nudge down to offset the dots' upward bounce so
                              // they read as vertically centered in the button.
                              ? Transform.translate(
                                  offset: const Offset(0, 6),
                                  child: const BouncingDotsLoader(),
                                )
                              : Text(
                                  t.startGuest,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Honest caveat: guest sign-in needs a network round-trip
                      // and can occasionally fail on a poor connection.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Guest mode may occasionally fail on a weak '
                          'connection. For the most reliable experience, we '
                          'recommend signing in normally.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: textColor.withOpacity(0.45),
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: textColor.withOpacity(0.54),
                            fontSize: 12,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          children: [
                            TextSpan(
                              text: t.startLegalPrefix,
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse('https://sites.google.com/view/synthese-workout-health/home');
                                  try {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (_) {
                                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                                  }
                                },
                                child: Text(
                                  t.startPrivacyPolicy,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: t.startAnd),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse('https://sites.google.com/view/syntheseworkouthealthtandc/home');
                                  try {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } catch (_) {
                                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                                  }
                                },
                                child: Text(
                                  t.startTerms,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      SizedBox(height: privacyBottomSpacing),
                    ],
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
