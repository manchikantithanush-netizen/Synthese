import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';

class CycleDeviationModal extends StatelessWidget {
  final String alertId;

  const CycleDeviationModal({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    final article = _articleData[alertId] ?? _fallbackArticle;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Matches the exact background colors of HistoryCyclesModal
    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    final textColor = isDark ? Colors.white : Colors.black;
    final bodyTextColor = isDark ? Colors.white70 : Colors.black87;
    final sourceTextColor = isDark ? Colors.grey[400] : Colors.grey[700];
    const alertColor = Color(0xFFF57C00); // Elegant Amber

    return FractionallySizedBox(
      heightFactor: 0.93, // Matches exact height of History Modal
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(38),
          ), // Matches exact radius
        ),
        padding: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            // --- HEADER ---
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Cycle Insight",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: UniversalCloseButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- MAIN SCROLLABLE CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(), // Matches bouncing physics
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon & Article Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.auto_awesome,
                            color: alertColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            article['title'],
                            style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Body Paragraphs
                    ..._buildParagraphs(article['body'], bodyTextColor),

                    const SizedBox(height: 40),
                    Divider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      height: 1,
                    ),
                    const SizedBox(height: 24),

                    // Sources Section
                    Text(
                      "Sources",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildSources(article['sources'], sourceTextColor),

                    const SizedBox(height: 60), // Generous bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs(List<String> paragraphs, Color textColor) {
    return paragraphs
        .map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              p,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                height: 1.65, // Generous line height for reading
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildSources(List<String> sources, Color? textColor) {
    return sources
        .map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(color: textColor, fontSize: 14)),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

// ============================================================================
// ARTICLE DATA
// ============================================================================

const Map<String, dynamic> _fallbackArticle = {
  'title': 'Cycle Insight',
  'body': ['More information about this insight will be available soon.'],
  'sources': [],
};

const Map<String, dynamic> _articleData = {
  'missing_90': {
    'title': 'Period Over 3 Months Late',
    'body': [
      "Going 3 or more months without a period is a condition called secondary amenorrhea. In an adolescent, amenorrhea can be a sign of a medical problem or a side effect of certain medications. Children's Hospital of Philadelphia",
      "The most common causes in young people include significant mental or physical stress, low body weight, and excessive exercise. The body can essentially \"shut down\" its reproductive system when it is severely malnourished, and young athletes often experience amenorrhea due to excessive exercise, low body fat, and stress.",
      "Most cases of amenorrhea are caused by dysfunction of the hypothalamic-pituitary-ovarian (HPO) axis, which is the major regulator of the female reproductive hormones estrogen and progesterone. Other possible causes include thyroid disorders, a condition called PCOS (polycystic ovary syndrome), or in rare cases, a pituitary adenoma — a small, usually benign growth near the brain that disrupts hormone signalling.",
      "A healthcare provider may recommend blood tests to look at hormone levels, and a pelvic ultrasound, which is a painless test that uses sound waves to create images of the reproductive system. Treatment depends on the underlying cause and may involve lifestyle changes, hormonal therapy, or other medicines. Please speak to a doctor or a trusted adult as soon as possible — the earlier this is investigated, the easier it is to manage.",
    ],
    'sources': [
      "Children's Hospital of Philadelphia — Amenorrhea in Teens. chop.edu",
      "ScienceDirect — Etiology and Management of Amenorrhea in Adolescent and Young Adult Women (2022). sciencedirect.com",
      "Stanford Medicine Children's Health — Amenorrhea in Teens. stanfordchildrens.org",
    ],
  },
  'late_14': {
    'title': 'Period 14 Days Late',
    'body': [
      "A period that is two weeks late is worth paying attention to, even if it turns out to be nothing serious. At your age, the most common causes are stress, changes in sleep or diet, intense exercise, or illness — all of which can disrupt the hormonal signals that control your cycle.",
      "However, a 14-day delay can also be an early sign of an underlying hormonal condition. PCOS (polycystic ovary syndrome) is a common health problem that can affect teen girls and young women. It can cause irregular menstrual periods, make periods heavier, or even make periods stop.",
      "Thyroid dysfunction was found in 13.6% of girls with menstrual disorders compared to 3.5% in those without — a statistically significant difference. Both conditions are very common and very treatable once diagnosed.",
      "A doctor can run simple blood tests to check your hormone levels, thyroid function, and rule out other causes. You don't need to panic — but getting it checked early is always the right move.",
    ],
    'sources': [
      "Nemours KidsHealth — Polycystic Ovary Syndrome (PCOS) for Teens. kidshealth.org",
      "PMC — Endocrine Abnormalities in Adolescents with Menstrual Disorders (2018). pmc.ncbi.nlm.nih.gov",
    ],
  },
  'late_7': {
    'title': 'Period 7 Days Late',
    'body': [
      "A period that is up to 7 days late is considered within the normal range of variation for most people, especially teenagers. Your cycle is controlled by a sensitive hormonal system involving your brain, pituitary gland, and ovaries — and this system responds strongly to what is happening in your life.",
      "Emotional or physical stress may cause amenorrhea for as long as the stress remains. Rapid weight loss or gain, medications, and chronic illness can also cause missed or delayed periods.",
      "Common triggers at your age include exam pressure, disrupted sleep, skipping meals, travel, or recovering from an illness.",
      "Approximately 75% of menstruating adolescents report their cycle to be between 21 and 45 days in the first year post-menarche. Your body is still learning its rhythm. If this keeps happening across multiple cycles, consistent tracking will help you and any doctor you see understand your pattern much faster.",
    ],
    'sources': [
      "Drugs.com — Amenorrhea Guide (reviewed November 2024). drugs.com",
      "PMC — PCOS in Adolescents: Ongoing Riddles in Diagnosis and Treatment (2023). pmc.ncbi.nlm.nih.gov",
    ],
  },
  'irregular': {
    'title': 'Highly Irregular Cycles',
    'body': [
      "Cycle irregularity means the number of days between your periods varies significantly from month to month. Some variation — a few days either way — is completely normal. High irregularity over many cycles is more noteworthy.",
      "During adolescence, the most common cause of irregular menstrual cycles is immaturity of the hypothalamic-pituitary-ovarian (HPO) axis — the hormonal control system that regulates your cycle. This is normal in the first few years after your first period.",
      "However, other causes should also be considered. In the first year after menarche, only 20% of menstrual cycles are ovulatory. This increases to 25–35% in the second year, 45% in the fourth year, and up to 70% during years 5 to 9 after menarche.",
      "As many as one in four people who menstruate have menstrual irregularities. Your menstrual cycle could be considered irregular if your cycles are unpredictably short (fewer than 21 days), long (more than 35 days), or spaced out by more than three months.",
      "If irregularity persists beyond 2–3 years after your first period, a doctor can run hormone tests to get a clearer picture. It is a straightforward investigation that can rule out PCOS, thyroid issues, and other common and treatable conditions.",
    ],
    'sources': [
      "Harvard T.H. Chan School of Public Health — Apple Women's Health Study Update (2023). hsph.harvard.edu",
      "PMC — Abnormal Uterine Bleeding in Adolescents (2018). pmc.ncbi.nlm.nih.gov",
      "PMC — Diagnosis and Treatment of Adolescent PCOS (2024). pmc.ncbi.nlm.nih.gov",
    ],
  },
  'short_cycle': {
    'title': 'Unusually Short Cycles',
    'body': [
      "A cycle shorter than 21 days means your period is arriving more frequently than what is considered typical. For teenagers this can sometimes be normal, particularly in the early years after your first period when the hormonal system is still maturing.",
      "According to international evidence-based guidelines, cycles shorter than 21 days in the period between 1 and 3 years after menarche are defined as irregular and worth monitoring.",
      "Consistently short cycles can sometimes be linked to a condition called a luteal phase defect, where the phase after ovulation is too short, or to low progesterone levels. They can also simply reflect your body responding to stress, significant changes in weight, or nutritional deficiencies.",
      "Additional causes to consider include PCOS, hypothyroidism, elevated prolactin levels, and functional hypothalamic dysfunction. If your cycles have consistently been shorter than 21 days for 3 or more cycles, mention it to a doctor. A simple blood hormone panel can identify or rule out most causes quickly.",
    ],
    'sources': [
      "BMC Medicine — Adolescent PCOS According to the International Evidence-Based Guideline (2020). link.springer.com",
      "Medscape — Menstruation Disorders in Adolescents. emedicine.medscape.com",
    ],
  },
  'long_cycle': {
    'title': 'Unusually Long Cycles',
    'body': [
      "A cycle longer than 35 days means your body is taking more time than usual between periods. This is actually one of the most common menstrual patterns seen in teenagers, because the hormonal axis that controls ovulation takes several years to fully regulate after your first period.",
      "According to international clinical guidelines, cycles longer than 45 days in the first 1 to 3 years after menarche, or longer than 35 days from 3 years post-menarche onwards, are considered irregular and warrant evaluation.",
      "Studies have indicated that irregular menstrual cycles during puberty are predictive of future PCOS development — though this does not mean every long cycle is a sign of PCOS. Stress, thyroid dysfunction, elevated prolactin, and nutritional factors are all equally common causes.",
      "Research from the Apple Women's Health Study, analysing 160,206 menstrual cycles across 15,586 participants, found that those with early-life irregular cycles consistently had longer mean cycle lengths in early reproductive years, with differences diminishing with age through the twenties and thirties.",
      "If cycles are consistently over 35 days across 3 or more cycles, a doctor can do blood tests to check hormone levels including LH, FSH, thyroid function, and androgens.",
    ],
    'sources': [
      "BMC Medicine — Adolescent PCOS According to the International Evidence-Based Guideline (2020). link.springer.com",
      "PubMed / ScienceDirect — Apple Women's Health Study: Variability of Menstrual Cycles by Age and PCOS (2025). pubmed.ncbi.nlm.nih.gov",
      "PMC — PCOS in Adolescents: Ongoing Riddles in Diagnosis and Treatment (2023). pmc.ncbi.nlm.nih.gov",
    ],
  },
  'long_period': {
    'title': 'Long Periods',
    'body': [
      "A typical period lasts between 3 and 7 days. Bleeding consistently beyond 8 days is worth investigating. Heavy menstrual bleeding (HMB) is defined as blood loss exceeding 80 mL or bleeding lasting longer than 7 days per cycle.",
      "Extended periods in teenagers are most commonly caused by anovulatory cycles — cycles where ovulation does not occur — which leads to an overgrown uterine lining that takes longer to shed. Menstrual cycles are often irregular and anovulatory in the first few years after menarche, and the time to establish regular ovulatory cycles increases with increasing age at menarche.",
      "Other causes include thyroid dysfunction, PCOS, and in some cases an underlying bleeding disorder. Anovulation is the most common cause of heavy menstrual bleeding in adolescents; an underlying bleeding disorder is the second most common cause.",
      "Approximately 20% of all adolescent girls with heavy menstrual bleeding and 33% of those hospitalised for it have an underlying bleeding disorder. If your periods are consistently lasting more than 8 days, a doctor can check your iron levels — prolonged bleeding can lead to iron deficiency anaemia, which causes fatigue and difficulty concentrating.",
    ],
    'sources': [
      "AAFP — Heavy Menstrual Bleeding in Adolescents: ACOG Management Recommendations (2020). aafp.org",
      "Royal Children's Hospital Melbourne — Clinical Practice Guidelines: Adolescent Gynaecology — Heavy Menstrual Bleeding. rch.org.au",
    ],
  },
  'heavy_bleeding': {
    'title': 'Very Heavy Bleeding',
    'body': [
      "Heavy menstrual bleeding — clinically called menorrhagia — is defined as excessive blood loss that interferes with your physical, social, or emotional quality of life. It is estimated to occur in approximately 37% of adolescent females. So while it can feel alarming, you are far from alone.",
      "The most common cause of heavy menstrual bleeding in adolescents is ovulatory dysfunction, followed by coagulopathies — conditions where the blood does not clot properly. The most common inherited bleeding disorder is von Willebrand disease.",
      "Even in the absence of anaemia, iron depletion from heavy menstrual bleeding can cause fatigue and decreased cognition, especially in verbal learning and memory.",
      "Research advocates for conducting a comprehensive bleeding evaluation in all adolescents with heavy menstrual bleeding, even within their first year post-menarche. If you are soaking through a pad or tampon in under 2 hours, passing large clots, or feeling dizzy and fatigued during your period, speak to a doctor. Effective treatments are available — including iron supplementation, hormonal options, and other medications — that can significantly improve quality of life.",
    ],
    'sources': [
      "PMC — Hematological Evaluation and Management of Menorrhagia in Adolescents (2025). pmc.ncbi.nlm.nih.gov",
      "PubMed — Diagnosis and Management of Heavy Menstrual Bleeding and Bleeding Disorders in Adolescents (2020). pubmed.ncbi.nlm.nih.gov",
      "AAFP — ACOG Management Recommendations: Heavy Menstrual Bleeding in Adolescents (2020). aafp.org",
      "Children's Hospital of Philadelphia — Heavy Menstrual Bleeding (Menorrhagia). chop.edu",
    ],
  },
};
