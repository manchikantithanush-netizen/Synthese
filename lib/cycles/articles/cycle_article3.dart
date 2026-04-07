import 'package:flutter/material.dart';

class ArticleThreeView extends StatelessWidget {
  final bool isDark;
  const ArticleThreeView({super.key, required this.isDark});

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
          "Hormones and Your Cycle",
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
          "What estrogen, progesterone, LH, and FSH actually do — and why they affect your entire life",
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
        _buildHeading("Why hormones matter beyond reproduction", textColor),
        _buildParagraph("Most people think of reproductive hormones as purely physical — they control your period, full stop. The reality is far more interesting. The hormones that drive your menstrual cycle are neuroactive steroids: they cross the blood-brain barrier, act directly on the brain, and shape your mood, memory, motivation, sleep, appetite, and pain sensitivity throughout the month.", bodyColor),
        _buildParagraph("The menstrual cycle is an intricate biological process governed by hormonal changes that affect different facets of the female reproductive system — but also broad effects on psychology, cognition, and emotional experience across each phase.", bodyColor, citation: "PubMed"),
        _buildParagraph("There are four primary hormones to understand. Two are produced in the brain. Two are produced in the ovaries. Together they form a continuous feedback loop that runs without stopping from your first period to your last.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2 ---
        _buildHeading("The hormonal command chain", textColor),
        _buildParagraph("Before getting to the four main hormones, it helps to understand that the system has a clear hierarchy. It starts in the brain, not the ovaries.", bodyColor),
        _buildParagraph("Hormonal regulation begins in the hypothalamus, where gonadotropin-releasing hormone (GnRH) is secreted in a pulsatile fashion starting at puberty. GnRH is transported to the anterior pituitary, where it signals the pituitary gland to release follicle-stimulating hormone (FSH) and luteinizing hormone (LH). FSH and LH then travel through the bloodstream to the ovaries, stimulating the production of sex steroid hormones from follicular cells.", bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph("In plain terms: your brain sends a signal, which tells your pituitary gland to release two hormones, which travel to your ovaries, which produce estrogen and progesterone, which feed back to the brain to regulate the next signal. This loop repeats every cycle.", bodyColor),
        const SizedBox(height: 32),

        // --- FSH ---
        _buildHeading("Hormone 1 — FSH (Follicle-Stimulating Hormone)", textColor),
        Text("Produced by: The pituitary gland, located at the base of the brain\nPrimary role: Stimulating egg development", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph("FSH's main function is to help regulate the menstrual cycle. Specifically, FSH stimulates follicles on the ovary to grow and prepare the eggs for ovulation. As the follicles increase in size, they begin to release estrogen and a low level of progesterone into the bloodstream.", bodyColor, citation: "Boston Children's Hospital"),
        _buildParagraph("FSH is highest at the very start of your cycle, when estrogen is at its lowest. This is the brain's response to the hormonal drop at the end of the previous cycle — it detects low estrogen and sends FSH to restart follicle development.", bodyColor),
        _buildParagraph("One follicle will soon begin to grow faster than the others. This is called the dominant follicle. As the follicle grows, blood levels of estrogen rise significantly by cycle day seven. This increase in estrogen begins to inhibit the secretion of FSH. The fall in FSH allows smaller follicles to die off — they are, in effect, starved of FSH.", bodyColor, citation: "Cleveland Clinic"),
        
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("FSH rises at the start of each cycle to kickstart follicle growth.", bodyColor),
        _buildSimpleBullet("Only the strongest follicle survives the natural FSH drop — all others are reabsorbed.", bodyColor),
        _buildSimpleBullet("FSH also induces the development of LH receptors within the dominant follicle, preparing it for the next step — ovulation.", bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildSimpleBullet("Abnormally high FSH levels can indicate reduced ovarian reserve — something doctors check during fertility investigations.", bodyColor),
        const SizedBox(height: 32),

        // --- LH ---
        _buildHeading("Hormone 2 — LH (Luteinizing Hormone)", textColor),
        Text("Produced by: The pituitary gland\nPrimary role: Triggering ovulation and supporting the corpus luteum", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph("LH is the hormone responsible for the single most important event in the cycle: the release of the egg.", bodyColor),
        _buildParagraph("Levels of estrogen, particularly estradiol, increase exponentially in the late follicular phase. When high levels of estradiol trigger LH secretion by gonadotropes — a positive feedback mechanism — this results in a massive LH surge, usually over 36 to 48 hours.", bodyColor, citation: "ScienceDirect"),
        _buildParagraph("The onset of the LH surge usually precedes ovulation by 36 hours. The peak of the LH surge precedes ovulation by 10 to 12 hours. The LH surge stimulates luteinization of the granulosa cells and stimulates the synthesis of progesterone.", bodyColor, citation: "Drugs.com"),
        _buildParagraph("This is why ovulation predictor kits (OPKs) work — they detect the LH surge in urine, giving you a 24 to 36 hour window of advance warning before ovulation occurs.", bodyColor),
        _buildParagraph("After ovulation, LH's role shifts. After ovulation, the ruptured follicle forms a corpus luteum — a temporary endocrine gland — that produces high levels of progesterone. Progesterone blocks the release of FSH and helps prepare the uterine lining.", bodyColor, citation: "Boston Children's Hospital"),
        
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("The LH surge is the direct trigger for ovulation.", bodyColor),
        _buildSimpleBullet("It can be detected in urine using OPK tests 24 to 36 hours before egg release.", bodyColor),
        _buildSimpleBullet("After ovulation, LH maintains the corpus luteum and its progesterone production.", bodyColor),
        _buildSimpleBullet("If no pregnancy occurs, LH drops, the corpus luteum dies, and the cycle resets.", bodyColor),
        const SizedBox(height: 32),

        // --- ESTROGEN ---
        _buildHeading("Hormone 3 — Estrogen (Estradiol)", textColor),
        Text("Produced by: The ovarian follicles, and later the corpus luteum\nPrimary role: Building uterine lining and acting as a powerful brain modulator", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph("Estrogen is the hormone most people have heard of, but its effects are far broader than most people realise. It does not just prepare the uterus — it acts directly on the brain, influencing mood, cognition, and emotional regulation.", bodyColor),
        _buildParagraph("During the follicular phase, rising estrogen levels increase serotonin synthesis, enhancing mood, cognition, and pain tolerance. Estrogen may also influence dopamine levels, promoting motivation and reward sensitivity. GABA, involved in anxiety regulation, may be modulated by estrogen, inducing relaxation.", bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph("A landmark 2024 study published in Frontiers in Neuroscience confirmed that estradiol functions as a neuroactive steroid, playing a crucial role in modulating neurotransmitter systems affecting neuronal circuits and brain functions including learning, memory, reward, and social behaviour.", bodyColor, citation: "ACOG"),
        _buildParagraph("A separate study published in Nature Neuroscience in 2025 found that estrogen boosts dopamine-driven learning signals in the brain — providing a biological reason behind why motivation, focus, and mental clarity naturally ebb and flow throughout the month.", bodyColor, citation: "Medscape"),
        
        Text("What rising estrogen does to your body:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Thickens and builds the uterine lining (endometrium).", bodyColor),
        _buildSimpleBullet("Changes cervical mucus from thick and sticky to clear and stretchy.", bodyColor),
        _buildSimpleBullet("Improves skin clarity in the follicular phase.", bodyColor),
        _buildSimpleBullet("Increases bone density and cardiovascular protection over time.", bodyColor),
        
        const SizedBox(height: 12),
        Text("What rising estrogen does to your brain:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Boosts serotonin production — the neurotransmitter most associated with stable mood.", bodyColor),
        _buildSimpleBullet("Increases dopamine sensitivity — driving motivation, confidence, and reward-seeking.", bodyColor),
        _buildSimpleBullet("Enhances verbal memory, verbal fluency, and creative thinking.", bodyColor),
        _buildSimpleBullet("Reduces anxiety through its modulation of GABA.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Estrogen peaks twice: once just before ovulation (its highest point) and once mid-luteal phase.", bodyColor),
        _buildSimpleBullet("The follicular phase energy and mood boost most people feel is directly caused by rising estrogen.", bodyColor),
        _buildSimpleBullet("During the luteal phase, where estrogen levels are lower and progesterone levels are high, there is a corresponding decrease in serotonin levels — which is the neurobiological mechanism behind PMS mood symptoms.", bodyColor, citation: "PubMed Central"),
        _buildSimpleBullet("Estrogen acts on over 300 different tissues in the body — it is not just a reproductive hormone.", bodyColor),
        
        const SizedBox(height: 32),

        // --- THE CUSTOM GRID ---
        _buildHormonesGrid(isDark),

        const SizedBox(height: 32),

        // --- PROGESTERONE ---
        _buildHeading("Hormone 4 — Progesterone", textColor),
        Text("Produced by: The corpus luteum\nPrimary role: Maintaining uterine lining and producing most PMS symptoms", 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        _buildParagraph("Progesterone is the dominant hormone of the luteal phase and the hormone most responsible for the physical and emotional symptoms that most people associate with the days before their period.", bodyColor),
        _buildParagraph("After ovulation, the empty follicle transforms into the corpus luteum, which produces progesterone and some estrogen to support a potential pregnancy. The luteal phase is characterised by changes to hormone levels including a dramatic increase in progesterone, a decrease in FSH and LH, and changes to the endometrial lining.", bodyColor, citation: "MDPI"),
        _buildParagraph("Progesterone's effect on the brain is significant and often misunderstood. It does not simply cause bad moods — it acts on GABA receptors, the same receptors targeted by anti-anxiety medications. Progesterone and its metabolites interact with the GABAergic system, producing calming and sedating effects — which explains the fatigue and low motivation many people feel in the luteal phase.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("The problem occurs at the end of the luteal phase, when both progesterone and estrogen drop sharply. A 2023 study published in Biological Psychiatry found an 18% change in serotonin transporter density in the midbrain between the periovulatory and premenstrual phase — directly correlating with the severity of depressed mood premenstrually.", bodyColor, citation: "PubMed Central"),

        Text("What progesterone does to your body:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Maintains and matures the uterine lining for a possible pregnancy.", bodyColor),
        _buildSimpleBullet("Increases basal body temperature slightly after ovulation.", bodyColor),
        _buildSimpleBullet("Causes water retention and bloating.", bodyColor),
        _buildSimpleBullet("Increases sebum production — often causing pre-period breakouts.", bodyColor),
        _buildSimpleBullet("Raises appetite, particularly for carbohydrates and fats.", bodyColor),

        const SizedBox(height: 12),
        Text("What progesterone does to your brain:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Acts on GABA receptors, producing sedation and fatigue.", bodyColor),
        _buildSimpleBullet("Reduces serotonin availability — contributing to low mood, irritability, and sensitivity.", bodyColor),
        _buildSimpleBullet("Interacts with the dopaminergic system in complex ways — with varying effects on executive function.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildSimpleBullet("Drives carbohydrate cravings through its influence on serotonin precursors.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Progesterone is not the villain — it is doing its biological job correctly.", bodyColor),
        _buildSimpleBullet("PMS symptoms are the result of your brain's sensitivity to progesterone's effects on neurotransmitters, not a hormonal imbalance per se.", bodyColor),
        _buildSimpleBullet("The drop in progesterone at the end of the cycle is what triggers menstruation.", bodyColor),
        _buildSimpleBullet("If the corpus luteum persists (due to pregnancy), progesterone stays high — this is why periods stop during pregnancy.", bodyColor),
        const SizedBox(height: 32),

        // --- FEEDBACK LOOP ---
        _buildHeading("How it all connects — the feedback loop", textColor),
        _buildParagraph("The four hormones do not operate independently. They regulate each other through a continuous feedback system:", bodyColor),
        _buildSimpleBullet("Low estrogen at cycle start → hypothalamus releases GnRH → pituitary releases FSH and LH.", bodyColor),
        _buildSimpleBullet("FSH stimulates follicle growth → follicles produce estrogen → estrogen rises.", bodyColor),
        _buildSimpleBullet("High estrogen triggers LH surge → LH triggers ovulation.", bodyColor),
        _buildSimpleBullet("After ovulation, corpus luteum produces progesterone → progesterone and estrogen suppress FSH and LH.", bodyColor),
        _buildSimpleBullet("If no pregnancy: corpus luteum breaks down → progesterone and estrogen drop → FSH begins rising again → cycle restarts.", bodyColor),
        _buildParagraph("Both estradiol and progesterone are secreted into the bloodstream and affect various tissues, including the uterus and pituitary gland. At the anterior pituitary, these hormones provide negative feedback, reducing the secretion of FSH and LH, which subsequently reduces their own production.", bodyColor, citation: "Stanford Medicine Children's Health"),
        const SizedBox(height: 32),

        // --- STRESS ---
        _buildHeading("Why stress, sleep, and food affect your hormones", textColor),
        _buildParagraph("The hormonal command chain starts in the hypothalamus — and the hypothalamus is directly connected to the brain's stress response system. This is why life circumstances can directly disrupt your cycle.", bodyColor),
        _buildParagraph("Chronic stress and dysregulation of the HPA (hypothalamic-pituitary-adrenal) axis can lead to alterations in cortisol levels, which are linked to both menstrual disorders and mood disorders. Elevated cortisol can suppress the release of GnRH, interfering with FSH and LH production and disrupting the entire hormonal cascade.", bodyColor, citation: "UChicago Medicine"),
        _buildParagraph("The same mechanism explains why extreme caloric restriction, overtraining, illness, and significant weight changes can delay or stop ovulation — the hypothalamus detects physiological stress and downregulates the reproductive system as a protective response. Your body is not malfunctioning. It is prioritising survival.", bodyColor),
        const SizedBox(height: 32),

        // --- WHEN TO SEE A DOCTOR ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildSimpleBullet("You have severe mood symptoms in the 1 to 2 weeks before your period that significantly affect your daily life (possible PMDD).", bodyColor),
        _buildSimpleBullet("Your periods are consistently absent.", bodyColor),
        _buildSimpleBullet("You experience hot flashes, night sweats, or significant mood changes unrelated to your cycle.", bodyColor),
        _buildSimpleBullet("You have been diagnosed with depression or anxiety and notice symptoms worsening significantly in the premenstrual phase.", bodyColor, citation: "PubMed Central"),
        const SizedBox(height: 48),

        // --- SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Thiyagarajan DK, Basit H, Jeanmonod R. Physiology, Menstrual Cycle. StatPearls, 2024.", isDark),
        _buildSourceItem("• Kale MB, Wankhede NL et al. Unveiling the Neurotransmitter Symphony. Reproductive Sciences, Jan 2025.", isDark),
        _buildSourceItem("• Bendis PJ et al. The impact of estradiol on serotonin, glutamate, and dopamine systems. Frontiers in Neuroscience, 2024.", isDark),
        _buildSourceItem("• Sacher J, Zsido RG et al. Increase in serotonin transporter binding in patients with PMDD. Biological Psychiatry, 2023.", isDark),
        _buildSourceItem("• Pritschet L et al. Hormonal modulation of prefrontal cortex function across the menstrual cycle. Nature Neuroscience, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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
      padding: const EdgeInsets.only(bottom: 12.0, left: 8.0),
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
  Widget _buildHormonesGrid(bool isDark) {
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
            "How hormones affect mood and cognition across the cycle",
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
              _phaseLabel("Menstrual", cMenstrual, tEstrogen.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel("Follicular", cFollicular, tFSH.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel("Ovulation", cOvulation, tLH.withOpacity(isDark ? 0.8 : 1)),
              const SizedBox(width: 8),
              _phaseLabel("Luteal", cLuteal, tProgesterone.withOpacity(isDark ? 0.8 : 1)),
            ],
          ),
          const SizedBox(height: 16),

          // The 2x2 Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _gridCard(
                  "Estrogen ↑", tEstrogen, borderColor, primaryTextColor,
                  ["↑ Serotonin synthesis", "↑ Dopamine sensitivity", "↑ Mood, memory, focus", "↓ Anxiety via GABA"]
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gridCard(
                  "Progesterone ↑", tProgesterone, borderColor, primaryTextColor,
                  ["↓ Serotonin availability", "↑ GABA — sedating effect", "↑ Bloating, fatigue", "↑ Food cravings"]
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
                  "FSH ↑", tFSH, borderColor, primaryTextColor,
                  ["↑ Follicle recruitment", "↑ Estrogen production", "Highest at cycle start", "Falls as estrogen rises"]
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gridCard(
                  "LH surge", tLH, borderColor, primaryTextColor,
                  ["→ Triggers ovulation", "↑ Progesterone begins", "Detectable in urine", "Peaks ~10–12h pre-ovulation"]
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