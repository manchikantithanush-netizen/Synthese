import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/services/finance_service.dart';

/// Builds the Contextual Insights section with dismissible insight cards
Widget buildContextualInsights({
  required BuildContext context,
  required bool isDark,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required Stream<QuerySnapshot>? debtsStream,
  required Map<String, Category> categoriesMap,
  required String Function(double) formatCurrency,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const SizedBox.shrink();

  return FutureBuilder<Map<String, dynamic>>(
    future: FinanceService().getDismissedInsights(uid),
    builder: (context, dismissedSnapshot) {
      final dismissedInsights = dismissedSnapshot.data ?? {};

      // Stream user document to get monthlyBudget
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          double monthlyBudget = 0;
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            monthlyBudget = (userData?['monthlyBudget'] as num?)?.toDouble() ?? 0;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: transactionsStream,
            builder: (context, txnSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: debtsStream,
                builder: (context, debtSnapshot) {
                  return FutureBuilder<int>(
                    future: FinanceService().getNoSpendDaysThisWeek(uid),
                    builder: (context, noSpendSnapshot) {
                      return FutureBuilder<int>(
                        future: FinanceService().getUnderBudgetStreak(uid),
                        builder: (context, streakSnapshot) {
                          // Compute all insights
                          final insights = _computeInsights(
                            selectedMonth: selectedMonth,
                            txnSnapshot: txnSnapshot,
                            debtSnapshot: debtSnapshot,
                            categoriesMap: categoriesMap,
                            formatCurrency: formatCurrency,
                            monthlyBudget: monthlyBudget,
                            noSpendDays: noSpendSnapshot.data ?? 0,
                            underBudgetStreak: streakSnapshot.data ?? 0,
                            dismissedInsights: dismissedInsights,
                          );

                          if (insights.isEmpty) return const SizedBox.shrink();

                          return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "For You",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...insights.map((insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InsightCard(
                              insight: insight,
                              isDark: isDark,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              onDismiss: () async {
                                HapticFeedback.lightImpact();
                                await FinanceService().dismissInsight(
                                  uid,
                                  insight.id,
                                  insight.dataHash,
                                );
                              },
                            ),
                          )),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    },
  );
  },
);
}

/// Computes all applicable insights based on current data
List<FinanceInsight> _computeInsights({
  required DateTime selectedMonth,
  required AsyncSnapshot<QuerySnapshot> txnSnapshot,
  required AsyncSnapshot<QuerySnapshot> debtSnapshot,
  required Map<String, Category> categoriesMap,
  required String Function(double) formatCurrency,
  required double monthlyBudget,
  required int noSpendDays,
  required int underBudgetStreak,
  required Map<String, dynamic> dismissedInsights,
}) {
  final insights = <FinanceInsight>[];
  final financeService = FinanceService();

  // Guard: If user has no transactions, return empty
  if (!txnSnapshot.hasData || txnSnapshot.data!.docs.isEmpty) {
    return [];
  }
  final now = selectedMonth;
  final lastMonth = DateTime(now.year, now.month - 1, 1);

  // Parse transactions
  double totalIncome = 0;
  double totalExpenses = 0;
  final Map<String, double> currentMonthByCategory = {};
  final Map<String, double> lastMonthByCategory = {};
  final Map<String, List<double>> categoryAmountHistory = {};

  if (txnSnapshot.hasData) {
    for (var doc in txnSnapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final txn = FinanceTransaction.fromMap(data);

      // Current month
      if (txn.date.year == now.year && txn.date.month == now.month) {
        if (txn.type == 'expense') {
          totalExpenses += txn.amount;
          currentMonthByCategory[txn.categoryId] =
              (currentMonthByCategory[txn.categoryId] ?? 0) + txn.amount;
        } else {
          totalIncome += txn.amount;
        }
      }

      // Last month expenses by category
      if (txn.type == 'expense' &&
          txn.date.year == lastMonth.year &&
          txn.date.month == lastMonth.month) {
        lastMonthByCategory[txn.categoryId] =
            (lastMonthByCategory[txn.categoryId] ?? 0) + txn.amount;
      }

      // Build category history for unusual transaction detection
      if (txn.type == 'expense') {
        categoryAmountHistory.putIfAbsent(txn.categoryId, () => []);
        categoryAmountHistory[txn.categoryId]!.add(txn.amount);
      }
    }
  }

  // Parse debts
  double totalDebtLoad = 0;
  final List<Debt> overdueDebts = [];

  if (debtSnapshot.hasData) {
    for (var doc in debtSnapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final debt = Debt.fromMap(data);

      if (!debt.isPaid && debt.type == 'owe') {
        totalDebtLoad += debt.remainingAmount;

        // Check for overdue
        if (debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now())) {
          overdueDebts.add(debt);
        }
      }
    }
  }

  // --- 1. Spending Spike vs Last Month ---
  final spikeCategories = <MapEntry<String, double>>[];
  currentMonthByCategory.forEach((categoryId, currentAmount) {
    final lastAmount = lastMonthByCategory[categoryId] ?? 0;
    if (lastAmount > 0) {
      final increase = ((currentAmount - lastAmount) / lastAmount) * 100;
      if (increase >= 20) {
        spikeCategories.add(MapEntry(categoryId, increase));
      }
    }
  });
  spikeCategories.sort((a, b) => b.value.compareTo(a.value));

  for (var i = 0; i < spikeCategories.length && i < 2; i++) {
    final entry = spikeCategories[i];
    final category = categoriesMap[entry.key];
    final categoryName = category?.name ?? 'Unknown';
    final increasePercent = entry.value.toStringAsFixed(0);
    final hash = _generateHash('spending_spike_${entry.key}_$increasePercent');

    if (!financeService.isInsightDismissed(dismissedInsights, 'spending_spike_${entry.key}', hash)) {
      insights.add(FinanceInsight(
        id: 'spending_spike_${entry.key}',
        title: 'Spending Spike',
        message: 'You spent $increasePercent% more on $categoryName this month compared to last month.',
        severity: InsightSeverity.warning,
        dataHash: hash,
        icon: CupertinoIcons.arrow_up_right_circle_fill,
      ));
    }
  }

  // --- 2. Budget Burn Rate ---
  if (monthlyBudget > 0 && totalExpenses > 0) {
    final burnPercent = (totalExpenses / monthlyBudget) * 100;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final timePercent = (daysPassed / daysInMonth) * 100;
    final daysRemaining = daysInMonth - daysPassed;

    if (burnPercent > timePercent && burnPercent >= 60 && burnPercent < 100) {
      final hash = _generateHash('budget_burn_${burnPercent.toStringAsFixed(0)}_$daysRemaining');

      if (!financeService.isInsightDismissed(dismissedInsights, 'budget_burn', hash)) {
        insights.add(FinanceInsight(
          id: 'budget_burn',
          title: 'Budget Alert',
          message: "You've used ${burnPercent.toStringAsFixed(0)}% of your monthly budget with $daysRemaining days left.",
          severity: InsightSeverity.warning,
          dataHash: hash,
          icon: CupertinoIcons.flame_fill,
        ));
      }
    }
  }

  // --- 3. Top Spending Category (always shown) ---
  if (currentMonthByCategory.isNotEmpty) {
    String? topCategoryId;
    double topAmount = 0;
    currentMonthByCategory.forEach((id, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategoryId = id;
      }
    });

    if (topCategoryId != null && totalExpenses > 0) {
      final category = categoriesMap[topCategoryId];
      final categoryName = category?.name ?? 'Unknown';
      final percent = ((topAmount / totalExpenses) * 100).toStringAsFixed(0);
      final hash = _generateHash('top_category_${topCategoryId}_$percent');

      if (!financeService.isInsightDismissed(dismissedInsights, 'top_category', hash)) {
        insights.add(FinanceInsight(
          id: 'top_category',
          title: 'Top Spending',
          message: '$categoryName is your biggest expense this month — $percent% of total spending.',
          severity: InsightSeverity.info,
          dataHash: hash,
          icon: CupertinoIcons.chart_pie_fill,
        ));
      }
    }
  }

  // --- 4. Income vs Expense Health ---
  if (totalIncome > 0) {
    final savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;

    if (savingsRate < 0) {
      final hash = _generateHash('income_health_negative_${savingsRate.toStringAsFixed(0)}');
      if (!financeService.isInsightDismissed(dismissedInsights, 'income_health', hash)) {
        insights.add(FinanceInsight(
          id: 'income_health',
          title: 'Overspending Alert',
          message: 'You spent more than you earned this month. Consider reducing expenses.',
          severity: InsightSeverity.warning,
          dataHash: hash,
          icon: CupertinoIcons.exclamationmark_triangle_fill,
        ));
      }
    } else if (savingsRate >= 20) {
      final hash = _generateHash('income_health_positive_${savingsRate.toStringAsFixed(0)}');
      if (!financeService.isInsightDismissed(dismissedInsights, 'income_health', hash)) {
        insights.add(FinanceInsight(
          id: 'income_health',
          title: 'Great Savings!',
          message: 'You saved ${savingsRate.toStringAsFixed(0)}% of your income this month — keep it up! 🎉',
          severity: InsightSeverity.positive,
          dataHash: hash,
          icon: CupertinoIcons.checkmark_seal_fill,
        ));
      }
    }
  }

  // --- 5. Recurring Payment Reminder ---
  // (Skipped for now - requires recurring transaction due date tracking)

  // --- 6. Unusual Single Transaction ---
  categoryAmountHistory.forEach((categoryId, amounts) {
    if (amounts.length >= 3) {
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final latestAmount = amounts.last;

      if (latestAmount > avgAmount * 2.5) {
        final category = categoriesMap[categoryId];
        final categoryName = category?.name ?? 'Unknown';
        final multiplier = (latestAmount / avgAmount).toStringAsFixed(1);
        final hash = _generateHash('unusual_txn_${categoryId}_${latestAmount.toStringAsFixed(0)}');

        if (!financeService.isInsightDismissed(dismissedInsights, 'unusual_txn_$categoryId', hash)) {
          insights.add(FinanceInsight(
            id: 'unusual_txn_$categoryId',
            title: 'Unusual Spending',
            message: 'Your ${formatCurrency(latestAmount)} $categoryName purchase was ${multiplier}x your usual spending there.',
            severity: InsightSeverity.warning,
            dataHash: hash,
            icon: CupertinoIcons.bolt_fill,
          ));
        }
      }
    }
  });

  // --- 7. Debt Overdue Alert ---
  if (overdueDebts.isNotEmpty) {
    final debt = overdueDebts.first;
    final daysPastDue = DateTime.now().difference(debt.dueDate!).inDays;
    final hash = _generateHash('debt_overdue_${debt.id}_$daysPastDue');

    if (!financeService.isInsightDismissed(dismissedInsights, 'debt_overdue', hash)) {
      insights.add(FinanceInsight(
        id: 'debt_overdue',
        title: 'Payment Overdue',
        message: 'Your payment for "${debt.title}" was due $daysPastDue days ago.',
        severity: InsightSeverity.warning,
        dataHash: hash,
        icon: CupertinoIcons.clock_fill,
      ));
    }
  }

  // --- 8. Debt-to-Income Ratio Warning ---
  if (totalDebtLoad > 0 && totalIncome > 0) {
    final debtRatio = (totalDebtLoad / totalIncome) * 100;

    if (debtRatio > 40) {
      final severity = debtRatio > 70 ? InsightSeverity.warning : InsightSeverity.warning;
      final hash = _generateHash('debt_ratio_${debtRatio.toStringAsFixed(0)}');

      if (!financeService.isInsightDismissed(dismissedInsights, 'debt_ratio', hash)) {
        insights.add(FinanceInsight(
          id: 'debt_ratio',
          title: 'High Debt Load',
          message: 'Your total debt is ${debtRatio.toStringAsFixed(0)}% of your monthly income. Consider paying down debt.',
          severity: severity,
          dataHash: hash,
          icon: CupertinoIcons.creditcard_fill,
        ));
      }
    }
  }

  // --- 9. Positive Under-Budget Streak ---
  if (underBudgetStreak >= 2) {
    final hash = _generateHash('budget_streak_$underBudgetStreak');

    if (!financeService.isInsightDismissed(dismissedInsights, 'budget_streak', hash)) {
      insights.add(FinanceInsight(
        id: 'budget_streak',
        title: 'Budget Streak!',
        message: "You've stayed under budget for $underBudgetStreak months in a row 🎉",
        severity: InsightSeverity.positive,
        dataHash: hash,
        icon: CupertinoIcons.flame_fill,
      ));
    }
  }

  // --- 10. No-Spend Day Streak ---
  // Only show if user has at least one expense transaction
  bool hasExpenseTxn = false;
  if (txnSnapshot.hasData) {
    for (var doc in txnSnapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final txn = FinanceTransaction.fromMap(data);
      if (txn.type == 'expense') {
        hasExpenseTxn = true;
        break;
      }
    }
  }
  if (noSpendDays >= 2 && hasExpenseTxn) {
    final hash = _generateHash('no_spend_$noSpendDays');

    if (!financeService.isInsightDismissed(dismissedInsights, 'no_spend', hash)) {
      insights.add(FinanceInsight(
        id: 'no_spend',
        title: 'No-Spend Days',
        message: "You've had $noSpendDays no-spend days this week — nice discipline!",
        severity: InsightSeverity.positive,
        dataHash: hash,
        icon: CupertinoIcons.hand_thumbsup_fill,
      ));
    }
  }

  // Limit to 4 insights max to avoid overwhelming the user
  return insights.take(4).toList();
}

/// Generates a simple hash from a string for change detection
String _generateHash(String input) {
  // Simple hash using hashCode - sufficient for change detection
  return input.hashCode.toRadixString(16).padLeft(8, '0');
}

/// Insight card widget matching Cycles alert style
class _InsightCard extends StatefulWidget {
  final FinanceInsight insight;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onDismiss;

  const _InsightCard({
    required this.insight,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.onDismiss,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> with SingleTickerProviderStateMixin {
  bool _isDismissing = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? widget.insight.backgroundColorDark
        : widget.insight.backgroundColor;
    final borderColor = widget.isDark
        ? widget.insight.borderColorDark
        : widget.insight.borderColor;
    final iconColor = widget.insight.iconColor;

    return AnimatedOpacity(
      opacity: _isDismissing ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isDismissing ? 0 : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.insight.icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.insight.title,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.insight.message,
                style: TextStyle(
                  color: widget.subTextColor,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _isDismissing = true);
                    await Future.delayed(const Duration(milliseconds: 200));
                    widget.onDismiss();
                  },
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      color: widget.subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
