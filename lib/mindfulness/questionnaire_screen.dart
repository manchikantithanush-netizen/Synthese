import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:synthese/mindfulness/questionnaire_data.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 760;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151515) : const Color.fromARGB(255, 245, 245, 245);
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
              padding: EdgeInsets.only(
                top: isCompact ? 16 : 24,
                left: 20,
                right: 20,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Mental Health Assessment',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 17 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  UniversalCloseButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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
                  return _buildQuestionPage(
                    index,
                    isDark,
                    textColor,
                    isCompact,
                  );
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

  Widget _buildQuestionPage(
    int index,
    bool isDark,
    Color textColor,
    bool isCompact,
  ) {
    final question = questions[index];
    final pillBgColor = isDark ? const Color(0xFF151515) : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
            child: Text(
              'QUESTION ${index + 1} OF 15',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: isCompact ? 13 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(
            question.text,
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 17 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 24),
          Expanded(
            child: Column(
              children: List.generate(question.options.length, (optionIndex) {
                return _buildOptionItem(
                  question: question,
                  optionIndex: optionIndex,
                  isDark: isDark,
                  textColor: textColor,
                  pillBgColor: pillBgColor,
                  compact: isCompact,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required Question question,
    required int optionIndex,
    required bool isDark,
    required Color textColor,
    required Color pillBgColor,
    required bool compact,
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
        margin: EdgeInsets.only(bottom: compact ? 8 : 12),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 24,
          vertical: compact ? 11 : 18,
        ),
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
                  fontSize: compact ? 14 : 16,
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
                  ? Icon(
                      Icons.check_circle,
                      color: tealColor,
                      size: compact ? 20 : 24,
                      key: const ValueKey('checked'),
                    )
                  : SizedBox(
                      width: compact ? 20 : 24,
                      height: compact ? 20 : 24,
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
    final tealColor = isDark
        ? const Color(0xFF33BEBE)
        : const Color(0xFF0A9B9B);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 760;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        isCompact ? 12 : 20,
        24,
        mediaQuery.padding.bottom + (isCompact ? 12 : 24),
      ),
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
