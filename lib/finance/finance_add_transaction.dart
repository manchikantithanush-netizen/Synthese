import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/services/finance_service.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final FinanceService _financeService = FinanceService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Timer? _errorTimer;

  // Transaction type: 0 = Expense, 1 = Income
  int _transactionType = 0;

  // Selected account and category
  Account? _selectedAccount;
  Category? _selectedCategory;

  // Transaction date
  DateTime _selectedDate = DateTime.now();

  // Recurring transaction
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';

  // Loaded data
  List<Account> _accounts = [];
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];

  // Colors
  static const Color expenseColor = Color(0xFFE53935);
  static const Color incomeColor = Color(0xFF43A047);

  // Currency symbol based on user's country
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchUserCurrency();
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
      // Americas
      'United States': '\$',
      'USA': '\$',
      'Canada': 'CA\$',
      'Mexico': 'MX\$',
      'Brazil': 'R\$',
      'Argentina': 'AR\$',
      // Europe
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
      // Middle East
      'United Arab Emirates': 'AED ',
      'UAE': 'AED ',
      'Saudi Arabia': 'SAR ',
      'Qatar': 'QAR ',
      'Kuwait': 'KWD ',
      'Bahrain': 'BHD ',
      'Oman': 'OMR ',
      'Israel': '₪',
      'Egypt': 'E£',
      // Asia
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
      // Oceania
      'Australia': 'A\$',
      'New Zealand': 'NZ\$',
      // Africa
      'South Africa': 'R ',
      'Nigeria': '₦',
      'Kenya': 'KSh ',
    };
    return currencyMap[country] ?? '\$';
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // Initialize defaults if needed
      await _financeService.initializeDefaultAccounts(uid);
      await _financeService.initializeDefaultCategories(uid);

      // Load accounts
      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_accounts')
          .get();

      _accounts = accountsSnapshot.docs
          .map((doc) => Account.fromMap(doc.data()))
          .toList();

      // Load expense categories
      _expenseCategories = await _financeService.getExpenseCategories(uid);

      // Load income categories
      _incomeCategories = await _financeService.getIncomeCategories(uid);

      // Set default selections
      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
      if (_expenseCategories.isNotEmpty) {
        _selectedCategory = _expenseCategories.first;
      }
    } catch (e) {
      debugPrint('Error loading finance data: $e');
    }

    setState(() => _isLoading = false);
  }

  List<Category> get _currentCategories =>
      _transactionType == 0 ? _expenseCategories : _incomeCategories;

  Color get _activeColor => _transactionType == 0 ? expenseColor : incomeColor;

  Future<void> _saveTransaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Validation
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Please select an account');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = FinanceTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        accountId: _selectedAccount!.id,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        type: _transactionType == 0 ? 'expense' : 'income',
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring ? _recurrenceType : null,
      );

      await _financeService.addTransaction(uid, transaction);

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      _showError('Failed to save transaction');
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMessage = message);
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.teal,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        setState(() => _selectedDate = date);
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 760;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    final bottomActionPadding =
        mediaQuery.viewInsets.bottom +
        mediaQuery.padding.bottom +
        (isCompact ? 10.0 : 16.0);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // --- HEADER ---
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
                      "Add Transaction",
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
            ),

            // --- ERROR MESSAGE ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 20,
                        right: 20,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            SizedBox(height: isCompact ? 14 : 20),

            // --- CONTENT ---
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _activeColor),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TRANSACTION TYPE TOGGLE ---
                          _buildTransactionTypeToggle(isDark, cardColor),

                          const SizedBox(height: 24),

                          // --- AMOUNT INPUT ---
                          _buildAmountInput(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- ACCOUNT SELECTOR ---
                          _buildSectionLabel('Account', subtextColor),
                          const SizedBox(height: 8),
                          _buildAccountSelector(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- CATEGORY SELECTOR ---
                          _buildCategorySelector(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- DATE PICKER ---
                          _buildSectionLabel('Date', subtextColor),
                          const SizedBox(height: 8),
                          _buildDatePicker(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- RECURRING TOGGLE ---
                          _buildRecurringSection(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- NOTES FIELD ---
                          _buildSectionLabel('Note (optional)', subtextColor),
                          const SizedBox(height: 8),
                          _buildNotesField(isDark, cardColor, textColor),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),

            // --- SAVE BUTTON ---
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, bottomActionPadding),
              child: PremiumButton(
                text: _transactionType == 0 ? 'Add Expense' : 'Add Income',
                isLoading: _isSaving,
                onPressed: _saveTransaction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTransactionTypeToggle(bool isDark, Color cardColor) {
    return UniversalSegmentedControl<int>(
      items: const [0, 1],
      labels: const ['Expense', 'Income'],
      selectedItem: _transactionType,
      onSelectionChanged: (value) {
        HapticFeedback.selectionClick();
        setState(() {
          _transactionType = value;
          // Reset category when switching type
          _selectedCategory = _currentCategories.isNotEmpty
              ? _currentCategories.first
              : null;
        });
      },
    );
  }

  Widget _buildAmountInput(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _currencySymbol,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _activeColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(bool isDark, Color cardColor, Color textColor) {
    if (_accounts.isEmpty) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No accounts available',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final account = _accounts[index];
          final isSelected = _selectedAccount?.id == account.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedAccount = account);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _activeColor.withOpacity(0.15) : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _activeColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    account.icon,
                    color: isSelected
                        ? _activeColor
                        : (isDark ? Colors.white70 : Colors.black54),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? _activeColor : textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark, Color cardColor, Color textColor) {
    final categories = _currentCategories;

    if (categories.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No categories available',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((category) {
            final isSelected = _selectedCategory?.id == category.id;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.15)
                      : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected
                          ? category.color
                          : (isDark ? Colors.white70 : Colors.black54),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? category.color
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark, Color cardColor, Color textColor) {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);
    final isToday =
        DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, color: _activeColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isToday ? 'Today' : formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection(bool isDark, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.repeat,
                color: _isRecurring
                    ? _activeColor
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recurring',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              CNSwitch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
              ),
            ],
          ),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 12),
          UniversalSegmentedControl<String>(
            items: const ['daily', 'weekly', 'monthly'],
            labels: const ['Daily', 'Weekly', 'Monthly'],
            selectedItem: _recurrenceType,
            onSelectionChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _recurrenceType = value);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotesField(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _noteController,
        style: TextStyle(fontSize: 16, color: textColor),
        decoration: InputDecoration(
          hintText: 'Add a note...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              CupertinoIcons.pencil_outline,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        ),
        maxLines: 1,
      ),
    );
  }
}

/// Helper function to show the AddTransactionModal
Future<bool?> showAddTransactionModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddTransactionModal(),
  );
}
