import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'dart:ui';
import 'package:synthese/mindfulness/questionnaire_data.dart';
import 'package:synthese/mindfulness/questionnaire_results_screen.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  /// Show the questionnaire as a 93% height modal bottom sheet
  /// Returns the answers map when completed, or null if cancelled
  static Future<Map<int, int>?> show(BuildContext context) {
    return showModalBottomSheet<Map<int, int>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuestionnaireScreen(),
    );
  }

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // questionId -> optionIndex (0-3)
  late PageController _pageController;

  static const Color tealColor = Color(0xFF33BEBE);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 14) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showResults();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showResults() {
    // Return answers and close questionnaire
    Navigator.pop(context, _answers);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final textColor = isDark ? Colors.white : Colors.black;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Mental Health Assessment',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: UniversalCloseButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // PageView for questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: 15,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (context, index) {
                  return _buildQuestionPage(index, isDark, textColor);
                },
              ),
            ),

            // Bottom navigation row
            _buildBottomNavigation(isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int index, bool isDark, Color textColor) {
    final question = questions[index];
    final pillBgColor = isDark ? const Color(0xFF252528) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            'QUESTION ${index + 1} OF 15',
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            question.text,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Options list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: question.options.length,
            itemBuilder: (context, optionIndex) {
              return _buildOptionItem(
                question: question,
                optionIndex: optionIndex,
                isDark: isDark,
                textColor: textColor,
                pillBgColor: pillBgColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required Question question,
    required int optionIndex,
    required bool isDark,
    required Color textColor,
    required Color pillBgColor,
  }) {
    final option = question.options[optionIndex];
    final isSelected = _answers[question.id] == optionIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _answers[question.id] = optionIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: pillBgColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? tealColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: tealColor,
                      size: 24,
                      key: ValueKey('checked'),
                    )
                  : const SizedBox(
                      width: 24,
                      height: 24,
                      key: ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liquidGlassPillButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
    Color? accentColor,
  }) {
    final isEnabled = onPressed != null;
    final background = accentColor != null
        ? accentColor.withValues(alpha: isEnabled ? 0.26 : 0.16)
        : (isDark ? Colors.white : Colors.black).withValues(
            alpha: isEnabled ? 0.16 : 0.1,
          );
    final border = accentColor != null
        ? accentColor.withValues(alpha: isEnabled ? 0.5 : 0.25)
        : (isDark ? Colors.white : Colors.black).withValues(
            alpha: isEnabled ? 0.35 : 0.2,
          );
    final textColor = accentColor ?? (isDark ? Colors.white : Colors.black);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: background,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: border, width: 1.1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark, Color textColor) {
    final tealColor = isDark ? const Color(0xFF33BEBE) : const Color(0xFF0A9B9B);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Next/View Results button
          _liquidGlassPillButton(
            label: _currentPage == 14 ? "View Results" : "Next",
            onPressed: _nextPage,
            isDark: isDark,
            accentColor: tealColor,
          ),
          
          const SizedBox(height: 12),
          
          // Back button
          AnimatedOpacity(
            opacity: _currentPage > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _currentPage == 0,
              child: _liquidGlassPillButton(
                label: 'Back',
                onPressed: _currentPage > 0 ? _prevPage : null,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
