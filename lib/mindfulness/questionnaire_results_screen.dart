import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/mindfulness/questionnaire_data.dart';
import 'package:synthese/mindfulness/questionnaire_screen.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';

const Color tealColor = Color(0xFF33BEBE);

class QuestionnaireResultsScreen extends StatelessWidget {
  final Map<int, int> answers; // questionId -> optionIndex

  const QuestionnaireResultsScreen({super.key, required this.answers});

  /// Show the results as a 93% height modal bottom sheet
  static Future<void> show(BuildContext context, Map<int, int> answers) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestionnaireResultsScreen(answers: answers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.6);

    // Calculate scores
    final scores = calculateDimensionScores(answers);
    final hasCrisis = hasCrisisIndicator(answers);

    // Get high and moderate risk dimensions
    final highRisk = <String>[];
    final moderateRisk = <String>[];
    for (final entry in scores.entries) {
      final level = getRiskLevel(entry.value);
      if (level == RiskLevel.high) {
        highRisk.add(getDimensionById(entry.key)?.name ?? entry.key);
      }
      if (level == RiskLevel.moderate) {
        moderateRisk.add(getDimensionById(entry.key)?.name ?? entry.key);
      }
    }

    // Sort dimensions by score descending
    final sortedDimensions = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                      'Results',
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
                        // Close all modals and go back to mindfulness page
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Your Wellbeing Snapshot',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your responses, here\'s a breakdown across eight dimensions of mental health.',
                      style: TextStyle(color: subTextColor, fontSize: 15),
                    ),
                    const SizedBox(height: 24),

                    // Insight Card
                    _buildInsightCard(
                      context,
                      hasCrisis: hasCrisis,
                      highRisk: highRisk,
                      moderateRisk: moderateRisk,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),

                    // Risk Dimension Cards
                    ...sortedDimensions.map((entry) {
                      final dimension = getDimensionById(entry.key);
                      if (dimension == null) return const SizedBox.shrink();
                      return _buildDimensionCard(
                        context,
                        dimension: dimension,
                        score: entry.value,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        isDark: isDark,
                      );
                    }),

                    // Disclaimer footer
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'This assessment is for personal reflection only and does not constitute a clinical diagnosis. If you are experiencing distress, please speak with a qualified mental health professional.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Retake button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: UniversalButton(
                        text: 'Retake Assessment',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Close results modal and show questionnaire modal
                          Navigator.of(context).pop();
                          QuestionnaireScreen.show(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required bool hasCrisis,
    required List<String> highRisk,
    required List<String> moderateRisk,
    required Color cardColor,
    required Color textColor,
  }) {
    IconData insightIcon;
    Color insightColor;
    Color insightBorderColor;
    String insightTitle;
    String insightBody;

    // Priority 1: Crisis indicator (Q12 answer is C (2) or D (3))
    if (hasCrisis) {
      insightIcon = CupertinoIcons.heart_fill;
      insightColor = Colors.red;
      insightBorderColor = Colors.red;
      insightTitle = 'A note of care';
      insightBody =
          'Some of your responses suggest you may be experiencing thoughts that are difficult to carry. Please consider reaching out to a mental health professional, a trusted person, or a crisis line — you don\'t have to manage this alone.';
    }
    // Priority 2: Any HIGH risk
    else if (highRisk.isNotEmpty) {
      insightIcon = CupertinoIcons.exclamationmark_triangle_fill;
      insightColor = Colors.orange;
      insightBorderColor = Colors.orange;
      insightTitle = 'Where to focus';
      insightBody =
          'Your results suggest elevated indicators in: ${highRisk.join(', ')}. These areas may benefit from intentional support — whether through rest, professional guidance, or mindfulness practice.';
    }
    // Priority 3: Any MODERATE risk
    else if (moderateRisk.isNotEmpty) {
      insightIcon = CupertinoIcons.info_circle_fill;
      insightColor = Colors.blue;
      insightBorderColor = Colors.blue;
      insightTitle = 'Worth watching';
      insightBody =
          'You\'re showing moderate indicators in: ${moderateRisk.join(', ')}. Small, consistent habits — quality sleep, connection, movement — can make a meaningful difference.';
    }
    // Priority 4: All LOW
    else {
      insightIcon = CupertinoIcons.checkmark_circle_fill;
      insightColor = Colors.green;
      insightBorderColor = Colors.green;
      insightTitle = 'Looking good overall';
      insightBody =
          'Your responses suggest a relatively balanced state of mental wellbeing. Keep up your healthy habits, and check in regularly — mental health can shift with life circumstances.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insightBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(insightIcon, color: insightColor, size: 24),
              const SizedBox(width: 12),
              Text(
                insightTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: insightColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insightBody,
            style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionCard(
    BuildContext context, {
    required Dimension dimension,
    required double score,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    final riskLevel = getRiskLevel(score);
    final riskLevelText = _getRiskLevelText(riskLevel);
    final riskLevelColor = _getRiskLevelColor(riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RISK INDICATOR',
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dimension.name,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(dimension.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            riskLevelText,
            style: TextStyle(
              color: riskLevelColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskLevelText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  Color _getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }
}
