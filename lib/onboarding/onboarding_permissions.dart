import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/ui/auth/login_page.dart';
import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/services/first_launch_permissions_service.dart';
import 'package:synthese/services/step_tracker_service.dart';
import 'package:synthese/ui/components/disclaimer_banner.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main stateful widget — owns the PageController and shared state
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingPermissions extends StatefulWidget {
  const OnboardingPermissions({super.key});
  @override
  State<OnboardingPermissions> createState() => _OnboardingPermissionsState();
}

class _OnboardingPermissionsState extends State<OnboardingPermissions> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _agreed = false;
  bool _isSaving = false;
  bool _isFinishing = false;

  // Per-permission loading flags
  bool _loadingNotification = false;
  bool _loadingLocation = false;
  bool _loadingActivity = false;
  bool _loadingCamera = false;
  bool _loadingPhotos = false;

  final _permService = FirstLaunchPermissionsService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _prev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _signOutToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _fadeRoute(const LoginPage()), (_) => false,
    );
  }

  Future<void> _requestThenAdvance(
    Future<void> Function() request,
    void Function(bool) setLoading,
  ) async {
    setLoading(true);
    try { await request(); } catch (_) {}
    if (!mounted) return;
    setLoading(false);
    _next();
  }

  Future<void> _acceptAndContinue() async {
    if (!_agreed) return;
    HapticFeedback.mediumImpact();
    _next();
  }

  Future<void> _finishAndEnter() async {
    setState(() => _isFinishing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'privacyPolicyAccepted': true}, SetOptions(merge: true));
      }
      // Mark all permissions as asked so the old bulk-request doesn't re-fire
      await _permService.markAllAsked();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        _fadeRoute(const DashboardPage()), (_) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    // 1 welcome + 4 permissions (5 on iOS, photos hidden on Android)
    // + privacy + finish
    final totalPages = Platform.isAndroid ? 7 : 8;
    // Back is blocked on the Finish slide only.
    final blockBackFrom = totalPages - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentPage >= blockBackFrom) return;
        if (_currentPage > 0) _prev();
        else await _signOutToLogin();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DefaultTextStyle(
          style: GoogleFonts.plusJakartaSans(),
          child: SafeArea(
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: Row(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: AlignmentDirectional.centerStart,
                      child: (_currentPage > 0 &&
                              _currentPage < blockBackFrom)
                          ? Padding(
                              padding: const EdgeInsetsDirectional.only(end: 16),
                              child: UniversalBackButton(onPressed: _prev),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(
                          totalPages,
                          (i) => Expanded(
                            child: Container(
                              height: 4,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: i <= _currentPage
                                    ? textColor
                                    : textColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    // ── Combined welcome slide ────────────────────────────
                    _SlideWelcome(onContinue: _next),

                    // ── Individual permission slides ──────────────────────
                    _SlidePermissionRequest(
                      imagePath: 'assets/notification.png',
                      title: AppLocalizations.of(context).permNotificationTitle,
                      body: AppLocalizations.of(context).permNotificationBody,
                      allowLabel:
                          AppLocalizations.of(context).permNotificationAllow,
                      isLoading: _loadingNotification,
                      permission: Permission.notification,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestNotification,
                        (v) => setState(() => _loadingNotification = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/gps.png',
                      title: AppLocalizations.of(context).permLocationTitle,
                      body: AppLocalizations.of(context).permLocationBody,
                      allowLabel:
                          AppLocalizations.of(context).permLocationAllow,
                      isLoading: _loadingLocation,
                      permission: Permission.location,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestLocation,
                        (v) => setState(() => _loadingLocation = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/step.png',
                      title: AppLocalizations.of(context).permActivityTitle,
                      body: AppLocalizations.of(context).permActivityBody,
                      allowLabel:
                          AppLocalizations.of(context).permActivityAllow,
                      isLoading: _loadingActivity,
                      permission: Permission.activityRecognition,
                      onAllow: () => _requestThenAdvance(
                        // Route through StepTracker so the pedometer stream is
                        // restarted right after the user grants the permission
                        // (a stream subscribed at app start without permission
                        // never emits, so we need to re-subscribe).
                        // If the user denies the OS dialog, disable background
                        // tracking so the green dot doesn't light up falsely.
                        () async {
                          final granted =
                              await StepTracker.instance.requestPermission();
                          if (!granted) {
                            await StepTracker.instance
                                .setBackgroundEnabled(false);
                          }
                        },
                        (v) => setState(() => _loadingActivity = v),
                      ),
                      onSkip: () async {
                        // User explicitly skipped — disable background step
                        // tracking so the green dot and foreground service don't
                        // activate without permission. The user can enable it
                        // later from Settings once they grant the permission.
                        await StepTracker.instance.setBackgroundEnabled(false);
                        _next();
                      },
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/camera.png',
                      title: AppLocalizations.of(context).permCameraTitle,
                      body: AppLocalizations.of(context).permCameraBody,
                      allowLabel:
                          AppLocalizations.of(context).permCameraAllow,
                      isLoading: _loadingCamera,
                      permission: Permission.camera,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestCamera,
                        (v) => setState(() => _loadingCamera = v),
                      ),
                      onSkip: _next,
                    ),
                    // Photos slide — only shown on iOS where the Photos
                    // permission is meaningful. On Android we use the system
                    // Photo Picker which needs zero permissions, so showing
                    // this slide would be misleading (the Allow button would
                    // show a spinner but never open an OS dialog).
                    if (!Platform.isAndroid)
                      _SlidePermissionRequest(
                        imagePath: 'assets/camera.png',
                        title: AppLocalizations.of(context).permPhotosTitle,
                        body: AppLocalizations.of(context).permPhotosBody,
                        allowLabel:
                            AppLocalizations.of(context).permPhotosAllow,
                        isLoading: _loadingPhotos,
                        permission: Permission.photos,
                        onAllow: () => _requestThenAdvance(
                          _permService.requestPhotos,
                          (v) => setState(() => _loadingPhotos = v),
                        ),
                        onSkip: _next,
                      ),

                    // ── Privacy & finish ──────────────────────────────────
                    _SlidePrivacyPolicy(
                      agreed: _agreed,
                      isSaving: _isSaving,
                      onAgreedChanged: (v) => setState(() => _agreed = v),
                      onAccept: _acceptAndContinue,
                      onDecline: _signOutToLogin,
                    ),
                    _SlideFinish(
                      onFinish: _finishAndEnter,
                      isLoading: _isFinishing,
                    ),
                  ],
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

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 1 — Combined welcome (replaces the old Intro / App Overview / What
// to Expect trio with a single, scannable card so users don't tap through
// three near-identical screens before reaching the permission flow).
// ─────────────────────────────────────────────────────────────────────────────
class _SlideWelcome extends StatelessWidget {
  final VoidCallback onContinue;
  const _SlideWelcome({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            t.permWelcomeTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.permWelcomeBody,
            style: TextStyle(
              color: textColor.withOpacity(0.55),
              fontSize: 16,
              height: 1.45,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: textColor.withOpacity(0.07)),
            ),
            child: Column(
              children: [
                _DimensionRow(
                  icon: Icons.home_rounded,
                  title: t.permWelcomeDimHome,
                  desc: t.permWelcomeDimHomeDesc,
                  textColor: textColor,
                  isLast: false,
                ),
                _DimensionRow(
                  icon: Icons.restaurant_menu_rounded,
                  title: t.permWelcomeDimDiet,
                  desc: t.permWelcomeDimDietDesc,
                  textColor: textColor,
                  isLast: false,
                ),
                _DimensionRow(
                  icon: Icons.directions_run_rounded,
                  title: t.permWelcomeDimWorkout,
                  desc: t.permWelcomeDimWorkoutDesc,
                  textColor: textColor,
                  isLast: false,
                ),
                _DimensionRow(
                  icon: Icons.self_improvement_rounded,
                  title: t.permWelcomeDimMindfulness,
                  desc: t.permWelcomeDimMindfulnessDesc,
                  textColor: textColor,
                  isLast: false,
                ),
                _DimensionRow(
                  icon: Icons.favorite_rounded,
                  title: t.permWelcomeDimCycles,
                  desc: t.permWelcomeDimCyclesDesc,
                  textColor: textColor,
                  isLast: false,
                ),
                _DimensionRow(
                  icon: Icons.account_balance_wallet_rounded,
                  title: t.permWelcomeDimFinance,
                  desc: t.permWelcomeDimFinanceDesc,
                  textColor: textColor,
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _TrustChip(
                  icon: Icons.block_outlined,
                  label: t.permTrustNoAds,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrustChip(
                  icon: Icons.gavel_rounded,
                  label: t.permTrustPdpl,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrustChip(
                  icon: Icons.lock_outline_rounded,
                  label: t.permTrustYourData,
                  textColor: textColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),
          PremiumButton(text: t.commonLetsGo, onPressed: onContinue),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color textColor;
  final bool isLast;
  const _DimensionRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.textColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: textColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      desc,
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 18,
            endIndent: 18,
            color: textColor.withOpacity(0.07),
          ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final bool isDark;
  const _TrustChip({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDES — Individual permission request slides
// ─────────────────────────────────────────────────────────────────────────────
class _SlidePermissionRequest extends StatefulWidget {
  final String imagePath;
  final String title;
  final String body;
  final String allowLabel;
  final bool isLoading;
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  /// The permission to check for the status indicator. Null = no indicator
  /// (used for the Photos slide on iOS where we don't need one).
  final Permission? permission;

  const _SlidePermissionRequest({
    required this.imagePath,
    required this.title,
    required this.body,
    required this.allowLabel,
    required this.isLoading,
    required this.onAllow,
    required this.onSkip,
    this.permission,
  });

  @override
  State<_SlidePermissionRequest> createState() =>
      _SlidePermissionRequestState();
}

class _SlidePermissionRequestState extends State<_SlidePermissionRequest> {
  // null = still loading, true = granted, false = denied/restricted
  bool? _isGranted;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final p = widget.permission;
    if (p == null) return;
    final status = await p.status;
    if (mounted) {
      setState(() => _isGranted = status.isGranted);
    }
  }

  /// Re-check after the Allow flow completes so the badge updates immediately.
  Future<void> _refreshAfterAllow() async {
    // Call the parent's allow handler (requests the OS permission + advances).
    widget.onAllow();
    // After the OS dialog resolves and before the page transitions away,
    // re-query the permission so the badge animates to green if granted.
    // The mounted guard ensures this is a no-op if the slide was already
    // paged away.
    await Future.delayed(const Duration(milliseconds: 400));
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.55);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final imgHeight = (constraints.maxHeight * 0.30).clamp(120.0, 200.0);
      return Column(
        children: [
          // Image — contained, no crop, with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
            child: Image.asset(
              widget.imagePath,
              height: imgHeight,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.2)),
                  const SizedBox(height: 12),
                  Text(widget.body,
                      style: TextStyle(
                          color: subColor,
                          fontSize: 15,
                          height: 1.55,
                          letterSpacing: -0.1)),

                  // ── Permission status indicator ──────────────────────
                  if (widget.permission != null) ...[
                    const SizedBox(height: 24),
                    _PermissionStatusBadge(
                      isGranted: _isGranted,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
            child: _InlineLoadingButton(
              text: widget.allowLabel,
              isLoading: widget.isLoading,
              onPressed: _refreshAfterAllow,
            ),
          ),
          TextButton(
            onPressed: widget.isLoading ? null : widget.onSkip,
            child: Text(AppLocalizations.of(context).commonSkipForNow,
                style: TextStyle(
                    color: textColor.withOpacity(0.35),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission status badge — shown in the blank space below the body text
// ─────────────────────────────────────────────────────────────────────────────
class _PermissionStatusBadge extends StatelessWidget {
  final bool? isGranted; // null = loading
  final bool isDark;
  final Color textColor;

  const _PermissionStatusBadge({
    required this.isGranted,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // While still checking, show a neutral loading pill.
    if (isGranted == null) {
      return _Pill(
        icon: Icons.hourglass_empty_rounded,
        label: 'Checking…',
        iconColor: textColor.withOpacity(0.4),
        bgColor: textColor.withOpacity(0.06),
        textColor: textColor.withOpacity(0.45),
      );
    }

    if (isGranted == true) {
      return _Pill(
        icon: Icons.check_circle_rounded,
        label: 'Permission enabled',
        iconColor: const Color(0xFF34C759),
        bgColor: const Color(0xFF34C759).withOpacity(isDark ? 0.15 : 0.10),
        textColor: const Color(0xFF34C759),
      );
    }

    return _Pill(
      icon: Icons.radio_button_unchecked_rounded,
      label: 'Not enabled yet',
      iconColor: textColor.withOpacity(0.35),
      bgColor: textColor.withOpacity(0.06),
      textColor: textColor.withOpacity(0.45),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor, bgColor, textColor;

  const _Pill({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 10 — Privacy Policy
// ─────────────────────────────────────────────────────────────────────────────
class _SlidePrivacyPolicy extends StatelessWidget {
  final bool agreed;
  final bool isSaving;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _SlidePrivacyPolicy({
    required this.agreed, required this.isSaving,
    required this.onAgreedChanged, required this.onAccept, required this.onDecline,
  });

  static const _privacyUrl =
      'https://sites.google.com/view/synthese-workout-health/home';

  Future<void> _openPolicy() async {
    final uri = Uri.parse(_privacyUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    final subColor = textColor.withOpacity(0.55);
    final t = AppLocalizations.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            t.permPrivacyTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.permPrivacyBody,
            style: TextStyle(color: subColor, fontSize: 15, height: 1.4),
          ),

          const SizedBox(height: 28),

          // Big privacy policy button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _openPolicy();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textColor.withOpacity(0.10), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.policy_rounded,
                      color: Color(0xFF007AFF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.permPrivacyTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.permPrivacyReadLabel,
                          style: TextStyle(
                            color: const Color(0xFF007AFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Checkbox agree row
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onAgreedChanged(!agreed);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: agreed
                    ? (isDark ? const Color(0xFF1C3A2A) : const Color(0xFFE8F5E9))
                    : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: agreed
                      ? const Color(0xFF4CD964)
                      : textColor.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: agreed ? const Color(0xFF4CD964) : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: agreed
                            ? const Color(0xFF4CD964)
                            : textColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: agreed
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t.permPrivacyAgreeCheckbox,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Accept / Decline buttons
          _AgreeButton(
            agreed: agreed,
            isSaving: isSaving,
            onAccept: onAccept,
          ),
          const SizedBox(height: 10),
          _DeclineButton(onPressed: onDecline, isSaving: isSaving),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 6 — Finish
// ─────────────────────────────────────────────────────────────────────────────
class _SlideFinish extends StatefulWidget {
  final VoidCallback onFinish;
  final bool isLoading;
  const _SlideFinish({required this.onFinish, required this.isLoading});
  @override
  State<_SlideFinish> createState() => _SlideFinishState();
}

class _SlideFinishState extends State<_SlideFinish>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutBack);
    // Slight delay so the slide transition finishes first
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final t = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Scale down on small screens
        final checkSize = h < 600 ? 80.0 : 120.0;
        final iconSize = h < 600 ? 42.0 : 64.0;
        final titleSize = h < 600 ? 24.0 : 32.0;
        final subtitleSize = h < 600 ? 13.0 : 16.0;
        final vGapLarge = h < 600 ? 16.0 : 36.0;
        final vGapSmall = h < 600 ? 10.0 : 16.0;
        final topSpace = h < 600 ? 16.0 : 32.0;
        final bottomSpace = h < 600 ? 16.0 : 36.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: topSpace),
              // Animated checkmark
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: checkSize,
                  height: checkSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CD964).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: const Color(0xFF4CD964),
                    size: iconSize,
                  ),
                ),
              ),
              SizedBox(height: vGapLarge),
              Text(
                t.permFinishTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                  height: 1.2,
                ),
              ),
              SizedBox(height: vGapSmall),
              Text(
                t.permFinishBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.55),
                  fontSize: subtitleSize,
                  height: 1.55,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: vGapLarge),
              // Checklist
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withOpacity(0.07)),
                ),
                child: Column(children: [
                  _CheckItem(label: t.permFinishCheck1, textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: t.permFinishCheck2, textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: t.permFinishCheck3, textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: t.permFinishCheck4, textColor: textColor),
                ]),
              ),
              SizedBox(height: vGapLarge),
              // ── Disclaimer ────────────────────────────────────────────
              const DisclaimerBanner.general(),
              SizedBox(height: vGapSmall),
              _InlineLoadingButton(
                text: t.commonLetsGo,
                isLoading: widget.isLoading,
                onPressed: widget.onFinish,
              ),
              const SizedBox(height: 12),
              Text(
                t.permFinishFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.35),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              SizedBox(height: bottomSpace),
            ],
          ),
        );
      },
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final Color textColor;
  const _CheckItem({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF4CD964).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Color(0xFF4CD964), size: 14),
      ),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Agree button (primary, dims when unchecked)
// ─────────────────────────────────────────────────────────────────────────────
class _AgreeButton extends StatefulWidget {
  final bool agreed, isSaving;
  final VoidCallback onAccept;
  const _AgreeButton({required this.agreed, required this.isSaving, required this.onAccept});
  @override
  State<_AgreeButton> createState() => _AgreeButtonState();
}

class _AgreeButtonState extends State<_AgreeButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.agreed && !widget.isSaving;
    return GestureDetector(
      onTapDown: enabled ? (_) { HapticFeedback.lightImpact(); _ctrl.forward(); } : null,
      onTapUp: enabled ? (_) => _ctrl.reverse() : null,
      onTapCancel: enabled ? () => _ctrl.reverse() : null,
      onTap: enabled ? widget.onAccept : () { if (!widget.agreed) HapticFeedback.heavyImpact(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.agreed ? 1.0 : 0.4,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(child: widget.isSaving
                ? BouncingDotsLoader.compact(color: isDark ? Colors.black : Colors.white)
                : Text(AppLocalizations.of(context).permPrivacyAgree,
                    style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decline button (red outline)
// ─────────────────────────────────────────────────────────────────────────────
class _DeclineButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSaving;
  const _DeclineButton({required this.onPressed, this.isSaving = false});
  @override
  State<_DeclineButton> createState() => _DeclineButtonState();
}

class _DeclineButtonState extends State<_DeclineButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
          ),
          child: Center(child: widget.isSaving
              ? const BouncingDotsLoader.compact(color: Colors.redAccent)
              : Text(AppLocalizations.of(context).permPrivacyDecline,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline loading button (for permissions slide)
// ─────────────────────────────────────────────────────────────────────────────
class _InlineLoadingButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  const _InlineLoadingButton({required this.text, required this.isLoading, required this.onPressed});
  @override
  State<_InlineLoadingButton> createState() => _InlineLoadingButtonState();
}

class _InlineLoadingButtonState extends State<_InlineLoadingButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
      onTapUp: widget.isLoading ? null : (_) => _ctrl.reverse(),
      onTapCancel: widget.isLoading ? null : () => _ctrl.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(child: widget.isLoading
              ? BouncingDotsLoader.compact(color: isDark ? Colors.black : Colors.white)
              : Text(widget.text,
                  style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy content
// ─────────────────────────────────────────────────────────────────────────────
class _PolicyContent extends StatelessWidget {
  final Color textColor, subColor;
  const _PolicyContent({required this.textColor, required this.subColor});

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(body, style: TextStyle(color: subColor, fontSize: 13, height: 1.6)),
    ]),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 5, start: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("• ", style: TextStyle(color: subColor, fontSize: 13)),
      Expanded(child: Text(text, style: TextStyle(color: subColor, fontSize: 13, height: 1.5))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Synthese: Workout & Health",
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text("Effective Date: April 21, 2026  ·  Jurisdiction: UAE",
          style: TextStyle(color: subColor, fontSize: 12)),
      const SizedBox(height: 20),
      _section("1. Introduction",
          "Welcome to Synthese: Workout & Health. We are committed to protecting your personal information in compliance with UAE Federal Decree-Law No. 45 of 2021 (PDPL). By using Synthese, you agree to this Privacy Policy."),
      _section("2. Data Controller",
          "Synthese is developed and operated from the UAE. We are the sole data controller. We do not share, sell, or transfer your data to any third-party businesses, marketing partners, or affiliates."),
      _section("3. Who This Policy Applies To",
          "This App is for users aged 18 and older. By using Synthese, you confirm that you are at least 18 years of age. Users under 18 are not permitted to create an account or use the App."),
      Text("4. Data We Collect", style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text("Personal Information", style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _bullet("Name, username, or display name"),
      _bullet("Email address and account credentials"),
      _bullet("Date of birth and age"),
      _bullet("Gender (optional)"),
      const SizedBox(height: 10),
      Text("Health & Biometric Data", style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _bullet("Workout and exercise activity logs"),
      _bullet("Physical metrics: height, weight, body measurements"),
      _bullet("Biometric indicators: heart rate, calorie data"),
      _bullet("Fitness goals and progress tracking data"),
      _bullet("Medical or clinical health information you voluntarily enter"),
      const SizedBox(height: 10),
      Text("Device Permissions", style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _bullet("Camera: Used for AI calorie analysis and progress photos."),
      _bullet("Photos / Media: To save and retrieve workout data and health records."),
      _bullet("Location: Used during workout tracking sessions only."),
      _bullet("Activity Recognition: To count steps and detect physical activity."),
      _bullet("Notifications: Service-related alerts only — not marketing."),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text("You may revoke any permission through your device settings at any time.",
            style: TextStyle(color: subColor, fontSize: 13, height: 1.5)),
      ),
      _section("5. How We Use Your Data",
          "We use your data exclusively to provide and improve Synthese — account management, personalised health insights, technical diagnostics, and UAE law compliance. We do not use your data for advertising or commercial profiling."),
      _section("6. Data Storage & Security",
          "Your data is stored on secure cloud servers with TLS/SSL encryption in transit and at rest, access controls, regular security audits, and secure deletion protocols."),
      _section("7. Data Sharing & Third Parties",
          "We do not sell, rent, or share your personal or health data with any third parties under any circumstances. Data may only be disclosed to comply with a lawful request from UAE government authorities."),
      Text("8. Your Rights Under UAE PDPL", style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      _bullet("Right to Access: Request a copy of the data we hold about you"),
      _bullet("Right to Rectification: Request correction of inaccurate data"),
      _bullet("Right to Erasure: Request deletion of your personal data"),
      _bullet("Right to Restriction: Limit how we process your data"),
      _bullet("Right to Data Portability: Receive your data in a machine-readable format"),
      _bullet("Right to Withdraw Consent: Withdraw consent at any time"),
      _bullet("Right to Object: Object to processing of your sensitive health data"),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text("Contact us through the App to exercise any right. We respond within 30 days.",
            style: TextStyle(color: subColor, fontSize: 13, height: 1.5)),
      ),
      _section("9. Data Retention",
          "We retain your data only as long as necessary. Deleting your account in the app removes your data immediately; requests made by email are completed within 30 days."),
      _section("10. Minors",
          "Synthese is strictly for users aged 18 and older. Users under 18 are not permitted to use this App. The onboarding flow enforces a minimum age of 18 at the point of account setup. If we become aware that a user under 18 has created an account, we will delete their data and terminate their account without notice."),
      _section("11. Changes to This Policy",
          "We may update this policy periodically and will notify you of material changes through the App or via email."),
      _section("12. Governing Law",
          "This Privacy Policy is governed by the laws of the United Arab Emirates. Last updated: April 21, 2026."),
    ]);
  }
}

