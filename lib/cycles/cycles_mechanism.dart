import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A data class to smoothly pass all processed data over to the UI file
class CycleDashboardData {
  final int avgCycleLength;
  final int cycleDayToday;
  final DateTime nextPeriodDate;
  final int daysUntilNextPeriod;
  final String currentCycleId;
  final List<Map<String, String>> deviationAlerts;
  final String phaseText;
  final String countdownText;
  final String insightText;
  final int healthScore;
  final Color healthColor;
  final String? confidenceBadge;
  final List<int> loggedCycleDays; // <-- NEW: Added to pass to the UI

  CycleDashboardData({
    required this.avgCycleLength,
    required this.cycleDayToday,
    required this.nextPeriodDate,
    required this.daysUntilNextPeriod,
    required this.currentCycleId,
    required this.deviationAlerts,
    required this.phaseText,
    required this.countdownText,
    required this.insightText,
    required this.healthScore,
    required this.healthColor,
    this.confidenceBadge,
    required this.loggedCycleDays, // <-- NEW
  });
}

/// The logic mechanism that powers CyclesPage without cluttering the UI
mixin CyclesMechanism<T extends StatefulWidget> on State<T> {
  DateTime simulatedToday = DateTime.now();

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  // --- FIRESTORE BATCH OVERFLOW & BUG 4 FIX ---
  Future<void> performDataWipe() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final logsSnap = await userRef.collection('daily_logs').get();
    final cyclesSnap = await userRef.collection('cycles').get();

    final allDocs = [...logsSnap.docs, ...cyclesSnap.docs];

    const int chunkSize = 400;
    for (int i = 0; i < allDocs.length; i += chunkSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = allDocs.sublist(i, min(i + chunkSize, allDocs.length));
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await userRef.update({
      'cyclesSetupCompleted': false,
      'loggedCyclesCount': 0, 
      'pastCycles': FieldValue.delete(), 
      'dismissedAlerts': FieldValue.delete(), 
      'lastPeriodStart': FieldValue.delete(),
    });
  }

  double calculateStdDev(List<int> values) {
    if (values.length < 2) return 0.0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  int calculateHealthScore(List<Map<String, dynamic>> recentCycles) {
    if (recentCycles.isEmpty) return 100;
    int score = 100;

    for (var c in recentCycles) {
      int cLen = c['cycleLength'] ?? 28;
      
      if (cLen < 21 || cLen > 35) score -= 10;
      if ((c['spottingDays'] ?? 0) > 2) score -= 5;
      if ((c['veryHeavyDays'] ?? 0) >= 5) score -= 10;
    }

    final lengths = recentCycles.map((c) => c['cycleLength'] as int).toList();
    double stdDev = calculateStdDev(lengths);

    if (stdDev > 5) score -= 15;
    else if (stdDev > 3) score -= 5;

    return score.clamp(0, 100);
  }

  Future<void> dismissAlert(String alertId, String currentCycleId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'dismissedAlerts': { alertId: currentCycleId }
    }, SetOptions(merge: true));
  }

  List<Map<String, String>> getDeviationAlerts(Map<String, dynamic> userData, int daysUntilNextPeriod, List<Map<String, dynamic>> recentCycles, String currentCycleId) {
    List<Map<String, String>> alerts = [];

    bool isDismissed(String alertId) {
      final dismissedAlerts = userData['dismissedAlerts'] as Map<String, dynamic>? ?? {};
      return dismissedAlerts[alertId] == currentCycleId;
    }

    if (daysUntilNextPeriod < -90 && !isDismissed('missing_90')) {
      alerts.add({
        'id': 'missing_90', 
        'title': 'Period Over 3 Months Late',
        'msg': "Your period is over 3 months late. This could indicate PCOS or hormonal changes. Please consult a healthcare provider.",
        'learnMore': "Going 3 months without a period is called amenorrhea, and it always deserves medical attention. In teenagers and young adults, the most common causes are significant stress, very low body weight, intense athletic training, or hormonal imbalances like PCOS or thyroid disorders. These are all conditions that doctors deal with regularly and can treat effectively. Please speak to a doctor, school nurse, or a trusted adult as soon as possible — the earlier it's looked into, the easier it is to manage."
      });
    } else if (daysUntilNextPeriod < -14 && !isDismissed('late_14')) {
      alerts.add({
        'id': 'late_14', 
        'title': 'Period 14 Days Late',
        'msg': "Your period is 14 days late. You may want to speak to a doctor if this is unusual for you.",
        'learnMore': "A period that's 2 weeks late is worth paying attention to. While stress and lifestyle factors can cause delays this long, it's a good idea to speak to a doctor or a trusted adult at this point. They can check if anything hormonal is going on, like a thyroid issue or a condition called PCOS (polycystic ovary syndrome), which is actually very common and very treatable. You don't need to panic — but you shouldn't ignore it either. Getting it checked early is always the right move."
      });
    } else if (daysUntilNextPeriod < -7 && daysUntilNextPeriod >= -14 && !isDismissed('late_7')) {
      alerts.add({
        'id': 'late_7', 
        'title': 'Period 7 Days Late',
        'msg': "Your period is 7 days late. This can happen due to stress, illness or changes in routine.",
        'learnMore': "A period that's up to 7 days late is considered within the normal range of variation. Your cycle is controlled by a complex hormonal system that's sensitive to what's happening in your life. Common causes at your age include exam stress, travel, changes in sleep patterns, skipping meals, intense exercise, or even being sick recently. Your body isn't a perfect clock — small delays are normal and usually nothing to worry about. If this keeps happening, tracking your cycle consistently will help you spot patterns over time."
      });
    }

    if (recentCycles.length >= 6) {
      final lengths = recentCycles.map((c) => c['cycleLength'] as int).toList();
      double stdDev = calculateStdDev(lengths);
      if (stdDev > 4.5 && !isDismissed('irregular')) {
        alerts.add({
          'id': 'irregular', 
          'title': 'Highly Irregular Cycles',
          'msg': "Your cycles have been highly irregular recently. While this can be normal, consider speaking to a doctor if concerned.",
          'learnMore': "Cycle irregularity means the gap between your periods varies significantly from month to month. Some variation — a few days here and there — is completely normal. High irregularity over many cycles can be a sign that your body's hormonal signals aren't fully in sync yet, which is common in your teens. It can also be linked to conditions like PCOS, stress, or changes in weight. Tracking your cycle consistently is one of the most useful things you can do — the data helps doctors understand what's happening much faster. If you're concerned, a gynaecologist or your regular doctor can run hormone tests to get a clearer picture."
        });
      }
    }

    if (recentCycles.length >= 3) {
      final last3 = recentCycles.sublist(recentCycles.length - 3);
      bool allShort = last3.every((c) => (c['cycleLength'] as int) < 21);
      bool allLong = last3.every((c) => (c['cycleLength'] as int) > 35);
      
      if (allShort && !isDismissed('short_cycle')) {
        alerts.add({
          'id': 'short_cycle', 
          'title': 'Unusually Short Cycles',
          'msg': "Your last 3 cycles have been unusually short. Stress, travel, and illness can affect this.",
          'learnMore': "A cycle shorter than 21 days means your period is coming more frequently than usual. For teenagers, short cycles are sometimes normal as your body is still regulating itself — especially in the first few years after your first period. However, consistently short cycles can sometimes indicate low progesterone levels or a condition called a luteal phase defect. It can also just mean your body is responding to stress or nutritional changes. If it keeps happening across 3 or more cycles, mention it to a doctor — it's an easy thing to investigate."
        });
      }
      if (allLong && !isDismissed('long_cycle')) {
        alerts.add({
          'id': 'long_cycle', 
          'title': 'Unusually Long Cycles',
          'msg': "Your last 3 cycles have been unusually long. If this keeps happening, mention it to a doctor.",
          'learnMore': "A cycle longer than 35 days means your body is taking more time than usual to ovulate and menstruate. This is actually very common in teenagers because the hormonal system that controls your cycle takes several years to fully regulate after your first period. Longer cycles can also be linked to PCOS, thyroid issues, or simply stress and lifestyle factors. As long as your period does eventually arrive and you feel okay, an occasional long cycle is usually fine. If it's consistently over 35 days for several months in a row, a doctor can do a simple blood test to check your hormone levels."
        });
      }
    }

    if (recentCycles.length >= 2 && !isDismissed('long_period')) {
      final last2 = recentCycles.sublist(recentCycles.length - 2);
      bool bothLongPeriods = last2.every((c) => (c['periodLength'] as int) > 8);
      if (bothLongPeriods) {
        alerts.add({
          'id': 'long_period', 
          'title': 'Long Periods',
          'msg': "Your period has been lasting longer than usual (over 8 days). If this continues, check in with a doctor.",
          'learnMore': "Periods usually last between 3 to 7 days. Bleeding for longer than 8 days regularly can lower your iron levels, making you feel tired and weak. This can be caused by hormonal imbalances where your body builds up too much uterine lining, or simply because your cycle is still regulating. If you consistently have periods lasting longer than 8 days, mention it to a doctor. They can provide advice and check to make sure your iron levels are healthy."
        });
      }
    }

    if (recentCycles.isNotEmpty) {
      final lastCycle = recentCycles.last;
      if ((lastCycle['veryHeavyDays'] ?? 0) >= 5 && !isDismissed('heavy_bleeding')) {
         alerts.add({
          'id': 'heavy_bleeding', 
          'title': 'Very Heavy Bleeding',
          'msg': "Your last period had 5 or more days of very heavy bleeding. If this is unusual or causes fatigue, consult a doctor.",
          'learnMore': "Heavy bleeding during your period — needing to change a pad or tampon every hour or two for several hours — is called menorrhagia. Having 5 or more very heavy days in a single period can lead to iron deficiency over time, which causes fatigue and dizziness. Common causes include hormonal imbalances, a condition called endometriosis, or uterine fibroids — though these are less common in teenagers. Sometimes it's simply how your body is wired. Either way, consistently heavy periods are worth mentioning to a doctor. They can check your iron levels and help make your periods more manageable if needed."
         });
      }
    }

    return alerts;
  }

  /// Processes all strings, colors, and math logic to keep it out of the UI
  CycleDashboardData processDashboardData(
    Map<String, dynamic> userData, 
    List<Map<String, dynamic>> recentCycles,
    List<Map<String, dynamic>> currentCycleLogs // <-- NEW: Now accepts logs
  ) {
    final DateTime lastPeriodStart = (userData['lastPeriodStart'] as Timestamp?)?.toDate() ?? simulatedToday;
    final int loggedCyclesCount = userData['loggedCyclesCount'] ?? 0;

    int avgCycleLength = userData['cycleLength'] ?? 28;
    int avgPeriodLength = userData['periodLength'] ?? 5;

    if (recentCycles.isNotEmpty) {
      avgCycleLength = (recentCycles.map((c) => c['cycleLength'] as int).reduce((a, b) => a + b) / recentCycles.length).round();
      avgPeriodLength = (recentCycles.map((c) => c['periodLength'] as int).reduce((a, b) => a + b) / recentCycles.length).round();
    }

    int estimatedOvulationDay = avgCycleLength - 14;
    DateTime nextPeriodDate = dateOnly(lastPeriodStart).add(Duration(days: avgCycleLength));

    int cycleDayToday = dateOnly(simulatedToday).difference(dateOnly(lastPeriodStart)).inDays + 1;
    final int daysUntilNextPeriod = dateOnly(nextPeriodDate).difference(dateOnly(simulatedToday)).inDays;

    cycleDayToday = min(cycleDayToday, avgCycleLength * 2);

    final String currentCycleId = (userData['lastPeriodStart'] as Timestamp?)?.toDate().toIso8601String() ?? 'unknown';
    final List<Map<String, String>> deviationAlerts = getDeviationAlerts(userData, daysUntilNextPeriod, recentCycles, currentCycleId);

    // --- NEW: Calculate Logged Days for Markers ---
    List<int> loggedCycleDays = [];
    for (var log in currentCycleLogs) {
      String flow = log['flow'] ?? 'None';
      
      // We only want a marker if they DID NOT log a period flow today
      bool isPeriodFlow = ['Spotting', 'Light', 'Medium', 'Heavy', 'Very Heavy'].contains(flow);
      
      if (!isPeriodFlow) {
        DateTime logDate = (log['date'] as Timestamp).toDate();
        int loggedDay = dateOnly(logDate).difference(dateOnly(lastPeriodStart)).inDays + 1;
        if (loggedDay > 0) {
          loggedCycleDays.add(loggedDay);
        }
      }
    }
    // ----------------------------------------------

    String phaseText;
    String countdownText;

    if (cycleDayToday >= 1 && cycleDayToday <= avgPeriodLength) {
      phaseText = "Your period is here";
    } else if (cycleDayToday > avgPeriodLength && cycleDayToday < estimatedOvulationDay) {
      phaseText = "Your egg is growing"; 
    } else if (cycleDayToday == estimatedOvulationDay) {
      phaseText = "Ovulation today";
    } else if (cycleDayToday > estimatedOvulationDay && cycleDayToday <= avgCycleLength) {
      phaseText = "Body is waiting"; 
    } else {
      phaseText = "Period due soon";
    }

    if (daysUntilNextPeriod > 0) {
      countdownText = "Your next period is in $daysUntilNextPeriod days";
    } else if (daysUntilNextPeriod == 0) {
      countdownText = "Your period is due today";
    } else {
      countdownText = "Your period is ${daysUntilNextPeriod.abs()} days late";
    }

    String insightText = "";
    if (daysUntilNextPeriod < 0) {
      insightText = "Your period is running late. This is more common than you think and doesn't always mean something is wrong. Stress, changes in sleep, illness, sudden weight changes, and intense exercise can all delay your cycle by several days or even weeks. If it's been over 2 weeks, it's worth taking a moment to check in with a trusted adult or doctor.";
    } else if (daysUntilNextPeriod <= 2 && cycleDayToday > estimatedOvulationDay) {
      insightText = "Your period could arrive any day now. Progesterone levels are dropping which is what triggers menstruation to begin. You might feel more emotional, tired, or notice lower back discomfort — these are signs your body is getting ready. Keep a pad or period product nearby just in case.";
    } else if (cycleDayToday <= avgPeriodLength) {
      insightText = "Your period is here because your body didn't need the uterine lining it built up this month, so it's shedding it. This is driven by a drop in estrogen and progesterone — your two main cycle hormones. Cramps happen because your uterus is contracting to push the lining out. Rest, heat pads, and staying hydrated can genuinely help right now.";
    } else if (cycleDayToday < estimatedOvulationDay) {
      insightText = "Your body is now growing and maturing an egg inside your ovaries. Rising estrogen levels are doing a lot of good work — rebuilding your uterine lining and boosting your mood and energy. Most people feel their best during this phase. It's a great time to be active, social, and take on things that need focus.";
    } else if (cycleDayToday == estimatedOvulationDay) {
      insightText = "Your body is releasing an egg today. A surge in a hormone called LH triggered this, and your estrogen is at its peak. You might notice clearer, stretchy discharge — this is completely normal and actually helps the reproductive system function. Some people feel a slight twinge or pain on one side of their lower abdomen during ovulation, which is also normal.";
    } else {
      insightText = "After ovulation, your body produces more progesterone to prepare for a possible pregnancy. This hormone is responsible for most PMS symptoms — bloating, breast tenderness, mood swings, and fatigue are all very common in this phase. If your period isn't coming, these symptoms will peak around 5 to 7 days before it arrives. You're not imagining it, it's hormonal.";
    }

    int healthScore = calculateHealthScore(recentCycles);
    Color healthColor = healthScore > 80 ? Colors.greenAccent : (healthScore > 50 ? Colors.orangeAccent : Colors.redAccent);

    String? confidenceBadge;
    double stdDev = recentCycles.isEmpty ? 0 : calculateStdDev(recentCycles.map((c) => c['cycleLength'] as int).toList());

    if (loggedCyclesCount >= 6 && stdDev <= 4.5) {
      confidenceBadge = "High Confidence";
    } else if (loggedCyclesCount >= 3 && stdDev <= 6.0) {
      confidenceBadge = "Medium Confidence";
    } else {
      confidenceBadge = "Low Confidence";
    }

    return CycleDashboardData(
      avgCycleLength: avgCycleLength,
      cycleDayToday: cycleDayToday,
      nextPeriodDate: nextPeriodDate,
      daysUntilNextPeriod: daysUntilNextPeriod,
      currentCycleId: currentCycleId,
      deviationAlerts: deviationAlerts,
      phaseText: phaseText,
      countdownText: countdownText,
      insightText: insightText,
      healthScore: healthScore,
      healthColor: healthColor,
      confidenceBadge: confidenceBadge,
      loggedCycleDays: loggedCycleDays, // <-- NEW: Output to the UI
    );
  }
}