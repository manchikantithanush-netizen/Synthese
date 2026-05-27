import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleSixView extends StatelessWidget {
  final bool isDark;
  const ArticleSixView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, bottom: 60.0),
      children: [
        // --- MAIN TITLE ---
        Text(
          t.cyA6Title,
          style: TextStyle(
            color: textColor,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.cyA6Sub,
          style: TextStyle(
            color: isDark
                ? const Color(0xFFEBEBF5).withOpacity(0.6)
                : const Color(0xFF3C3C43).withOpacity(0.6),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 40),

        // --- SECTION 1: TRACKING IS NOT ABOUT PREDICTION ---
        _buildHeading(t.cyA6S1H, textColor),
        _buildParagraph(t.cyA6S1P1, bodyColor),
        _buildParagraph(t.cyA6S1P2, bodyColor),
        _buildParagraph(t.cyA6S1P3, bodyColor, citation: "Nicklaus Children's Hospital"),
        _buildParagraph(t.cyA6S1P4, bodyColor, citation: "Cleveland Clinic"),
        _buildParagraph(t.cyA6S1P5, bodyColor),
        _buildParagraph(t.cyA6S1P6, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2: FLOW DATA ---
        _buildHeading(t.cyA6FlowH, textColor),
        _buildParagraph(t.cyA6FlowP1, bodyColor),
        Text(t.cyA6FlowPatternsLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6FlowPat1, bodyColor),
        _buildSimpleBullet(t.cyA6FlowPat2, bodyColor),
        _buildSimpleBullet(t.cyA6FlowPat3, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA6FlowResearchLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildParagraph(t.cyA6FlowResP1, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA6FlowResP2, bodyColor),

        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6FlowK1, bodyColor),
        _buildSimpleBullet(t.cyA6FlowK2, bodyColor),
        _buildSimpleBullet(t.cyA6FlowK3, bodyColor),
        _buildSimpleBullet(t.cyA6FlowK4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 3: SYMPTOM DATA ---
        _buildHeading(t.cyA6SympH, textColor),
        _buildParagraph(t.cyA6SympP1, bodyColor),
        _buildBullet(t.cyA6SympCrampsT, t.cyA6SympCrampsB, bodyColor, textColor, citation: "Medscape"),
        _buildParagraph(t.cyA6SympCrampsP, bodyColor),
        _buildBullet(t.cyA6SympHeadT, t.cyA6SympHeadB, bodyColor, textColor),
        _buildBullet(t.cyA6SympDigT, t.cyA6SympDigB, bodyColor, textColor),
        _buildBullet(t.cyA6SympAcneT, t.cyA6SympAcneB, bodyColor, textColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6SympK1, bodyColor),
        _buildSimpleBullet(t.cyA6SympK2, bodyColor),
        _buildSimpleBullet(t.cyA6SympK3, bodyColor),
        _buildSimpleBullet(t.cyA6SympK4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 4: MOOD DATA ---
        _buildHeading(t.cyA6MoodH, textColor),
        _buildParagraph(t.cyA6MoodP1, bodyColor),
        _buildParagraph(t.cyA6MoodP2, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA6MoodP3, bodyColor),
        _buildSimpleBullet(t.cyA6MoodL1, bodyColor),
        _buildSimpleBullet(t.cyA6MoodL2, bodyColor),
        _buildSimpleBullet(t.cyA6MoodL3, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6MoodK1, bodyColor),
        _buildSimpleBullet(t.cyA6MoodK2, bodyColor),
        _buildSimpleBullet(t.cyA6MoodK3, bodyColor),
        const SizedBox(height: 32),

        // --- CUSTOM UI: DATA POINTS LIST ---
        _buildDataPointsList(t, isDark),
        const SizedBox(height: 32),

        // --- SECTION 5: CERVICAL MUCUS ---
        _buildHeading(t.cyA6MucusH, textColor),
        _buildParagraph(t.cyA6MucusP1, bodyColor),
        _buildSimpleBullet(t.cyA6MucusL1, bodyColor),
        _buildSimpleBullet(t.cyA6MucusL2, bodyColor),
        _buildSimpleBullet(t.cyA6MucusL3, bodyColor),
        _buildSimpleBullet(t.cyA6MucusL4, bodyColor),
        _buildSimpleBullet(t.cyA6MucusL5, bodyColor),
        _buildParagraph(t.cyA6MucusP2, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6: STARTING EARLY ---
        _buildHeading(t.cyA6EarlyH, textColor),
        _buildParagraph(t.cyA6EarlyP1, bodyColor),
        _buildParagraph(t.cyA6EarlyP2, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA6EarlyP3, bodyColor),
        _buildParagraph(t.cyA6EarlyP4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7: DOCTOR'S APPOINTMENT ---
        _buildHeading(t.cyA6DocAptH, textColor),
        _buildParagraph(t.cyA6DocAptP1, bodyColor),
        _buildParagraph(t.cyA6DocAptP2, bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph(t.cyA6DocAptP3, bodyColor),

        Text(t.cyA6BringLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6Bring1, bodyColor),
        _buildSimpleBullet(t.cyA6Bring2, bodyColor),
        _buildSimpleBullet(t.cyA6Bring3, bodyColor),
        _buildSimpleBullet(t.cyA6Bring4, bodyColor),
        _buildSimpleBullet(t.cyA6Bring5, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA6ConvLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6Conv1, bodyColor),
        _buildSimpleBullet(t.cyA6Conv2, bodyColor),
        _buildSimpleBullet(t.cyA6Conv3, bodyColor),
        _buildSimpleBullet(t.cyA6Conv4, bodyColor),

        const SizedBox(height: 12),
        _buildParagraph(t.cyA6DocAptP4, bodyColor, citation: "Amegroups"),
        const SizedBox(height: 32),

        // --- SECTION 8: PREDICTION ACCURACY ---
        _buildHeading(t.cyA6PredH, textColor),
        _buildParagraph(t.cyA6PredP1, bodyColor),
        _buildParagraph(t.cyA6PredP2, bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph(t.cyA6PredP3, bodyColor),
        _buildSimpleBullet(t.cyA6PredL1, bodyColor),
        _buildSimpleBullet(t.cyA6PredL2, bodyColor),
        _buildSimpleBullet(t.cyA6PredL3, bodyColor),
        _buildSimpleBullet(t.cyA6PredL4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 9: PRACTICAL GUIDANCE ---
        _buildHeading(t.cyA6PracH, textColor),
        Text(t.cyA6LogDailyLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6LogDaily1, bodyColor),
        _buildSimpleBullet(t.cyA6LogDaily2, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA6LogNoticeLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6LogNotice1, bodyColor),
        _buildSimpleBullet(t.cyA6LogNotice2, bodyColor),
        _buildSimpleBullet(t.cyA6LogNotice3, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA6LogCycleLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6LogCycle1, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA6LogNotLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6LogNot1, bodyColor),
        _buildSimpleBullet(t.cyA6LogNot2, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA6PracK1, bodyColor),
        _buildSimpleBullet(t.cyA6PracK2, bodyColor),
        _buildSimpleBullet(t.cyA6PracK3, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 10: WHEN TO SEE A DOCTOR ---
        _buildHeading(t.cyA6WhenH, textColor),
        _buildParagraph(t.cyA6WhenP1, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL1, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL2, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL3, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL4, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL5, bodyColor),
        _buildSimpleBullet(t.cyA6WhenL6, bodyColor),
        _buildParagraph(t.cyA6WhenP2, bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 11: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Hong M, Rajaguru V et al. Menstrual Cycle Management and Period Tracker App Use. Journal of Medical Internet Research, 2024.", isDark),
        _buildSourceItem("• Symul L, Wac K et al. Characterizing physiological and symptomatic variation... npj Digital Medicine, 2020.", isDark),
        _buildSourceItem("• Stujenske TM, Mu Q et al. Survey Analysis of Menstrual Cycle Tracking Technologies. Medicina, 2023.", isDark),
        _buildSourceItem("• Li H et al. Menstrual cycle length variation by demographic characteristics. npj Digital Medicine, 2023.", isDark),
        _buildSourceItem("• Zhang CY, Li H et al. Abnormal uterine bleeding patterns determined through menstrual tracking. AJOG, 2023.", isDark),
        _buildSourceItem("• Epstein D et al. Examining menstrual tracking to inform the design of personal informatics tools. ACM CHI Conference, 2017.", isDark),
        _buildSourceItem("• Lyzwinski L, Elgendi M et al. Innovative Approaches to Menstruation Tracking. Journal of Medical Internet Research, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• Apple Newsroom — Findings from Apple Women's Health Study (2023)", isDark),
        _buildSourceItem("• Harvard T.H. Chan School of Public Health — Apple Women's Health Study Updates", isDark),
        _buildSourceItem("• Frontiers in Computer Science — Reimagining the Cycle (2023)", isDark),
        _buildSourceItem("• Oxford Open Digital Health — Women's Views on Privacy and Data Security (2025)", isDark),
        _buildSourceItem("• Unified Premier Women's Care — Menstrual Cycle Tracking: Techniques and Benefits (2024)", isDark),
        _buildSourceItem("• Clue by Biowink — About Clue Research (2024)", isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeading(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, Color color, {String? citation}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            color: color,
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(text: text),
            if (citation != null) ...[
              const TextSpan(text: "  "),
              TextSpan(
                text: "($citation)",
                style: TextStyle(
                  color: color.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String boldText, String normalText, Color bodyColor, Color titleColor, {String? citation}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12.0, start: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•  ", style: TextStyle(color: titleColor, fontSize: 17, fontWeight: FontWeight.bold, height: 1.45)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: bodyColor, fontSize: 17, height: 1.45),
                children: [
                  TextSpan(text: "$boldText — ", style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
                  TextSpan(text: normalText),
                  if (citation != null) ...[
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: "($citation)",
                      style: TextStyle(
                        color: bodyColor.withOpacity(0.5),
                        fontSize: 15,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12.0, start: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•  ", style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold, height: 1.45)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 17, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  // --- CUSTOM UI FOR DATA POINTS LIST ---
  Widget _buildDataPointsList(AppLocalizations t, bool isDark) {
    final bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final primaryText = isDark ? Colors.white : Colors.black;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    Widget buildListItem({
      required IconData icon,
      required Color color,
      required String title,
      required String desc,
      required String pillText,
      bool showBorder = true,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          border: showBorder ? Border(bottom: BorderSide(color: borderColor, width: 1)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(color: secondaryText, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pillText,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cyA6CardTitle,
            style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            t.cyA6CardSub,
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 32),

          buildListItem(
            icon: CupertinoIcons.drop_fill,
            color: const Color(0xFFFF2D55),
            title: t.cyA6DpFlowT,
            desc: t.cyA6DpFlowD,
            pillText: t.cyA6PillHigh,
          ),
          buildListItem(
            icon: CupertinoIcons.arrow_2_squarepath,
            color: const Color(0xFF007AFF),
            title: t.cyA6DpSympT,
            desc: t.cyA6DpSympD,
            pillText: t.cyA6PillHigh,
          ),
          buildListItem(
            icon: CupertinoIcons.time,
            color: const Color(0xFF34C759),
            title: t.cyA6DpMoodT,
            desc: t.cyA6DpMoodD,
            pillText: t.cyA6PillMedHigh,
          ),
          buildListItem(
            icon: CupertinoIcons.location_solid,
            color: const Color(0xFFFF9500),
            title: t.cyA6DpMucusT,
            desc: t.cyA6DpMucusD,
            pillText: t.cyA6PillMed,
          ),
          buildListItem(
            icon: CupertinoIcons.calendar,
            color: const Color(0xFF5856D6),
            title: t.cyA6DpLenT,
            desc: t.cyA6DpLenD,
            pillText: t.cyA6PillTime,
            showBorder: false,
          ),

          Divider(color: borderColor, height: 32),
          Text(
            "Sources: Clue / npj Digital Medicine 4.9M cycle study (2020); Apple Women's Health Study (2023); Stujenske et al. Medicina (2023)",
            style: TextStyle(color: secondaryText, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            t.cyA6CardCaption,
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45),
          ),
        ],
      ),
    );
  }
}
