import 'package:flutter/material.dart';

class ArticleOneView extends StatelessWidget {
  final bool isDark;
  const ArticleOneView({super.key, required this.isDark});

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
          "What Is a Menstrual Cycle?",
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
          "The complete beginner's guide to understanding your body",
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
        _buildHeading("What is actually happening?", textColor),
        _buildParagraph("Every month, your body goes through a series of changes designed to prepare for a possible pregnancy. This sequence of events is called the menstrual cycle. It involves your brain, your ovaries, your uterus, and a carefully timed series of hormonal signals that all work together in a coordinated rhythm.", bodyColor),
        _buildParagraph("The menstrual cycle is a series of natural changes in hormone production and the structures of the uterus and ovaries of the female reproductive system. The ovarian cycle controls the production and release of eggs, and the uterine cycle governs the preparation and maintenance of the lining of the uterus to receive an embryo. These two cycles run concurrently and are coordinated with each other.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("In simple terms: your ovaries grow and release an egg. Your uterus builds up a thick, soft lining in case that egg gets fertilised. If it doesn't, the lining sheds. That shedding is your period. Then the whole process starts again.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2 ---
        _buildHeading("The organs involved", textColor),
        _buildParagraph("Understanding your cycle starts with knowing which parts of your body are involved:", bodyColor),
        _buildBullet("The ovaries", "Two small, almond-shaped organs on either side of your uterus. They store your eggs and produce the hormones estrogen and progesterone. You are born with all the eggs you will ever have — roughly 1 to 2 million at birth, which reduces to around 300,000 by puberty.", bodyColor, textColor),
        _buildBullet("The uterus", "A pear-shaped muscular organ where a baby grows during pregnancy. Its inner lining, called the endometrium, builds up and sheds every cycle.", bodyColor, textColor),
        _buildBullet("The fallopian tubes", "Two narrow tubes connecting the ovaries to the uterus. When an egg is released, it travels down the fallopian tube toward the uterus.", bodyColor, textColor),
        _buildBullet("The hypothalamus and pituitary gland", "Located in your brain. These send out the hormonal signals that start and control the entire cycle.", bodyColor, textColor),
        const SizedBox(height: 32),

        // --- SECTION 3 ---
        _buildHeading("When does it all begin?", textColor),
        _buildParagraph("Menarche — the first menstrual period — typically occurs between the ages of 10 and 16, with the average age of onset being 12.4 years.", bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph("Another way to predict when your period will come is to think back to when breast development began — menarche usually happens about 2 to 2.5 years after breasts start developing.", bodyColor, citation: "RCH Clinical Practice Guidelines"),
        _buildParagraph("The age varies widely from person to person and is influenced by genetics, body composition, nutrition, and general health. People commonly get their periods at around the same time their mother did. Getting your first period any time between ages 9 and 15 is considered within the normal range.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 4 ---
        _buildHeading("How long is a normal cycle?", textColor),
        _buildParagraph("This is where a lot of confusion starts. Most people have heard that a cycle is 28 days. That number is an average — not a rule.", bodyColor),
        _buildParagraph("For teenagers, a normal menstrual cycle can be anywhere between 21 and 45 days. The average menstrual cycle length is approximately 28 days.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("A large-scale real-world study published in npj Digital Medicine analysed data from over 600,000 cycles and found that the mean cycle length across ovulatory cycles was 29.3 days, with a mean follicular phase length of 16.9 days and a mean luteal phase length of 12.4 days.", bodyColor, citation: "Amegroups"),
        const SizedBox(height: 24),
        
        // --- THE GRAPH ---
        _buildAppleGraph(isDark),

        const SizedBox(height: 24),
        _buildParagraph("Research from the Apple Women's Health Study — one of the largest studies of its kind, conducted by Harvard T.H. Chan School of Public Health — analysed 165,668 cycles across 12,608 participants and found that cycle variability is considerably higher — by 46% — among those aged under 20 compared to those aged 35 to 39. In other words, irregular cycles are the norm for teenagers, not the exception.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 5 ---
        _buildHeading("How long does a period last?", textColor),
        _buildParagraph("According to the International Federation of Gynecology and Obstetrics (FIGO), normal menstrual cycles should have consistent frequency, regularity, duration, and volume of flow.", bodyColor, citation: "Cleveland Clinic"),
        _buildParagraph("A period typically lasts between 3 and 7 days, though anywhere in that range is normal. The amount of blood lost during a typical period is around 30 to 80 mL — roughly 2 to 6 tablespoons.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6 ---
        _buildHeading("Why are teenage cycles so irregular?", textColor),
        _buildParagraph("In the first 1 to 2 years following your first period, it is very common and normal to have irregular cycles. In fact, in the first year after your first period, up to 80% of your menstrual cycles may be anovulatory — meaning no egg is released.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("This happens because the hormonal communication system between your brain and ovaries — called the HPO axis — is still maturing. It takes time for this system to find its rhythm. During the first two years following menarche, ovulation is absent in around half of cycles. Five years after menarche, ovulation occurs in around 75% of cycles.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("A 2024 study published in ScienceDirect, analysing 38,916 cycles from 6,486 adolescents aged 13–18 using the Clue app, found that individuals less than 1 year post-menarche had a 2.6 times higher odds of having a highly variable cycle and 5 times higher odds of short cycles compared to those further along in their reproductive development.", bodyColor, citation: "UChicago Medicine"),

        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Irregular cycles in your teens are biological, not a sign something is wrong.", bodyColor),
        _buildSimpleBullet("It can take 2 to 5 years after your first period for cycles to stabilise.", bodyColor),
        _buildSimpleBullet("The 28-day average applies to adults, not teenagers.", bodyColor),
        _buildSimpleBullet("Your cycle length may vary by several days from month to month and that is completely normal.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7 ---
        _buildHeading("What does \"Day 1\" mean?", textColor),
        _buildParagraph("When discussing timing within the menstrual cycle, the first day of heavy menstrual flow is considered Day 1. This is the standard used by doctors and researchers worldwide. Every cycle is measured from Day 1 of one period to Day 1 of the next.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 8 ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildParagraph("Most cycle irregularities in teenagers are normal. However, there are specific situations where it is worth speaking to a doctor or a trusted adult:", bodyColor),
        _buildSimpleBullet("Your first period has not arrived by age 15.", bodyColor),
        _buildSimpleBullet("Your periods stop for 3 or more months in a row and you are not pregnant.", bodyColor),
        _buildSimpleBullet("Your cycle is consistently shorter than 21 days or longer than 45 days.", bodyColor),
        _buildSimpleBullet("Your period lasts longer than 7 days regularly.", bodyColor),
        _buildSimpleBullet("You are soaking through a pad or tampon in under 2 hours.", bodyColor),
        _buildSimpleBullet("Your periods cause pain severe enough to miss school or daily activities.", bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 9: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Thiyagarajan DK, Basit H, Jeanmonod R. Physiology, Menstrual Cycle. StatPearls Publishing, Updated 2024.", isDark),
        _buildSourceItem("• Li H. et al. Menstrual cycle length variation by demographic characteristics from the Apple Women's Health Study. npj Digital Medicine, 2023.", isDark),
        _buildSourceItem("• Grieger JA et al. Real-world menstrual cycle characteristics of more than 600,000 menstrual cycles. npj Digital Medicine, 2019.", isDark),
        _buildSourceItem("• Kurmi M et al. Menstrual Cycle Characteristics of U.S. Adolescents. ScienceDirect, 2024.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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

  Widget _buildAppleGraph(bool isDark) {
    final graphBgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final axisTextColor = isDark ? Colors.white : Colors.black;
    final mutedTextColor = isDark ? Colors.white70 : Colors.black54;
    final pinkColor = const Color(0xFFFF2D55);
    final outlineColor = isDark ? Colors.white30 : Colors.black26;

    final List<Map<String, dynamic>> data = [
      {'age': 'Under\n20', 'val': 30.8, 'isUser': true},
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
            "Average cycle length by age group — Apple Women's Health Study, 2023 (n = 165,668 cycles)",
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
              Text("Your age group",
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
              Text("Other age groups",
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
            "Cycles are longest and most variable in the teenage years and gradually shorten and stabilise into the late twenties and thirties.",
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