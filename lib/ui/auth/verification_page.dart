import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'login_page.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isResending = false;
  bool _isVerified = false;

  // Inline Notification State
  String? _errorMessage;
  Timer? _errorTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Send the email automatically when the page loads
    _sendInitialVerificationEmail();
    _startChecking();
  }

  // --- NEW: Send initial email function ---
  Future<void> _sendInitialVerificationEmail() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      // We fail silently here because if Firebase rate-limits the requests 
      // (e.g., they just signed up and an email was already triggered), 
      // we don't want to spam the user with error messages immediately.
      debugPrint("Initial verification email error: $e");
    }
  }

  void _startChecking() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload(); 

      if (user != null && user.emailVerified) {
        timer.cancel();
        
        // Premium two-beat success haptic
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });

        if (mounted) {
          setState(() {
            _isVerified = true;
          });
        }
        
        await Future.delayed(const Duration(seconds: 2));
        await FirebaseAuth.instance.signOut(); 
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            _fadeRoute(const LoginPage()),
          );
        }
      }
    });
  }

  // --- Inline Notification System ---
  void _triggerNotification(String message, {bool isError = true}) {
    if (isError) HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = message;
    });

    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _triggerNotification('Verification email resent!', isError: false);
    } catch (e) {
      _triggerNotification('Wait a moment before resending.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
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

  Widget _buildWaitingView() {
    // DYNAMIC TEXT COLOR
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      key: const ValueKey('WaitingView'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
          Center(
            child: Icon(
              Icons.mark_email_unread_outlined,
              color: textColor, // DYNAMIC
              size: 64,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Verify your email',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor, // DYNAMIC
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
            ),
          ),

          // --- INLINE NOTIFICATION AREA ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _errorMessage!.contains('resent') 
                            ? const Color(0xFF4CD964) 
                            : const Color(0xFFFF3B30),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox(height: 20),
          ),

          const SizedBox(height: 12),
          
          Text(
            'We sent a verification link to your email.\nPlease click it to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.54), // DYNAMIC
              fontSize: 16,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 48),

          FadeTransition(
            opacity: _pulseAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                SizedBox(
                  width: 44,
                  height: 22,
                  child: BouncingDotsLoader.compact(
                    color: textColor.withOpacity(0.54),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Checking for verification...',
                  style: TextStyle(
                    color: textColor.withOpacity(0.54), // DYNAMIC
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),

          // --- PREMIUM RESEND BUTTON (No Ripple) ---
          _isResending
              ? const Center(child: BouncingDotsLoader())
              : _PremiumButton(
                  text: 'Resend Email',
                  isSecondary: true,
                  onPressed: _resendEmail,
                ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    // DYNAMIC TEXT COLOR
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      key: const ValueKey('SuccessView'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 110),
          ),
          const SizedBox(height: 24),
          Text(
            'Verified!',
            style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1.0), // DYNAMIC
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REMOVED: backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isVerified ? _buildSuccessView() : _buildWaitingView(),
        ),
      ),
    );
  }
}

/// Premium Scale-Interaction Button (No Ripple)
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

class _PremiumButtonState extends State<_PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Needed to know the current mode to adjust outline/background colors properly
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          height: 56,
          decoration: BoxDecoration(
            // DYNAMIC: Secondary button is transparent, primary button inverts based on mode
            color: widget.isSecondary 
                ? Colors.transparent 
                : (isDark ? Colors.white : Colors.black),
            borderRadius: BorderRadius.circular(50),
            // DYNAMIC: Lighter border for light mode, dark border for dark mode
            border: widget.isSecondary 
                ? Border.all(
                    color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300, 
                    width: 1.5
                  ) 
                : null,
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                // DYNAMIC: Inverts text color based on button type and active theme
                color: widget.isSecondary 
                    ? (isDark ? Colors.white : Colors.black) 
                    : (isDark ? Colors.black : Colors.white),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}