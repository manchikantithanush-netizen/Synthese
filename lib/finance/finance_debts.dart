import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/services/finance_service.dart';
import 'package:synthese/finance/finance_add_debt.dart';
import 'package:synthese/finance/finance_debt_detail.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/app_toast.dart';

class DebtsListScreen extends StatefulWidget {
  const DebtsListScreen({super.key});

  @override
  State<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends State<DebtsListScreen> {
  final FinanceService _financeService = FinanceService();

  // Tab selection: 0 = I Owe, 1 = Owe Me
  int _selectedTab = 0;

  // Currency symbol
  String _currencySymbol = '\$';

  // Category lookup
  final Map<String, DebtCategory> _debtCategoriesMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUserCurrency();
    _buildCategoriesMap();
  }

  void _buildCategoriesMap() {
    for (final category in defaultDebtCategories) {
      _debtCategoriesMap[category.id] = category;
    }
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

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '$_currencySymbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$_currencySymbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  void _showAddDebtModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddDebtModal(),
    );
  }

  void _showDebtDetailModal(Debt debt) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color.fromARGB(255, 26, 26, 28)
          : const Color.fromARGB(255, 245, 245, 245),
      builder: (context) => DebtDetailModal(debt: debt),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    bool isDark,
  ) async {
    bool result = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Debt',
      message:
          'Are you sure you want to delete this debt? This action cannot be undone.',
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

  Future<void> _deleteDebt(String debtId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _financeService.deleteDebt(uid, debtId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF19191A)
        : const Color(0xFFF0F0F6);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final backgroundColor = isDark
        ? const Color(0xFF19191A)
        : const Color(0xFFF0F0F6);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Debts',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(height: 16),
          // Content with horizontal padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Tab selector
                  _buildTabSelector(isDark, cardColor),
                  const SizedBox(height: 20),
                  // Add Debt button
                  PremiumButton(text: 'Add Debt', onPressed: _showAddDebtModal),
                  const SizedBox(height: 20),
                  // Debts list
                  Expanded(
                    child: _buildDebtsList(
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(bool isDark, Color cardColor) {
    return UniversalSegmentedControl<int>(
      items: const [0, 1],
      labels: const ['I Owe', 'Owe Me'],
      selectedItem: _selectedTab,
      onSelectionChanged: (value) {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = value);
      },
    );
  }

  Widget _buildDebtsList({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Text(
          'Please sign in to view debts',
          style: TextStyle(color: subTextColor, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _financeService.getDebtsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Container(
            color: isDark
                ? Colors.black
                : const Color.fromARGB(255, 245, 245, 245), // Match dashboard background
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: BouncingDotsLoader(color: Color(0xFFEC548A)),
              ),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filterType = _selectedTab == 0 ? 'owe' : 'owedToMe';

        // Separate active and paid debts
        final activeDebts = <QueryDocumentSnapshot>[];
        final paidDebts = <QueryDocumentSnapshot>[];

        for (final doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final debt = Debt.fromMap(data);

          if (debt.type == filterType) {
            if (debt.isPaid) {
              paidDebts.add(doc);
            } else {
              activeDebts.add(doc);
            }
          }
        }

        if (activeDebts.isEmpty && paidDebts.isEmpty) {
          return _buildEmptyState(isDark, cardColor, subTextColor);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active debts
              if (activeDebts.isNotEmpty)
                _buildDebtsSection(
                  debts: activeDebts,
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

              // Paid debts section
              if (paidDebts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Paid',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildDebtsSection(
                  debts: paidDebts,
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  isPaidSection: true,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color cardColor, Color subTextColor) {
    final emptyMessage = _selectedTab == 0
        ? "No debts you owe"
        : "No debts owed to you";
    final emptySubMessage = _selectedTab == 0
        ? "Tap 'Add Debt' to track money you owe"
        : "Tap 'Add Debt' to track money owed to you";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, color: subTextColor, size: 40),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(color: subTextColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            emptySubMessage,
            style: TextStyle(
              color: subTextColor.withOpacity(0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsSection({
    required List<QueryDocumentSnapshot> debts,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    bool isPaidSection = false,
  }) {
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
        itemCount: debts.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.white12 : Colors.black12,
          height: 1,
          indent: 60,
        ),
        itemBuilder: (context, index) {
          final doc = debts[index];
          final data = doc.data() as Map<String, dynamic>;
          final debt = Debt.fromMap(data);

          return _buildDebtRow(
            doc: doc,
            debt: debt,
            isDark: isDark,
            textColor: textColor,
            subTextColor: subTextColor,
            isPaidSection: isPaidSection,
          );
        },
      ),
    );
  }

  Widget _buildDebtRow({
    required QueryDocumentSnapshot doc,
    required Debt debt,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
    bool isPaidSection = false,
  }) {
    final category = _debtCategoriesMap[debt.category];
    final isOverdue =
        debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now()) &&
        !debt.isPaid;

    // Amount display
    final amountText =
        '${_formatCurrency(debt.remainingAmount)} / ${_formatCurrency(debt.totalAmount)}';

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
      onDismissed: (direction) {
        _deleteDebt(doc.id);
        AppToast.info(context, 'Debt deleted', icon: Icons.delete_outline_rounded);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showDebtDetailModal(debt),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (category?.color ?? Colors.grey).withOpacity(
              isPaidSection ? 0.08 : 0.15,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              category?.icon ?? Icons.help_outline,
              color: isPaidSection
                  ? (category?.color ?? Colors.grey).withOpacity(0.5)
                  : (category?.color ?? Colors.grey),
              size: 22,
            ),
          ),
        ),
        title: Text(
          debt.title,
          style: TextStyle(
            color: isPaidSection ? textColor.withOpacity(0.5) : textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: isPaidSection ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              amountText,
              style: TextStyle(
                color: isPaidSection
                    ? subTextColor.withOpacity(0.5)
                    : subTextColor,
                fontSize: 12,
              ),
            ),
            if (debt.dueDate != null) ...[
              const SizedBox(width: 8),
              _buildDueDateChip(debt.dueDate!, isOverdue, isPaidSection),
            ],
          ],
        ),
        trailing: isPaidSection
            ? Icon(
                Icons.check_circle,
                color: const Color(0xFF34C759).withOpacity(0.5),
                size: 20,
              )
            : Icon(Icons.chevron_right, color: subTextColor, size: 18),
      ),
    );
  }

  Widget _buildDueDateChip(
    DateTime dueDate,
    bool isOverdue,
    bool isPaidSection,
  ) {
    final dateStr = DateFormat('MMM d').format(dueDate);
    final chipColor = isOverdue && !isPaidSection
        ? const Color(0xFFFF3B30)
        : const Color(0xFF8E8E93);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(isPaidSection ? 0.08 : 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        dateStr,
        style: TextStyle(
          color: isPaidSection ? chipColor.withOpacity(0.5) : chipColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
