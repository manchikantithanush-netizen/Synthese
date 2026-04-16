import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';

class QuestionnaireDisclaimerModal extends StatelessWidget {
  const QuestionnaireDisclaimerModal({super.key});

  static const Color tealColor = Color(0xFF33BEBE);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 760;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withValues(alpha: 0.6);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // Header
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
                      'Before You Begin',
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
                      Navigator.of(context).pop(false);
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: isCompact ? 16 : 24),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: tealColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 36,
                          color: tealColor,
                        ),
                      ),
                    ),

                    SizedBox(height: isCompact ? 16 : 24),

                    // Disclaimer text
                    Text(
                      'This assessment is designed for personal reflection and self-awareness. It is not a clinical diagnosis tool and should not replace professional mental health advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isCompact ? 14 : 15,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: isCompact ? 14 : 20),

                    // Credits section
                    Text(
                      'This questionnaire covers 15 carefully researched questions inspired by validated tools like the PHQ-9, GAD-7, and Maslach Burnout Inventory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: isCompact ? 12 : 13,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: isCompact ? 12 : 16),

                    // Duration note
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: isCompact ? 14 : 16,
                          color: subTextColor,
                        ),
                        SizedBox(width: isCompact ? 4 : 6),
                        Text(
                          'Takes about 3-5 minutes to complete.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: isCompact ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isCompact ? 16 : 24),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                10,
                24,
                mediaQuery.padding.bottom + (isCompact ? 12 : 24),
              ),
              child: UniversalButton(
                text: 'Start Test',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
