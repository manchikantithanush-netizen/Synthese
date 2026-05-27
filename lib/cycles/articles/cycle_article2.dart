import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class ArticleTwoView extends StatelessWidget {
  final bool isDark;
  const ArticleTwoView({super.key, required this.isDark});

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
          t.cyA2Title,
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
          t.cyA2Sub,
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

        // --- OVERVIEW ---
        _buildHeading(t.cyA2OvH, textColor),
        _buildParagraph(t.cyA2OvP1, bodyColor),
        _buildParagraph(t.cyA2OvP2, bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph(t.cyA2OvP3, bodyColor),
        const SizedBox(height: 32),

        // --- PHASE 1 ---
        _buildHeading(t.cyA2P1H, textColor),
        Text(t.cyA2P1Meta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA2P1P1, bodyColor),
        _buildParagraph(t.cyA2P1P2, bodyColor, citation: "Amegroups"),
        _buildParagraph(t.cyA2P1P3, bodyColor, citation: "Nicklaus Children's Hospital"),

        Text(t.cyA2PhysLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA2P1Phys1, bodyColor),
        _buildSimpleBullet(t.cyA2P1Phys2, bodyColor),
        _buildSimpleBullet(t.cyA2P1Phys3, bodyColor),

        const SizedBox(height: 12),
        Text(t.cyA2EmoLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet(t.cyA2P1Emo1, bodyColor),
        _buildSimpleBullet(t.cyA2P1Emo2, bodyColor),
        const SizedBox(height: 32),

        // --- PHASE 2 ---
        _buildHeading(t.cyA2P2H, textColor),
        Text(t.cyA2P2Meta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA2P2P1, bodyColor),
        _buildParagraph(t.cyA2P2P2, bodyColor, citation: "Drugs.com"),
        _buildParagraph(t.cyA2P2P3, bodyColor, citation: "ScienceDirect"),
        _buildParagraph(t.cyA2P2P4, bodyColor, citation: "Nicklaus Children's Hospital"),

        const SizedBox(height: 24),

        // --- THE HORMONE GRAPH ---
        _buildHormoneGraph(t, isDark),

        const SizedBox(height: 24),

        _buildBullet(t.cyA2P2KeyT, t.cyA2P2KeyB, bodyColor, textColor, citation: "Cleveland Clinic"),
        const SizedBox(height: 32),

        // --- PHASE 3 ---
        _buildHeading(t.cyA2P3H, textColor),
        Text(t.cyA2P3Meta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA2P3P1, bodyColor),
        _buildParagraph(t.cyA2P3P2, bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph(t.cyA2P3P3, bodyColor, citation: "Amegroups"),
        _buildParagraph(t.cyA2P3P4, bodyColor, citation: "Nicklaus Children's Hospital"),
        const SizedBox(height: 32),

        // --- PHASE 4 ---
        _buildHeading(t.cyA2P4H, textColor),
        Text(t.cyA2P4Meta,
          style: TextStyle(color: metaColor, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph(t.cyA2P4P1, bodyColor),
        _buildParagraph(t.cyA2P4P2, bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph(t.cyA2P4P3, bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph(t.cyA2P4P4, bodyColor, citation: "ACOG"),
        _buildParagraph(t.cyA2P4P5, bodyColor, citation: "ACOG"),
        _buildParagraph(t.cyA2P4P6, bodyColor, citation: "UChicago Medicine"),
        const SizedBox(height: 32),

        // --- SECTION 8 ---
        _buildHeading(t.cyA2S8H, textColor),
        _buildSimpleBullet(t.cyA2S8L1, bodyColor),
        _buildSimpleBullet(t.cyA2S8L2, bodyColor),
        _buildSimpleBullet(t.cyA2S8L3, bodyColor),
        _buildParagraph(t.cyA2S8P1, bodyColor, citation: "Stanford Medicine Children's Health"),
        const SizedBox(height: 48),

        // --- SECTION 9: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text(t.cyArtSourcesTitle, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem(t.cyArtPrimaryResearch, isDark),
        _buildSourceItem("• Thiyagarajan DK et al. Physiology, Menstrual Cycle. StatPearls, 2024.", isDark),
        _buildSourceItem("• Pritschet L et al. Hormonal modulation of prefrontal cortex function across the menstrual cycle. Nature Neuroscience, 2024.", isDark),
        _buildSourceItem("• Gava G et al. Premenstrual Syndrome. StatPearls Publishing, 2023.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem(t.cyArtClinicalResources, isDark),
        _buildSourceItem("• Stanford Medicine Children's Health — The Menstrual Cycle", isDark),
        _buildSourceItem("• Cleveland Clinic — Follicular Phase", isDark),
        _buildSourceItem("• Nicklaus Children's Hospital — Menstrual Disorders in Adolescents", isDark),
        _buildSourceItem("• American Academy of Family Physicians — PMS Management", isDark),
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

  Widget _buildHormoneGraph(AppLocalizations t, bool isDark) {
    final graphBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final axisTextColor = isDark ? Colors.white : Colors.black;
    final pinkColor = const Color(0xFFFF2D55);
    final blueColor = const Color(0xFF007AFF);
    final orangeColor = const Color(0xFFFF9500);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: graphBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
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
            t.cyA2GraphTitle,
            style: TextStyle(color: axisTextColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // Phase labels
          Row(
            children: [
              _phaseLabel(t.cyA2GraphMenstrual, const Color(0xFF3D262E), 1.5),
              const SizedBox(width: 2),
              _phaseLabel(t.cyA2GraphFollicular, const Color(0xFF242E3D), 3.0),
              const SizedBox(width: 2),
              _phaseLabel(t.cyA2GraphOv, const Color(0xFF3D3624), 0.8),
              const SizedBox(width: 2),
              _phaseLabel(t.cyA2GraphLuteal, const Color(0xFF2B3D24), 2.5),
            ],
          ),
          const SizedBox(height: 20),
          // The visual chart
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: HormonePainter(
                blue: blueColor,
                pink: pinkColor,
                orange: orangeColor,
                isDark: isDark
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendItem(t.cyA2GraphEstrogen, blueColor),
              _legendItem(t.cyA2GraphProgesterone, pinkColor),
              _legendItem(t.cyA2GraphLH, orangeColor, isDashed: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t.cyA2GraphCaption,
            style: TextStyle(color: axisTextColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _phaseLabel(String text, Color color, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _legendItem(String text, Color color, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 2,
          decoration: BoxDecoration(
            color: isDashed ? null : color,
            border: isDashed ? Border(bottom: BorderSide(color: color, width: 2, style: BorderStyle.solid)) : null,
          ),
          child: isDashed ? Row(children: List.generate(3, (i) => Expanded(child: Container(color: i % 2 == 0 ? color : Colors.transparent, height: 2)))) : null,
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    );
  }
}

// Custom Painter to draw the hormone curves
class HormonePainter extends CustomPainter {
  final Color blue, pink, orange;
  final bool isDark;
  HormonePainter({required this.blue, required this.pink, required this.orange, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()..color = blue..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final paintPink = Paint()..color = pink..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final paintOrange = Paint()..color = orange..style = PaintingStyle.stroke..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    // Grid lines (optional but adds to the look)
    final gridPaint = Paint()..color = isDark ? Colors.white10 : Colors.black12..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(0, h * i / 4), Offset(w, h * i / 4), gridPaint);
    }

    // Estrogen Curve (Blue)
    final pathEstrogen = Path();
    pathEstrogen.moveTo(0, h * 0.8);
    pathEstrogen.quadraticBezierTo(w * 0.2, h * 0.8, w * 0.35, h * 0.5); // Rise
    pathEstrogen.quadraticBezierTo(w * 0.48, h * 0.1, w * 0.52, h * 0.1); // Peak
    pathEstrogen.quadraticBezierTo(w * 0.55, h * 0.5, w * 0.7, h * 0.8); // Drop
    pathEstrogen.lineTo(w, h * 0.85);
    canvas.drawPath(pathEstrogen, paintBlue);

    // Progesterone Curve (Pink)
    final pathProgesterone = Path();
    pathProgesterone.moveTo(0, h * 0.9);
    pathProgesterone.lineTo(w * 0.52, h * 0.9); // Low during follicular
    pathProgesterone.quadraticBezierTo(w * 0.65, h * 0.1, w * 0.75, h * 0.1); // Rise in Luteal
    pathProgesterone.quadraticBezierTo(w * 0.85, h * 0.1, w, h * 0.9); // Drop
    canvas.drawPath(pathProgesterone, paintPink);

    // LH Surge (Orange - Dashed simplified)
    final pathLH = Path();
    pathLH.moveTo(w * 0.48, h * 0.85);
    pathLH.lineTo(w * 0.5, h * 0.3); // Sharp peak
    pathLH.lineTo(w * 0.52, h * 0.85);
    canvas.drawPath(pathLH, paintOrange);

    // Dot for ovulation
    canvas.drawCircle(Offset(w * 0.5, h * 0.3), 3, Paint()..color = orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
