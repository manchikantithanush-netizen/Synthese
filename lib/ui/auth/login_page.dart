import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'signup_page.dart';
import 'package:synthese/onboarding/onboarding_intro.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  String? _errorMessage;
  bool _notificationIsError = true;
  Timer? _errorTimer;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _triggerNotification(String message, {bool isError = true}) {
    if (isError) HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = message;
      _notificationIsError = isError;
    });
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  Future<void> signInWithEmail() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _triggerNotification(AppLocalizations.of(context).loginErrEnterCredentials);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      User? user = FirebaseAuth.instance.currentUser;
      const _bypassVerificationEmails = {
        'testforgoogle@synthese.com',
        'testforthanush@synthese.com',
      };
      final emailLower = (user?.email ?? '').toLowerCase();
      if (user != null && !user.emailVerified && !_bypassVerificationEmails.contains(emailLower)) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _triggerNotification(
              AppLocalizations.of(context).loginErrVerifyEmail);
        }
        setState(() => _isLoading = false);
        return;
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushAndRemoveUntil(
          context,
          _fadeRoute(const OnboardingIntro()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _triggerNotification(
            e.message ?? AppLocalizations.of(context).loginErrLoginFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
      final googleSignIn = GoogleSignIn(
        // `clientId` is needed for Apple platforms; using it on Android can
        // break the token handoff after account selection.
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? '118165710666-mu9h11167ij8v9ttqs8u569g0d77bqke.apps.googleusercontent.com'
            : null,
        serverClientId: webClientId != null && webClientId.isNotEmpty
            ? webClientId
            : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: mounted
              ? AppLocalizations.of(context).authGoogleNoToken
              : 'Google sign-in did not return an auth token.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pushAndRemoveUntil(
          context,
          _fadeRoute(const OnboardingIntro()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _triggerNotification(
          e.message ?? AppLocalizations.of(context).authGoogleFailedCode(e.code));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      final rawMessage = e.message ?? '';
      if (e.code == 'sign_in_failed' &&
          rawMessage.contains('ApiException: 10')) {
        _triggerNotification(t.authGoogleAndroidConfig);
        return;
      }
      final details = [
        e.code,
        e.message,
      ].whereType<String>().where((part) => part.isNotEmpty).join(': ');
      _triggerNotification(
        '${t.authGoogleFailed}${details.isNotEmpty ? ' ($details)' : ''}',
      );
    } catch (e) {
      if (!mounted) return;
      _triggerNotification(
          AppLocalizations.of(context).authGoogleFailedType('${e.runtimeType}'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _triggerNotification(
          AppLocalizations.of(context).loginErrResetEnterEmail);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _triggerNotification(
          AppLocalizations.of(context).loginMsgResetSent,
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _triggerNotification(AppLocalizations.of(context).loginErrResetFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _iosInputDecoration(
    BuildContext context,
    String hint,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
      ),
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
            final mediaQuery = MediaQuery.of(context);
            final bottomSpacing =
                mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom + 24;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, 12, 28, bottomSpacing),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Back button row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UniversalBackButton(
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Image.asset(
                          isDark
                              ? 'assets/logotextdarkside.png'
                              : 'assets/logotextlightside.png',
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Text(
                      t.loginTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),

                    // Inline notification area
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: _errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _notificationIsError
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF4CD964),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : const SizedBox(height: 20),
                    ),

                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: _iosInputDecoration(
                        context,
                        t.loginEmail,
                        Icons.mail_outline,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: _iosInputDecoration(
                        context,
                        t.loginPassword,
                        Icons.lock_outline,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: GestureDetector(
                        onTap: resetPassword,
                        child: Text(
                          t.loginForgot,
                          style: TextStyle(
                            color: textColor.withOpacity(0.54),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    _isLoading
                        ? const Center(child: BouncingDotsLoader())
                        : Column(
                            children: [
                              PremiumButton(
                                text: t.loginButton,
                                onPressed: signInWithEmail,
                              ),
                              const SizedBox(height: 14),
                              PremiumButton(
                                text: t.authContinueGoogle,
                                onPressed: signInWithGoogle,
                                showIcon: true,
                                icon: Image.asset(
                                  'assets/google.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            ],
                          ),

                    const SizedBox(height: 32),

                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pushReplacement(
                          context,
                          _fadeRoute(const SignupPage()),
                        );
                      },
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: textColor.withOpacity(0.54),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: t.loginNoAccount),
                            TextSpan(
                              text: t.loginSignUp,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
