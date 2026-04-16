import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

class OnboardingCycles extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingCycles({super.key, required this.onContinue});

  @override
  State<OnboardingCycles> createState() => _OnboardingCyclesState();
}

class _OnboardingCyclesState extends State<OnboardingCycles> {
  int _currentPage = 0;

  DateTime _selectedDate = DateTime.now();
  int _periodLength = 5;
  int _cycleLength = 28;

  bool _isSaving = false;

  final Color pinkColor = const Color(0xFFEC548A);

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
          'lastPeriodStart': _selectedDate,
          'periodLength': _periodLength,
          'cycleLength': _cycleLength,
          'cyclesSetupCompleted': true,
        }, SetOptions(merge: true));
      }

      HapticFeedback.mediumImpact();
      widget.onContinue();
    } catch (e) {
      debugPrint("Error saving cycle data: $e");
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
    final isCompact = mediaQuery.size.height < 760;

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
            child: _buildCurrentPage(isDark, textColor, isCompact),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(bool isDark, Color textColor, bool isCompact) {
    switch (_currentPage) {
      case 0:
        return _buildIntroPage(isDark, textColor, isCompact);
      case 1:
        return _buildWarningPage(
          isDark,
          textColor,
          isCompact,
        ); // --- NEW WARNING PAGE ---
      case 2:
        return _buildCalendarPage(isDark, textColor, isCompact);
      case 3:
        return _buildPeriodLengthPage(isDark, textColor, isCompact);
      case 4:
        return _buildCycleLengthPage(isDark, textColor, isCompact);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroPage(bool isDark, Color textColor, bool isCompact) {
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
                      color: textColor.withValues(alpha: 0.6),
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

    return Padding(
      key: const ValueKey('intro'),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isCompact ? 20 : 48),
          Text(
            "Welcome to\nMenstrual Cycle Tracker",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 30 : 34,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  buildFeature(
                    "Smart predictions",
                    "Knows when your next period is coming and gets more accurate the more you log.",
                    CupertinoIcons.calendar,
                    const Color(0xFF5E5CE6), // Indigo
                  ),
                  buildFeature(
                    "Daily logging",
                    "Track your flow, mood, symptoms and more. Takes less than a minute each day",
                    CupertinoIcons.square_pencil,
                    const Color(0xFFFF9F0A), // Orange
                  ),
                  buildFeature(
                    "Health alerts",
                    "Get notified when something unusual happens in your cycle so you're never caught off guard.",
                    CupertinoIcons.bell_fill,
                    const Color(0xFFFF453A), // Red
                  ),
                  buildFeature(
                    "Cycle history",
                    "See patterns across your past cycles and understand what's normal for your body.",
                    Icons.history,
                    const Color(0xFF32ADE6), // Light Blue
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 12),
          PremiumButton(text: "Next", onPressed: _nextPage, color: pinkColor),
          SizedBox(height: isCompact ? 16 : 40),
        ],
      ),
    );
  }

  // --- NEW MEDICAL DISCLAIMER / WARNING PAGE ---
  Widget _buildWarningPage(bool isDark, Color textColor, bool isCompact) {
    Widget buildWarningParagraph(String text, {bool isBold = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 16.0 : 24.0),
        child: Text(
          text,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.85),
            fontSize: isCompact ? 15 : 16,
            height: 1.5,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }

    return Padding(
      key: const ValueKey('warning'),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          UniversalBackButton(onPressed: _previousPage),
          SizedBox(height: isCompact ? 16 : 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Color(0xFFFF9F0A), // iOS Warning Orange
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
                  buildWarningParagraph(
                    "This app provides cycle predictions based on the information you enter. These predictions are estimates and may not be accurate for everyone.",
                  ),

                  // Made the birth control warning bold for emphasis
                  buildWarningParagraph(
                    "This app provides general cycle tracking and predictions based on user input. It is not a medical tool and should not be used for diagnosis or health decisions. For medical advice, consult a qualified healthcare professional.",
                    isBold: true,
                  ),

                  buildWarningParagraph(
                    "Cycle lengths and ovulation can vary due to stress, health conditions, lifestyle changes, and other factors. Always listen to your body and seek medical advice if you notice unusual symptoms.",
                  ),

                  // Final acknowledgment
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      "By continuing, you acknowledge that this app is for informational purposes only and does not provide medical advice.",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          PremiumButton(
            text: "I Understand",
            onPressed: _nextPage,
            color: pinkColor,
          ),
          SizedBox(height: isCompact ? 16 : 40),
        ],
      ),
    );
  }

  Widget _buildCalendarPage(bool isDark, Color textColor, bool isCompact) {
    return Padding(
      key: const ValueKey('calendar'),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          UniversalBackButton(onPressed: _previousPage),
          SizedBox(height: isCompact ? 16 : 24),
          Text(
            "When did your last period start?",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          Theme(
            data: isDark
                ? ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: pinkColor,
                      onPrimary: Colors.white,
                      surface: Colors.black,
                      onSurface: Colors.white,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.black,
                    ),
                  )
                : ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(
                      primary: pinkColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.white,
                    ),
                  ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              onDateChanged: (DateTime newDate) =>
                  setState(() => _selectedDate = newDate),
            ),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage, color: pinkColor),
          SizedBox(height: isCompact ? 16 : 40),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthPage(bool isDark, Color textColor, bool isCompact) {
    return Padding(
      key: const ValueKey('period'),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          UniversalBackButton(onPressed: _previousPage),
          SizedBox(height: isCompact ? 16 : 24),
          Text(
            "How long does your period usually last?",
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
            height: isCompact ? 220 : 250,
            child: CupertinoPicker(
              itemExtent: isCompact ? 52 : 60,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: FixedExtentScrollController(
                initialItem: _periodLength - 1,
              ),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: pinkColor.withValues(alpha: 0.15),
              ),
              onSelectedItemChanged: (int index) {
                setState(() => _periodLength = index + 1);
                HapticFeedback.selectionClick();
              },
              children: List.generate(
                20,
                (index) => Center(
                  child: Text(
                    "${index + 1} days",
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage, color: pinkColor),
          SizedBox(height: isCompact ? 16 : 40),
        ],
      ),
    );
  }

  Widget _buildCycleLengthPage(bool isDark, Color textColor, bool isCompact) {
    return Padding(
      key: const ValueKey('cycle'),
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20.0 : 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          UniversalBackButton(onPressed: _previousPage),
          SizedBox(height: isCompact ? 16 : 24),
          Text(
            "How long is your typical cycle?",
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
            height: isCompact ? 220 : 250,
            child: CupertinoPicker(
              itemExtent: isCompact ? 52 : 60,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: FixedExtentScrollController(
                initialItem: _cycleLength - 1,
              ),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: pinkColor.withValues(alpha: 0.15),
              ),
              onSelectedItemChanged: (int index) {
                setState(() => _cycleLength = index + 1);
                HapticFeedback.selectionClick();
              },
              children: List.generate(
                90,
                (index) => Center(
                  child: Text(
                    "${index + 1} days",
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          PremiumButton(
            text: "Finish Setup",
            isLoading: _isSaving,
            onPressed: _isSaving ? () {} : _saveData,
            color: pinkColor,
          ),
          SizedBox(height: isCompact ? 16 : 40),
        ],
      ),
    );
  }
}
