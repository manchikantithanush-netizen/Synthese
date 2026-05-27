import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleOneView extends StatelessWidget {
  final bool isDark;
  const ArticleOneView({super.key, required this.isDark});

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
          t.cyA1Title,
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
          t.cyA1Sub,
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
        _buildHeading(t.cyA1S1H, textColor),
        _buildParagraph(t.cyA1S1P1, bodyColor),
        _buildParagraph(t.cyA1S1P2, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA1S1P3, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2 ---
        _buildHeading(t.cyA1S2H, textColor),
        _buildParagraph(t.cyA1S2P1, bodyColor),
        _buildBullet(t.cyA1S2B1T, t.cyA1S2B1B, bodyColor, textColor),
        _buildBullet(t.cyA1S2B2T, t.cyA1S2B2B, bodyColor, textColor),
        _buildBullet(t.cyA1S2B3T, t.cyA1S2B3B, bodyColor, textColor),
        _buildBullet(t.cyA1S2B4T, t.cyA1S2B4B, bodyColor, textColor),
        const SizedBox(height: 32),

        // --- SECTION 3 ---
        _buildHeading(t.cyA1S3H, textColor),
        _buildParagraph(t.cyA1S3P1, bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph(t.cyA1S3P2, bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph(t.cyA1S3P3, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 4 ---
        _buildHeading(t.cyA1S4H, textColor),
        _buildParagraph(t.cyA1S4P1, bodyColor),
        _buildParagraph(t.cyA1S4P2, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA1S4P3, bodyColor, citation: "Amegroups"),
        const SizedBox(height: 24),

        // --- THE GRAPH ---
        _buildAppleGraph(t, isDark),

        const SizedBox(height: 24),
        _buildParagraph(t.cyA1S4P4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 5 ---
        _buildHeading(t.cyA1S5H, textColor),
        _buildParagraph(t.cyA1S5P1, bodyColor, citation: "Cleveland Clinic"),
        _buildParagraph(t.cyA1S5P2, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6 ---
        _buildHeading(t.cyA1S6H, textColor),
        _buildParagraph(t.cyA1S6P1, bodyColor, citation: "PubMed Central"),
        _buildParagraph(t.cyA1S6P2, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA1S6P3, bodyColor, citation: "UChicago Medicine"),

        const SizedBox(height: 12),
        Text(t.cyArtKeyPoints, style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA1S6KP1, bodyColor),
        _buildSimpleBullet(t.cyA1S6KP2, bodyColor),
        _buildSimpleBullet(t.cyA1S6KP3, bodyColor),
        _buildSimpleBullet(t.cyA1S6KP4, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7 ---
        _buildHeading(t.cyA1S7H, textColor),
        _buildParagraph(t.cyA1S7P1, bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 8 ---
        _buildHeading(t.cyA1S8H, textColor),
        _buildParagraph(t.cyA1S8P1, bodyColor),
        _buildSimpleBullet(t.cyA1S8L1, bodyColor),
        _buildSimpleBullet(t.cyA1S8L2, bodyColor),
        _buildSimpleBullet(t.cyA1S8L3, bodyColor),
        _buildSimpleBullet(t.cyA1S8L4, bodyColor),
        _buildSimpleBullet(t.cyA1S8L5, bodyColor),
        _buildSimpleBullet(t.cyA1S8L6, bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 9: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Thiyagarajan DK, Basit H, Jeanmonod R. Physiology, Menstrual Cycle. StatPearls Publishing, Updated 2024.", isDark),
        _buildSourceItem("• Li H. et al. Menstrual cycle length variation by demographic characteristics from the Apple Women's Health Study. npj Digital Medicine, 2023.", isDark),
        _buildSourceItem("• Grieger JA et al. Real-world menstrual cycle characteristics of more than 600,000 menstrual cycles. npj Digital Medicine, 2019.", isDark),
        _buildSourceItem("• Kurmi M et al. Menstrual Cycle Characteristics of U.S. Adolescents. ScienceDirect, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• Harvard T.H. Chan School of Public Health — Apple Women's Health Study", isDark),
        _buildSourceItem("• Nemours KidsHealth — Irregular Periods for Teens", isDark),
        _buildSourceItem("• Cleveland Clinic — Menarche", isDark),
        _buildSourceItem("• AboutKidsHealth — The Menstrual Cycle", isDark),
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

  Widget _buildAppleGraph(AppLocalizations t, bool isDark) {
    final graphBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final axisTextColor = isDark ? Colors.white : Colors.black;
    final mutedTextColor = isDark ? Colors.white70 : Colors.black54;
    final pinkColor = const Color(0xFFFF2D55);
    final outlineColor = isDark ? Colors.white30 : Colors.black26;

    final List<Map<String, dynamic>> data = [
      {'age': t.cyA1GraphUnder20, 'val': 30.8, 'isUser': true},
      {'age': '20–24', 'val': 29.4, 'isUser': false},
      {'age': '25–29', 'val': 28.9, 'isUser': false},
      {'age': '30–34', 'val': 28.4, 'isUser': false},
      {'age': '35–39', 'val': 27.9, 'isUser': false},
      {'age': '40–44', 'val': 27.1, 'isUser': false},
    ];

    const double maxHeight = 110.0;
    const double minBase = 20.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: graphBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cyA1GraphTitle,
            style: TextStyle(
              color: axisTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 190,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final double val = d['val'];
                final bool isUser = d['isUser'];

                final double barHeight = ((val - minBase) / (30.8 - minBase)) * maxHeight;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${val}d",
                          style: TextStyle(
                            color: axisTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isUser ? pinkColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isUser ? null : Border.all(color: outlineColor, width: 1.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['age'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: pinkColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(t.cyA1GraphYourAge,
                  style:
                      TextStyle(color: axisTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    border: Border.all(color: outlineColor, width: 1.5),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(t.cyA1GraphOtherAge,
                  style:
                      TextStyle(color: axisTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Source: Li H. et al., npj Digital Medicine, 2023. doi:10.1038/s41746-023-00848-1",
            style: TextStyle(color: mutedTextColor, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Text(
            t.cyA1GraphCaption,
            style: TextStyle(
              color: axisTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
