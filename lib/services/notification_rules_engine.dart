import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/app_notifications_service.dart';

class NotificationRulesEngine {
  NotificationRulesEngine._();

  static bool _running = false;

  /// Cache the last known localizations so timer-based calls (no context)
  /// can still use the correct locale.
  static AppLocalizations? _cachedT;

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static Future<void> evaluateGlobal({AppLocalizations? t}) async {
    if (_running) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Update cache if a fresh instance was provided.
    if (t != null) _cachedT = t;
    final localizations = _cachedT;
    // If we have no localizations at all yet, skip — will run again once
    // a widget provides them.
    if (localizations == null) return;

    _running = true;
    try {
      await AppNotificationsService.instance.init();
      final now = DateTime.now();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? const <String, dynamic>{};

      await Future.wait([
        _evaluateDiet(t: localizations, userRef: userRef, uid: uid, userData: userData, now: now),
        _evaluateMindfulness(
          t: localizations,
          userRef: userRef,
          uid: uid,
          userData: userData,
          now: now,
        ),
        _evaluateCycles(t: localizations, userRef: userRef, userData: userData, now: now),
        _evaluateFinance(t: localizations, userRef: userRef, uid: uid, userData: userData, now: now),
        _evaluateDashboard(t: localizations, userRef: userRef, now: now),
      ]);
    } catch (error) {
      debugNotification('Rules engine failed: $error');
    } finally {
      _running = false;
    }
  }

  static Future<void> _evaluateDiet({
    required AppLocalizations t,
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    // Don't send diet notifications until the user has completed diet setup.
    final dietSetupDone = (userData['dietSetupCompleted'] as bool?) ?? false;
    if (!dietSetupDone) return;
    final todayKey = _dateKey(now);
    final dailyCalorieGoal =
        (userData['dailyCalorieGoal'] as num?)?.toInt() ?? 2000;
    final waterGoal = (userData['dailyWaterGoalGlasses'] as num?)?.toInt() ?? 8;
    final dailyAggDoc = await userRef.collection('dailyAgg').doc(todayKey).get();
    final dailyAgg = dailyAggDoc.data() ?? const <String, dynamic>{};
    final todayCalories = (dailyAgg['caloriesLogged'] as num?)?.toInt() ?? 0;
    final waterGlasses = (dailyAgg['waterGlasses'] as num?)?.toInt() ?? 0;
    final hasMealToday = (dailyAgg['mealLogged'] as bool?) ?? false;

    if (!hasMealToday && now.hour >= 20) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_meal_logging_$todayKey',
        title: t.notifDietMealTitle,
        body: t.notifDietMealBody,
        now: now,
      );
    }

    if (waterGlasses < waterGoal && now.hour >= 12 && now.hour <= 21) {
      await AppNotificationsService.instance.showWithCooldown(
        uniqueKey: 'diet_water_behind',
        title: t.notifDietWaterTitle,
        body: t.notifDietWaterBody(waterGlasses, waterGoal),
        cooldown: const Duration(hours: 4),
        now: now,
      );
    }

    final eightyPercent = (dailyCalorieGoal * 0.8).round();
    if (todayCalories >= eightyPercent &&
        todayCalories < dailyCalorieGoal &&
        now.hour >= 12) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_goal_nudge_$todayKey',
        title: t.notifDietCalorieNudgeTitle,
        body: t.notifDietCalorieNudgeBody(todayCalories, dailyCalorieGoal),
        now: now,
      );
    }

    final streakStart = _dateKey(now.subtract(const Duration(days: 13)));
    final streakAggSnap = await userRef
        .collection('dailyAgg')
        .where('dateKey', isGreaterThanOrEqualTo: streakStart)
        .orderBy('dateKey', descending: true)
        .get();
    final byDate = <String, Map<String, dynamic>>{
      for (final d in streakAggSnap.docs) d.id: d.data(),
    };
    var streak = 0;
    for (var i = 0; i < 14; i++) {
      final key = _dateKey(now.subtract(Duration(days: i)));
      final cal = (byDate[key]?['caloriesLogged'] as num?)?.toInt() ?? 0;
      if (cal >= dailyCalorieGoal) {
        streak += 1;
      } else {
        break;
      }
    }
    if (streak > 0 && streak % 3 == 0) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_streak_${streak}_$todayKey',
        title: t.notifDietStreakTitle(streak),
        body: t.notifDietStreakBody(streak),
        now: now,
      );
    }
  }

  static Future<void> _evaluateMindfulness({
    required AppLocalizations t,
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    // Don't send mindfulness notifications until the user has completed
    // mindfulness onboarding.
    final mindfulnessDone =
        (userData['mindfulnessOnboardingCompleted'] as bool?) ?? false;
    if (!mindfulnessDone) return;
    final todayKey = _dateKey(now);
    final dailyAggDoc = await userRef.collection('dailyAgg').doc(todayKey).get();
    final dailyAgg = dailyAggDoc.data() ?? const <String, dynamic>{};
    final moodLogged = (dailyAgg['moodLogged'] as bool?) ?? false;
    final readinessLogged = (dailyAgg['readinessLogged'] as bool?) ?? false;

    if (!moodLogged && now.hour >= 19) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_mood_check_$todayKey',
        title: t.notifMindfulnessMoodTitle,
        body: t.notifMindfulnessMoodBody,
        now: now,
      );
    }

    if (!readinessLogged && now.hour >= 10 && now.hour <= 14) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_readiness_$todayKey',
        title: t.notifMindfulnessReadinessTitle,
        body: t.notifMindfulnessReadinessBody,
        now: now,
      );
    }

    if (!moodLogged && !readinessLogged && now.hour >= 21) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_breathe_$todayKey',
        title: t.notifMindfulnessBreatheTitle,
        body: t.notifMindfulnessBreatheBody,
        now: now,
      );
    }

    if (userData.isEmpty || uid.isEmpty) return;
  }

  static Future<void> _evaluateCycles({
    required AppLocalizations t,
    required DocumentReference<Map<String, dynamic>> userRef,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    final setupDone = (userData['cyclesSetupCompleted'] as bool?) ?? false;
    if (!setupDone) return;

    final lastStartTs = userData['lastPeriodStart'] as Timestamp?;
    if (lastStartTs == null) return;
    final cycleLength = (userData['cycleLength'] as num?)?.toInt() ?? 28;
    final periodLength = (userData['periodLength'] as num?)?.toInt() ?? 5;
    final lastPeriodStart = _dayStart(lastStartTs.toDate());
    final nextPeriod = lastPeriodStart.add(Duration(days: cycleLength));
    final daysUntilNext = _dayStart(nextPeriod).difference(_dayStart(now)).inDays;
    final cycleDay = _dayStart(now).difference(lastPeriodStart).inDays + 1;
    final ovulationDay = math.max(1, cycleLength - 14);

    final todayKey = _dateKey(now);
    final logDoc = await userRef.collection('daily_logs').doc(todayKey).get();
    if (!logDoc.exists && now.hour >= 20) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_daily_log_$todayKey',
        title: t.notifCyclesDailyLogTitle,
        body: t.notifCyclesDailyLogBody,
        now: now,
      );
    }

    if (daysUntilNext == 2) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_period_soon_$todayKey',
        title: t.notifCyclesPeriodSoonTitle,
        body: t.notifCyclesPeriodSoonBody,
        now: now,
      );
    } else if (daysUntilNext == 0) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_due_today_$todayKey',
        title: t.notifCyclesPeriodDueTodayTitle,
        body: t.notifCyclesPeriodDueTodayBody,
        now: now,
      );
    } else if (daysUntilNext <= -7 && daysUntilNext > -14) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_7_$todayKey',
        title: t.notifCyclesLate7Title,
        body: t.notifCyclesLate7Body,
        now: now,
      );
    } else if (daysUntilNext <= -14 && daysUntilNext > -90) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_14_$todayKey',
        title: t.notifCyclesLate14Title,
        body: t.notifCyclesLate14Body,
        now: now,
      );
    } else if (daysUntilNext <= -90) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_90_$todayKey',
        title: t.notifCyclesLate90Title,
        body: t.notifCyclesLate90Body,
        now: now,
      );
    }

    if (cycleDay == ovulationDay - 2) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_ovulation_window_$todayKey',
        title: t.notifCyclesOvulationWindowTitle,
        body: t.notifCyclesOvulationWindowBody,
        now: now,
      );
    }
    if (cycleDay == ovulationDay) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_ovulation_peak_$todayKey',
        title: t.notifCyclesOvulationPeakTitle,
        body: t.notifCyclesOvulationPeakBody,
        now: now,
      );
    }

    final recentCyclesSnap = await userRef
        .collection('cycles')
        .orderBy('startDate', descending: true)
        .limit(6)
        .get();
    final recentCycles = recentCyclesSnap.docs
        .map((d) => d.data())
        .toList()
        .reversed
        .toList();
    if (recentCycles.length >= 3) {
      final last3 = recentCycles.sublist(recentCycles.length - 3);
      final allShort = last3.every((c) => ((c['cycleLength'] as num?) ?? 28) < 21);
      final allLong = last3.every((c) => ((c['cycleLength'] as num?) ?? 28) > 35);
      if (allShort) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_short_cycle_$todayKey',
          title: t.notifCyclesShortCycleTitle,
          body: t.notifCyclesShortCycleBody,
          now: now,
        );
      }
      if (allLong) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_long_cycle_$todayKey',
          title: t.notifCyclesLongCycleTitle,
          body: t.notifCyclesLongCycleBody,
          now: now,
        );
      }
    }
    if (recentCycles.length >= 2) {
      final last2 = recentCycles.sublist(recentCycles.length - 2);
      final longPeriods = last2.every(
        (c) => ((c['periodLength'] as num?) ?? periodLength) > 8,
      );
      if (longPeriods) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_long_period_$todayKey',
          title: t.notifCyclesLongPeriodTitle,
          body: t.notifCyclesLongPeriodBody,
          now: now,
        );
      }
    }
    if (recentCycles.isNotEmpty) {
      final last = recentCycles.last;
      final veryHeavyDays = ((last['veryHeavyDays'] as num?) ?? 0).toInt();
      if (veryHeavyDays >= 5) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_heavy_bleeding_$todayKey',
          title: t.notifCyclesHeavyBleedingTitle,
          body: t.notifCyclesHeavyBleedingBody,
          now: now,
        );
      }
    }
  }

  static Future<void> _evaluateFinance({
    required AppLocalizations t,
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    // Don't send finance notifications until the user has completed finance
    // onboarding (set up their accounts and budget).
    final financeSetupDone = (userData['financeSetupCompleted'] as bool?) ?? false;
    if (!financeSetupDone) return;
    final financeDebtsRef = userRef.collection('finance_debts');
    final debtsSnap = await financeDebtsRef.get();
    final todayKey = _dateKey(now);
    final todayStart = _dayStart(now);

    for (final debtDoc in debtsSnap.docs) {
      final debt = debtDoc.data();
      final isPaid = (debt['isPaid'] as bool?) ?? false;
      final title = (debt['title'] as String?)?.trim().isNotEmpty == true
          ? debt['title'] as String
          : 'Debt';

      if (isPaid) {
        final paidKey = 'finance_debt_paid_${debtDoc.id}';
        final alreadyMarked = await AppNotificationsService.instance.hasMarked(
          paidKey,
        );
        if (!alreadyMarked) {
          await AppNotificationsService.instance.show(
            uniqueKey: paidKey,
            title: t.notifFinanceDebtClearedTitle,
            body: t.notifFinanceDebtClearedBody(title),
          );
          await AppNotificationsService.instance.markOnce(uniqueKey: paidKey);
        }
        continue;
      }

      final dueTs = debt['dueDate'] as Timestamp?;
      if (dueTs != null) {
        final dueDate = _dayStart(dueTs.toDate());
        final daysUntilDue = dueDate.difference(todayStart).inDays;
        if (daysUntilDue == 7 ||
            daysUntilDue == 3 ||
            daysUntilDue == 1 ||
            daysUntilDue == 0) {
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_debt_due_${debtDoc.id}_$todayKey',
            title: t.notifFinanceDebtDueTitle(title),
            body: daysUntilDue == 0
                ? t.notifFinanceDebtDueTodayBody
                : t.notifFinanceDebtDueDaysBody(daysUntilDue),
            now: now,
          );
        } else if (daysUntilDue < 0) {
          final overdueDays = daysUntilDue.abs();
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_debt_overdue_${debtDoc.id}_$todayKey',
            title: t.notifFinanceDebtOverdueTitle,
            body: t.notifFinanceDebtOverdueBody(title, overdueDays),
            now: now,
          );
        }
      }

      final isRecurring = (debt['isRecurring'] as bool?) ?? false;
      if (isRecurring && dueTs != null) {
        final dueDate = _dayStart(dueTs.toDate());
        final daysUntilDue = dueDate.difference(todayStart).inDays;
        if (daysUntilDue <= 2 && daysUntilDue >= 0) {
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_installment_${debtDoc.id}_$todayKey',
            title: t.notifFinanceInstallmentTitle,
            body: t.notifFinanceInstallmentBody(title),
            now: now,
          );
        }
      }
    }

    final accountsSnap = await userRef.collection('finance_accounts').get();
    final lowBalanceThreshold =
        (userData['financeLowBalanceThreshold'] as num?)?.toDouble() ?? 100.0;
    for (final accountDoc in accountsSnap.docs) {
      final name = (accountDoc.data()['name'] as String?) ?? 'Account';
      final balance =
          (accountDoc.data()['balance'] as num?)?.toDouble() ?? 0.0;
      if (balance <= lowBalanceThreshold) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'finance_low_balance_${accountDoc.id}_$todayKey',
          title: t.notifFinanceLowBalanceTitle,
          body: t.notifFinanceLowBalanceBody(name, balance.toStringAsFixed(2)),
          now: now,
        );
      }
    }

    final txSnap = await userRef
        .collection('finance_transactions')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .orderBy('date', descending: true)
        .limit(80)
        .get();

    final largeExpenseThreshold =
        (userData['financeLargeExpenseThreshold'] as num?)?.toDouble() ?? 500.0;
    final monthlyBudget =
        (userData['financeMonthlyBudget'] as num?)?.toDouble() ?? 2000.0;
    var monthExpense = 0.0;

    for (final txDoc in txSnap.docs) {
      final tx = txDoc.data();
      final type = (tx['type'] as String?) ?? 'expense';
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      if (type == 'expense' && amount >= largeExpenseThreshold) {
        final key = 'finance_large_expense_${txDoc.id}';
        final already = await AppNotificationsService.instance.hasMarked(key);
        if (!already) {
          await AppNotificationsService.instance.show(
            uniqueKey: key,
            title: t.notifFinanceLargeExpenseTitle,
            body: t.notifFinanceLargeExpenseBody(amount.toStringAsFixed(2)),
          );
          await AppNotificationsService.instance.markOnce(uniqueKey: key);
        }
      }
    }

    final monthDoc = await userRef
        .collection('financeMonthly')
        .doc(_monthKey(now))
        .get();
    monthExpense = (monthDoc.data()?['expenseTotal'] as num?)?.toDouble() ?? 0.0;
    if (!monthDoc.exists) {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final fallbackMonthSnap = await userRef
          .collection('finance_transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(
              DateTime(now.year, now.month + 1, 1),
            ),
          )
          .get();
      monthExpense = fallbackMonthSnap.docs.fold<double>(0.0, (acc, txDoc) {
        final tx = txDoc.data();
        final type = (tx['type'] as String?) ?? 'expense';
        if (type != 'expense') return acc;
        return acc + ((tx['amount'] as num?)?.toDouble() ?? 0);
      });
    }

    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final expectedSpendByNow = monthlyBudget * (now.day / daysInMonth);
    if (monthExpense > expectedSpendByNow * 1.2 && now.day >= 10) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'finance_budget_pacing_$todayKey',
        title: t.notifFinanceBudgetPacingTitle,
        body: t.notifFinanceBudgetPacingBody(monthExpense.toStringAsFixed(0)),
        now: now,
      );
    }

    if (uid.isEmpty) return;
  }

  static Future<void> _evaluateDashboard({
    required AppLocalizations t,
    required DocumentReference<Map<String, dynamic>> userRef,
    required DateTime now,
  }) async {
    final todayKey = _dateKey(now);
    final aggDoc = await userRef.collection('dailyAgg').doc(todayKey).get();
    final agg = aggDoc.data() ?? const <String, dynamic>{};
    final dashboardUpdated = (agg['dashboardUpdated'] as bool?) ?? false;
    final steps = (agg['dashboardSteps'] as num?)?.toInt() ?? 0;
    final activeCalories = (agg['dashboardActiveCalories'] as num?)?.toInt() ?? 0;

    if ((!dashboardUpdated || (steps == 0 && activeCalories == 0)) &&
        now.hour >= 19) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'dashboard_daily_health_reminder_$todayKey',
        title: t.notifDashboardHealthTitle,
        body: t.notifDashboardHealthBody,
        now: now,
      );
    }
  }
}
