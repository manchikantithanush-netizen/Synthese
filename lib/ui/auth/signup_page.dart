import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'login_page.dart';
import 'verification_page.dart';
import 'package:synthese/onboarding/onboarding_intro.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  late FocusNode _passwordFocusNode;
  String _passwordText = '';
  bool _isLoading = false;

  String? _errorMessage;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();
    _passwordFocusNode.addListener(() => setState(() {}));
    passwordController.addListener(
      () => setState(() => _passwordText = passwordController.text),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _triggerError(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMessage = message);
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
      _triggerError(
          e.message ?? AppLocalizations.of(context).authGoogleFailedCode(e.code));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      final rawMessage = e.message ?? '';
      if (e.code == 'sign_in_failed' &&
          rawMessage.contains('ApiException: 10')) {
        _triggerError(t.authGoogleAndroidConfig);
        return;
      }
      final details = [
        e.code,
        e.message,
      ].whereType<String>().where((part) => part.isNotEmpty).join(': ');
      _triggerError(
        '${t.authGoogleFailed}${details.isNotEmpty ? ' ($details)' : ''}',
      );
    } catch (e) {
      if (!mounted) return;
      _triggerError(
          AppLocalizations.of(context).authGoogleFailedType('${e.runtimeType}'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signUp() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _triggerError(AppLocalizations.of(context).signupErrFillFields);
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _triggerError(AppLocalizations.of(context).signupErrPasswordMismatch);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        const _bypassVerificationEmails = {
          'testforgoogle@synthese.com',
          'testforthanush@synthese.com',
        };
        final emailLower = emailController.text.trim().toLowerCase();
        if (_bypassVerificationEmails.contains(emailLower)) {
          Navigator.pushReplacement(
            context,
            _fadeRoute(const OnboardingIntro()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            _fadeRoute(const VerificationPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _triggerError(
            e.message ?? AppLocalizations.of(context).signupErrFailed);
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
                      t.signupTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                      ),
                    ),

                    // Inline error notification
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: _errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFF3B30),
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
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: _iosInputDecoration(
                        context,
                        t.loginPassword,
                        Icons.lock_outline,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      decoration: _iosInputDecoration(
                        context,
                        t.signupConfirmPassword,
                        Icons.lock_outline,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _isLoading
                        ? const Center(child: BouncingDotsLoader())
                        : Column(
                            children: [
                              PremiumButton(
                                text: t.signupCreateAccount,
                                onPressed: signUp,
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
                          _fadeRoute(const LoginPage()),
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
                            TextSpan(text: t.signupHaveAccount),
                            TextSpan(
                              text: t.loginButton,
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
