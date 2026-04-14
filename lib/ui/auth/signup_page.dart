import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'login_page.dart';
import 'verification_page.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

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

  Future<void> signUp() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _triggerError('Please fill in all fields');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _triggerError('Passwords do not match');
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
        Navigator.pushReplacement(
          context,
          _fadeRoute(const VerificationPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _triggerError(e.message ?? 'Sign up failed');
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
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button row
              Row(
                children: [
                  UniversalBackButton(onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text(
                    'Synthese',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                'Sign Up',
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
                  'Email',
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
                  'Password',
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
                  'Confirm Password',
                  Icons.lock_outline,
                ),
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PremiumButton(text: 'Create Account', onPressed: signUp),

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
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
