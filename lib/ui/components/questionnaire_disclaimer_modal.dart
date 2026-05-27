import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
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
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withValues(alpha: 0.6);
    final t = AppLocalizations.of(context);

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
                      t.disclaimerTitle,
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
                      t.disclaimerBody,
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
                      t.disclaimerCredits,
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
                          t.disclaimerDuration,
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
                text: t.disclaimerStartTest,
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
