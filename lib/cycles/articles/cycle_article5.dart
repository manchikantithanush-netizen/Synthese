import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleFiveView extends StatelessWidget {
  final bool isDark;
  const ArticleFiveView({super.key, required this.isDark});

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
          t.cyA5Title,
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
          t.cyA5Sub,
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

        // --- SECTION 1 ---
        _buildHeading(t.cyA5S1H, textColor),
        _buildParagraph(t.cyA5S1P1, bodyColor),
        _buildParagraph(t.cyA5S1P2, bodyColor),
        _buildParagraph(t.cyA5S1P3, bodyColor, citation: "Drugs.com"),
        _buildParagraph(t.cyA5S1P4, bodyColor),
        const SizedBox(height: 32),

        // --- STRESS ---
        _buildHeading(t.cyA5StressH, textColor),
        _buildParagraph(t.cyA5StressP1, bodyColor),
        _buildParagraph(t.cyA5StressP2, bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph(t.cyA5StressP3, bodyColor, citation: "Amegroups"),
        _buildParagraph(t.cyA5StressP4, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA5StressP5, bodyColor),

        Text(t.cyA5PracticeLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5StressPr1, bodyColor),
        _buildSimpleBullet(t.cyA5StressPr2, bodyColor),
        _buildSimpleBullet(t.cyA5StressPr3, bodyColor),
        _buildSimpleBullet(t.cyA5StressPr4, bodyColor),
        _buildSimpleBullet(t.cyA5StressPr5, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5StressK1, bodyColor),
        _buildSimpleBullet(t.cyA5StressK2, bodyColor),
        _buildSimpleBullet(t.cyA5StressK3, bodyColor),
        _buildSimpleBullet(t.cyA5StressK4, bodyColor),
        const SizedBox(height: 32),

        // --- SLEEP ---
        _buildHeading(t.cyA5SleepH, textColor),
        _buildParagraph(t.cyA5SleepP1, bodyColor),
        _buildParagraph(t.cyA5SleepP2, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA5SleepP3, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA5SleepP4, bodyColor, citation: "PubMed"),
        _buildParagraph(t.cyA5SleepP5, bodyColor, citation: "Medscape"),
        _buildParagraph(t.cyA5SleepP6, bodyColor, citation: "PubMed Central"),

        Text(t.cyA5PracticeLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5SleepPr1, bodyColor),
        _buildSimpleBullet(t.cyA5SleepPr2, bodyColor),
        _buildSimpleBullet(t.cyA5SleepPr3, bodyColor),
        _buildSimpleBullet(t.cyA5SleepPr4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5SleepK1, bodyColor),
        _buildSimpleBullet(t.cyA5SleepK2, bodyColor),
        _buildSimpleBullet(t.cyA5SleepK3, bodyColor),
        _buildSimpleBullet(t.cyA5SleepK4, bodyColor),
        const SizedBox(height: 32),

        // --- CUSTOM EVIDENCE CHART ---
        _buildEvidenceChart(t, isDark),
        const SizedBox(height: 32),

        // --- EXERCISE ---
        _buildHeading(t.cyA5ExH, textColor),
        _buildParagraph(t.cyA5ExP1, bodyColor),
        _buildParagraph(t.cyA5ExP2, bodyColor),
        _buildParagraph(t.cyA5ExP3, bodyColor),
        _buildParagraph(t.cyA5ExP4, bodyColor, citation: "Drugs.com"),
        _buildParagraph(t.cyA5ExP5, bodyColor),

        Text(t.cyA5PracticeLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5ExPr1, bodyColor),
        _buildSimpleBullet(t.cyA5ExPr2, bodyColor),
        _buildSimpleBullet(t.cyA5ExPr3, bodyColor),
        _buildSimpleBullet(t.cyA5ExPr4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5ExK1, bodyColor),
        _buildSimpleBullet(t.cyA5ExK2, bodyColor),
        _buildSimpleBullet(t.cyA5ExK3, bodyColor),
        _buildSimpleBullet(t.cyA5ExK4, bodyColor),
        const SizedBox(height: 32),

        // --- DIET & NUTRITION ---
        _buildHeading(t.cyA5DietH, textColor),
        _buildParagraph(t.cyA5DietP1, bodyColor),
        _buildBullet(t.cyA5DietB1T, t.cyA5DietB1B, bodyColor, textColor),

        Text(t.cyA5MicroLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5Micro1, bodyColor),
        _buildSimpleBullet(t.cyA5Micro2, bodyColor),
        _buildSimpleBullet(t.cyA5Micro3, bodyColor),
        _buildSimpleBullet(t.cyA5Micro4, bodyColor),
        _buildSimpleBullet(t.cyA5Micro5, bodyColor),

        const SizedBox(height: 12),
        _buildBullet(t.cyA5DietB2T, t.cyA5DietB2B, bodyColor, textColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5DietK1, bodyColor),
        _buildSimpleBullet(t.cyA5DietK2, bodyColor),
        _buildSimpleBullet(t.cyA5DietK3, bodyColor),
        _buildSimpleBullet(t.cyA5DietK4, bodyColor),
        const SizedBox(height: 32),

        // --- TRAVEL & JET LAG ---
        _buildHeading(t.cyA5TravelH, textColor),
        _buildParagraph(t.cyA5TravelP1, bodyColor),
        _buildParagraph(t.cyA5TravelP2, bodyColor, citation: "Harvard T.H. Chan School of Public Health"),
        _buildParagraph(t.cyA5TravelP3, bodyColor, citation: "Harvard T.H. Chan School of Public Health"),
        _buildParagraph(t.cyA5TravelP4, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA5TravelP5, bodyColor),

        Text(t.cyA5PracticeLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5TravelPr1, bodyColor),
        _buildSimpleBullet(t.cyA5TravelPr2, bodyColor),
        _buildSimpleBullet(t.cyA5TravelPr3, bodyColor),
        _buildSimpleBullet(t.cyA5TravelPr4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5TravelK1, bodyColor),
        _buildSimpleBullet(t.cyA5TravelK2, bodyColor),
        _buildSimpleBullet(t.cyA5TravelK3, bodyColor),
        _buildSimpleBullet(t.cyA5TravelK4, bodyColor),
        const SizedBox(height: 32),

        // --- ILLNESS & FEVER ---
        _buildHeading(t.cyA5IllH, textColor),
        _buildParagraph(t.cyA5IllP1, bodyColor),
        _buildParagraph(t.cyA5IllP2, bodyColor),
        _buildParagraph(t.cyA5IllP3, bodyColor),

        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5IllK1, bodyColor),
        _buildSimpleBullet(t.cyA5IllK2, bodyColor),
        _buildSimpleBullet(t.cyA5IllK3, bodyColor),
        _buildSimpleBullet(t.cyA5IllK4, bodyColor),
        const SizedBox(height: 32),

        // --- MEDICATIONS ---
        _buildHeading(t.cyA5MedH, textColor),
        _buildParagraph(t.cyA5MedP1, bodyColor),
        _buildBullet(t.cyA5MedB1T, t.cyA5MedB1B, bodyColor, textColor),
        _buildBullet(t.cyA5MedB2T, t.cyA5MedB2B, bodyColor, textColor),
        _buildBullet(t.cyA5MedB3T, t.cyA5MedB3B, bodyColor, textColor),
        _buildBullet(t.cyA5MedB4T, t.cyA5MedB4B, bodyColor, textColor),
        _buildBullet(t.cyA5MedB5T, t.cyA5MedB5B, bodyColor, textColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA5MedK1, bodyColor),
        _buildSimpleBullet(t.cyA5MedK2, bodyColor),
        _buildSimpleBullet(t.cyA5MedK3, bodyColor),
        const SizedBox(height: 32),

        // --- WHEN TO SEE A DOCTOR ---
        _buildHeading(t.cyA5DocH, textColor),
        _buildParagraph(t.cyA5DocP1, bodyColor),
        _buildSimpleBullet(t.cyA5DocL1, bodyColor),
        _buildSimpleBullet(t.cyA5DocL2, bodyColor),
        _buildSimpleBullet(t.cyA5DocL3, bodyColor),
        _buildSimpleBullet(t.cyA5DocL4, bodyColor),
        _buildSimpleBullet(t.cyA5DocL5, bodyColor),
        _buildSimpleBullet(t.cyA5DocL6, bodyColor),
        const SizedBox(height: 48),

        // --- SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Jain P, Chauhan AK, Singh K et al. Correlation of perceived stress with monthly cyclical changes. Journal of Family Medicine and Primary Care, 2023.", isDark),
        _buildSourceItem("• Gopal Anapana et al. Stress, sleep patterns, and reproductive health. International Journal of Zoology, 2025.", isDark),
        _buildSourceItem("• Addressing the effects of stress on menstrual cycle regularity. DigitalCommons@PCOM, 2025.", isDark),
        _buildSourceItem("• Nam GE, Han K, Lee G. Association between sleep duration and menstrual cycle irregularity. Sleep Medicine, 2017.", isDark),
        _buildSourceItem("• Maeng LY, Bhatt P et al. Menstrual disturbances and its association with sleep disturbances. BMC Women's Health, 2023.", isDark),
        _buildSourceItem("• Mahoney MM. Shift work, jet lag, and female reproduction. International Journal of Endocrinology, 2010.", isDark),
        _buildSourceItem("• Nagata C et al. Social jetlag and menstrual symptoms among female university students. PubMed, 2018.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• Samphire Neuroscience — How Irregular Sleep Affects Your Menstrual Cycle (2025)", isDark),
        _buildSourceItem("• Samphire Neuroscience — Does Traveling Affect Your Period? (2025)", isDark),
        _buildSourceItem("• Clue by Biowink — How Travel and Jet Lag Can Affect Your Period", isDark),
        _buildSourceItem("• Elara Care — How Cortisol Affects Women's Health (2024)", isDark),
        _buildSourceItem("• Cleveland Clinic — Can Stress Cause You to Skip a Period", isDark),
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

  Widget _buildBullet(String boldText, String normalText, Color bodyColor, Color titleColor) {
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

  // --- CUSTOM EVIDENCE CHART ---
  Widget _buildEvidenceChart(AppLocalizations t, bool isDark) {
    final bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final primaryText = isDark ? Colors.white : Colors.black;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    // Brand Colors matched to the image
    final cPink = const Color(0xFFFF528A);
    final cOrange = const Color(0xFFE56A39);
    final cYellow = const Color(0xFFD99A29);
    final cBlue = const Color(0xFF4A89DF);
    final cGreen = const Color(0xFF5B9D3B);

    Widget buildBarRow(String label, double fillPercent, Color color, String strength) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: Row(
          children: [
            SizedBox(
              width: 105,
              child: Text(
                label,
                style: TextStyle(color: primaryText, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.transparent, width: 0.5),
                ),
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: fillPercent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 85,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  strength,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cyA5ChartTitle,
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            t.cyA5ChartSub,
            style: TextStyle(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Bars
          buildBarRow(t.cyA5ChartLStress, 0.92, cPink, t.cyA5StrVeryStrong),
          buildBarRow(t.cyA5ChartLSleep, 0.85, cPink, t.cyA5StrVeryStrong),
          buildBarRow(t.cyA5ChartLLowWt, 0.85, cOrange, t.cyA5StrStrong),
          buildBarRow(t.cyA5ChartLOverEx, 0.80, cOrange, t.cyA5StrStrong),
          buildBarRow(t.cyA5ChartLIllness, 0.70, cYellow, t.cyA5StrModerate),
          buildBarRow(t.cyA5ChartLTravel, 0.58, cYellow, t.cyA5StrModerate),
          buildBarRow(t.cyA5ChartLDiet, 0.52, cBlue, t.cyA5StrEmerging),
          buildBarRow(t.cyA5ChartLMildEx, 0.25, cGreen, t.cyA5StrProtective),

          const SizedBox(height: 12),
          Text(
            "Sources: DigitalCommons@PCOM Review (2025); BMC Women's Health Systematic Review (2023); Samphire Neuroscience Sleep Review (2025); Mahoney MM, PMC (2010)",
            style: TextStyle(color: secondaryText, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            t.cyA5ChartCaption,
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }
}
