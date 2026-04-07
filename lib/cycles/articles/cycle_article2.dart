import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ArticleTwoView extends StatelessWidget {
  final bool isDark;
  const ArticleTwoView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 60.0),
      children: [
        // --- MAIN TITLE ---
        Text(
          "The Four Phases of Your Cycle",
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
          "What your body is doing every single day of the month",
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
        _buildHeading("Overview", textColor),
        _buildParagraph("Most people think of their menstrual cycle as just their period — a few uncomfortable days every month. But your period is only one of four distinct phases that your body moves through every single cycle. Each phase has its own hormonal environment, its own physical changes, and its own emotional signature.", bodyColor),
        _buildParagraph("The menstrual cycle comprises two distinct cycles — one within the ovary and another within the endometrium. The phases of the ovarian cycle include the follicular phase, ovulation, and the luteal phase, while the endometrial cycle consists of the proliferative phase, the secretory phase, and the menstrual phase. These phases are coordinated with each other and run simultaneously.", bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph("In everyday language, these are grouped into four phases: menstrual, follicular, ovulation, and the luteal phase. Here is what happens in each one.", bodyColor),
        const SizedBox(height: 32),

        // --- PHASE 1 ---
        _buildHeading("Phase 1 — The Menstrual Phase", textColor),
        Text("Days 1 to 3–7  |  Hormone profile: Estrogen low, progesterone low", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph("This is Day 1. The first day of your period is officially the first day of your entire cycle — not the end of it.", bodyColor),
        _buildParagraph("The menstrual phase starts with the shedding of the uterine lining, which occurs when a drop in estrogen and progesterone signals the uterus to shed its endometrial lining. The average blood loss during a period is around 2 to 3 tablespoons.", bodyColor, citation: "Amegroups"),
        _buildParagraph("How long a period lasts varies by person, but most periods last 3 to 7 days, with 5 to 6 days being most common. If your period consistently lasts longer than 8 days or is very heavy, consult your healthcare provider.", bodyColor, citation: "Nicklaus Children's Hospital"),
        
        Text("What you might feel physically:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Cramping in the lower abdomen and back — caused by prostaglandins, chemicals that trigger uterine contractions.", bodyColor),
        _buildSimpleBullet("Fatigue and low energy — your body is doing real physiological work.", bodyColor),
        _buildSimpleBullet("Flow that is heavier at the start and lighter toward the end.", bodyColor),
        
        const SizedBox(height: 12),
        Text("What you might feel emotionally:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Lower mood and reduced motivation as both estrogen and progesterone are at their lowest point.", bodyColor),
        _buildSimpleBullet("Increased sensitivity and a desire to rest and withdraw.", bodyColor),
        const SizedBox(height: 32),

        // --- PHASE 2 ---
        _buildHeading("Phase 2 — The Follicular Phase", textColor),
        Text("Days 1 to ~14  |  Hormone profile: Estrogen rising, FSH active", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph("The follicular phase begins on the same day as your period and runs until ovulation. The name comes from follicles: tiny fluid-filled sacs in your ovaries, each containing an immature egg.", bodyColor),
        _buildParagraph("This phase starts when the brain releases follicle-stimulating hormone (FSH). This stimulates the ovaries to produce around 5 to 20 small follicles. Only the healthiest egg will eventually mature — the rest are reabsorbed. The average follicular phase lasts about 16 days, ranging from 11 to 27 days depending on the cycle.", bodyColor, citation: "Drugs.com"),
        _buildParagraph("The development of the dominant follicle happens in three stages: recruitment (days 1 to 4), selection (days 5 to 7), and dominance (from day 8 onward). By cycle day 8, one follicle exerts dominance by promoting its own growth and suppressing others.", bodyColor, citation: "ScienceDirect"),
        _buildParagraph("A groundbreaking 2024 study found that during the pre-ovulatory phase (the end of the follicular phase), brain network connectivity and complexity are at their highest. You're not just having a good week by chance — your brain is operating in its most responsive state.", bodyColor, citation: "Nicklaus Children's Hospital"),

        const SizedBox(height: 24),
        
        // --- THE HORMONE GRAPH ---
        _buildHormoneGraph(isDark),

        const SizedBox(height: 24),

        _buildBullet("Key point", "The length of this phase varies most between individuals. The luteal phase is usually stable at 14 days — so variability in overall cycle length comes almost entirely from the follicular phase.", bodyColor, textColor, citation: "Cleveland Clinic"),
        const SizedBox(height: 32),

        // --- PHASE 3 ---
        _buildHeading("Phase 3 — Ovulation", textColor),
        Text("Day ~14  |  Hormone profile: LH surge, estrogen peaks then drops", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph("Ovulation is a single event, not a phase — it lasts only 12 to 24 hours. But it is the central event of the entire cycle. Everything before it builds toward it, and everything after is a response to it.", bodyColor),
        _buildParagraph("Ovulation typically occurs approximately 36 to 44 hours after the onset of the LH surge. At the end of ovulation, levels of estradiol decrease. Cervical changes result in increased, watery cervical mucus to facilitate sperm entry.", bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph("In the middle of the cycle, a surge of luteinizing hormone triggers the release of a mature egg from the dominant follicle in one of the ovaries. The egg travels down the fallopian tube where it stays for 12 to 24 hours.", bodyColor, citation: "Amegroups"),
        _buildParagraph("Only about 13% of people have exactly 28-day cycles, so significant variation in ovulation timing is completely normal.", bodyColor, citation: "Nicklaus Children's Hospital"),
        const SizedBox(height: 32),

        // --- PHASE 4 ---
        _buildHeading("Phase 4 — The Luteal Phase", textColor),
        Text("Days ~15 to 28  |  Hormone profile: Progesterone dominant", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 12),
        _buildParagraph("After ovulation, the follicle that released the egg transforms into a temporary gland called the corpus luteum, which begins producing progesterone. This is the phase most people feel the most.", bodyColor),
        _buildParagraph("The empty follicle produces progesterone and some estrogen to support a potential pregnancy. If no pregnancy occurs, it breaks down after about 9 to 11 days. The luteal phase often lasts about 14 days but can range between 9 and 16 days.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("PMS is likely influenced by the action of progesterone on neurotransmitters including GABA, serotonin, and dopamine. Clinical trials show that serotonin levels shift significantly during this phase, linking PMS to mood changes.", bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph("A 2024 study published in Nature Neuroscience found measurable structural changes in the brain during the luteal phase. Luteal phase symptoms aren't \"all in your head\" — they're rooted in real neurobiological changes driven by hormones.", bodyColor, citation: "ACOG"),
        _buildParagraph("Food cravings, especially for carbohydrates and sugar, are common as progesterone and serotonin fluctuations drive appetite during this phase.", bodyColor, citation: "ACOG"),
        _buildParagraph("Large surveys show up to 90% of people who menstruate experience at least one PMS symptom like anger, irritability, or bloating.", bodyColor, citation: "UChicago Medicine"),
        const SizedBox(height: 32),

        // --- SECTION 8 ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildSimpleBullet("Your periods are consistently causing pain severe enough to miss school or daily activities.", bodyColor),
        _buildSimpleBullet("Luteal phase mood symptoms are significantly affecting your relationships or mental health.", bodyColor),
        _buildSimpleBullet("You experience no recognisable phase pattern (no energy shifts or mucus changes).", bodyColor),
        _buildParagraph("In some cases, ovulation may not occur, resulting in anovulatory cycles. These are common in the first 12 to 18 months after the first period. If you are well past your first year and symptoms suggest you aren't ovulating, a doctor can investigate.", bodyColor, citation: "Stanford Medicine Children's Health"),
        const SizedBox(height: 48),

        // --- SECTION 9: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Thiyagarajan DK et al. Physiology, Menstrual Cycle. StatPearls, 2024.", isDark),
        _buildSourceItem("• Pritschet L et al. Hormonal modulation of prefrontal cortex function across the menstrual cycle. Nature Neuroscience, 2024.", isDark),
        _buildSourceItem("• Gava G et al. Premenstrual Syndrome. StatPearls Publishing, 2023.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
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
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
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

  Widget _buildHormoneGraph(bool isDark) {
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
            "Hormone levels across a 28-day menstrual cycle",
            style: TextStyle(color: axisTextColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // Phase labels
          Row(
            children: [
              _phaseLabel("Menstrual", const Color(0xFF3D262E), 1.5),
              const SizedBox(width: 2),
              _phaseLabel("Follicular", const Color(0xFF242E3D), 3.0),
              const SizedBox(width: 2),
              _phaseLabel("Ov.", const Color(0xFF3D3624), 0.8),
              const SizedBox(width: 2),
              _phaseLabel("Luteal", const Color(0xFF2B3D24), 2.5),
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
              _legendItem("Estrogen", blueColor),
              _legendItem("Progesterone", pinkColor),
              _legendItem("LH surge", orangeColor, isDashed: true),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Estrogen peaks just before ovulation, the LH surge triggers egg release, then progesterone takes over for the luteal phase.",
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