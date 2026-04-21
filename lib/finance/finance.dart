import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/services/finance_service.dart';
import 'package:synthese/finance/finance_add_transaction.dart';
import 'package:synthese/finance/finance_transfer.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/onboarding/onboarding_finance.dart';
import 'package:synthese/finance/finance_insights.dart';
import 'package:synthese/finance/finance_debts.dart';
import 'package:synthese/finance/finance_contextual_insights.dart';

class FinancePage extends StatefulWidget {
  final Function(bool)? onModalStateChanged;
  const FinancePage({super.key, this.onModalStateChanged});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final FinanceService _financeService = FinanceService();
  bool _isModalOpen = false;
  bool _isInitialized = false;
  bool? _financeSetupCompleted;

  // Cached streams
  Stream<QuerySnapshot>? _accountsStream;
  Stream<QuerySnapshot>? _transactionsStream;
  Stream<QuerySnapshot>? _categoriesStream;
  Stream<QuerySnapshot>? _debtsStream;

  // Category lookup cache
  Map<String, Category> _categoriesMap = {};

  // Filter state
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime.now();
  String? _selectedCategoryFilter;

  // Currency symbol based on user's country
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _checkFinanceSetup();
    _setupStreams();
    _fetchUserCurrency();
  }

  Future<void> _checkFinanceSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final completed = doc.data()?['financeSetupCompleted'] as bool? ?? false;
    if (mounted) {
      setState(() => _financeSetupCompleted = completed);
    }
  }

  void _onFinanceOnboardingComplete() {
    setState(() => _financeSetupCompleted = true);
    _setupStreams();
  }

  Future<void> _fetchUserCurrency() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final country = doc.data()?['country'] as String?;
    if (country != null && mounted) {
      setState(() => _currencySymbol = _getCurrencySymbol(country));
    }
  }

  String _getCurrencySymbol(String country) {
    final Map<String, String> currencyMap = {
      'United States': '\$',
      'USA': '\$',
      'Canada': 'CA\$',
      'Mexico': 'MX\$',
      'Brazil': 'R\$',
      'Argentina': 'AR\$',
      'United Kingdom': '£',
      'UK': '£',
      'Germany': '€',
      'France': '€',
      'Italy': '€',
      'Spain': '€',
      'Netherlands': '€',
      'Belgium': '€',
      'Austria': '€',
      'Ireland': '€',
      'Portugal': '€',
      'Greece': '€',
      'Finland': '€',
      'Switzerland': 'CHF ',
      'Sweden': 'kr ',
      'Norway': 'kr ',
      'Denmark': 'kr ',
      'Poland': 'zł ',
      'Russia': '₽',
      'Turkey': '₺',
      'United Arab Emirates': 'AED ',
      'UAE': 'AED ',
      'Saudi Arabia': 'SAR ',
      'Qatar': 'QAR ',
      'Kuwait': 'KWD ',
      'Bahrain': 'BHD ',
      'Oman': 'OMR ',
      'Israel': '₪',
      'Egypt': 'E£',
      'India': '₹',
      'Japan': '¥',
      'China': '¥',
      'South Korea': '₩',
      'Singapore': 'S\$',
      'Malaysia': 'RM ',
      'Thailand': '฿',
      'Indonesia': 'Rp ',
      'Philippines': '₱',
      'Vietnam': '₫',
      'Pakistan': 'Rs ',
      'Bangladesh': '৳',
      'Hong Kong': 'HK\$',
      'Taiwan': 'NT\$',
      'Australia': 'A\$',
      'New Zealand': 'NZ\$',
      'South Africa': 'R ',
      'Nigeria': '₦',
      'Kenya': 'KSh ',
    };
    return currencyMap[country] ?? '\$';
  }

  void _setupStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _accountsStream = _financeService.getAccountsStream(uid);
    _transactionsStream = _financeService.getTransactionsStream(uid);
    _categoriesStream = _financeService.getCategoriesStream(uid);
    _debtsStream = _financeService.getDebtsStream(uid);
    _initializeDefaults(uid);
  }

  Future<void> _initializeDefaults(String uid) async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _financeService.initializeDefaultAccounts(uid);
    await _financeService.initializeDefaultCategories(uid);
  }

  void _showAddTransactionModal() async {
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionModal(),
    );

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  void _showTransferModal() async {
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransferModal(),
    );

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  void _showDebtListScreen() async {
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.93,
        child: const DebtsListScreen(),
      ),
    );
    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  Widget _buildDebtsSummaryCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _debtsStream,
      builder: (context, snapshot) {
        double totalYouOwe = 0;
        double totalOwedToYou = 0;
        double totalPaidOff = 0;
        double totalDebtAmount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final debt = Debt.fromMap(data);
            totalDebtAmount += debt.totalAmount;

            if (!debt.isPaid) {
              if (debt.type == 'owe') {
                totalYouOwe += debt.remainingAmount;
              } else if (debt.type == 'owedToMe') {
                totalOwedToYou += debt.remainingAmount;
              }
            }
            totalPaidOff += (debt.totalAmount - debt.remainingAmount);
          }
        }

        // Calculate paydown percentage
        double paydownPercentage = totalDebtAmount > 0
            ? (totalPaidOff / totalDebtAmount).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: _showDebtListScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Debts",
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
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "You Owe",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(totalYouOwe),
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
                                "Owed to You",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(totalOwedToYou),
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
                    // Progress bar showing debt paydown
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Paydown Progress",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${(paydownPercentage * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: paydownPercentage,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF34C759),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Tap to view all debts",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 12,
                          color: subTextColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark
        ? const Color(0xFF151515)
        : const Color.fromARGB(255, 245, 245, 245);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final safePadding = MediaQuery.of(context).padding;

    if (_financeSetupCompleted == null) {
      return Container(
        color: bgColor,
        child: const Center(child: BouncingDotsLoader()),
      );
    }

    if (_financeSetupCompleted == false) {
      return OnboardingFinance(onContinue: _onFinanceOnboardingComplete);
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: safePadding.top + 24.0,
          bottom: safePadding.bottom + 120,
          left: 24.0,
          right: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Finance",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 24),

            // Total Balance Card
            _buildTotalBalanceCard(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 16),

            // Account Balances Row
            _buildAccountsRow(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 12),

            // Transfer Button
            AnimatedOpacity(
              opacity: _isModalOpen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: _showTransferModal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: const Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Transfer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Transaction Button
            AnimatedOpacity(
              opacity: _isModalOpen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: PremiumButton(
                text: "Add Transaction",
                onPressed: _showAddTransactionModal,
              ),
            ),
            const SizedBox(height: 24),

            // Monthly Summary
            buildMonthlySummary(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              selectedMonth: _selectedMonth,
              transactionsStream: _transactionsStream,
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 16),

            // Debts Summary Card
            _buildDebtsSummaryCard(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 16),

            // Income vs Expense Chart
            buildIncomeExpenseChart(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              selectedMonth: _selectedMonth,
              transactionsStream: _transactionsStream,
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 16),

            // Monthly Trends
            buildMonthlyTrendsChart(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              transactionsStream: _transactionsStream,
            ),
            const SizedBox(height: 16),

            // Spending by Category Pie Chart
            buildCategoryPieChart(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              selectedMonth: _selectedMonth,
              transactionsStream: _transactionsStream,
              categoriesStream: _categoriesStream,
              categoriesMap: _categoriesMap,
              formatCurrency: _formatCurrency,
              onCategoriesMapUpdated: (map) => _categoriesMap = map,
            ),
            const SizedBox(height: 16),

            // Contextual Insights (For You section)
            buildContextualInsights(
              context: context,
              isDark: isDark,
              textColor: textColor,
              subTextColor: subTextColor,
              selectedMonth: _selectedMonth,
              transactionsStream: _transactionsStream,
              debtsStream: _debtsStream,
              categoriesMap: _categoriesMap,
              formatCurrency: _formatCurrency,
            ),

            // Spending Insights
            buildSpendingInsights(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              selectedMonth: _selectedMonth,
              transactionsStream: _transactionsStream,
              categoriesStream: _categoriesStream,
              categoriesMap: _categoriesMap,
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 24),

            // Search Bar
            _buildSearchBar(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 16),

            // Month Filter
            _buildMonthFilter(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 16),

            // Category Filter
            _buildCategoryFilter(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            const SizedBox(height: 24),

            // Transaction History Section
            Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Transaction List
            _buildTransactionList(
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _accountsStream,
      builder: (context, snapshot) {
        double totalBalance = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalBalance += (data['balance'] as num?)?.toDouble() ?? 0.0;
          }
        }
        final isPositive = totalBalance >= 0;
        final balanceColor = isPositive
            ? const Color(0xFF34C759)
            : const Color(0xFFFF3B30);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatCurrency(totalBalance),
                style: TextStyle(
                  color: balanceColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountsRow({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _accountsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < 2 ? 8 : 0,
                    left: index > 0 ? 8 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.circle_outlined,
                          color: subTextColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 40, color: cardColor),
                        const SizedBox(height: 4),
                        Container(height: 16, width: 50, color: cardColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final accounts = snapshot.data!.docs
            .map((doc) => Account.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return Row(
          children: accounts
              .map(
                (account) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: account != accounts.last ? 8 : 0,
                      left: account != accounts.first ? 8 : 0,
                    ),
                    child: _buildAccountCard(
                      account: account,
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAccountCard({
    required Account account,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final isPositive = account.balance >= 0;
    final balanceColor = isPositive
        ? const Color(0xFF34C759)
        : const Color(0xFFFF3B30);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            account.icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            account.name,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(account.balance),
              style: TextStyle(
                color: balanceColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _categoriesStream,
      builder: (context, catSnapshot) {
        if (catSnapshot.hasData) {
          _categoriesMap = {};
          for (var doc in catSnapshot.data!.docs) {
            final category = Category.fromMap(
              doc.data() as Map<String, dynamic>,
            );
            _categoriesMap[category.id] = category;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _transactionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: BouncingDotsLoader(color: Color(0xFFEC548A)),
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];
            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final transaction = FinanceTransaction.fromMap(data);
              final category = _categoriesMap[transaction.categoryId];

              if (transaction.date.year != _selectedMonth.year ||
                  transaction.date.month != _selectedMonth.month)
                return false;
              if (_selectedCategoryFilter != null &&
                  transaction.categoryId != _selectedCategoryFilter)
                return false;
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final categoryName = category?.name.toLowerCase() ?? '';
                final note = transaction.note?.toLowerCase() ?? '';
                if (!categoryName.contains(query) && !note.contains(query))
                  return false;
              }
              return true;
            }).toList();

            if (filteredDocs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: subTextColor,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      allDocs.isEmpty
                          ? "No transactions yet"
                          : "No matching transactions",
                      style: TextStyle(color: subTextColor, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      allDocs.isEmpty
                          ? "Tap 'Add Transaction' to get started"
                          : "Try adjusting your filters",
                      style: TextStyle(
                        color: subTextColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) => Divider(
                  color: isDark ? Colors.white12 : Colors.black12,
                  height: 1,
                  indent: 60,
                ),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final transaction = FinanceTransaction.fromMap(data);
                  final category = _categoriesMap[transaction.categoryId];

                  final isExpense = transaction.type == 'expense';
                  final amountColor = isExpense
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFF34C759);
                  final amountPrefix = isExpense ? '-' : '+';
                  final dateStr = DateFormat(
                    'MMM d, yyyy',
                  ).format(transaction.date);

                  return Dismissible(
                    key: Key(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: const Color(0xFFFF3B30),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      HapticFeedback.mediumImpact();
                      return await _showDeleteConfirmation(context, isDark);
                    },
                    onDismissed: (direction) =>
                        _deleteTransaction(doc.id, transaction),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (category?.color ?? Colors.grey).withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            category?.icon ?? Icons.help_outline,
                            color: category?.color ?? Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                      title: Text(
                        category?.name ?? 'Unknown',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        dateStr,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      trailing: Text(
                        '$amountPrefix${_formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          hintStyle: TextStyle(color: subTextColor, fontSize: 16),
          prefixIcon: Icon(
            Icons.search,
            color: subTextColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() => _searchQuery = ''),
                  child: Icon(
                    Icons.cancel,
                    color: subTextColor,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthFilter({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final now = DateTime.now();
    final canGoForward =
        _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(
                () => _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_left,
                color: textColor,
                size: 18,
              ),
            ),
          ),
          Text(
            monthLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: canGoForward
                ? () {
                    HapticFeedback.lightImpact();
                    setState(
                      () => _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      ),
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right,
                color: canGoForward ? textColor : subTextColor.withOpacity(0.3),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        final categories = <Category>[];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            categories.add(
              Category.fromMap(doc.data() as Map<String, dynamic>),
            );
          }
        }

        // Find selected category for display
        Category? selectedCategory;
        if (_selectedCategoryFilter != null) {
          for (var cat in categories) {
            if (cat.id == _selectedCategoryFilter) {
              selectedCategory = cat;
              break;
            }
          }
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showCategoryBottomSheet(
              context: context,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              categories: categories,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (selectedCategory != null) ...[
                  Icon(
                    selectedCategory.icon,
                    color: selectedCategory.color,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    selectedCategory == null
                        ? 'All Categories'
                        : (selectedCategory.name == 'Other'
                              ? 'Other (${selectedCategory.type == 'expense' ? 'Expense' : 'Income'})'
                              : selectedCategory.name),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: subTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryBottomSheet({
    required BuildContext context,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required List<Category> categories,
  }) async {
    // Hide dock bar
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Select Category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Options list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // All Categories option
                    _buildCategoryOption(
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      category: null,
                      isSelected: _selectedCategoryFilter == null,
                      onTap: () {
                        setState(() => _selectedCategoryFilter = null);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    // Category options
                    ...categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCategoryOption(
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          category: cat,
                          isSelected: _selectedCategoryFilter == cat.id,
                          onTap: () {
                            setState(() => _selectedCategoryFilter = cat.id);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Show dock bar again
    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  Widget _buildCategoryOption({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Category? category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF34C759), width: 2)
              : null,
        ),
        child: Row(
          children: [
            if (category != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 14),
            ] else ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.grid_view,
                  color: subTextColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                category == null
                    ? 'All Categories'
                    : (category.name == 'Other'
                          ? 'Other (${category.type == 'expense' ? 'Expense' : 'Income'})'
                          : category.name),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF34C759),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    bool isDark,
  ) async {
    bool result = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
      icon: 'trash.fill',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Delete',
          style: AlertActionStyle.destructive,
          onPressed: () {
            HapticFeedback.lightImpact();
            result = true;
          },
        ),
      ],
    );
    return result;
  }

  Future<void> _deleteTransaction(
    String docId,
    FinanceTransaction transaction,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _financeService.deleteTransaction(uid, docId, transaction);
  }
}
