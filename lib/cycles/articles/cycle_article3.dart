import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleThreeView extends StatelessWidget {
  final bool isDark;
  const ArticleThreeView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);
    final metaColor = isDark ? Colors.white70 : Colors.black54;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsetsDirectional.only(start: 24.0, end: 24.0, bottom: 60.0),
      children: [
        // --- MAIN TITLE ---
        Text(
          t.cyA3Title,
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
          t.cyA3Sub,
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
        _buildHeading(t.cyA3S1H, textColor),
        _buildParagraph(t.cyA3S1P1, bodyColor),
        _buildParagraph(t.cyA3S1P2, bodyColor, citation: "PubMed"),
        _buildParagraph(t.cyA3S1P3, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2 ---
        _buildHeading(t.cyA3S2H, textColor),
        _buildParagraph(t.cyA3S2P1, bodyColor),
        _buildParagraph(t.cyA3S2P2, bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph(t.cyA3S2P3, bodyColor),
        const SizedBox(height: 32),

        // --- FSH ---
        _buildHeading(t.cyA3FshH, textColor),
        Text(t.cyA3FshMeta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA3FshP1, bodyColor, citation: "Boston Children's Hospital"),
        _buildParagraph(t.cyA3FshP2, bodyColor),
        _buildParagraph(t.cyA3FshP3, bodyColor, citation: "Cleveland Clinic"),

        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3FshL1, bodyColor),
        _buildSimpleBullet(t.cyA3FshL2, bodyColor),
        _buildSimpleBullet(t.cyA3FshL3, bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildSimpleBullet(t.cyA3FshL4, bodyColor),
        const SizedBox(height: 32),

        // --- LH ---
        _buildHeading(t.cyA3LhH, textColor),
        Text(t.cyA3LhMeta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA3LhP1, bodyColor),
        _buildParagraph(t.cyA3LhP2, bodyColor, citation: "ScienceDirect"),
        _buildParagraph(t.cyA3LhP3, bodyColor, citation: "Drugs.com"),
        _buildParagraph(t.cyA3LhP4, bodyColor),
        _buildParagraph(t.cyA3LhP5, bodyColor, citation: "Boston Children's Hospital"),

        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3LhL1, bodyColor),
        _buildSimpleBullet(t.cyA3LhL2, bodyColor),
        _buildSimpleBullet(t.cyA3LhL3, bodyColor),
        _buildSimpleBullet(t.cyA3LhL4, bodyColor),
        const SizedBox(height: 32),

        // --- ESTROGEN ---
        _buildHeading(t.cyA3EstH, textColor),
        Text(t.cyA3EstMeta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA3EstP1, bodyColor),
        _buildParagraph(t.cyA3EstP2, bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph(t.cyA3EstP3, bodyColor, citation: "ACOG"),
        _buildParagraph(t.cyA3EstP4, bodyColor, citation: "Medscape"),

        Text(t.cyA3EstBodyLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3EstBody1, bodyColor),
        _buildSimpleBullet(t.cyA3EstBody2, bodyColor),
        _buildSimpleBullet(t.cyA3EstBody3, bodyColor),
        _buildSimpleBullet(t.cyA3EstBody4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA3EstBrainLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3EstBrain1, bodyColor),
        _buildSimpleBullet(t.cyA3EstBrain2, bodyColor),
        _buildSimpleBullet(t.cyA3EstBrain3, bodyColor),
        _buildSimpleBullet(t.cyA3EstBrain4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3EstKey1, bodyColor),
        _buildSimpleBullet(t.cyA3EstKey2, bodyColor),
        _buildSimpleBullet(t.cyA3EstKey3, bodyColor, citation: "PubMed Central"),
        _buildSimpleBullet(t.cyA3EstKey4, bodyColor),

        const SizedBox(height: 32),

        // --- THE CUSTOM GRID ---
        _buildHormonesGrid(t, isDark),

        const SizedBox(height: 32),

        // --- PROGESTERONE ---
        _buildHeading(t.cyA3ProgH, textColor),
        Text(t.cyA3ProgMeta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA3ProgP1, bodyColor),
        _buildParagraph(t.cyA3ProgP2, bodyColor, citation: "MDPI"),
        _buildParagraph(t.cyA3ProgP3, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA3ProgP4, bodyColor, citation: "PubMed Central"),

        Text(t.cyA3ProgBodyLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3ProgBody1, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBody2, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBody3, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBody4, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBody5, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA3ProgBrainLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3ProgBrain1, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBrain2, bodyColor),
        _buildSimpleBullet(t.cyA3ProgBrain3, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildSimpleBullet(t.cyA3ProgBrain4, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA3ProgKey1, bodyColor),
        _buildSimpleBullet(t.cyA3ProgKey2, bodyColor),
        _buildSimpleBullet(t.cyA3ProgKey3, bodyColor),
        _buildSimpleBullet(t.cyA3ProgKey4, bodyColor),
        const SizedBox(height: 32),

        // --- FEEDBACK LOOP ---
        _buildHeading(t.cyA3FbH, textColor),
        _buildParagraph(t.cyA3FbP1, bodyColor),
        _buildSimpleBullet(t.cyA3FbL1, bodyColor),
        _buildSimpleBullet(t.cyA3FbL2, bodyColor),
        _buildSimpleBullet(t.cyA3FbL3, bodyColor),
        _buildSimpleBullet(t.cyA3FbL4, bodyColor),
        _buildSimpleBullet(t.cyA3FbL5, bodyColor),
        _buildParagraph(t.cyA3FbP2, bodyColor, citation: "Stanford Medicine Children's Health"),
        const SizedBox(height: 32),

        // --- STRESS ---
        _buildHeading(t.cyA3StressH, textColor),
        _buildParagraph(t.cyA3StressP1, bodyColor),
        _buildParagraph(t.cyA3StressP2, bodyColor, citation: "UChicago Medicine"),
        _buildParagraph(t.cyA3StressP3, bodyColor),
        const SizedBox(height: 32),

        // --- WHEN TO SEE A DOCTOR ---
        _buildHeading(t.cyA3DocH, textColor),
        _buildSimpleBullet(t.cyA3DocL1, bodyColor),
        _buildSimpleBullet(t.cyA3DocL2, bodyColor),
        _buildSimpleBullet(t.cyA3DocL3, bodyColor),
        _buildSimpleBullet(t.cyA3DocL4, bodyColor, citation: "PubMed Central"),
        const SizedBox(height: 48),

        // --- SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Thiyagarajan DK, Basit H, Jeanmonod R. Physiology, Menstrual Cycle. StatPearls, 2024.", isDark),
        _buildSourceItem("• Kale MB, Wankhede NL et al. Unveiling the Neurotransmitter Symphony. Reproductive Sciences, Jan 2025.", isDark),
        _buildSourceItem("• Bendis PJ et al. The impact of estradiol on serotonin, glutamate, and dopamine systems. Frontiers in Neuroscience, 2024.", isDark),
        _buildSourceItem("• Sacher J, Zsido RG et al. Increase in serotonin transporter binding in patients with PMDD. Biological Psychiatry, 2023.", isDark),
        _buildSourceItem("• Pritschet L et al. Hormonal modulation of prefrontal cortex function across the menstrual cycle. Nature Neuroscience, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• UCSF Health — The Menstrual Cycle", isDark),
        _buildSourceItem("• Cleveland Clinic — Follicle-Stimulating Hormone (FSH)", isDark),
        _buildSourceItem("• Samphire Neuroscience — Hormonal Fluctuations and Their Role in PMS", isDark),
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

  Widget _buildSimpleBullet(String text, Color color, {String? citation}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12.0, start: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•  ", style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold, height: 1.45)),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: color, fontSize: 17, height: 1.45),
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

  // --- CUSTOM TABLE GRAPH RECREATION ---
  Widget _buildHormonesGrid(AppLocalizations t, bool isDark) {
    final containerBg = isDark ? const Color(0xFF262626) : const Color(0xFFF9F9F9);
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    // Phase Pill Colors
    final cMenstrual = isDark ? const Color(0xFF3D262E) : const Color(0xFFF5E6EC);
    final cFollicular = isDark ? const Color(0xFF242E3D) : const Color(0xFFE6F0F5);
    final cOvulation = isDark ? const Color(0xFF3D3624) : const Color(0xFFF5EFE6);
    final cLuteal = isDark ? const Color(0xFF2B3D24) : const Color(0xFFEBF5E6);

    // Hormone Title Colors
    final tEstrogen = const Color(0xFFFF2D55);
    final tFSH = const Color(0xFF007AFF);
    final tProgesterone = const Color(0xFF34C759);
    final tLH = const Color(0xFFFF9500);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cyA3GridTitle,
            style: TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(
            "Based on Kale MB et al., Reproductive Sciences, 2025 — doi:10.1007/s43032-024-01740-3",
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Phase Indicators
          Row(
            children: [
              _phaseLabel(t.cyA3GridMenstrual, cMenstrual, tEstrogen.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel(t.cyA3GridFollicular, cFollicular, tFSH.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel(t.cyA3GridOvulation, cOvulation, tLH.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel(t.cyA3GridLuteal, cLuteal, tProgesterone.withOpacity(isDark ? 0.8 : 1)),
            ],
          ),
          const SizedBox(height: 16),

          // The 2x2 Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _gridCard(
                  t.cyA3GridEstrogenT, tEstrogen, borderColor, primaryTextColor,
                  [t.cyA3GridEst1, t.cyA3GridEst2, t.cyA3GridEst3, t.cyA3GridEst4]
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gridCard(
                  t.cyA3GridProgesteroneT, tProgesterone, borderColor, primaryTextColor,
                  [t.cyA3GridProg1, t.cyA3GridProg2, t.cyA3GridProg3, t.cyA3GridProg4]
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _gridCard(
                  t.cyA3GridFshT, tFSH, borderColor, primaryTextColor,
                  [t.cyA3GridFsh1, t.cyA3GridFsh2, t.cyA3GridFsh3, t.cyA3GridFsh4]
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gridCard(
                  t.cyA3GridLhT, tLH, borderColor, primaryTextColor,
                  [t.cyA3GridLh1, t.cyA3GridLh2, t.cyA3GridLh3, t.cyA3GridLh4]
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Source: Kale MB et al. Unveiling the Neurotransmitter Symphony. Reproductive Sciences, 2025. Bendis et al. Frontiers in Neuroscience, 2024.",
            style: TextStyle(color: secondaryTextColor, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _phaseLabel(String text, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _gridCard(String title, Color titleColor, Color borderColor, Color textColor, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              item,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
            ),
          )),
        ],
      ),
    );
  }
}
