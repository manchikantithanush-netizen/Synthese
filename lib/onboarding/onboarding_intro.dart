import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
// 1. IMPORT DASHBOARD INSTEAD OF MAIN
import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/start_page.dart';
import 'onboarding_data.dart';

class OnboardingIntro extends StatefulWidget {
  const OnboardingIntro({super.key});

  @override
  State<OnboardingIntro> createState() => _OnboardingIntroState();
}

class _OnboardingIntroState extends State<OnboardingIntro> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['onboardingCompleted'] == true) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                // 2. CHANGED HomePage() TO DashboardPage()
                _fadeRoute(const DashboardPage()),
              );
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking status: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goBack() async {
    try {
      HapticFeedback.lightImpact();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          _fadeRoute(const StartPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: BouncingDotsLoader()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            "Hello,",
                            style: TextStyle(
                              color: textColor, // DYNAMIC
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We are going to collect some data so that you can get the best out of your app.",
                            style: TextStyle(
                              color: textColor, // DYNAMIC
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              // DYNAMIC: Dark gray in dark mode, light gray in light mode
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(28),
                              // DYNAMIC: Subtle border matching the theme
                              border: Border.all(
                                color: textColor.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      color: textColor.withOpacity(
                                        0.7,
                                      ), // DYNAMIC
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Privacy First",
                                      style: TextStyle(
                                        color: textColor, // DYNAMIC
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Your data is yours, we will not be using your data for any purpose other than improving your experience.",
                                  style: TextStyle(
                                    color: textColor.withOpacity(
                                      0.5,
                                    ), // DYNAMIC
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Continue Button uses Navigator.push so that OnboardingIntro stays in the background
                          PremiumButton(
                            text: "Continue",
                            onPressed: () {
                              Navigator.push(
                                context,
                                _fadeRoute(const OnboardingData()),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Go Back Button
                          GestureDetector(
                            onTap: _goBack,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: textColor.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Go Back",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
                  ),
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

/// Premium Scale-Interaction Button (Same as Login Page)
class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DYNAMIC THEME VARIABLES
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            // DYNAMIC: Primary button adapts to theme, Secondary is transparent
            color: widget.isSecondary
                ? Colors.transparent
                : (isDark ? Colors.white : Colors.black),
            borderRadius: BorderRadius.circular(50),
            // DYNAMIC: Secondary button border matches the current text color
            border: widget.isSecondary
                ? Border.all(color: textColor.withOpacity(0.2), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  // DYNAMIC: Secondary button text matches theme, primary inverts it
                  color: widget.isSecondary
                      ? textColor
                      : (isDark ? Colors.black : Colors.white),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
