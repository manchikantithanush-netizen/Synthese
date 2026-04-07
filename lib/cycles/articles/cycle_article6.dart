import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ArticleSixView extends StatelessWidget {
  final bool isDark;
  const ArticleSixView({super.key, required this.isDark});

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
          "How to Track Your Cycle and Why It Matters",
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
          "What your data is really telling you — and how to use it",
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
        _buildHeading("Tracking is not about predicting your period", textColor),
        _buildParagraph("Most people start tracking their cycle for one reason: to know when their period is coming. That is a completely valid reason. But it is also the least interesting thing your cycle data can tell you.", bodyColor),
        _buildParagraph("When you track consistently over time, you build something far more valuable than a prediction. You build a personal health baseline — a record of what is normal for your body specifically, not what is average for a population. That baseline becomes one of the most useful tools you can have in any healthcare conversation, at any age.", bodyColor),
        _buildParagraph("Timely self-monitoring of menstrual health is valuable as it provides insight and self-awareness of one's general health and how one's body responds to different phases of the cycle — insight that can directly inform conversations with healthcare providers.", bodyColor, citation: "Nicklaus Children's Hospital"),
        _buildParagraph("Period tracker apps empower people by helping them gain a better understanding of their bodies, ultimately enhancing their social, academic, and health-related lives.", bodyColor, citation: "Cleveland Clinic"),
        _buildParagraph("A 2024 mixed methods study published in the Journal of Medical Internet Research, surveying Gen Z and millennial users, found that the primary reported benefit of cycle tracking was not period prediction — it was body literacy: understanding why they felt the way they felt at different points in the month.", bodyColor),
        _buildParagraph("This article covers what each piece of data you log actually reveals, why starting early matters more than most people realise, and how to turn your tracked data into something a doctor can actually use.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2: FLOW DATA ---
        _buildHeading("What your flow data reveals", textColor),
        _buildParagraph("Flow level is the most basic thing you can track and the first thing most doctors ask about. But it tells you more than just \"heavy\" or \"light.\"", bodyColor),
        Text("Patterns over time:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Consistently light flow can indicate low estrogen or a thin uterine lining — sometimes caused by hormonal imbalances or certain medications.", bodyColor),
        _buildSimpleBullet("Consistently heavy flow is one of the primary indicators of conditions like endometriosis, fibroids, or a bleeding disorder — conditions that are significantly underdiagnosed, in part because people assume heavy periods are just normal for them.", bodyColor),
        _buildSimpleBullet("Flow that gets progressively heavier over several cycles is more clinically significant than a single heavy cycle.", bodyColor),
        
        const SizedBox(height: 12),
        Text("What the research shows:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildParagraph("The Apple Women's Health Study found that the most frequently tracked symptoms were abdominal cramps, bloating, and tiredness — all experienced by more than 60 percent of participants who logged symptoms. More than half reported acne and headaches. Notably, less widely recognised symptoms like diarrhoea and sleep changes were also tracked by 37 percent of participants.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("Many of these people had normalised these symptoms for years. Tracking made the pattern visible.", bodyColor),

        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Log flow every day of your period, not just the first day.", bodyColor),
        _buildSimpleBullet("Note the difference between heavy days and very heavy days — this distinction matters clinically.", bodyColor),
        _buildSimpleBullet("Changes in your personal flow pattern are more significant than absolute volume — a change from your normal is the signal.", bodyColor),
        _buildSimpleBullet("If you are consistently soaking through protection in under 2 hours, this warrants medical attention regardless of what you have been told is \"normal\" for your family.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 3: SYMPTOM DATA ---
        _buildHeading("What your symptom data reveals", textColor),
        _buildParagraph("Symptoms logged over multiple cycles reveal patterns that are completely invisible in a single cycle.", bodyColor),
        _buildBullet("Cramps", "Mild cramping on day 1–2 is normal. Cramping that starts before your period, lasts beyond day 2–3, or radiates to the lower back and legs consistently is not — and is one of the primary presenting symptoms of endometriosis. A study analysing 4.9 million natural cycles from over 378,000 users of the Clue app found that period flow and pain are among the highest-signal self-tracked symptoms for identifying health conditions including endometriosis and PCOS.", bodyColor, textColor, citation: "Medscape"),
        _buildParagraph("Endometriosis currently takes an average of 7 to 10 years to diagnose. Tracked symptom data documenting a consistent pain pattern is one of the most powerful tools for shortening that timeline.", bodyColor),
        _buildBullet("Headaches", "Headaches that consistently appear in the same phase of your cycle — most commonly in the late luteal phase or around menstruation — are called menstrual migraines and are a recognised medical condition. Showing a doctor they are hormonally triggered opens up targeted treatment options.", bodyColor, textColor),
        _buildBullet("Digestive symptoms", "Bloating, diarrhoea, and constipation that follow a consistent cycle pattern are driven by prostaglandins — chemicals produced during menstruation that affect the gut. These are often dismissed as coincidental until someone sees the pattern.", bodyColor, textColor),
        _buildBullet("Acne", "Acne that consistently appears in the same phase — typically the late luteal phase — is hormonally driven and responds to different interventions than non-hormonal acne.", bodyColor, textColor),
        
        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Symptoms logged in isolation are anecdotes — symptoms logged across 3 or more cycles become a pattern.", bodyColor),
        _buildSimpleBullet("The phase in which a symptom appears is as important as the symptom itself.", bodyColor),
        _buildSimpleBullet("You do not need to log every symptom every day — logging when something feels notable is enough to build a useful picture.", bodyColor),
        _buildSimpleBullet("Consistent pre-menstrual symptom patterns that significantly affect your quality of life may indicate PMDD, which is treatable.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 4: MOOD DATA ---
        _buildHeading("What your mood data reveals", textColor),
        _buildParagraph("Mood tracking is arguably the most under-appreciated aspect of cycle logging. The connection between hormonal phase and emotional state is real, biological, and well-researched — but because most people experience it without any framework, it remains invisible and is frequently attributed to personality or external circumstances.", bodyColor),
        _buildParagraph("A concern in menstrual self-tracking research is that data reflects not only physiological behaviour but also the engagement dynamics of users — context is necessary for interpretation. A note of a headache during the cycle does not spur personal reflection if it is not contextualised. What happened on this day? How was sleep? These interrelated data are necessary to provide any personal insights.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("When you log mood consistently across cycles, several things become visible:", bodyColor),
        _buildSimpleBullet("The follicular phase lift — most people notice improved mood, motivation, and sociability in the week after their period ends. Seeing this pattern consistently helps you plan around it.", bodyColor),
        _buildSimpleBullet("The luteal phase drop — the irritability, sensitivity, and low mood that often appears 5 to 10 days before a period follows a predictable pattern. When you can see it in your data, it stops feeling random and starts feeling manageable.", bodyColor),
        _buildSimpleBullet("PMDD identification — premenstrual dysphoric disorder is characterised by severe mood disruption in the luteal phase that resolves within a few days of menstruation beginning. It affects 3 to 8 percent of people who menstruate and is significantly underdiagnosed. A pattern of consistently severe premenstrual mood changes tracked across cycles is the primary diagnostic tool.", bodyColor),
        
        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("You do not need to document every mood every day — simply logging when you feel notably good or notably difficult is enough to reveal the pattern.", bodyColor),
        _buildSimpleBullet("Seeing the pattern changes your relationship to it — instead of \"I am anxious today,\" it becomes \"I am in the late luteal phase and this is temporary.\"", bodyColor),
        _buildSimpleBullet("Mood data logged across cycles is clinically useful — bring it to any mental health or gynaecology appointment.", bodyColor),
        const SizedBox(height: 32),

        // --- CUSTOM UI: DATA POINTS LIST ---
        _buildDataPointsList(isDark),
        const SizedBox(height: 32),

        // --- SECTION 5: CERVICAL MUCUS ---
        _buildHeading("What cervical mucus data reveals", textColor),
        _buildParagraph("Cervical mucus is the most underlogged data point in cycle tracking — and one of the most informative. Changes in mucus consistency are directly driven by estrogen and are one of the most reliable natural indicators of where you are in your cycle.", bodyColor),
        _buildSimpleBullet("Dry or no mucus — early follicular phase and post-ovulation luteal phase. Estrogen is low.", bodyColor),
        _buildSimpleBullet("Sticky or crumbly — early to mid follicular phase. Estrogen beginning to rise.", bodyColor),
        _buildSimpleBullet("Creamy or lotion-like — mid follicular phase. Estrogen rising. Getting closer to ovulation.", bodyColor),
        _buildSimpleBullet("Egg-white: clear, stretchy, slippery — the peak fertility sign. Indicates you are at or very close to ovulation. This is the most important mucus type to recognise.", bodyColor),
        _buildSimpleBullet("Dry again — post-ovulation. Progesterone thickens mucus to create a barrier.", bodyColor),
        _buildParagraph("If you never notice egg-white mucus across multiple cycles, it can indicate that ovulation is not occurring, or that it is occurring at a different time than calendar predictions suggest. This is worth mentioning to a doctor.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6: STARTING EARLY ---
        _buildHeading("Why starting early creates a baseline that is impossible to replicate later", textColor),
        _buildParagraph("The most important reason to start tracking young — ideally in the first year or two after your first period — is that you are recording your baseline. The normal that exists before anything has had a chance to change it.", bodyColor),
        _buildParagraph("The Apple Women's Health Study found that participants whose cycles took 5 or more years to reach regularity after their first period had more than twice the risk of endometrial hyperplasia and more than 3.5 times the risk of uterine cancer compared to those who reached regularity within one year. These findings highlight the importance of understanding cycle regularity early, and encouraging people to have conversations with their healthcare providers about cycle irregularity earlier.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("Dr. Shruthi Mahalingaiah, MD MS — Associate Professor of Environmental, Reproductive and Women's Health at Harvard — has stated that more awareness of menstrual cycle physiology and the impact of irregular periods on uterine health is needed, and that cycle tracking data is central to building that awareness at a population level.", bodyColor),
        _buildParagraph("A baseline established in your teens gives you a reference point for the rest of your life. If something changes — your flow gets heavier, your cycle length shifts, a new symptom appears — you will know it is a change because you have data showing what your normal used to look like. Without that baseline, changes are much harder to detect and much harder to communicate to a doctor.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7: DOCTOR'S APPOINTMENT ---
        _buildHeading("How to use tracked data in a doctor's appointment", textColor),
        _buildParagraph("Most people go to a doctor and say \"my periods have been irregular lately.\" This gives the doctor very little to work with. A person who brings 3 to 6 months of tracked cycle data can say something entirely different — and get a much more targeted response.", bodyColor),
        _buildParagraph("Women with PCOS, endometriosis, and infertility in a 2023 survey reported that the use of tracking technologies directly aided in the diagnosis of their conditions — 61.8% for endometriosis, 63.6% for PCOS, and 75% for infertility.", bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph("Tracked data shortens the diagnostic path because it replaces recall-based estimates with actual longitudinal records.", bodyColor),
        
        Text("What to bring to a doctor's appointment:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Your average cycle length and how much it varies month to month.", bodyColor),
        _buildSimpleBullet("Your typical period length and flow pattern.", bodyColor),
        _buildSimpleBullet("Any symptoms that appear consistently in the same phase, especially pain, mood changes, and digestive symptoms.", bodyColor),
        _buildSimpleBullet("Any changes from your previous normal — even if you cannot articulate why it feels different.", bodyColor),
        _buildSimpleBullet("How many cycles you have tracked and how consistently.", bodyColor),

        const SizedBox(height: 12),
        Text("Specific conversations tracked data enables:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("\"My period has been getting progressively heavier over the last 4 cycles\" — this is the opening to an investigation for endometriosis or fibroids.", bodyColor),
        _buildSimpleBullet("\"I have severe mood symptoms for exactly 8 days before every period that resolve within 2 days of my period starting\" — this is the clinical description of PMDD.", bodyColor),
        _buildSimpleBullet("\"My cycle has been consistently over 35 days for the past 6 cycles\" — this is the basis for a PCOS screening conversation.", bodyColor),
        _buildSimpleBullet("\"I have never noticed egg-white cervical mucus across 4 cycles\" — this is a flag for possible anovulation.", bodyColor),
        
        const SizedBox(height: 12),
        _buildParagraph("Participants in a qualitative study on period tracking app use stated that exporting their data as a document and sharing it with doctors was one of the most helpful features of cycle tracking apps — giving doctors a concrete record rather than a memory-based estimate.", bodyColor, citation: "Amegroups"),
        const SizedBox(height: 32),

        // --- SECTION 8: PREDICTION ACCURACY ---
        _buildHeading("How accurate is cycle tracking for prediction?", textColor),
        _buildParagraph("Prediction accuracy is one of the most common questions about cycle tracking — and it is worth being honest about. Calendar-based prediction works reasonably well for people with very regular cycles, and improves substantially with more data.", bodyColor),
        _buildParagraph("A large-scale validation study of the Flo app's algorithm, published in JMIR mHealth and uHealth in 2023 and analysing over 3 million cycles, found that app-based menstrual cycle tracking data has significant potential for epidemiological research and clinical applications, particularly for identifying cycle characteristics associated with conditions like endometriosis and PCOS — with accuracy improving substantially as more cycles are logged.", bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph("For teenagers specifically, prediction is less reliable than for adults — because the follicular phase length is more variable. The most honest framework is:", bodyColor),
        _buildSimpleBullet("1 to 3 cycles logged: Prediction is a rough estimate — useful for planning but not for precision.", bodyColor),
        _buildSimpleBullet("3 to 6 cycles logged: Prediction improves significantly. Your personal average starts to emerge.", bodyColor),
        _buildSimpleBullet("6+ cycles logged: Prediction is meaningfully personalised. The app knows your cycle, not just the population average.", bodyColor),
        _buildSimpleBullet("Irregular cycles: Prediction will always have more variance. This is not a failure of the technology — it is an accurate reflection of your biology.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 9: PRACTICAL GUIDANCE ---
        _buildHeading("Practical guidance — how to actually track effectively", textColor),
        Text("What to log every day of your period:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Flow level — consistently, every day.", bodyColor),
        _buildSimpleBullet("Any symptoms, even mild ones.", bodyColor),
        
        const SizedBox(height: 12),
        Text("What to log when you notice it:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Cervical mucus changes — particularly when you notice egg-white consistency.", bodyColor),
        _buildSimpleBullet("Mood changes that feel notably different from your baseline.", bodyColor),
        _buildSimpleBullet("Spotting — note the amount and colour.", bodyColor),

        const SizedBox(height: 12),
        Text("What to log at least once per cycle:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("The first day of your period — this is the most critical data point and should never be missed.", bodyColor),

        const SizedBox(height: 12),
        Text("What you do not need to log:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Everything, every day — this level of logging is not sustainable and is not necessary for useful data.", bodyColor),
        _buildSimpleBullet("Symptoms you have to invent because you feel like you should be logging something — inaccurate data is worse than no data.", bodyColor),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Consistency matters more than comprehensiveness — a partial log every cycle is more valuable than a perfect log for one cycle and nothing for three cycles.", bodyColor),
        _buildSimpleBullet("The first day of your period is the single most important data point — prioritise it above everything else.", bodyColor),
        _buildSimpleBullet("Start now — even one cycle of data is more than zero, and the baseline you build now will be relevant for decades.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 10: WHEN TO SEE A DOCTOR ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildParagraph("Tracking itself will not tell you when something is wrong — but it will tell you when something has changed. Bring your tracked data to a doctor if:", bodyColor),
        _buildSimpleBullet("Your cycle length has shifted by more than 7 days from your previous consistent pattern across 3 or more cycles.", bodyColor),
        _buildSimpleBullet("Your flow has become consistently heavier or you are experiencing more pain than before.", bodyColor),
        _buildSimpleBullet("You notice mood symptoms that follow a clear premenstrual pattern and significantly affect your daily life.", bodyColor),
        _buildSimpleBullet("You have never noticed egg-white cervical mucus across 3 or more cycles.", bodyColor),
        _buildSimpleBullet("Your period has been absent for 3 or more consecutive cycles.", bodyColor),
        _buildSimpleBullet("You simply feel like something is different from before — even if you cannot articulate exactly what — and your tracked data confirms a change in pattern.", bodyColor),
        _buildParagraph("Your tracked data is not a diagnosis. It is evidence. Bring it to someone who can interpret it.", bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 11: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Hong M, Rajaguru V et al. Menstrual Cycle Management and Period Tracker App Use. Journal of Medical Internet Research, 2024.", isDark),
        _buildSourceItem("• Symul L, Wac K et al. Characterizing physiological and symptomatic variation... npj Digital Medicine, 2020.", isDark),
        _buildSourceItem("• Stujenske TM, Mu Q et al. Survey Analysis of Menstrual Cycle Tracking Technologies. Medicina, 2023.", isDark),
        _buildSourceItem("• Li H et al. Menstrual cycle length variation by demographic characteristics. npj Digital Medicine, 2023.", isDark),
        _buildSourceItem("• Zhang CY, Li H et al. Abnormal uterine bleeding patterns determined through menstrual tracking. AJOG, 2023.", isDark),
        _buildSourceItem("• Epstein D et al. Examining menstrual tracking to inform the design of personal informatics tools. ACM CHI Conference, 2017.", isDark),
        _buildSourceItem("• Lyzwinski L, Elgendi M et al. Innovative Approaches to Menstruation Tracking. Journal of Medical Internet Research, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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

  // --- CUSTOM UI FOR DATA POINTS LIST ---
  Widget _buildDataPointsList(bool isDark) {
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
            "What each data point reveals over time",
            style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            "Value increases significantly after 3+ cycles of consistent logging",
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 32),

          buildListItem(
            icon: CupertinoIcons.drop_fill,
            color: const Color(0xFFFF2D55),
            title: "Flow level",
            desc: "Identifies heavy bleeding patterns, endometriosis risk, anaemia, and hormonal imbalances over time",
            pillText: "High clinical value",
          ),
          buildListItem(
            icon: CupertinoIcons.arrow_2_squarepath,
            color: const Color(0xFF007AFF),
            title: "Symptoms",
            desc: "Phase-correlated pain and digestive symptoms are primary diagnostic signals for endometriosis, PCOS, and PMDD",
            pillText: "High clinical value",
          ),
          buildListItem(
            icon: CupertinoIcons.time,
            color: const Color(0xFF34C759),
            title: "Mood",
            desc: "Reveals luteal phase mood patterns, supports PMDD identification, and helps contextualise emotional experiences",
            pillText: "Medium-high value",
          ),
          buildListItem(
            icon: CupertinoIcons.location_solid,
            color: const Color(0xFFFF9500),
            title: "Cervical mucus",
            desc: "Confirms ovulation timing independently of calendar prediction. Egg-white mucus is the most reliable natural ovulation indicator",
            pillText: "Medium value",
          ),
          buildListItem(
            icon: CupertinoIcons.calendar,
            color: const Color(0xFF5856D6),
            title: "Cycle length history",
            desc: "Enables PCOS screening, detects short/long cycle patterns, and improves prediction accuracy significantly after 3+ cycles",
            pillText: "Increases with time",
            showBorder: false,
          ),

          Divider(color: borderColor, height: 32),
          Text(
            "Sources: Clue / npj Digital Medicine 4.9M cycle study (2020); Apple Women's Health Study (2023); Stujenske et al. Medicina (2023)",
            style: TextStyle(color: secondaryText, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            "The clinical value of your tracked data compounds over time. Flow and symptom data have the highest immediate value. Cycle length history becomes more powerful after 3 or more cycles. All of it is most useful when it is consistent.",
            style: TextStyle(color: primaryText, fontSize: 15, fontWeight: FontWeight.w500, height: 1.45),
          ),
        ],
      ),
    );
  }
}