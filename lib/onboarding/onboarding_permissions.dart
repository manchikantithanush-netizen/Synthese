import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synthese/ui/auth/login_page.dart';
import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/services/first_launch_permissions_service.dart';

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
  bool _loadingHealth = false;

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
    // 3 intro + 6 permission + privacy + finish = 11
    const totalPages = 11;
    // Back is blocked on the last 2 slides (privacy agreed, finish)
    const blockBackFrom = 9;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentPage >= blockBackFrom) return;
        if (_currentPage > 0) _prev();
        else await _signOutToLogin();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Row(
                  children: List.generate(totalPages, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? textColor
                            : textColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    // ── Intro slides ──────────────────────────────────────
                    _SlideIntro(onContinue: _next),
                    _SlideAppOverview(onContinue: _next),
                    _SlideWhatToExpect(onContinue: _next),

                    // ── Individual permission slides ──────────────────────
                    _SlidePermissionRequest(
                      imagePath: 'assets/notification.png',
                      title: 'Stay in the loop',
                      body: 'Synthese sends you workout reminders, hydration nudges, and important health alerts. We never send marketing or spam — only things that help you stay on track.',
                      allowLabel: 'Allow Notifications',
                      isLoading: _loadingNotification,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestNotification,
                        (v) => setState(() => _loadingNotification = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/gps.png',
                      title: 'Track your route',
                      body: 'Location access (coarse + fine) is used only during active workout sessions to map your run, cycle, or walk. Background location keeps your session running even when the screen is off — no interruptions mid-workout.',
                      allowLabel: 'Allow Location',
                      isLoading: _loadingLocation,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestLocation,
                        (v) => setState(() => _loadingLocation = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/step.png',
                      title: 'Count every step',
                      body: 'Activity Recognition lets Synthese detect your movement and automatically count your steps throughout the day — no manual logging needed.',
                      allowLabel: 'Allow Activity Recognition',
                      isLoading: _loadingActivity,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestActivityRecognition,
                        (v) => setState(() => _loadingActivity = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/camera.png',
                      title: 'AI calorie analysis',
                      body: 'Camera access powers the AI food analyser — snap a photo of your meal and Synthese instantly estimates calories, protein, carbs, and fats. Camera is only activated when you choose to use this feature.',
                      allowLabel: 'Allow Camera',
                      isLoading: _loadingCamera,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestCamera,
                        (v) => setState(() => _loadingCamera = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlidePermissionRequest(
                      imagePath: 'assets/camera.png',
                      title: 'Photos & media',
                      body: 'Photo library access lets you upload a profile picture and pick meal images for AI analysis. We only read images you explicitly select — we never scan your gallery.',
                      allowLabel: 'Allow Photos & Media',
                      isLoading: _loadingPhotos,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestPhotos,
                        (v) => setState(() => _loadingPhotos = v),
                      ),
                      onSkip: _next,
                    ),
                    _SlideHealthConnect(
                      isLoading: _loadingHealth,
                      onAllow: () => _requestThenAdvance(
                        _permService.requestHealthConnect,
                        (v) => setState(() => _loadingHealth = v),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 1 — Intro
// ─────────────────────────────────────────────────────────────────────────────
class _SlideIntro extends StatelessWidget {
  final VoidCallback onContinue;
  const _SlideIntro({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text("Before you begin,",
              style: TextStyle(color: textColor, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.2)),
          const SizedBox(height: 12),
          Text("We want to be fully transparent about how we use your data and what permissions we need.",
              style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 18, height: 1.5, letterSpacing: -0.3)),
          const SizedBox(height: 40),
          _Card(icon: Icons.lock_outline_rounded, title: "Your data stays yours",
              body: "We never sell, share, or use your data for advertising. Everything is used solely to power your experience.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 14),
          _Card(icon: Icons.health_and_safety_outlined, title: "Health & fitness permissions",
              body: "We request access to Health Connect, location, activity recognition, camera, and notifications — only to deliver the features you use.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 14),
          _Card(icon: Icons.gavel_rounded, title: "UAE PDPL compliant",
              body: "Synthese operates under UAE Federal Decree-Law No. 45 of 2021 on the Protection of Personal Data.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 48),
          PremiumButton(text: "Let's go", onPressed: onContinue),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 2 — App Overview
// ─────────────────────────────────────────────────────────────────────────────
class _SlideAppOverview extends StatelessWidget {
  final VoidCallback onContinue;
  const _SlideAppOverview({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text("One app,\nsix dimensions.",
              style: TextStyle(color: textColor, fontSize: 38, fontWeight: FontWeight.w700,
                  letterSpacing: -1.2, height: 1.15)),
          const SizedBox(height: 14),
          Text("Synthese brings together every part of your wellbeing — physical, mental, and financial — in one place.",
              style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 17, height: 1.5, letterSpacing: -0.2)),
          const SizedBox(height: 36),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: textColor.withOpacity(0.07)),
            ),
            child: Column(children: [
              _SectionRow(icon: Icons.home_rounded, title: "Home", desc: "Your daily metrics at a glance — steps, heart rate, calories, sleep, and more.", textColor: textColor, isLast: false),
              _SectionRow(icon: Icons.restaurant_menu_rounded, title: "Diet", desc: "AI-powered nutrition tracking, water intake, and personalised macro goals.", textColor: textColor, isLast: false),
              _SectionRow(icon: Icons.directions_run_rounded, title: "Workout", desc: "GPS-tracked sessions across running, cycling, swimming, and more.", textColor: textColor, isLast: false),
              _SectionRow(icon: Icons.self_improvement_rounded, title: "Mindfulness", desc: "Mood check-ins, breathing exercises, and mental health assessments.", textColor: textColor, isLast: false),
              _SectionRow(icon: Icons.favorite_rounded, title: "Cycles", desc: "Cycle tracking and symptom logging — available for female users.", textColor: textColor, isLast: false),
              _SectionRow(icon: Icons.account_balance_wallet_rounded, title: "Finance", desc: "Expense tracking, budgeting, and debt management in one view.", textColor: textColor, isLast: true),
            ]),
          ),
          const SizedBox(height: 36),
          PremiumButton(text: "Got it", onPressed: onContinue),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color textColor;
  final bool isLast;
  const _SectionRow({required this.icon, required this.title, required this.desc, required this.textColor, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(desc, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13, height: 1.45)),
          ])),
        ]),
      ),
      if (!isLast) Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20, color: textColor.withOpacity(0.07)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDE 3 — What to expect
// ─────────────────────────────────────────────────────────────────────────────
class _SlideWhatToExpect extends StatelessWidget {
  final VoidCallback onContinue;
  const _SlideWhatToExpect({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text("What to expect.",
              style: TextStyle(color: textColor, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1.2)),
          const SizedBox(height: 14),
          Text("A few things worth knowing before you dive in.",
              style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 17, height: 1.5, letterSpacing: -0.2)),
          const SizedBox(height: 32),
          _Card(icon: Icons.sync_rounded, title: "Your data, always in sync",
              body: "Connect Health Connect or grant health permissions to automatically pull your steps, heart rate, sleep, and calories into the Home dashboard.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 14),
          _Card(icon: Icons.tune_rounded, title: "Personalised from day one",
              body: "The data you entered during setup shapes your nutrition targets, workout suggestions, and health insights. Update it anytime from Account Details.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 14),
          _Card(icon: Icons.location_on_outlined, title: "Permissions are feature-gated",
              body: "Location is only used during active workout sessions. Camera is only used when you choose to upload a photo. You stay in control.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 14),
          _Card(icon: Icons.block_outlined, title: "No ads, ever",
              body: "Synthese does not show ads, sell your data, or share it with third parties. Your health information is yours alone.",
              isDark: isDark, textColor: textColor),
          const SizedBox(height: 36),
          PremiumButton(text: "Continue", onPressed: onContinue),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDES 4–9 — Individual permission request slides
// ─────────────────────────────────────────────────────────────────────────────
class _SlidePermissionRequest extends StatelessWidget {
  final String imagePath;
  final String title;
  final String body;
  final String allowLabel;
  final bool isLoading;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _SlidePermissionRequest({
    required this.imagePath,
    required this.title,
    required this.body,
    required this.allowLabel,
    required this.isLoading,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.55);

    return LayoutBuilder(builder: (context, constraints) {
      final imgHeight = (constraints.maxHeight * 0.30).clamp(120.0, 200.0);
      return Column(
        children: [
          // Image — contained, no crop, with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
            child: Image.asset(
              imagePath,
              height: imgHeight,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.2)),
                  const SizedBox(height: 12),
                  Text(body,
                      style: TextStyle(
                          color: subColor,
                          fontSize: 15,
                          height: 1.55,
                          letterSpacing: -0.1)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
            child: _InlineLoadingButton(
              text: allowLabel,
              isLoading: isLoading,
              onPressed: onAllow,
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onSkip,
            child: Text('Skip for now',
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

// Health Connect slide — uses dashboard-style metric icons instead of a photo
class _SlideHealthConnect extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _SlideHealthConnect({
    required this.isLoading,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.55);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100;

    final metrics = [
      (Icons.directions_walk_rounded, 'Steps', 'Daily step count'),
      (Icons.favorite_rounded, 'Heart Rate', 'BPM throughout the day'),
      (Icons.bedtime_rounded, 'Sleep', 'Duration & quality'),
      (Icons.local_fire_department_rounded, 'Active Calories', 'Calories burned'),
      (Icons.fitness_center_rounded, 'Exercise', 'Workout sessions'),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Watch icon header
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.watch_rounded,
                      size: 36, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 20),
                Text('Connect your wearable',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.2)),
                const SizedBox(height: 12),
                Text('Health Connect syncs data from your Samsung Galaxy Watch or any Android wearable — so your dashboard stays up to date automatically.',
                    style: TextStyle(color: subColor, fontSize: 15, height: 1.55)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: textColor.withOpacity(0.07)),
                  ),
                  child: Column(
                    children: metrics.asMap().entries.map((e) {
                      final isLast = e.key == metrics.length - 1;
                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(e.value.$1, color: textColor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.value.$2,
                                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(e.value.$3,
                                  style: TextStyle(color: subColor, fontSize: 13)),
                            ]),
                          ]),
                        ),
                        if (!isLast) Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20, color: textColor.withOpacity(0.07)),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
          child: _InlineLoadingButton(
            text: 'Connect Health Connect',
            isLoading: isLoading,
            onPressed: onAllow,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : onSkip,
          child: Text('Skip for now',
              style: TextStyle(
                  color: textColor.withOpacity(0.35),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 16),
      ],
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100;
    final subColor = textColor.withOpacity(0.55);

    return Column(children: [
      const SizedBox(height: 28),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Privacy Policy",
              style: TextStyle(color: textColor, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -1.0)),
          const SizedBox(height: 6),
          Text("Please read and agree to continue using Synthese.",
              style: TextStyle(color: subColor, fontSize: 15, height: 1.4)),
        ]),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: textColor.withOpacity(0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: _PolicyContent(textColor: textColor, subColor: subColor),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      // Checkbox
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onAgreedChanged(!agreed); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: agreed
                  ? (isDark ? const Color(0xFF1C3A2A) : const Color(0xFFE8F5E9))
                  : cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: agreed ? const Color(0xFF4CD964) : textColor.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: agreed ? const Color(0xFF4CD964) : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: agreed ? const Color(0xFF4CD964) : textColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: agreed ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Text("I have read and agree to the Privacy Policy",
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500))),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
        child: Column(children: [
          _AgreeButton(agreed: agreed, isSaving: isSaving, onAccept: onAccept),
          const SizedBox(height: 10),
          _DeclineButton(onPressed: onDecline, isSaving: isSaving),
        ]),
      ),
      const SizedBox(height: 32),
    ]);
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
                "Thank you for\ntrusting Synthese.",
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
                "You're all set. We hope Synthese helps you build a healthier, more balanced life.",
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
                  _CheckItem(label: "Privacy Policy agreed", textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: "Permissions configured", textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: "Account created & verified", textColor: textColor),
                  const SizedBox(height: 12),
                  _CheckItem(label: "Profile set up", textColor: textColor),
                ]),
              ),
              SizedBox(height: vGapLarge),
              _InlineLoadingButton(
                text: "Let's go",
                isLoading: widget.isLoading,
                onPressed: widget.onFinish,
              ),
              const SizedBox(height: 12),
              Text(
                "You can review your permissions and privacy settings anytime in the Settings page.",
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
// Shared card widget
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final bool isDark;
  final Color textColor;
  const _Card({required this.icon, required this.title, required this.body, required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.08)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: textColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: textColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
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
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                : Text("I Agree",
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
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
              : const Text("I Do Not Agree",
                  style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600))),
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
              ? SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
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
    padding: const EdgeInsets.only(bottom: 5, left: 4),
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
          "This App is for users aged 13 and older. Users aged 13–17 require parental or guardian consent before using the App."),
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
      _bullet("Health Connect (Android): Read-only access to steps, heart rate, sleep, calories, and exercise."),
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
          "We retain your data only as long as necessary. Upon account deletion, your data is deleted or anonymised within 90 days."),
      _section("10. Minors",
          "Users under 13 are not permitted. Users aged 13–17 may only use the App with verified parental or guardian consent."),
      _section("11. Changes to This Policy",
          "We may update this policy periodically and will notify you of material changes through the App or via email."),
      _section("12. Governing Law",
          "This Privacy Policy is governed by the laws of the United Arab Emirates. Last updated: April 21, 2026."),
    ]);
  }
}
