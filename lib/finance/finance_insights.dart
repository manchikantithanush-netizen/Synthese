import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/finance_charts.dart';

/// Builds the Insights section combining analytics widgets
Widget buildInsightsSection({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required Stream<QuerySnapshot>? categoriesStream,
  required Stream<QuerySnapshot>? accountsStream,
  required Map<String, Category> categoriesMap,
  required String Function(double) formatCurrency,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Insights",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      const SizedBox(height: 16),
      // Monthly Summary
      buildMonthlySummary(
        context: context,
        isDark: isDark,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        selectedMonth: selectedMonth,
        transactionsStream: transactionsStream,
        formatCurrency: formatCurrency,
      ),
      const SizedBox(height: 16),
      // Income vs Expense Chart
      buildIncomeExpenseChart(
        context: context,
        isDark: isDark,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        selectedMonth: selectedMonth,
        transactionsStream: transactionsStream,
        formatCurrency: formatCurrency,
      ),
      const SizedBox(height: 16),
      // Monthly Trends
      buildMonthlyTrendsChart(
        context: context,
        isDark: isDark,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        transactionsStream: transactionsStream,
      ),
      const SizedBox(height: 16),
      // Spending Insights
      buildSpendingInsights(
        context: context,
        isDark: isDark,
        cardColor: cardColor,
        textColor: textColor,
        subTextColor: subTextColor,
        selectedMonth: selectedMonth,
        transactionsStream: transactionsStream,
        categoriesStream: categoriesStream,
        categoriesMap: categoriesMap,
        formatCurrency: formatCurrency,
      ),
    ],
  );
}

/// Monthly Summary Widget
Widget buildMonthlySummary({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required String Function(double) formatCurrency,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: transactionsStream,
    builder: (context, snapshot) {
      double totalSpent = 0;
      double totalEarned = 0;

      if (snapshot.hasData) {
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final transaction = FinanceTransaction.fromMap(data);
          
          if (transaction.date.year == selectedMonth.year &&
              transaction.date.month == selectedMonth.month) {
            if (transaction.type == 'expense') {
              totalSpent += transaction.amount;
            } else {
              totalEarned += transaction.amount;
            }
          }
        }
      }

      double net = totalEarned - totalSpent;
      final netColor = net >= 0
          ? const Color(0xFF34C759)
          : const Color(0xFFFF3B30);

      final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Spent",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '-${formatCurrency(totalSpent)}',
                            style: const TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Earned",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${formatCurrency(totalEarned)}',
                            style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Net: ${net >= 0 ? '+' : ''}${formatCurrency(net)}',
                  style: TextStyle(
                    color: netColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// Monthly Trends Bar Chart
Widget buildMonthlyTrendsChart({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required Stream<QuerySnapshot>? transactionsStream,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: transactionsStream,
    builder: (context, snapshot) {
      final now = DateTime.now();
      List<double> expenses = [];
      List<double> incomes = [];
      List<String> labels = [];

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        double monthExpense = 0;
        double monthIncome = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final transaction = FinanceTransaction.fromMap(data);

            if (transaction.date.year == month.year &&
                transaction.date.month == month.month) {
              if (transaction.type == 'expense') {
                monthExpense += transaction.amount;
              } else {
                monthIncome += transaction.amount;
              }
            }
          }
        }

        expenses.add(monthExpense);
        incomes.add(monthIncome);
        labels.add(DateFormat('MMM').format(month));
      }

      final hasData = expenses.any((e) => e > 0) || incomes.any((i) => i > 0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Trends",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                if (!hasData)
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No transaction data yet',
                        style: TextStyle(color: subTextColor),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: MonthlyTrendsBarChartPainter(
                        expenses: expenses,
                        incomes: incomes,
                        labels: labels,
                        expenseColor: const Color(0xFFFF3B30),
                        incomeColor: const Color(0xFF34C759),
                        labelColor: subTextColor,
                        gridColor: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Income',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expense',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// Income vs Expense Chart
Widget buildIncomeExpenseChart({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required String Function(double) formatCurrency,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: transactionsStream,
    builder: (context, snapshot) {
      double totalIncome = 0;
      double totalExpense = 0;

      if (snapshot.hasData) {
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final transaction = FinanceTransaction.fromMap(data);

          if (transaction.date.year == selectedMonth.year &&
              transaction.date.month == selectedMonth.month) {
            if (transaction.type == 'expense') {
              totalExpense += transaction.amount;
            } else {
              totalIncome += transaction.amount;
            }
          }
        }
      }

      final total = totalIncome + totalExpense;
      final incomePercent = total > 0 ? (totalIncome / total * 100).toStringAsFixed(1) : '0';
      final expensePercent = total > 0 ? (totalExpense / total * 100).toStringAsFixed(1) : '0';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Income vs Expense",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Income',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: CustomPaint(
                          size: const Size(double.infinity, 64),
                          painter: IncomeExpenseBarPainter(
                            income: totalIncome,
                            expense: totalExpense,
                            incomeColor: const Color(0xFF34C759),
                            expenseColor: const Color(0xFFFF3B30),
                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(totalIncome),
                            style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$incomePercent%',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(totalExpense),
                            style: const TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$expensePercent%',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// Spending Insights Widget
Widget buildSpendingInsights({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required Stream<QuerySnapshot>? categoriesStream,
  required Map<String, Category> categoriesMap,
  required String Function(double) formatCurrency,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const SizedBox.shrink();

  // Create debts stream (using 'finance_debts' collection for consistency)
  final debtsStream = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('finance_debts')
      .snapshots();

  return StreamBuilder<QuerySnapshot>(
    stream: categoriesStream,
    builder: (context, catSnapshot) {
      Map<String, Category> localCategoriesMap = Map.from(categoriesMap);
      if (catSnapshot.hasData) {
        for (var doc in catSnapshot.data!.docs) {
          final category = Category.fromMap(doc.data() as Map<String, dynamic>);
          localCategoriesMap[category.id] = category;
        }
      }

      return StreamBuilder<QuerySnapshot>(
        stream: transactionsStream,
        builder: (context, txnSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: debtsStream,
                builder: (context, debtSnapshot) {
              final now = selectedMonth;
              final lastMonth = DateTime(now.year, now.month - 1, 1);

              Map<String, double> currentMonthSpending = {};
              Map<String, double> lastMonthSpending = {};
              double totalCurrentMonth = 0;
              double totalLastMonth = 0;

              if (txnSnapshot.hasData) {
                for (var doc in txnSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final transaction = FinanceTransaction.fromMap(data);

                  if (transaction.type != 'expense') continue;

                  if (transaction.date.year == now.year &&
                      transaction.date.month == now.month) {
                    currentMonthSpending[transaction.categoryId] =
                        (currentMonthSpending[transaction.categoryId] ?? 0) +
                            transaction.amount;
                    totalCurrentMonth += transaction.amount;
                  }

                  if (transaction.date.year == lastMonth.year &&
                      transaction.date.month == lastMonth.month) {
                    lastMonthSpending[transaction.categoryId] =
                        (lastMonthSpending[transaction.categoryId] ?? 0) +
                            transaction.amount;
                    totalLastMonth += transaction.amount;
                  }
                }
              }

              String? biggestCategoryId;
              double biggestAmount = 0;
              currentMonthSpending.forEach((categoryId, amount) {
                if (amount > biggestAmount) {
                  biggestAmount = amount;
                  biggestCategoryId = categoryId;
                }
              });

              double trendPercent = 0;
              bool isSpendingUp = false;
              if (totalLastMonth > 0) {
                trendPercent =
                    ((totalCurrentMonth - totalLastMonth) / totalLastMonth) * 100;
                isSpendingUp = trendPercent > 0;
              }

              double monthlyBudget = 0;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                monthlyBudget =
                    (userData?['monthlyBudget'] as num?)?.toDouble() ?? 0;
              }

              List<MapEntry<String, double>> spikeCategories = [];
              currentMonthSpending.forEach((categoryId, currentAmount) {
                final lastAmount = lastMonthSpending[categoryId] ?? 0;
                if (lastAmount > 0) {
                  final increase = ((currentAmount - lastAmount) / lastAmount) * 100;
                  if (increase >= 50) {
                    spikeCategories.add(MapEntry(categoryId, increase));
                  }
                }
              });
              spikeCategories.sort((a, b) => b.value.compareTo(a.value));

              final biggestCategory = biggestCategoryId != null
                  ? localCategoriesMap[biggestCategoryId]
                  : null;

              // Calculate monthly income from transactions
              double monthlyIncome = 0;
              if (txnSnapshot.hasData) {
                for (var doc in txnSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final transaction = FinanceTransaction.fromMap(data);
                  if (transaction.type == 'income' &&
                      transaction.date.year == now.year &&
                      transaction.date.month == now.month) {
                    monthlyIncome += transaction.amount;
                  }
                }
              }

              // Calculate debt metrics
              double totalDebtLoad = 0;
              double lastMonthDebtLoad = 0;
              if (debtSnapshot.hasData) {
                for (var doc in debtSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final debt = Debt.fromMap(data);
                  // Only count active debts where user owes money
                  if (!debt.isPaid && debt.type == 'owe') {
                    totalDebtLoad += debt.remainingAmount;
                    // Estimate last month's debt by adding back any payments made this month
                    lastMonthDebtLoad += debt.remainingAmount;
                  }
                }
              }

              // Calculate debt-to-income ratio
              double debtToIncomeRatio = 0;
              if (monthlyIncome > 0) {
                debtToIncomeRatio = (totalDebtLoad / monthlyIncome) * 100;
              }

              // Determine debt-to-income ratio color
              Color debtRatioColor;
              if (debtToIncomeRatio < 30) {
                debtRatioColor = const Color(0xFF34C759); // Green
              } else if (debtToIncomeRatio <= 50) {
                debtRatioColor = const Color(0xFFFF9500); // Orange
              } else {
                debtRatioColor = const Color(0xFFFF3B30); // Red
              }

              // Calculate debt payoff percentage this month
              double debtPayoffPercent = 0;
              if (lastMonthDebtLoad > 0 && totalDebtLoad < lastMonthDebtLoad) {
                debtPayoffPercent = ((lastMonthDebtLoad - totalDebtLoad) / lastMonthDebtLoad) * 100;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spending Insights",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (biggestCategory != null) ...[
                          _buildInsightRow(
                            icon: biggestCategory.icon,
                            iconColor: biggestCategory.color,
                            label: "Biggest Expense",
                            value: biggestCategory.name,
                            subValue: formatCurrency(biggestAmount),
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (totalLastMonth > 0) ...[
                          _buildInsightRow(
                            icon: isSpendingUp
                                ? CupertinoIcons.arrow_up_right
                                : CupertinoIcons.arrow_down_right,
                            iconColor: isSpendingUp
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF34C759),
                            label: "vs Last Month",
                            value: isSpendingUp
                                ? "↑${trendPercent.abs().toStringAsFixed(0)}% more"
                                : "↓${trendPercent.abs().toStringAsFixed(0)}% less",
                            valueColor: isSpendingUp
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF34C759),
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (monthlyBudget > 0) ...[
                          _buildBudgetProgress(
                            used: totalCurrentMonth,
                            total: monthlyBudget,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            formatCurrency: formatCurrency,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Total Debt Load row
                        if (totalDebtLoad > 0) ...[
                          _buildInsightRow(
                            icon: CupertinoIcons.creditcard_fill,
                            iconColor: const Color(0xFFFF3B30),
                            label: "Total Debt Load",
                            value: formatCurrency(totalDebtLoad),
                            valueColor: const Color(0xFFFF3B30),
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Debt-to-Income Ratio row
                        if (totalDebtLoad > 0 && monthlyIncome > 0) ...[
                          _buildInsightRow(
                            icon: CupertinoIcons.percent,
                            iconColor: debtRatioColor,
                            label: "Debt-to-Income Ratio",
                            value: "${debtToIncomeRatio.toStringAsFixed(1)}%",
                            valueColor: debtRatioColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Debt payoff celebration tip
                        if (debtPayoffPercent >= 5) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: Color(0xFF34C759),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "You've paid off ${debtPayoffPercent.toStringAsFixed(0)}% of your debt this month 🎉",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (spikeCategories.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_triangle_fill,
                                  color: Color(0xFFFF9500),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Spending Alert",
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        spikeCategories.take(2).map((e) {
                                          final cat = localCategoriesMap[e.key];
                                          return "${cat?.name ?? 'Unknown'} +${e.value.toStringAsFixed(0)}%";
                                        }).join(", "),
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (biggestCategory == null &&
                            totalLastMonth == 0 &&
                            monthlyBudget == 0 &&
                            totalDebtLoad == 0)
                          Text(
                            "Add transactions to see insights",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
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
}

Widget _buildInsightRow({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
  String? subValue,
  Color? valueColor,
  required Color textColor,
  required Color subTextColor,
}) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      if (subValue != null)
        Text(
          subValue,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );
}

Widget _buildBudgetProgress({
  required double used,
  required double total,
  required Color textColor,
  required Color subTextColor,
  required String Function(double) formatCurrency,
}) {
  final progress = (used / total).clamp(0.0, 1.0);
  final isOverBudget = used > total;
  final progressColor = isOverBudget
      ? const Color(0xFFFF3B30)
      : progress > 0.8
          ? const Color(0xFFFF9500)
          : const Color(0xFF34C759);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.chart_bar_fill,
                color: progressColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Budget",
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "${formatCurrency(used)} / ${formatCurrency(total)}",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${(progress * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              color: progressColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: progressColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 6,
        ),
      ),
    ],
  );
}

/// Net Worth Tracker Widget
Widget buildNetWorthTracker({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required Stream<QuerySnapshot>? accountsStream,
  required String Function(double) formatCurrency,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: accountsStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFEC548A)),
          ),
        );
      }

      final docs = snapshot.data?.docs ?? [];
      final accounts = docs
          .map((doc) => Account.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final totalNetWorth = accounts.fold<double>(
        0,
        (acc, account) => acc + account.balance,
      );

      final isPositive = totalNetWorth >= 0;
      final netWorthColor = isPositive
          ? const Color(0xFF34C759)
          : const Color(0xFFFF3B30);

      final positiveAccounts = accounts.where((a) => a.balance > 0).length;
      final totalAccounts = accounts.length;
      final healthRatio = totalAccounts > 0 ? positiveAccounts / totalAccounts : 0.0;
      
      String trendText;
      IconData trendIcon;
      Color trendColor;
      
      if (healthRatio >= 0.7) {
        trendText = 'Healthy';
        trendIcon = CupertinoIcons.arrow_up_right;
        trendColor = const Color(0xFF34C759);
      } else if (healthRatio >= 0.4) {
        trendText = 'Stable';
        trendIcon = CupertinoIcons.minus;
        trendColor = const Color(0xFFFF9500);
      } else {
        trendText = 'Needs Attention';
        trendIcon = CupertinoIcons.arrow_down_right;
        trendColor = const Color(0xFFFF3B30);
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Worth',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        trendText,
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                formatCurrency(totalNetWorth),
                style: TextStyle(
                  color: netWorthColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Total across ${accounts.length} account${accounts.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                ),
              ),
            ),
            if (accounts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: subTextColor.withOpacity(0.2)),
              const SizedBox(height: 12),
              ...accounts.map((account) {
                final accountIsPositive = account.balance >= 0;
                final balanceColor = accountIsPositive
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          account.icon,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          account.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        formatCurrency(account.balance),
                        style: TextStyle(
                          color: balanceColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    },
  );
}

/// Category Pie Chart
Widget buildCategoryPieChart({
  required BuildContext context,
  required bool isDark,
  required Color cardColor,
  required Color textColor,
  required Color subTextColor,
  required DateTime selectedMonth,
  required Stream<QuerySnapshot>? transactionsStream,
  required Stream<QuerySnapshot>? categoriesStream,
  required Map<String, Category> categoriesMap,
  required String Function(double) formatCurrency,
  required void Function(Map<String, Category>) onCategoriesMapUpdated,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: categoriesStream,
    builder: (context, catSnapshot) {
      Map<String, Category> localMap = Map.from(categoriesMap);
      if (catSnapshot.hasData) {
        for (var doc in catSnapshot.data!.docs) {
          final category = Category.fromMap(doc.data() as Map<String, dynamic>);
          localMap[category.id] = category;
        }
        onCategoriesMapUpdated(localMap);
      }

      return StreamBuilder<QuerySnapshot>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          Map<String, double> categorySpending = {};

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final transaction = FinanceTransaction.fromMap(data);

              if (transaction.date.year == selectedMonth.year &&
                  transaction.date.month == selectedMonth.month &&
                  transaction.type == 'expense') {
                categorySpending[transaction.categoryId] =
                    (categorySpending[transaction.categoryId] ?? 0) +
                        transaction.amount;
              }
            }
          }

          final sortedCategories = categorySpending.entries
              .where((e) => e.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (sortedCategories.isEmpty) {
            return const SizedBox.shrink();
          }

          final values = sortedCategories.map((e) => e.value).toList();
          final colors = sortedCategories
              .map((e) => localMap[e.key]?.color ?? Colors.grey)
              .toList();
          final total = values.reduce((a, b) => a + b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Spending by Category",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: CategoryPieChartPainter(
                          values: values,
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sortedCategories.map((entry) {
                      final category = localMap[entry.key];
                      final percentage = (entry.value / total * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category?.color ?? Colors.grey,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category?.name ?? 'Unknown',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '${formatCurrency(entry.value)} ($percentage%)',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
