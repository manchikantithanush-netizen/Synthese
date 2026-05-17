import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'onboarding_stage1.dart';
import 'onboarding_stage2.dart';
import 'onboarding_stage3.dart';
import 'onboarding_permissions.dart';

class OnboardingData extends StatefulWidget {
  const OnboardingData({super.key});

  @override
  State<OnboardingData> createState() => _OnboardingDataState();
}

class _OnboardingDataState extends State<OnboardingData> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _errorTimer;

  // Stage 1
  final TextEditingController nameController = TextEditingController();
  DateTime? dob;
  String? gender;
  final List<String> selectedGoals = [];
  bool? isAthlete;

  // Stage 2 — defaults match the dashboard's previous hardcoded targets
  int goalSteps = 10000;
  int goalCaloriesBurnt = 500;
  int goalCaloriesEaten = 2000;
  int goalExerciseMinutes = 60;
  double goalSleepHours = 8.0;

  // Stage 3
  bool hasSupplements = false;
  bool hasDisabilities = false;
  final TextEditingController supplementsDetailsController =
      TextEditingController();
  final TextEditingController disabilityDetailsController =
      TextEditingController();
  final TextEditingController injuryHistoryController =
      TextEditingController();

  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['onboardingCompleted'] == true) {
          if (mounted) {
            final dest = data['privacyPolicyAccepted'] == true
                ? const DashboardPage()
                : const OnboardingPermissions();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => dest),
              (route) => false,
            );
          }
          return;
        }
        // Pre-fill the name field for guest accounts so GUEST#N carries through.
        final existingName = data['fullName'];
        if (existingName is String && existingName.isNotEmpty &&
            nameController.text.isEmpty) {
          nameController.text = existingName;
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _triggerError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMessage = msg);
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _pageController.dispose();
    nameController.dispose();
    supplementsDetailsController.dispose();
    disabilityDetailsController.dispose();
    injuryHistoryController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (nameController.text.trim().isEmpty ||
          dob == null ||
          gender == null ||
          selectedGoals.isEmpty ||
          isAthlete == null) {
        return _triggerError("Please complete all fields");
      }
    }

    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _saveData();
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        // Stage 1
        'fullName': nameController.text.trim(),
        'dob': dob,
        'gender': gender,
        'goals': selectedGoals,
        'isAthlete': isAthlete,
        // Stage 2 — daily goals (replaces hardcoded dashboard targets)
        'goalSteps': goalSteps,
        'goalCaloriesBurnt': goalCaloriesBurnt,
        'goalExerciseMinutes': goalExerciseMinutes,
        'goalSleepHours': goalSleepHours,
        // Eaten-calorie goal — shared with diet_page/notification engine
        'dailyCalorieGoal': goalCaloriesEaten,
        // Stage 3
        'hasSupplements': hasSupplements,
        'supplementsDetails': hasSupplements
            ? supplementsDetailsController.text.trim()
            : null,
        'hasDisabilities': hasDisabilities,
        'disabilityDetails': hasDisabilities
            ? disabilityDetailsController.text.trim()
            : null,
        'injuryHistory': injuryHistoryController.text.trim(),
        'onboardingCompleted': true,
      }, SetOptions(merge: true));

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const OnboardingPermissions()),
          (route) => false,
        );
      }
    } catch (e) {
      _triggerError("Save failed");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDatePicker() async {
    HapticFeedback.selectionClick();
    final maxDate = DateTime(
      DateTime.now().year - 4,
      DateTime.now().month,
      DateTime.now().day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(DateTime.now().year - 18),
      firstDate: DateTime(1940),
      lastDate: maxDate,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    surface: Color(0xFF1C1C1E),
                    onSurface: Colors.white,
                    primary: Color(0xFF007AFF),
                  )
                : const ColorScheme.light(
                    surface: Colors.white,
                    onSurface: Colors.black,
                    primary: Color(0xFF007AFF),
                  ),
            dialogBackgroundColor:
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: BouncingDotsLoader()));
    }

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
                child: Row(
                  children: [
                    UniversalBackButton(
                      onPressed: () {
                        if (_currentStep > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: List.generate(
                          _totalSteps,
                          (i) => Expanded(
                            child: Container(
                              height: 4,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: i <= _currentStep
                                    ? textColor
                                    : textColor.withOpacity(0.15),
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
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    OnboardingStage1(
                      nameController: nameController,
                      dob: dob,
                      onDateTap: _showDatePicker,
                      gender: gender,
                      onGenderSelect: (g) => setState(() => gender = g),
                      selectedGoals: selectedGoals,
                      onGoalToggle: (g) => setState(() {
                        if (selectedGoals.contains(g)) {
                          selectedGoals.remove(g);
                        } else {
                          selectedGoals.add(g);
                        }
                      }),
                      isAthlete: isAthlete,
                      onAthleteSelect: (v) => setState(() => isAthlete = v),
                    ),
                    OnboardingStage2(
                      goalSteps: goalSteps,
                      goalCaloriesBurnt: goalCaloriesBurnt,
                      goalCaloriesEaten: goalCaloriesEaten,
                      goalExerciseMinutes: goalExerciseMinutes,
                      goalSleepHours: goalSleepHours,
                      onStepsChange: (v) => goalSteps = v,
                      onCaloriesBurntChange: (v) => goalCaloriesBurnt = v,
                      onCaloriesEatenChange: (v) => goalCaloriesEaten = v,
                      onExerciseChange: (v) => goalExerciseMinutes = v,
                      onSleepChange: (v) => goalSleepHours = v,
                    ),
                    OnboardingStage3(
                      hasSupplements: hasSupplements,
                      hasDisabilities: hasDisabilities,
                      supplementsController: supplementsDetailsController,
                      disabilityController: disabilityDetailsController,
                      injuryHistoryController: injuryHistoryController,
                      onSupplementToggle: (v) =>
                          setState(() => hasSupplements = v),
                      onDisabilityToggle: (v) =>
                          setState(() => hasDisabilities = v),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: PremiumButton(
                  text: _currentStep == _totalSteps - 1 ? "Finish" : "Continue",
                  isLoading: _isSaving,
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
