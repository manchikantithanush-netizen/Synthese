import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

class DietOnboarding extends StatefulWidget {
  final VoidCallback onContinue;

  const DietOnboarding({super.key, required this.onContinue});

  @override
  State<DietOnboarding> createState() => _DietOnboardingState();
}

class _DietOnboardingState extends State<DietOnboarding> {
  int _currentPage = 0;

  int _dailyCalorieGoal = 2000; // Default: 2000 calories
  double _currentWaterIntake = 2.0; // Fetched from first onboarding
  double _dailyWaterGoalLitres = 2.0; // Default: 2L
  int _dailyWaterGoalGlasses = 8; // Calculated from litres
  bool _isSaving = false;

  final Color orangeColor = const Color(0xFFFF9500);

  @override
  void initState() {
    super.initState();
    _fetchWaterIntake();
  }

  Future<void> _fetchWaterIntake() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['waterIntake'] != null) {
            setState(() {
              _currentWaterIntake = (data['waterIntake'] as num).toDouble();
              _dailyWaterGoalLitres =
                  _currentWaterIntake; // Default to current intake
              _calculateGlasses();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching water intake: $e");
    }
  }

  void _calculateGlasses() {
    // 1 glass = 250ml = 0.25L
    // So glasses = litres / 0.25 = litres * 4
    _dailyWaterGoalGlasses = (_dailyWaterGoalLitres * 4).round();
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _previousPage() {
    setState(() {
      _currentPage--;
    });
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'dailyCalorieGoal': _dailyCalorieGoal,
          'dailyWaterGoalLitres': _dailyWaterGoalLitres,
          'dailyWaterGoalGlasses': _dailyWaterGoalGlasses,
          'dietSetupCompleted': true,
        }, SetOptions(merge: true));
      }

      HapticFeedback.mediumImpact();
      widget.onContinue();
    } catch (e) {
      debugPrint("Error saving diet data: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedTextScale.toDouble()),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentPage(isDark, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(bool isDark, Color textColor) {
    switch (_currentPage) {
      case 0:
        return _buildWelcomePage(isDark, textColor);
      case 1:
        return _buildDisclaimerPage(isDark, textColor);
      case 2:
        return _buildCalorieGoalPage(isDark, textColor);
      case 3:
        return _buildWaterGoalPage(isDark, textColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScrollablePage({
    required Key key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return KeyedSubtree(
      key: key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 760;
          final horizontalPadding = constraints.maxWidth < 370 ? 20.0 : 28.0;
          final mediaQuery = MediaQuery.of(context);
          final bottomSpacing =
              mediaQuery.viewInsets.bottom + (isCompact ? 12 : 24);
          final resolvedPadding =
              padding ??
              EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 8 : 12,
                horizontalPadding,
                bottomSpacing,
              );
          final verticalPadding = resolvedPadding.vertical;
          return Padding(
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - verticalPadding).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark, Color textColor) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 760;

    Widget buildFeature(
      String title,
      String desc,
      IconData iconData,
      Color iconColor,
    ) {
      return Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 18.0 : 28.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isCompact ? 48 : 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: isCompact ? 30 : 35,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: isCompact ? 14 : 15,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildScrollablePage(
      key: const ValueKey('welcome'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isCompact ? 14 : 32),
          Text(
            "Welcome to\nDiet Tracker",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 30 : 34,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
          buildFeature(
            "AI-Powered Analysis",
            "Snap a photo of your food and get instant calorie estimates powered by advanced AI.",
            CupertinoIcons.camera_viewfinder,
            const Color(0xFF5E5CE6),
          ),
          buildFeature(
            "Daily Tracking",
            "Effortlessly monitor your calorie intake throughout the day with a simple food log.",
            CupertinoIcons.chart_bar_fill,
            const Color(0xFFFF9F0A),
          ),
          buildFeature(
            "Smart Insights",
            "Understand your eating patterns over time and make informed nutrition choices.",
            CupertinoIcons.lightbulb_fill,
            const Color(0xFF32ADE6),
          ),
          buildFeature(
            "Goal Setting",
            "Set daily calorie targets and track your progress toward your health goals.",
            CupertinoIcons.flag_fill,
            const Color(0xFF30D158),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage, color: orangeColor),
        ],
      ),
    );
  }

  Widget _buildDisclaimerPage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;

    Widget buildDisclaimerParagraph(String text, {bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Text(
          text,
          style: TextStyle(
            color: textColor.withOpacity(0.85),
            fontSize: 16,
            height: 1.5,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }

    return _buildScrollablePage(
      key: const ValueKey('disclaimer'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          UniversalBackButton(onPressed: _previousPage),
          SizedBox(height: isCompact ? 16 : 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Color(0xFFFF9F0A),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Important Notice",
                  style: TextStyle(
                    color: textColor,
                    fontSize: isCompact ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDisclaimerParagraph(
                    "This app uses AI to analyze food images and estimate calorie counts. These estimates are approximations and may not be 100% accurate.",
                  ),
                  buildDisclaimerParagraph(
                    "AI recognition can be affected by image quality, portion sizes, food preparation methods, and other factors. The calorie estimates provided should be used as a general guide only.",
                    isBold: true,
                  ),
                  buildDisclaimerParagraph(
                    "This app is not a substitute for professional nutritional advice. For personalized dietary guidance, consult a registered dietitian or healthcare professional.",
                  ),
                  buildDisclaimerParagraph(
                    "Calorie needs vary based on age, gender, activity level, metabolism, and health conditions. Always consult a professional before making significant dietary changes.",
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      "By continuing, you acknowledge that this app provides estimates for informational purposes only and does not replace professional nutritional advice.",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          PremiumButton(
            text: "I Understand",
            onPressed: _nextPage,
            color: orangeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieGoalPage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    return _buildScrollablePage(
      key: const ValueKey('calorie-goal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          UniversalBackButton(onPressed: _previousPage),
          const SizedBox(height: 24),
          Text(
            "What's your daily calorie goal?",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: isCompact ? 210 : 250,
            child: CupertinoPicker(
              itemExtent: 60,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: FixedExtentScrollController(
                initialItem: (_dailyCalorieGoal - 1000) ~/ 100,
              ),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: orangeColor.withOpacity(0.15),
              ),
              onSelectedItemChanged: (int index) {
                setState(() => _dailyCalorieGoal = 1000 + (index * 100));
                HapticFeedback.selectionClick();
              },
              children: List.generate(
                31,
                (index) => Center(
                  child: Text(
                    "${1000 + (index * 100)} cal",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage, color: orangeColor),
        ],
      ),
    );
  }

  Widget _buildWaterGoalPage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    return _buildScrollablePage(
      key: const ValueKey('water-goal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          UniversalBackButton(onPressed: _previousPage),
          const SizedBox(height: 24),
          Text(
            "Water Intake Goal",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.drop_fill,
                  color: Color(0xFF4FC3F7),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You logged ${_currentWaterIntake.toStringAsFixed(1)}L of water intake daily",
                    style: TextStyle(
                      color: textColor.withOpacity(0.85),
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "What's your daily water goal?",
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: isCompact ? 210 : 250,
            child: CupertinoPicker(
              itemExtent: 60,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: FixedExtentScrollController(
                initialItem: ((_dailyWaterGoalLitres * 2) - 2).round(),
              ),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: const Color(0xFF4FC3F7).withOpacity(0.15),
              ),
              onSelectedItemChanged: (int index) {
                setState(() {
                  _dailyWaterGoalLitres = (index + 2) * 0.5;
                  _calculateGlasses();
                });
                HapticFeedback.selectionClick();
              },
              children: List.generate(15, (index) {
                final litres = (index + 2) * 0.5;
                final glasses = (litres * 4).round();
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${litres.toStringAsFixed(1)}L",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$glasses glasses",
                        style: TextStyle(
                          color: textColor.withOpacity(0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          PremiumButton(
            text: "Finish Setup",
            isLoading: _isSaving,
            onPressed: _isSaving ? () {} : _saveData,
            color: orangeColor,
          ),
        ],
      ),
    );
  }
}
