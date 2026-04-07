import 'package:flutter/material.dart';

class ArticleFourView extends StatelessWidget {
  final bool isDark;
  const ArticleFourView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final bodyColor = isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);
    final highlightColor = const Color(0xFFFF2D55); // Pink accent for spotting theme

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 60.0),
      children: [
        // --- MAIN TITLE ---
        Text(
          "What Is Spotting and Why Does It Happen?",
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
          "Everything you need to know about bleeding between periods",
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
        _buildHeading("What spotting actually is", textColor),
        _buildParagraph("Spotting is light vaginal bleeding that occurs outside of your normal period. It is not a flow — it is small amounts of blood, often noticed only when wiping or as light staining on underwear. The colour is usually pink, light red, or brown rather than the bright or deep red of a typical period. It does not require a pad or tampon in most cases, only a panty liner at most.", bodyColor),
        _buildParagraph("Spotting is one of the most common and most misunderstood experiences in the menstrual cycle. It can feel alarming the first time it happens, but in the majority of cases it has a completely benign hormonal cause. Spotting, or light vaginal discharge, can be a totally normal part of the menstrual cycle.", bodyColor, citation: "ScienceDirect"),
        _buildParagraph("Understanding the timing and context of spotting — specifically where you are in your cycle when it occurs — is the single most useful tool for interpreting what it means.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 2: TABLE ---
        _buildHeading("Spotting vs. a period — the key differences", textColor),
        _buildParagraph("Many people confuse spotting with the start of a light period. Here is how to tell them apart:", bodyColor),
        const SizedBox(height: 8),
        
        _buildComparisonTable(isDark, highlightColor, textColor),
        
        const SizedBox(height: 16),
        _buildParagraph("Spotting before your period may appear only when wiping or as a few drops on a panty liner. Menstrual bleeding, in contrast, lasts about 2 to 7 days and is continuous, often increasing in intensity before tapering off.", bodyColor, citation: "Cleveland Clinic"),
        const SizedBox(height: 32),

        // --- SECTION 3: COMMON CAUSES ---
        _buildHeading("The most common causes of spotting", textColor),
        
        _buildSubheading("1. Ovulation spotting", textColor),
        _buildParagraph("Mid-cycle bleeding, which generally takes the form of light spotting, is most commonly associated with ovulation. In a BioCycle Study, approximately 5% of women self-reported mid-cycle bleeding during or around the time of expected ovulation. Since ovulation bleeding is relatively uncommon, and can occur randomly or infrequently, it can easily be mistaken as a sign of something else.", bodyColor, citation: "Amegroups"),
        _buildParagraph("Changes in estrogen levels often cause this type of bleeding — some people refer to ovulation bleeding as estrogen breakthrough bleeding. Right before ovulation, estrogen rises sharply. Then immediately after the egg is released, estrogen drops suddenly while progesterone begins rising. This rapid hormonal shift can cause a small amount of the uterine lining to shed briefly, producing light spotting.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("You tend to release eggs from alternating ovaries — your left one cycle and your right the next. Some people notice spotting when they're ovulating on one side but not the other, which is why it may show up every other cycle.", bodyColor, citation: "Stanford Medicine Children's Health"),
        Text("What it looks like:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Light pink or red, very small amount.", bodyColor),
        _buildSimpleBullet("Lasts a few hours to 1–2 days maximum.", bodyColor),
        _buildSimpleBullet("Occurs around the middle of your cycle — roughly days 11 to 16 in a 28-day cycle.", bodyColor),
        _buildSimpleBullet("May be accompanied by mild one-sided pelvic cramping (mittelschmerz) and egg-white cervical mucus.", bodyColor),
        const SizedBox(height: 24),

        _buildSubheading("2. Pre-period spotting (late luteal spotting)", textColor),
        _buildParagraph("Some people experience light brown or pink spotting in the 1 to 3 days before their period properly begins. This is caused by progesterone dropping at the end of the luteal phase, which causes the uterine lining to begin breaking down before the full menstrual flow starts. It is considered normal when it lasts no more than 3 days and is followed by a normal period.", bodyColor),
        const SizedBox(height: 12),

        _buildSubheading("3. Hormonal fluctuations and anovulatory cycles", textColor),
        _buildParagraph("In cycles where ovulation does not occur — which is common in teenagers — the hormonal patterns are less predictable. Without the LH surge and subsequent progesterone rise, estrogen can fluctuate erratically, causing what is called estrogen breakthrough bleeding. This type of spotting is common in the first 2 to 3 years after your first period as the hormonal system matures.", bodyColor),
        const SizedBox(height: 12),

        _buildSubheading("4. Stress, illness, and significant lifestyle changes", textColor),
        _buildParagraph("The hypothalamus — the part of the brain that controls your hormonal cycle — is highly sensitive to psychological and physiological stress. Significant stress, illness, disrupted sleep, extreme exercise, or sudden weight changes can all disrupt hormonal signalling and cause mid-cycle spotting. This is one of the most common causes of unexplained spotting in teenagers.", bodyColor),
        const SizedBox(height: 12),

        _buildSubheading("5. Cervical ectropion", textColor),
        _buildParagraph("Cervical ectropion is a benign gynaecological condition regarded as a normal variant that frequently occurs in women of reproductive age. It occurs due to increased exposure of the cervical epithelium to estrogen.", bodyColor, citation: "ACOG"),
        _buildParagraph("In simple terms: cells that are normally found inside the cervical canal migrate to the outside of the cervix, where they are more fragile and prone to light bleeding — particularly after physical activity, sex, or even a cervical exam.", bodyColor),
        _buildParagraph("Ectropion is particularly common in adolescents, pregnant women, or those taking estrogen-containing contraceptives. Vaginal discharge is the most common symptom. Postcoital bleeding may also occur.", bodyColor, citation: "UChicago Medicine"),
        _buildParagraph("Importantly, cervical ectropion has no links to cervical cancer or cancer-causing health problems. It is a benign condition that often resolves on its own without any treatment.", bodyColor, citation: "PubMed Central"),
        const SizedBox(height: 32),

        // --- SECTION 4: LESS COMMON CAUSES ---
        _buildHeading("Less common but important causes", textColor),
        _buildSubheading("Sexually transmitted infections (STIs)", textColor),
        _buildParagraph("Sexually transmitted infections such as gonorrhoea or chlamydia may cause the cervical tissue to become inflamed and bleed easily.", bodyColor, citation: "Children's Hospital of Philadelphia"),
        _buildParagraph("Chlamydia in particular is often completely symptomless — the only sign may be unexpected spotting or bleeding after sex. Cervical ectropion (19–34%), cervical or endometrial polyps (5–18%), and infection including vaginitis and cervicitis are common causes of irregular spotting in premenopausal patients.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("This is one of the reasons why regular STI screening is recommended for sexually active teenagers — not because it assumes anything, but because chlamydia is the most commonly reported STI in the under-25 age group and is entirely treatable with a short course of antibiotics.", bodyColor),
        const SizedBox(height: 12),

        _buildSubheading("Cervical polyps", textColor),
        _buildParagraph("Cervical polyps are small growths that develop on the cervix. Most are benign but could cause bleeding after intercourse or between periods.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("They are more common in older adults but can occasionally occur in teenagers. They are usually found incidentally during a pelvic examination and can be removed easily in a clinical setting.", bodyColor),
        const SizedBox(height: 12),

        _buildSubheading("Anovulatory cycles", textColor),
        _buildParagraph("In cycles where no egg is released, progesterone is not produced — because progesterone only comes from the corpus luteum that forms after ovulation. Without progesterone to stabilise the uterine lining, estrogen alone controls the endometrium, causing it to thicken unevenly and shed irregularly. This produces unpredictable spotting that does not follow a clear pattern.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 5: COLOURS ---
        _buildHeading("What colour is spotting and what does it mean?", textColor),
        _buildParagraph("The colour of spotting carries information:", bodyColor),
        _buildBullet("Light pink", "Fresh blood mixed with cervical mucus. Common with ovulation spotting or very early menstruation.", bodyColor, textColor),
        _buildBullet("Bright red", "Fresh active bleeding. More associated with the start of a period or ovulation spotting during a heavy estrogen shift.", bodyColor, textColor),
        _buildBullet("Brown or rust", "Older blood that has taken time to travel through the cervical canal. Very common with pre-period spotting, the end of a period, or post-ovulation spotting.", bodyColor, textColor),
        _buildBullet("Dark brown or almost black", "Very old blood, often from the tail end of a period or from blood that was briefly retained. Not inherently concerning on its own.", bodyColor, textColor),
        
        const SizedBox(height: 12),
        Text("Key points:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildSimpleBullet("Brown spotting is almost always old blood — not an emergency.", bodyColor),
        _buildSimpleBullet("Pink spotting mid-cycle is one of the clearest signs of ovulation spotting.", bodyColor),
        _buildSimpleBullet("Bright red bleeding outside of your period window is worth noting and monitoring.", bodyColor),
        _buildSimpleBullet("Colour alone is not diagnostic — timing and context matter far more.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 6: NORMAL SPOTTING ---
        _buildHeading("Spotting that is almost always normal", textColor),
        _buildSimpleBullet("Light pink or brown spotting for 1–2 days around your expected ovulation window.", bodyColor),
        _buildSimpleBullet("Brown spotting in the 1–3 days before your period begins.", bodyColor),
        _buildSimpleBullet("Very light spotting in the first 1–2 days after your period ends.", bodyColor),
        _buildSimpleBullet("Occasional mid-cycle spotting in the first 2–3 years after your first period.", bodyColor),
        const SizedBox(height: 32),

        // --- SECTION 7: WHEN TO SEE A DOCTOR ---
        _buildHeading("When should you talk to a doctor?", textColor),
        _buildParagraph("Most spotting is harmless. But there are specific patterns that are worth getting checked:", bodyColor),
        _buildSimpleBullet("Spotting that lasts more than 3 days outside of your period.", bodyColor),
        _buildSimpleBullet("Spotting that occurs consistently after sex — this should always be investigated, even if it turns out to be something benign like cervical ectropion.", bodyColor),
        _buildSimpleBullet("Spotting accompanied by pelvic pain, unusual discharge, or an unpleasant odour — these can be signs of an infection.", bodyColor),
        _buildSimpleBullet("Spotting that is getting heavier over time rather than staying light.", bodyColor),
        _buildSimpleBullet("Spotting that occurs in a completely unpredictable pattern with no connection to your cycle phases across several months.", bodyColor),
        
        const SizedBox(height: 16),
        _buildParagraph("Any abnormal bleeding that causes significant anxiety or concern — even if the clinical cause turns out to be benign — is a valid reason to seek a medical opinion. A 2023 study reported the prevalence of abnormal uterine bleeding assessed by self-perception was 31.4%", bodyColor, citation: "American Academy of Family Physicians"),
        _buildParagraph("Meaning nearly one in three people who menstruate report some form of abnormal bleeding at some point. You are not being dramatic by asking a doctor about it.", bodyColor),
        
        const SizedBox(height: 16),
        _buildParagraph("A note on spotting after sex specifically: Cervical ectropion, cervical polyps, and infection are the most common causes of postcoital bleeding in premenopausal patients — the majority of which are benign and treatable.", bodyColor, citation: "PubMed Central"),
        _buildParagraph("Spotting after sex once is not necessarily cause for concern. Spotting after sex repeatedly is worth mentioning to a doctor, not because it is likely to be serious, but because it is easy to assess and easy to treat.", bodyColor),
        const SizedBox(height: 48),

        // --- SECTION 8: SOURCES ---
        Divider(color: isDark ? Colors.white24 : Colors.black12),
        const SizedBox(height: 24),
        Text("Reviewed sources & bibliography", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        _buildSourceItem("Primary research:", isDark),
        _buildSourceItem("• Jones K, et al. Anovulatory Bleeding. StatPearls Publishing, Updated 2023.", isDark),
        _buildSourceItem("• Ardestani S, Dason ES, Sobel M. Postcoital bleeding. CMAJ, September 11, 2023.", isDark),
        _buildSourceItem("• Zhang CY, Li H et al. Abnormal uterine bleeding patterns determined through menstrual tracking... American Journal of Obstetrics and Gynecology, 2023.", isDark),
        _buildSourceItem("• Aggarwal P, Ben Amor A. Cervical Ectropion. StatPearls Publishing, Updated 2023.", isDark),
        _buildSourceItem("• Owens GL, Wood NJ, Martin-Hirsch P. Investigation and management of postcoital bleeding. Obstet Gynaecol, 2022.", isDark),
        const SizedBox(height: 12),
        _buildSourceItem("Clinical and educational resources:", isDark),
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

  // --- CUSTOM COMPARISON TABLE ---
  Widget _buildComparisonTable(bool isDark, Color highlightColor, Color textColor) {
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
          _buildTableCell("Spotting", textColor, isHeader: true),
          _buildTableCell("Period", textColor, isHeader: true),
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
            buildRow("Volume", "Very light — only requires a panty liner", "Moderate to heavy — requires a pad or tampon"),
            buildRow("Colour", "Light pink, brown, or rust", "Bright red to deep red"),
            buildRow("Duration", "Hours to 1–2 days", "3 to 7 days"),
            buildRow("Clots", "None", "Possible, especially on heavy days"),
            buildRow("Timing", "Between periods, mid-cycle, or just before/after", "Follows your regular cycle rhythm"),
            buildRow("Cramping", "Minimal or none", "Common, especially day 1–2"),
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