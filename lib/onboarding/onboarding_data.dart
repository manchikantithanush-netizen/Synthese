import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'dart:async';

import 'package:synthese/ui/dashboard.dart'; 
import 'package:synthese/ui/components/premium_button.dart';
import 'onboarding_personal.dart';
import 'onboarding_physical.dart';
import 'onboarding_athlete.dart';
import 'onboarding_sports.dart';
import 'onboarding_training.dart'; 
import 'onboarding_lifestyle.dart'; 
// NOTE: onboarding_female.dart has been removed!

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

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController timeZoneController = TextEditingController();
  
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bodyFatController = TextEditingController();
  final TextEditingController waistCircumferenceController = TextEditingController();
  final TextEditingController supplementsDetailsController = TextEditingController();
  final TextEditingController disabilityDetailsController = TextEditingController();

  String? gender;
  DateTime? dob;
  bool hasSupplements = false;
  bool hasDisabilities = false;
  
  // Athlete Profile State
  String? athleteType;
  String? experienceLevel;

  final List<String> sportsOptions = ['Football', 'Track', 'Cricket', 'Basketball', 'Motor sport', 'Golf', 'Badminton', 'Tennis', 'Gymnastics', 'Volleyball', 'Martial arts'];
  final List<String> selectedSports = [];

  // Training Schedule State
  double trainingDays = 3; // Default to 3 days
  String? averageDuration;
  int intensityIndex = 0; // 0 = Easy, 1 = Medium, 2 = Hard
  final List<String> primaryGoals = [];
  final List<String> secondaryGoals = [];

  // Lifestyle State
  double sleepDuration = 6.0; // Default to 6
  int sleepQualityIndex = 2; // Default to 'Good'
  double waterIntake = 2.0; // Default to 2 L
  String? caffeineIntake;
  double screenTime = 1.0; // Default to 1 hour
  final TextEditingController injuryHistoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && (doc.data() as Map)['onboardingCompleted'] == true) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (route) => false,
          );
        }
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _triggerError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMessage = msg);
    _errorTimer?.cancel();
    
    // FIX: Add 'if (!mounted) return;' inside the Timer
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return; 
      setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    // 1. Cancel the timer if it is running
    _errorTimer?.cancel(); 
    
    // 2. Clean up all controllers to prevent major memory leaks
    _pageController.dispose();
    nameController.dispose();
    countryController.dispose();
    timeZoneController.dispose();
    heightController.dispose();
    weightController.dispose();
    bodyFatController.dispose();
    waistCircumferenceController.dispose();
    supplementsDetailsController.dispose();
    disabilityDetailsController.dispose();
    injuryHistoryController.dispose();
    
    super.dispose();
  }

  // --- CALCULATIONS ---
  Map<String, dynamic>? get bmiData {
    double? h = double.tryParse(heightController.text);
    double? w = double.tryParse(weightController.text);
    if (h == null || w == null || h <= 0 || w <= 0) return null;
    double bmi = w / ((h / 100) * (h / 100));
    String category = bmi < 18.5 ? "Underweight" : bmi < 25 ? "Healthy" : bmi < 30 ? "Overweight" : "Obese";
    Color color = bmi < 18.5 ? Colors.blue : bmi < 25 ? const Color(0xFF4CD964) : bmi < 30 ? Colors.orange : Colors.red;
    return {"value": bmi.toStringAsFixed(1), "category": category, "color": color};
  }

  // --- NAVIGATION & SAVE ---
  void _nextStep() {
    // Basic validations
    if (_currentStep == 0) {
      if (nameController.text.isEmpty || gender == null || dob == null || countryController.text.isEmpty || timeZoneController.text.isEmpty) return _triggerError("Fill all personal info");
    } else if (_currentStep == 1) {
      if (heightController.text.isEmpty || weightController.text.isEmpty) return _triggerError("Enter physical stats");
    } else if (_currentStep == 2) {
      if (athleteType == null || experienceLevel == null) return _triggerError("Select athlete type & experience");
    } else if (_currentStep == 3) {
      if (selectedSports.isEmpty) return _triggerError("Select at least one sport");
    } else if (_currentStep == 4) {
      if (averageDuration == null) return _triggerError("Select average session duration");
      if (primaryGoals.isEmpty) return _triggerError("Select at least one primary goal");
    } else if (_currentStep == 5) {
      if (caffeineIntake == null) return _triggerError("Select caffeine intake");
    }

    if (_currentStep < 5) { // 5 is now the final step for everyone
      HapticFeedback.lightImpact();
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _saveData();
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final calculatedBmi = bmiData != null ? double.tryParse(bmiData!['value']) : null;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': nameController.text,
        'gender': gender,
        'dob': dob,
        'country': countryController.text,
        'timeZone': timeZoneController.text,
        'height': heightController.text,
        'weight': weightController.text,
        'bmi': calculatedBmi, 
        'bodyFatPercentage': bodyFatController.text,
        'waistCircumference': waistCircumferenceController.text,
        'hasSupplements': hasSupplements,
        'supplementsDetails': hasSupplements ? supplementsDetailsController.text : null,
        'hasDisabilities': hasDisabilities,
        'disabilityDetails': hasDisabilities ? disabilityDetailsController.text : null,
        'athleteType': athleteType, 
        'experienceLevel': experienceLevel, 
        'selectedSports': selectedSports,
        // Save Training metrics
        'trainingDays': trainingDays.toInt(),
        'averageDuration': averageDuration,
        'trainingIntensity': ['Easy', 'Medium', 'Hard'][intensityIndex], 
        'primaryGoals': primaryGoals,
        'secondaryGoals': secondaryGoals,
        // Save Lifestyle metrics
        'sleepDuration': sleepDuration,
        'sleepQuality': ['Poor', 'Fair', 'Good', 'Excellent'][sleepQualityIndex],
        'waterIntake': waterIntake,
        'caffeineIntake': caffeineIntake,
        'screenTime': screenTime,
        'injuryHistory': injuryHistoryController.text,

        'onboardingCompleted': true,
      }, SetOptions(merge: true));
      
      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      _triggerError("Save failed");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDatePicker() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 320,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5
                  )
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text("Done", style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: dob ?? DateTime.now(),
                minimumYear: 1950,
                maximumYear: DateTime.now().year,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() => dob = newDate);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2) 
        )
      );
    }
    
    int totalSteps = 6; // Standardized to 6 steps for everyone
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Nav & Progress Bars
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
            child: Row(
              children: [
                CNButton.icon(
                  icon: const CNSymbol('chevron.left'),
                  style: CNButtonStyle.glass,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_currentStep > 0) {
                      _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: List.generate(totalSteps, (i) => Expanded(
                      child: Container(
                        height: 4, 
                        margin: const EdgeInsets.symmetric(horizontal: 2), 
                        decoration: BoxDecoration(
                          color: i <= _currentStep ? textColor : textColor.withOpacity(0.12), 
                          borderRadius: BorderRadius.circular(2)
                        )
                      )
                    )),
                  ),
                ),
              ],
            ),
          ),
          
          // Inline Notification
          AnimatedSize(
            duration: const Duration(milliseconds: 300), 
            child: _errorMessage != null 
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12), 
                  child: Text(
                    _errorMessage!, 
                    style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13)
                  )
                ) 
              : const SizedBox.shrink()
          ),
          
          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController, physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                OnboardingPersonal(
                  nameController: nameController, 
                  countryController: countryController,
                  timeZoneController: timeZoneController,
                  gender: gender, 
                  dob: dob, 
                  onGenderSelect: (g) => setState(() => gender = g), 
                  onDateTap: _showDatePicker
                ),
                OnboardingPhysical(
                  heightController: heightController, 
                  weightController: weightController,
                  bodyFatController: bodyFatController,
                  waistCircumferenceController: waistCircumferenceController,
                  bmi: bmiData, 
                  hasSupplements: hasSupplements, 
                  hasDisabilities: hasDisabilities, 
                  supplementsController: supplementsDetailsController, 
                  disabilityController: disabilityDetailsController, 
                  onSupplementToggle: (v) => setState(() => hasSupplements = v), 
                  onDisabilityToggle: (v) => setState(() => hasDisabilities = v), 
                  onValueChange: (v) => setState(() {})
                ),
                OnboardingAthlete(
                  athleteType: athleteType,
                  experienceLevel: experienceLevel,
                  onAthleteTypeSelect: (val) => setState(() => athleteType = val),
                  onExperienceSelect: (val) => setState(() => experienceLevel = val),
                ),
                OnboardingSports(
                  options: sportsOptions, 
                  selected: selectedSports, 
                  onSelect: (s) => setState(() => selectedSports.contains(s) ? selectedSports.remove(s) : selectedSports.add(s))
                ),
                OnboardingTraining(
                  trainingDays: trainingDays,
                  onTrainingDaysChange: (val) => setState(() => trainingDays = val),
                  averageDuration: averageDuration,
                  onDurationSelect: (val) => setState(() => averageDuration = val),
                  intensityIndex: intensityIndex,
                  onIntensitySelect: (index) => setState(() => intensityIndex = index),
                  primaryGoals: primaryGoals,
                  onPrimaryGoalToggle: (val) => setState(() {
                    primaryGoals.contains(val) ? primaryGoals.remove(val) : primaryGoals.add(val);
                  }),
                  secondaryGoals: secondaryGoals,
                  onSecondaryGoalToggle: (val) => setState(() {
                    secondaryGoals.contains(val) ? secondaryGoals.remove(val) : secondaryGoals.add(val);
                  }),
                ), 
                OnboardingLifestyle(
                  sleepDuration: sleepDuration,
                  onSleepDurationChange: (val) => setState(() => sleepDuration = val),
                  sleepQualityIndex: sleepQualityIndex,
                  onSleepQualitySelect: (index) => setState(() => sleepQualityIndex = index),
                  waterIntake: waterIntake,
                  onWaterIntakeChange: (val) => setState(() => waterIntake = val),
                  caffeineIntake: caffeineIntake,
                  onCaffeineSelect: (val) => setState(() => caffeineIntake = val),
                  screenTime: screenTime,
                  onScreenTimeChange: (val) => setState(() => screenTime = val),
                  injuryHistoryController: injuryHistoryController,
                ), 
              ],
            ),
          ),
          // Button
          Padding(
            padding: const EdgeInsets.all(28),
            child: PremiumButton(text: _currentStep == totalSteps - 1 ? "Finish" : "Continue", isLoading: _isSaving, onPressed: _nextStep),
          ),
        ]),
      ),
    );
  }
}