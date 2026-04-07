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
import 'package:synthese/ui/components/premium_button.dart';

class AddDebtModal extends StatefulWidget {
  final Function(bool)? onModalStateChanged;

  const AddDebtModal({super.key, this.onModalStateChanged});

  @override
  State<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<AddDebtModal> {
  final FinanceService _financeService = FinanceService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _installmentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Timer? _errorTimer;

  // Debt type: 0 = I Owe, 1 = Owe Me
  int _debtType = 0;

  // Selected account and category
  Account? _selectedAccount;
  DebtCategory? _selectedCategory;

  // Due date (optional)
  DateTime? _dueDate;

  // Installment toggle
  bool _hasInstallment = false;

  // Loaded data
  List<Account> _accounts = [];

  // Colors
  static const Color oweColor = Color(0xFFE53935);
  static const Color oweMeColor = Color(0xFF43A047);

  // Currency symbol based on user's country
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    widget.onModalStateChanged?.call(true);
    _loadData();
    _fetchUserCurrency();
    // Set default category
    if (defaultDebtCategories.isNotEmpty) {
      _selectedCategory = defaultDebtCategories.first;
    }
  }

  Future<void> _fetchUserCurrency() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    widget.onModalStateChanged?.call(false);
    _errorTimer?.cancel();
    _titleController.dispose();
    _amountController.dispose();
    _installmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // Initialize defaults if needed
      await _financeService.initializeDefaultAccounts(uid);

      // Load accounts
      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_accounts')
          .get();

      _accounts = accountsSnapshot.docs
          .map((doc) => Account.fromMap(doc.data()))
          .toList();

      // Set default selection
      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
    } catch (e) {
      debugPrint('Error loading finance data: $e');
    }

    setState(() => _isLoading = false);
  }

  Color get _activeColor => _debtType == 0 ? oweColor : oweMeColor;

  Future<void> _saveDebt() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

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

    double? installmentAmount;
    if (_hasInstallment) {
      installmentAmount = double.tryParse(_installmentController.text.replaceAll(',', '.'));
      if (installmentAmount == null || installmentAmount <= 0) {
        _showError('Please enter a valid installment amount');
        return;
      }
      if (installmentAmount > amount) {
        _showError('Installment cannot exceed total amount');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final debt = Debt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        type: _debtType == 0 ? 'owe' : 'owedToMe',
        totalAmount: amount,
        remainingAmount: amount,
        dueDate: _dueDate,
        linkedAccountId: _selectedAccount!.id,
        category: _selectedCategory!.id,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isRecurring: _hasInstallment,
        installmentAmount: installmentAmount,
        createdAt: DateTime.now(),
        isPaid: false,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(debt.id)
          .set(debt.toMap());

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving debt: $e');
      _showError('Failed to save debt');
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

  void _showDueDatePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252528) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() => _dueDate = null);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: _activeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                minimumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() => _dueDate = date);
                  HapticFeedback.selectionClick();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF19191A)
        : const Color(0xFFF0F0F6); // Unified modal background

    final cardColor = isDark ? const Color(0xFF19191A) : const Color(0xFFF0F0F6);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor, // Always set explicit color to avoid white flash
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // --- DRAG HANDLE ---
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Add Debt",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CNButton.icon(
                      icon: const CNSymbol('xmark'),
                      style: CNButtonStyle.glass,
                      onPressed: () {
                        HapticFeedback.lightImpact();
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
                      padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // --- CONTENT ---
            Expanded(
              child: _isLoading
                  ? Container(
                      color: bgColor, // Match dashboard background
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(color: _activeColor),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TITLE INPUT ---
                          _buildSectionLabel('Title', subtextColor),
                          const SizedBox(height: 8),
                          _buildTitleInput(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- DEBT TYPE TOGGLE ---
                          _buildDebtTypeToggle(isDark, cardColor),

                          const SizedBox(height: 24),

                          // --- AMOUNT INPUT ---
                          _buildSectionLabel('Total Amount', subtextColor),
                          const SizedBox(height: 8),
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

                          // --- DUE DATE PICKER ---
                          _buildSectionLabel('Due Date (optional)', subtextColor),
                          const SizedBox(height: 8),
                          _buildDueDatePicker(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- INSTALLMENT TOGGLE ---
                          _buildInstallmentSection(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- NOTES FIELD ---
                          _buildSectionLabel('Notes (optional)', subtextColor),
                          const SizedBox(height: 8),
                          _buildNotesField(isDark, cardColor, textColor),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),

            // --- SAVE BUTTON ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: PremiumButton(
                text: 'Add Debt',
                isLoading: _isSaving,
                onPressed: _saveDebt,
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

  Widget _buildTitleInput(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _titleController,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'e.g., Car Loan, Credit Card Balance...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          border: InputBorder.none,
        ),
        maxLines: 1,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildDebtTypeToggle(bool isDark, Color cardColor) {
    return CNSegmentedControl(
      labels: const ['I Owe', 'Owe Me'],
      selectedIndex: _debtType,
      onValueChanged: (value) {
        HapticFeedback.selectionClick();
        setState(() => _debtType = value);
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      height: 70,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    color: isSelected ? _activeColor : (isDark ? Colors.white70 : Colors.black54),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final categories = defaultDebtCategories;

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
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
                      color: isSelected ? category.color : (isDark ? Colors.white70 : Colors.black54),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? category.color : (isDark ? Colors.white : Colors.black87),
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

  Widget _buildDueDatePicker(bool isDark, Color cardColor, Color textColor) {
    final formattedDate = _dueDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(_dueDate!)
        : 'No due date';

    return GestureDetector(
      onTap: _showDueDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              color: _dueDate != null ? _activeColor : (isDark ? Colors.white38 : Colors.black38),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _dueDate != null ? textColor : (isDark ? Colors.white38 : Colors.black38),
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

  Widget _buildInstallmentSection(bool isDark, Color cardColor, Color textColor) {
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
                color: _hasInstallment ? _activeColor : (isDark ? Colors.white38 : Colors.black38),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Installments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              CNSwitch(
                value: _hasInstallment,
                onChanged: (v) => setState(() => _hasInstallment = v),
              ),
            ],
          ),
        ),
        if (_hasInstallment) ...[
          const SizedBox(height: 12),
          _buildSectionLabel('Installment Amount', isDark ? Colors.white54 : Colors.black54),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  _currencySymbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _activeColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _installmentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
                Text(
                  '/ payment',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
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
        controller: _notesController,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Add notes...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              CupertinoIcons.pencil_outline,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

/// Helper function to show the AddDebtModal
Future<bool?> showAddDebtModal(BuildContext context, {Function(bool)? onModalStateChanged}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddDebtModal(onModalStateChanged: onModalStateChanged),
  );
}
