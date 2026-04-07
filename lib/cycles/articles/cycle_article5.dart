import 'package:flutter/material.dart';

class ArticleFiveView extends StatelessWidget {
  final bool isDark;
  const ArticleFiveView({super.key, required this.isDark});

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
          "Things That Can Affect Your Cycle",
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
          "Why your period is one of the most accurate reflections of your overall health",
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
        _buildHeading("Your cycle as a health barometer", textColor),
        _buildParagraph("The American College of Obstetricians and Gynecologists (ACOG) officially designated the menstrual cycle as a vital sign in 2015 — placing it alongside blood pressure, heart rate, temperature, and respiratory rate as a core indicator of overall health. This is not symbolic. It reflects a clinical reality: your cycle responds to almost everything happening in your body and your life.", bodyColor),
        _buildParagraph("When your period is late, heavy, lighter than usual, or simply different from normal, it is almost never random. It is your body's hormonal system communicating that something has shifted — internally or externally. Understanding what can cause those shifts gives you the ability to interpret your cycle instead of just reacting to it.", bodyColor),
        _buildParagraph("The hormonal command chain that runs your cycle starts in the hypothalamus — a part of the brain that sits at the intersection of your nervous system, your endocrine system, and your stress response. Elevated cortisol levels suppress gonadotropin-releasing hormone (GnRH), leading to disrupted follicular development, anovulation, and alterations in cycle length. Psychological factors such as anxiety and depression further contribute to menstrual disturbances, while lifestyle factors — including poor sleep, diet, and excessive workload — exacerbate stress-related dysfunctions.", bodyColor, citation: "Drugs.com"),
        _buildParagraph("Everything in this article comes back to that one mechanism. Different inputs, same pathway.", bodyColor),
        const SizedBox(height: 32),

        // --- STRESS ---
        _buildHeading("1. Stress", textColor),
        _buildParagraph("Stress is the single most well-documented disruptor of the menstrual cycle, and for good reason — the biological pathway is direct and well understood.", bodyColor),
        _buildParagraph("Chronic stress can interfere with the hormones that regulate the menstrual cycle, specifically gonadotropin-releasing hormone (GnRH). This disruption can lead to irregular periods or even amenorrhea. Elevated cortisol can affect ovulation by suppressing the LH surge necessary for ovulation, leading to anovulatory cycles. Under stress, the body may also divert the precursors for progesterone to produce more cortisol — a phenomenon known as pregnenolone steal — which can further disrupt menstrual regularity.", bodyColor, citation: "Stanford Medicine Children's Health"),
        _buildParagraph("The research in this area is robust. A 2023 study published in the Journal of Family Medicine and Primary Care, analysing 341 participants, found that women who experienced moderate to severe stress also experienced more PMS symptoms including mood swings, anger, fatigue, and depression — a finding that was statistically significant across both the luteal and menstrual phases.", bodyColor, citation: "Amegroups"),
        _buildParagraph("A 2024 study following women in the aftermath of the 2023 earthquake in Turkey demonstrated just how powerfully acute stress can disrupt cycle patterns. Earthquake-related trauma and stress affected the nervous and endocrine system, leading to increased cortisol levels that disrupted hormonal balance by acting on the hypothalamic-pituitary-ovarian axis and inducing irregular menstrual cycles in a significant proportion of women studied.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("You do not need to experience a disaster for this to apply to you. Exam periods, family difficulties, relationship stress, bereavement, and sustained academic pressure all activate the same biological pathway. The hypothalamus does not distinguish between a natural disaster and a set of final exams. It responds to perceived threat.", bodyColor),
        
        Text("What this looks like in practice:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Period arrives later than usual or skips entirely.", bodyColor),
        _buildSimpleBullet("Cycle becomes shorter or longer than your normal pattern.", bodyColor),
        _buildSimpleBullet("Flow becomes heavier or lighter than usual.", bodyColor),
        _buildSimpleBullet("PMS symptoms intensify before the period.", bodyColor),
        _buildSimpleBullet("Spotting mid-cycle during unusually high-stress periods.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Short-term stress usually causes a one-cycle disruption — things return to normal once the stress resolves.", bodyColor),
        _buildSimpleBullet("Chronic ongoing stress can cause sustained irregularity over multiple cycles.", bodyColor),
        _buildSimpleBullet("The stress does not need to feel extreme to have a hormonal effect — sustained low-level stress (like academic pressure over weeks) is equally disruptive.", bodyColor),
        _buildSimpleBullet("Stress management is not optional for cycle health — it is one of the most direct levers you have.", bodyColor),
        const SizedBox(height: 32),

        // --- SLEEP ---
        _buildHeading("2. Sleep", textColor),
        _buildParagraph("Sleep and the menstrual cycle are in a bidirectional relationship — each affects the other, and disruption in one reliably disrupts the other.", bodyColor),
        _buildParagraph("A population-based study of 801 Korean female adolescents found that sleeping five hours or less per night was significantly associated with increased risk of menstrual cycle irregularity compared to sleeping eight or more hours, even after adjusting for age, BMI, depressive mood, and other confounding variables. The odds of irregularity increased steadily as sleep duration decreased.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("A systematic review published in BMC Women's Health in 2023, analysing multiple studies across different populations, confirmed the pattern: short sleep duration — typically defined as less than six hours — was consistently linked to abnormal menstrual cycle length and heavier bleeding during periods.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("The mechanism works through cortisol and the reproductive hormones simultaneously. Increased stress hormone production derived from sleep loss can reduce the production of FSH and LH — two hormones essential to menstrual function. If sleep disturbances persist, this may lead to irregular or even missing periods, known as Functional Hypothalamic Amenorrhoea (FHA).", bodyColor, citation: "PubMed"),
        _buildParagraph("Women with less than 8 hours of sleep secrete 20% less FSH compared to women with longer sleep durations. FSH is the hormone that starts the follicle development process at the beginning of each cycle. Less FSH means slower, less reliable follicle development — which delays ovulation and therefore delays the period.", bodyColor, citation: "Medscape"),
        _buildParagraph("The relationship also runs in the other direction. Sleep is most commonly disrupted in the late luteal phase — the days before a period — when progesterone drops and body temperature remains elevated. Approximately 70% of women with PMDD experience sleep disturbances during this window.", bodyColor, citation: "PubMed Central"),

        Text("What this looks like in practice:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Consistently short sleep delays ovulation, which delays the period.", bodyColor),
        _buildSimpleBullet("Poor sleep quality — even at normal duration — is associated with heavier bleeding.", bodyColor),
        _buildSimpleBullet("Sleep disruption worsens PMS and PMDD symptoms.", bodyColor),
        _buildSimpleBullet("Irregular sleep schedules (different bedtimes each night) are associated with more irregular cycles than simply sleeping less.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("The National Sleep Foundation recommends 8 to 10 hours of sleep for teenagers.", bodyColor),
        _buildSimpleBullet("Going to bed and waking at consistent times matters as much as total duration.", bodyColor),
        _buildSimpleBullet("Screen light (phones, laptops) suppresses melatonin and disrupts the hormonal signals that regulate both sleep and the cycle.", bodyColor),
        _buildSimpleBullet("Improving sleep is one of the most accessible and evidence-supported interventions for cycle regularity.", bodyColor),
        const SizedBox(height: 32),

        // --- CUSTOM EVIDENCE CHART ---
        _buildEvidenceChart(isDark),
        const SizedBox(height: 32),

        // --- EXERCISE ---
        _buildHeading("3. Exercise", textColor),
        _buildParagraph("Exercise has a dual relationship with the menstrual cycle that is worth understanding carefully — because the type and intensity matter enormously.", bodyColor),
        _buildParagraph("Moderate exercise is protective. Regular moderate physical activity reduces inflammation, improves insulin sensitivity, lowers cortisol, and supports the hormonal balance needed for regular ovulation. Multiple studies show that moderate exercise reduces PMS symptom severity, decreases menstrual pain, and is associated with more regular cycles.", bodyColor),
        _buildParagraph("Excessive exercise is disruptive. When exercise intensity or volume becomes too high — particularly when combined with insufficient caloric intake — the body interprets this as a physiological threat and begins to downregulate the reproductive system. This is the mechanism behind what is called the Female Athlete Triad: the combination of low energy availability, disrupted menstrual function, and reduced bone density that affects athletes who train very hard without eating enough.", bodyColor),
        _buildParagraph("Lifestyle factors including excessive exercise exacerbate stress-related menstrual dysfunctions through the neuroendocrine pathway, contributing to elevated cortisol, suppressed GnRH, and anovulatory cycles.", bodyColor, citation: "Drugs.com"),
        _buildParagraph("The threshold is not fixed — it depends on your overall energy balance. Running 5km a day while eating adequately is unlikely to affect your cycle. Running 15km a day while significantly undereating can cause your period to disappear within weeks.", bodyColor),

        Text("What this looks like in practice:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Sudden dramatic increase in training intensity → delayed period or missed cycle.", bodyColor),
        _buildSimpleBullet("Sustained intense training combined with low caloric intake → cycle stops (amenorrhea).", bodyColor),
        _buildSimpleBullet("Starting or resuming regular moderate exercise → cycle may become more regular over time.", bodyColor),
        _buildSimpleBullet("Reducing training after a heavy athletic season → period returns within 1 to 3 cycles.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("The key variable is energy availability, not exercise volume alone.", bodyColor),
        _buildSimpleBullet("Dance, gymnastics, distance running, and rowing carry the highest risk due to combining high output with aesthetic body pressures.", bodyColor),
        _buildSimpleBullet("Losing your period due to exercise is not normal and is not a sign of fitness — it is a sign of physiological stress.", bodyColor),
        _buildSimpleBullet("Bone density loss from exercise-related amenorrhea can be permanent if not addressed.", bodyColor),
        const SizedBox(height: 32),

        // --- DIET & NUTRITION ---
        _buildHeading("4. Diet and nutrition", textColor),
        _buildParagraph("What you eat affects your hormones more directly than most people realise. The menstrual cycle requires adequate energy, fat, and specific micronutrients to function. When any of these are deficient, the reproductive system is one of the first systems to be downregulated.", bodyColor),
        _buildBullet("Caloric restriction and low body weight", "The hypothalamus monitors body fat levels through hormones including leptin. When body fat drops too low — from restrictive eating, rapid weight loss, or eating disorders — leptin falls, and the hypothalamus reduces GnRH production, effectively pausing the cycle. This is the same mechanism as exercise-related amenorrhea.", bodyColor, textColor),
        
        Text("Specific micronutrients that matter:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Iron — heavy periods deplete iron rapidly. Iron deficiency causes fatigue, brain fog, and dizziness.", bodyColor),
        _buildSimpleBullet("Magnesium — low magnesium is associated with more severe PMS symptoms, particularly cramping and mood changes.", bodyColor),
        _buildSimpleBullet("Omega-3 fatty acids — anti-inflammatory. Research consistently shows omega-3 supplementation reduces menstrual pain severity.", bodyColor),
        _buildSimpleBullet("Vitamin D — low vitamin D is associated with more irregular cycles and more severe dysmenorrhoea.", bodyColor),
        _buildSimpleBullet("Zinc — involved in progesterone production and immune function. Low zinc is linked to more severe PMS.", bodyColor),
        
        const SizedBox(height: 12),
        _buildBullet("Ultra-processed food and blood sugar", "Diets high in refined carbohydrates and ultra-processed foods cause rapid spikes and crashes in blood sugar, which trigger cortisol release. A 2023 study found that dietary patterns characterised by high processed food intake were independently associated with more irregular cycles and more severe menstrual symptoms in adolescents.", bodyColor, textColor),
        
        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("You do not need to eat a perfect diet for a regular cycle — but extreme restriction is harmful.", bodyColor),
        _buildSimpleBullet("Eating enough fat is specifically important — steroid hormones including estrogen and progesterone are made from cholesterol.", bodyColor),
        _buildSimpleBullet("Crash diets and cleanses are among the fastest ways to disrupt your cycle.", bodyColor),
        _buildSimpleBullet("If you suspect your diet is affecting your cycle, a blood test checking iron, vitamin D, and ferritin levels is a reasonable starting point.", bodyColor),
        const SizedBox(height: 32),

        // --- TRAVEL & JET LAG ---
        _buildHeading("5. Travel and jet lag", textColor),
        _buildParagraph("Travel disrupts the menstrual cycle through a specific and well-understood mechanism: circadian rhythm disruption.", bodyColor),
        _buildParagraph("Your menstrual cycle is regulated by the hypothalamus, which is deeply integrated with your circadian clock — the 24-hour biological timing system that controls sleep, hormone release, digestion, and body temperature. When your circadian rhythm gets disrupted, the timing and amount of GnRH, FSH, and LH releases can change, potentially delaying ovulation or altering your cycle length. Jet lag goes beyond feeling tired after a flight — it affects multiple body systems simultaneously including sleep-wake cycles, digestion, mood, immune function, and reproductive hormones.", bodyColor, citation: "Harvard T.H. Chan School of Public Health"),
        _buildParagraph("Research shows that how long jet lag can delay your period typically ranges from 3 to 7 days, though some people experience longer delays. Eastward travel disrupts circadian rhythms more severely than westward travel — eastward jet lag can last over twice as long because shortening your day feels harder than lengthening one.", bodyColor, citation: "Harvard T.H. Chan School of Public Health"),
        _buildParagraph("A study published in PubMed on social jet lag — the mismatch between your body clock and your daily schedule, even without actual travel — found that students with larger social jet lag of 1 hour or more experienced more severe menstrual symptoms including pain, behavioural changes, and water retention, compared to those with smaller social jet lag.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("This means that simply having irregular sleep and wake times across the week — staying up late on weekends and waking early on weekdays — can affect your cycle.", bodyColor),
        
        Text("What this looks like in practice:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Period arrives 3 to 7 days later than expected after a long-haul flight.", bodyColor),
        _buildSimpleBullet("Period arrives earlier than expected in some cases — the circadian disruption can push ovulation in either direction.", bodyColor),
        _buildSimpleBullet("Flow may be heavier or lighter than usual for one cycle after significant travel.", bodyColor),
        _buildSimpleBullet("Things usually return to normal within one to two cycles.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("The disruption is almost always temporary — one to two cycles.", bodyColor),
        _buildSimpleBullet("Eastward travel (e.g. flying from Europe to Asia) causes more disruption than westward.", bodyColor),
        _buildSimpleBullet("The stress and sleep disruption of travel compound the effect — it is rarely just one mechanism.", bodyColor),
        _buildSimpleBullet("Staying hydrated, keeping to your home time zone for the first 24 hours where possible, and getting morning light exposure in the new time zone all help speed up circadian resynchronisation.", bodyColor),
        const SizedBox(height: 32),

        // --- ILLNESS & FEVER ---
        _buildHeading("6. Illness and fever", textColor),
        _buildParagraph("Illness disrupts the cycle through two overlapping pathways: the immune-inflammatory response and the stress response. Both activate cortisol and inflammatory cytokines that suppress GnRH and disrupt ovulation.", bodyColor),
        _buildParagraph("Fever specifically has a direct effect on the timing of ovulation. Elevated body temperature interferes with the precise hormonal timing required for the LH surge. A fever during the follicular phase — particularly in the week before expected ovulation — can delay ovulation by several days, pushing the period back by the same amount.", bodyColor),
        _buildParagraph("Common viral illnesses including influenza, COVID-19, and other febrile infections have all been associated with cycle disruption in research. A delayed or skipped period after a significant illness is extremely common and almost always resolves in the following cycle.", bodyColor),
        
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("One disrupted cycle after illness is completely normal and expected.", bodyColor),
        _buildSimpleBullet("The more severe the illness and the longer it lasted, the more disruption to expect.", bodyColor),
        _buildSimpleBullet("COVID-19 specifically has been associated with cycle changes in multiple studies — both short-term disruption and, in some cases, longer-term changes.", bodyColor),
        _buildSimpleBullet("If your cycle does not return to normal within two cycles after recovering from illness, mention it to a doctor.", bodyColor),
        const SizedBox(height: 32),

        // --- MEDICATIONS ---
        _buildHeading("7. Medications", textColor),
        _buildParagraph("Several categories of medication can affect the menstrual cycle either directly or indirectly:", bodyColor),
        _buildBullet("Hormonal contraceptives", "By design, these override the natural hormonal cycle. After stopping hormonal contraception, it can take 1 to 3 months for natural cycles to resume, though this varies significantly by person and by the type of contraception used.", bodyColor, textColor),
        _buildBullet("Antidepressants and antipsychotics", "Some medications in these classes, particularly those that raise prolactin levels, can suppress ovulation and affect cycle regularity. If you have started a new psychiatric medication and notice cycle changes, mention it to your prescribing doctor.", bodyColor, textColor),
        _buildBullet("Corticosteroids", "Anti-inflammatory steroids used for conditions like asthma or eczema can affect cortisol balance and temporarily disrupt cycles with prolonged use.", bodyColor, textColor),
        _buildBullet("Chemotherapy", "Can temporarily or permanently disrupt cycle function depending on the type and duration.", bodyColor, textColor),
        _buildBullet("Non-prescription", "High doses of vitamin C, certain herbal supplements (particularly those marketed for \"hormonal balance\"), and significant changes in caffeine intake have all been anecdotally associated with cycle changes, though the research evidence is variable.", bodyColor, textColor),
        
        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Always mention cycle changes to your doctor when starting a new medication.", bodyColor),
        _buildSimpleBullet("Never stop a prescribed medication because of cycle changes without speaking to your doctor first.", bodyColor),
        _buildSimpleBullet("The interaction between medications and cycle function is under-researched — your experience is valid even if your doctor is not immediately familiar with the connection.", bodyColor),
        const SizedBox(height: 32),

        // --- WHEN TO SEE A DOCTOR ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildParagraph("Most cycle disruptions caused by lifestyle factors resolve on their own within one to two cycles once the cause is addressed. However, speak to a doctor if:", bodyColor),
        _buildSimpleBullet("Your period has been absent for 3 or more consecutive cycles.", bodyColor),
        _buildSimpleBullet("Your cycle has been consistently irregular for more than 6 months with no identifiable lifestyle cause.", bodyColor),
        _buildSimpleBullet("You have lost your period in the context of intense exercise and low food intake — bone density loss begins quickly and is partially irreversible.", bodyColor),
        _buildSimpleBullet("You are experiencing significant fatigue, dizziness, or breathlessness during your period — this can indicate iron deficiency anaemia from heavy bleeding.", bodyColor),
        _buildSimpleBullet("A new medication has caused your cycle to change significantly and the change is affecting your quality of life.", bodyColor),
        _buildSimpleBullet("You are experiencing severe mood symptoms in the premenstrual phase that are affecting your daily functioning — this is treatable.", bodyColor),
        const SizedBox(height: 48),

        // --- SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Jain P, Chauhan AK, Singh K et al. Correlation of perceived stress with monthly cyclical changes. Journal of Family Medicine and Primary Care, 2023.", isDark),
        _buildSourceItem("• Gopal Anapana et al. Stress, sleep patterns, and reproductive health. International Journal of Zoology, 2025.", isDark),
        _buildSourceItem("• Addressing the effects of stress on menstrual cycle regularity. DigitalCommons@PCOM, 2025.", isDark),
        _buildSourceItem("• Nam GE, Han K, Lee G. Association between sleep duration and menstrual cycle irregularity. Sleep Medicine, 2017.", isDark),
        _buildSourceItem("• Maeng LY, Bhatt P et al. Menstrual disturbances and its association with sleep disturbances. BMC Women's Health, 2023.", isDark),
        _buildSourceItem("• Mahoney MM. Shift work, jet lag, and female reproduction. International Journal of Endocrinology, 2010.", isDark),
        _buildSourceItem("• Nagata C et al. Social jetlag and menstrual symptoms among female university students. PubMed, 2018.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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

  // --- CUSTOM EVIDENCE CHART ---
  Widget _buildEvidenceChart(bool isDark) {
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
                alignment: Alignment.centerLeft,
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
            "Relative strength of evidence linking lifestyle factors to cycle disruption",
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            "Based on systematic reviews and meta-analyses 2020–2024",
            style: TextStyle(color: secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Bars
          buildBarRow("Chronic stress", 0.92, cPink, "Very strong"),
          buildBarRow("Sleep <6hrs", 0.85, cPink, "Very strong"),
          buildBarRow("Low body wt.", 0.85, cOrange, "Strong"),
          buildBarRow("Over-exercise", 0.80, cOrange, "Strong"),
          buildBarRow("Illness / fever", 0.70, cYellow, "Moderate"),
          buildBarRow("Travel / jet lag", 0.58, cYellow, "Moderate"),
          buildBarRow("Poor diet", 0.52, cBlue, "Emerging"),
          buildBarRow("Mild exercise", 0.25, cGreen, "Protective"),

          const SizedBox(height: 12),
          Text(
            "Sources: DigitalCommons@PCOM Review (2025); BMC Women's Health Systematic Review (2023); Samphire Neuroscience Sleep Review (2025); Mahoney MM, PMC (2010)",
            style: TextStyle(color: secondaryText, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            "Stress and sleep have the strongest and most consistent evidence base. Exercise is the only factor that can be protective rather than disruptive — but only at moderate intensity.",
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }
}