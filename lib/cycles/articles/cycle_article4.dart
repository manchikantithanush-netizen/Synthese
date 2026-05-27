import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleFourView extends StatelessWidget {
  final bool isDark;
  const ArticleFourView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);
    final highlightColor = const Color(0xFFFF2D55); // Pink accent for spotting theme

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, bottom: 60.0),
      children: [
        // --- MAIN TITLE ---
        Text(
          t.cyA4Title,
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
          t.cyA4Sub,
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

        // --- SECTION 1: WHAT IT IS ---
        _buildHeading(t.cyA4S1H, textColor),
        _buildParagraph(t.cyA4S1P1, bodyColor),
        _buildParagraph(t.cyA4S1P2, bodyColor, citation: "ScienceDirect"),
        _buildParagraph(t.cyA4S1P3, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2: TABLE ---
        _buildHeading(t.cyA4S2H, textColor),
        _buildParagraph(t.cyA4S2P1, bodyColor),
        const SizedBox(height: 8),

        _buildComparisonTable(t, isDark, highlightColor, textColor),

        const SizedBox(height: 16),
        _buildParagraph(t.cyA4S2P2, bodyColor, citation: "Cleveland Clinic"),
        const SizedBox(height: 32),

        // --- SECTION 3: COMMON CAUSES ---
        _buildHeading(t.cyA4S3H, textColor),

        _buildSubheading(t.cyA4Sub1, textColor),
        _buildParagraph(t.cyA4Sub1P1, bodyColor, citation: "Amegroups"),
        _buildParagraph(t.cyA4Sub1P2, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA4Sub1P3, bodyColor, citation: "Stanford Medicine Children's Health"),
        Text(t.cyA4LooksLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA4Sub1L1, bodyColor),
        _buildSimpleBullet(t.cyA4Sub1L2, bodyColor),
        _buildSimpleBullet(t.cyA4Sub1L3, bodyColor),
        _buildSimpleBullet(t.cyA4Sub1L4, bodyColor),
        const SizedBox(height: 24),

        _buildSubheading(t.cyA4Sub2, textColor),
        _buildParagraph(t.cyA4Sub2P1, bodyColor),
        const SizedBox(height: 12),

        _buildSubheading(t.cyA4Sub3, textColor),
        _buildParagraph(t.cyA4Sub3P1, bodyColor),
        const SizedBox(height: 12),

        _buildSubheading(t.cyA4Sub4, textColor),
        _buildParagraph(t.cyA4Sub4P1, bodyColor),
        const SizedBox(height: 12),

        _buildSubheading(t.cyA4Sub5, textColor),
        _buildParagraph(t.cyA4Sub5P1, bodyColor, citation: "ACOG"),
        _buildParagraph(t.cyA4Sub5P2, bodyColor),
        _buildParagraph(t.cyA4Sub5P3, bodyColor, citation: "UChicago Medicine"),
        _buildParagraph(t.cyA4Sub5P4, bodyColor, citation: "PubMed Central"),
        const SizedBox(height: 32),

        // --- SECTION 4: LESS COMMON CAUSES ---
        _buildHeading(t.cyA4S4H, textColor),
        _buildSubheading(t.cyA4Sub6, textColor),
        _buildParagraph(t.cyA4Sub6P1, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA4Sub6P2, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA4Sub6P3, bodyColor),
        const SizedBox(height: 12),

        _buildSubheading(t.cyA4Sub7, textColor),
        _buildParagraph(t.cyA4Sub7P1, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA4Sub7P2, bodyColor),
        const SizedBox(height: 12),

        _buildSubheading(t.cyA4Sub8, textColor),
        _buildParagraph(t.cyA4Sub8P1, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 5: COLOURS ---
        _buildHeading(t.cyA4S5H, textColor),
        _buildParagraph(t.cyA4S5P1, bodyColor),
        _buildBullet(t.cyA4ColorPinkT, t.cyA4ColorPinkB, bodyColor, textColor),
        _buildBullet(t.cyA4ColorRedT, t.cyA4ColorRedB, bodyColor, textColor),
        _buildBullet(t.cyA4ColorBrownT, t.cyA4ColorBrownB, bodyColor, textColor),
        _buildBullet(t.cyA4ColorDarkT, t.cyA4ColorDarkB, bodyColor, textColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA4S5K1, bodyColor),
        _buildSimpleBullet(t.cyA4S5K2, bodyColor),
        _buildSimpleBullet(t.cyA4S5K3, bodyColor),
        _buildSimpleBullet(t.cyA4S5K4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6: NORMAL SPOTTING ---
        _buildHeading(t.cyA4S6H, textColor),
        _buildSimpleBullet(t.cyA4S6L1, bodyColor),
        _buildSimpleBullet(t.cyA4S6L2, bodyColor),
        _buildSimpleBullet(t.cyA4S6L3, bodyColor),
        _buildSimpleBullet(t.cyA4S6L4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7: WHEN TO SEE A DOCTOR ---
        _buildHeading(t.cyA4S7H, textColor),
        _buildParagraph(t.cyA4S7P1, bodyColor),
        _buildSimpleBullet(t.cyA4S7L1, bodyColor),
        _buildSimpleBullet(t.cyA4S7L2, bodyColor),
        _buildSimpleBullet(t.cyA4S7L3, bodyColor),
        _buildSimpleBullet(t.cyA4S7L4, bodyColor),
        _buildSimpleBullet(t.cyA4S7L5, bodyColor),

        const SizedBox(height: 16),
        _buildParagraph(t.cyA4S7P2, bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph(t.cyA4S7P3, bodyColor),

        const SizedBox(height: 16),
        _buildParagraph(t.cyA4S7P4, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA4S7P5, bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 8: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Jones K, et al. Anovulatory Bleeding. StatPearls Publishing, Updated 2023.", isDark),
        _buildSourceItem("• Ardestani S, Dason ES, Sobel M. Postcoital bleeding. CMAJ, September 11, 2023.", isDark),
        _buildSourceItem("• Zhang CY, Li H et al. Abnormal uterine bleeding patterns determined through menstrual tracking... American Journal of Obstetrics and Gynecology, 2023.", isDark),
        _buildSourceItem("• Aggarwal P, Ben Amor A. Cervical Ectropion. StatPearls Publishing, Updated 2023.", isDark),
        _buildSourceItem("• Owens GL, Wood NJ, Martin-Hirsch P. Investigation and management of postcoital bleeding. Obstet Gynaecol, 2022.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• Cleveland Clinic — Spotting During Ovulation (2025)", isDark),
        _buildSourceItem("• Cleveland Clinic — Cervical Ectropion (2025)", isDark),
        _buildSourceItem("• Medical News Today — Ovulation Bleeding (2024)", isDark),
        _buildSourceItem("• Clue by Biowink — Common Causes of Spotting (2024)", isDark),
        _buildSourceItem("• Fertility Institute of New Orleans — 10 Causes of Mid-Cycle Spotting (2025)", isDark),
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

  Widget _buildSubheading(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
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

  // --- CUSTOM COMPARISON TABLE ---
  Widget _buildComparisonTable(AppLocalizations t, bool isDark, Color highlightColor, Color textColor) {
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7);
    final rowBgColor = isDark ? const Color(0xFF252528) : Colors.white;

    TableRow buildHeaderRow() {
      return TableRow(
        decoration: BoxDecoration(
          color: headerBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        children: [
          _buildTableCell("", textColor, isHeader: true),
          _buildTableCell(t.cyA4TblSpotting, textColor, isHeader: true),
          _buildTableCell(t.cyA4TblPeriod, textColor, isHeader: true),
        ],
      );
    }

    TableRow buildRow(String feature, String spotting, String period) {
      return TableRow(
        decoration: BoxDecoration(
          color: rowBgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        children: [
          _buildTableCell(feature, textColor, isBold: true),
          _buildTableCell(spotting, textColor),
          _buildTableCell(period, textColor),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
          },
          children: [
            buildHeaderRow(),
            buildRow(t.cyA4TblVolumeF, t.cyA4TblVolumeS, t.cyA4TblVolumeP),
            buildRow(t.cyA4TblColourF, t.cyA4TblColourS, t.cyA4TblColourP),
            buildRow(t.cyA4TblDurationF, t.cyA4TblDurationS, t.cyA4TblDurationP),
            buildRow(t.cyA4TblClotsF, t.cyA4TblClotsS, t.cyA4TblClotsP),
            buildRow(t.cyA4TblTimingF, t.cyA4TblTimingS, t.cyA4TblTimingP),
            buildRow(t.cyA4TblCrampingF, t.cyA4TblCrampingS, t.cyA4TblCrampingP),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, Color textColor, {bool isHeader = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      child: Text(
        text,
        style: TextStyle(
          color: isHeader ? textColor.withOpacity(0.7) : textColor,
          fontSize: isHeader ? 13 : 14,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.w400,
          height: 1.3,
        ),
      ),
    );
  }
}
