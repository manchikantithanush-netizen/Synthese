import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color pinkColor = Color(0xFFEC548A);

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: isLoading
            ? Container(
                decoration: BoxDecoration(
                  color: pinkColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : CNButton(
                label: text,
                style: CNButtonStyle.prominentGlass,
                tint: pinkColor,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
              ),
      ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _buildCurrentPage(isDark, textColor),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(bool isDark, Color textColor) {
    switch (_currentPage) {
      case 0:
        return _buildIntroPage(isDark, textColor);
      case 1:
        return _buildWarningPage(isDark, textColor); // --- NEW WARNING PAGE ---
      case 2:
        return _buildCalendarPage(isDark, textColor);
      case 3:
        return _buildPeriodLengthPage(isDark, textColor);
      case 4:
        return _buildCycleLengthPage(isDark, textColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroPage(bool isDark, Color textColor) {
    Widget buildFeature(String title, String desc, IconData iconData, Color iconColor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56, 
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0), 
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            "Welcome to\nMenstrual Cycle Tracker",
            style: TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
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
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- NEW MEDICAL DISCLAIMER / WARNING PAGE ---
  Widget _buildWarningPage(bool isDark, Color textColor) {
    Widget buildWarningParagraph(String text, {bool isBold = false}) {
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

    return Padding(
      key: const ValueKey('warning'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CNButton.icon(
            icon: const CNSymbol('chevron.left'),
            style: CNButtonStyle.glass,
            onPressed: () {
              HapticFeedback.lightImpact();
              _previousPage();
            },
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill, 
                color: Color(0xFFFF9F0A), // iOS Warning Orange
                size: 32
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Important Notice", 
                  style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -1)
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildWarningParagraph("This app provides cycle predictions based on the information you enter. These predictions are estimates and may not be accurate for everyone."),
                  
                  // Made the birth control warning bold for emphasis
                  buildWarningParagraph("This app provides general cycle tracking and predictions based on user input. It is not a medical tool and should not be used for diagnosis or health decisions. For medical advice, consult a qualified healthcare professional.", isBold: true),
                  
                  buildWarningParagraph("Cycle lengths and ovulation can vary due to stress, health conditions, lifestyle changes, and other factors. Always listen to your body and seek medical advice if you notice unusual symptoms."),
                  
                  // Final acknowledgment
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12)
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
          PremiumButton(text: "I Understand", onPressed: _nextPage),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCalendarPage(bool isDark, Color textColor) {
    return Padding(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CNButton.icon(
            icon: const CNSymbol('chevron.left'),
            style: CNButtonStyle.glass,
            onPressed: () {
              HapticFeedback.lightImpact();
              _previousPage();
            },
          ),
          const SizedBox(height: 24),
          Text("When did your last period start?", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -1)),
          const Spacer(),
          Theme(
            data: isDark 
                ? ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(primary: pinkColor, onPrimary: Colors.white, surface: Colors.black, onSurface: Colors.white),
                    dialogBackgroundColor: Colors.black,
                  )
                : ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(primary: pinkColor, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
                    dialogBackgroundColor: Colors.white,
                  ),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)), 
              lastDate: DateTime.now(), 
              onDateChanged: (DateTime newDate) => setState(() => _selectedDate = newDate),
            ),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthPage(bool isDark, Color textColor) {
    return Padding(
      key: const ValueKey('period'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CNButton.icon(
            icon: const CNSymbol('chevron.left'),
            style: CNButtonStyle.glass,
            onPressed: () {
              HapticFeedback.lightImpact();
              _previousPage();
            },
          ),
          const SizedBox(height: 24),
          Text("How long does your period usually last?", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -1)),
          const Spacer(),
          SizedBox(
            height: 250,
            child: CupertinoPicker(
              itemExtent: 60, diameterRatio: 1.5, squeeze: 1.2,
              scrollController: FixedExtentScrollController(initialItem: _periodLength - 1),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(background: pinkColor.withOpacity(0.15)),
              onSelectedItemChanged: (int index) {
                setState(() => _periodLength = index + 1);
                HapticFeedback.selectionClick(); 
              },
              children: List.generate(20, (index) => Center(child: Text("${index + 1} days", style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.w600)))),
            ),
          ),
          const Spacer(),
          PremiumButton(text: "Next", onPressed: _nextPage),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCycleLengthPage(bool isDark, Color textColor) {
    return Padding(
      key: const ValueKey('cycle'),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CNButton.icon(
            icon: const CNSymbol('chevron.left'),
            style: CNButtonStyle.glass,
            onPressed: () {
              HapticFeedback.lightImpact();
              _previousPage();
            },
          ),
          const SizedBox(height: 24),
          Text("How long is your typical cycle?", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -1)),
          const Spacer(),
          SizedBox(
            height: 250,
            child: CupertinoPicker(
              itemExtent: 60, diameterRatio: 1.5, squeeze: 1.2,
              scrollController: FixedExtentScrollController(initialItem: _cycleLength - 1),
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(background: pinkColor.withOpacity(0.15)),
              onSelectedItemChanged: (int index) {
                setState(() => _cycleLength = index + 1);
                HapticFeedback.selectionClick();
              },
              children: List.generate(90, (index) => Center(child: Text("${index + 1} days", style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.w600)))),
            ),
          ),
          const Spacer(),
          PremiumButton(
            text: "Finish Setup", 
            isLoading: _isSaving, 
            onPressed: _isSaving ? () {} : _saveData, 
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}