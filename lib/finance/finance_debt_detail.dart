import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/finance/services/finance_service.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/app_toast.dart';

/// Model for debt payment history
class DebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  DebtPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    // Handle potential null or missing date field
    DateTime date;
    final dateValue = map['date'];
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      date = DateTime.now();
    }

    return DebtPayment(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      note: map['note'] as String?,
    );
  }
}

/// Debt Detail Modal - shows full debt info with payment options
class DebtDetailModal extends StatefulWidget {
  final Debt debt;

  const DebtDetailModal({super.key, required this.debt});

  @override
  State<DebtDetailModal> createState() => _DebtDetailModalState();
}

class _DebtDetailModalState extends State<DebtDetailModal>
    with TickerProviderStateMixin {
  final FinanceService _financeService = FinanceService();

  late Debt _debt;
  List<DebtPayment> _payments = [];
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _showPaidAnimation = false;
  String _currencySymbol = '\$';

  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _loadData();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      // Load currency
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final country = userDoc.data()?['country'] as String?;
      if (country != null) {
        _currencySymbol = _getCurrencySymbol(country);
      }

      // Load accounts
      await _financeService.initializeDefaultAccounts(uid);
      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_accounts')
          .get();
      _accounts = accountsSnapshot.docs
          .map((doc) => Account.fromMap(doc.data()))
          .toList();

      // Load payment history
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(_debt.id)
          .collection('payments')
          .orderBy('date', descending: true)
          .get();
      _payments = paymentsSnapshot.docs
          .map((doc) => DebtPayment.fromMap(doc.data()))
          .toList();

      // Refresh debt data
      final debtDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(_debt.id)
          .get();
      if (debtDoc.exists) {
        _debt = Debt.fromMap(debtDoc.data()!);
      }

      _progressController.forward();
    } catch (e) {
      debugPrint('Error loading debt data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
    return '$_currencySymbol${amount.toStringAsFixed(2)}';
  }

  DebtCategory _getCategoryInfo(String categoryId) {
    return defaultDebtCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => defaultDebtCategories.last,
    );
  }

  bool get _isOverdue {
    if (_debt.dueDate == null || _debt.isPaid) return false;
    return _debt.dueDate!.isBefore(DateTime.now());
  }

  bool get _isOweMe => _debt.type == 'owedToMe';

  double get _amountPaid => _debt.totalAmount - _debt.remainingAmount;

  double get _progressPercent {
    if (_debt.totalAmount == 0) return 0;
    return (_amountPaid / _debt.totalAmount).clamp(0.0, 1.0);
  }

  Future<void> _makePayment(double amount, String? note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Create payment record
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      final payment = DebtPayment(
        id: paymentId,
        amount: amount,
        date: DateTime.now(),
        note: note,
      );

      final paymentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(_debt.id)
          .collection('payments')
          .doc(paymentId);
      batch.set(paymentRef, payment.toMap());

      // Update debt remaining amount
      final newRemaining = (_debt.remainingAmount - amount).clamp(
        0.0,
        _debt.totalAmount,
      );
      final debtRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(_debt.id);

      final isPaid = newRemaining <= 0;
      batch.update(debtRef, {
        'remainingAmount': newRemaining,
        'isPaid': isPaid,
      });

      // Update linked account balance (deduct for 'owe', add for 'owedToMe')
      final accountRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_accounts')
          .doc(_debt.linkedAccountId);
      final accountDoc = await accountRef.get();

      if (accountDoc.exists) {
        final currentBalance =
            (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
        final balanceChange = _isOweMe ? amount : -amount;
        batch.update(accountRef, {'balance': currentBalance + balanceChange});
      }

      await batch.commit();
      if (mounted) AppToast.success(context, 'Payment recorded', icon: Icons.payments_outlined);

      // Update local state
      setState(() {
        _debt = Debt(
          id: _debt.id,
          title: _debt.title,
          type: _debt.type,
          totalAmount: _debt.totalAmount,
          remainingAmount: newRemaining,
          dueDate: _debt.dueDate,
          linkedAccountId: _debt.linkedAccountId,
          category: _debt.category,
          notes: _debt.notes,
          isRecurring: _debt.isRecurring,
          installmentAmount: _debt.installmentAmount,
          createdAt: _debt.createdAt,
          isPaid: isPaid,
        );
        _payments.insert(0, payment);
      });

      // Animate progress bar
      _progressController.forward(from: 0);

      if (isPaid) {
        _showCompletionAnimation();
      }
    } catch (e) {
      debugPrint('Error making payment: $e');
      HapticFeedback.heavyImpact();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _markAsComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final batch = FirebaseFirestore.instance.batch();

      // If there's remaining amount, log it as final payment
      if (_debt.remainingAmount > 0) {
        final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
        final payment = DebtPayment(
          id: paymentId,
          amount: _debt.remainingAmount,
          date: DateTime.now(),
          note: _isOweMe ? 'Marked as received' : 'Marked as paid',
        );

        final paymentRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('finance_debts')
            .doc(_debt.id)
            .collection('payments')
            .doc(paymentId);
        batch.set(paymentRef, payment.toMap());

        _payments.insert(0, payment);

        // Update linked account for remaining amount
        final accountRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('finance_accounts')
            .doc(_debt.linkedAccountId);
        final accountDoc = await accountRef.get();

        if (accountDoc.exists) {
          final currentBalance =
              (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
          final balanceChange = _isOweMe
              ? _debt.remainingAmount
              : -_debt.remainingAmount;
          batch.update(accountRef, {'balance': currentBalance + balanceChange});
        }
      }

      // Update debt
      final debtRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_debts')
          .doc(_debt.id);
      batch.update(debtRef, {'remainingAmount': 0.0, 'isPaid': true});

      await batch.commit();
      if (mounted) AppToast.success(context, 'Debt marked as complete', icon: Icons.check_circle_outline_rounded);

      // Update local state
      setState(() {
        _debt = Debt(
          id: _debt.id,
          title: _debt.title,
          type: _debt.type,
          totalAmount: _debt.totalAmount,
          remainingAmount: 0,
          dueDate: _debt.dueDate,
          linkedAccountId: _debt.linkedAccountId,
          category: _debt.category,
          notes: _debt.notes,
          isRecurring: _debt.isRecurring,
          installmentAmount: _debt.installmentAmount,
          createdAt: _debt.createdAt,
          isPaid: true,
        );
      });

      _showCompletionAnimation();
    } catch (e) {
      debugPrint('Error marking as complete: $e');
      HapticFeedback.heavyImpact();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _showCompletionAnimation() {
    HapticFeedback.heavyImpact();
    setState(() => _showPaidAnimation = true);
    _checkmarkController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showPaymentModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bgColor = isDark
            ? const Color(0xFF19191A)
            : const Color(0xFFF0F0F6);
        final textColor = isDark ? Colors.white : Colors.black;
        final subtextColor = isDark ? Colors.white54 : Colors.black54;
        final cardColor = isDark
            ? const Color(0xFF19191A)
            : const Color(0xFFF0F0F6);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  _isOweMe ? 'Record Payment Received' : 'Make a Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining: ${_formatCurrency(_debt.remainingAmount)}',
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
                const SizedBox(height: 24),

                // Amount input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currencySymbol,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryInfo(_debt.category).color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            border: InputBorder.none,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick amount buttons
                Row(
                  children: [
                    _buildQuickAmountButton(
                      'Full',
                      _debt.remainingAmount,
                      amountController,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAmountButton(
                      'Half',
                      _debt.remainingAmount / 2,
                      amountController,
                      isDark,
                    ),
                    if (_debt.installmentAmount != null) ...[
                      const SizedBox(width: 8),
                      _buildQuickAmountButton(
                        'Installment',
                        _debt.installmentAmount!,
                        amountController,
                        isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Note input
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: noteController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      hintStyle: TextStyle(color: subtextColor, fontSize: 15),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.edit_outlined,
                        color: subtextColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                PremiumButton(
                  text: _isOweMe ? 'Record Payment' : 'Submit Payment',
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    );
                    if (amount == null || amount <= 0) {
                      HapticFeedback.heavyImpact();
                      return;
                    }
                    if (amount > _debt.remainingAmount) {
                      HapticFeedback.heavyImpact();
                      return;
                    }
                    Navigator.pop(context);
                    _makePayment(
                      amount,
                      noteController.text.isEmpty ? null : noteController.text,
                    );
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAmountButton(
    String label,
    double amount,
    TextEditingController controller,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.text = amount.toStringAsFixed(2);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = _getCategoryInfo(_debt.category);

    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);
    final cardColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    if (_showPaidAnimation) {
      return _buildCompletionOverlay(isDark, textColor);
    }

    return FractionallySizedBox(
      heightFactor: 0.83,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(isDark, textColor, category),

            if (_isLoading)
              const Expanded(
                child: Center(child: BouncingDotsLoader()),
              )
            else ...[
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Progress Section
                      _buildProgressCard(
                        isDark,
                        cardColor,
                        textColor,
                        subtextColor,
                        category,
                      ),
                      const SizedBox(height: 16),

                      // Due Date Section
                      if (_debt.dueDate != null)
                        _buildDueDateCard(
                          isDark,
                          cardColor,
                          textColor,
                          subtextColor,
                        ),
                      if (_debt.dueDate != null) const SizedBox(height: 16),

                      // Notes Section
                      if (_debt.notes != null && _debt.notes!.isNotEmpty)
                        _buildNotesCard(
                          isDark,
                          cardColor,
                          textColor,
                          subtextColor,
                        ),
                      if (_debt.notes != null && _debt.notes!.isNotEmpty)
                        const SizedBox(height: 16),

                      // Payment History Section
                      _buildPaymentHistorySection(
                        isDark,
                        cardColor,
                        textColor,
                        subtextColor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              if (!_debt.isPaid) _buildActionButtons(isDark, category),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, DebtCategory category) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24.0,
        left: 20.0,
        right: 20.0,
        bottom: 16.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(category.icon, color: category.color, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Title and label
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _debt.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isOweMe
                        ? const Color(0xFF34C759).withOpacity(0.15)
                        : const Color(0xFFFF9500).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isOweMe ? 'Owe Me' : 'I Owe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isOweMe
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Close button
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Center(
              child: UniversalCloseButton(
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    DebtCategory category,
  ) {
    final progressColor = _debt.isPaid
        ? const Color(0xFF34C759)
        : _progressPercent > 0.8
        ? const Color(0xFF34C759)
        : _progressPercent > 0.5
        ? const Color(0xFFFF9500)
        : category.color;

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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _debt.isPaid
                        ? Icons.check_circle
                        : Icons.bar_chart,
                    color: progressColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _debt.isPaid ? 'Completed' : 'Progress',
                      style: TextStyle(color: subtextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatCurrency(_amountPaid)} paid of ${_formatCurrency(_debt.totalAmount)}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(_progressPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar with animation
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: _progressPercent * _progressAnimation.value,
                  backgroundColor: progressColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              );
            },
          ),

          if (_debt.remainingAmount > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Remaining: ${_formatCurrency(_debt.remainingAmount)}',
              style: TextStyle(color: subtextColor, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDueDateCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final dueDateStr = _formatDate(_debt.dueDate!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (_isOverdue
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF007AFF))
                      .withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.calendar_today,
                color: _isOverdue
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFF007AFF),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Due Date',
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                Text(
                  dueDateStr,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'OVERDUE',
                style: TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8E8E93).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.description_outlined,
                color: Color(0xFF8E8E93),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: TextStyle(color: subtextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _debt.notes!,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        if (_payments.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.description_outlined, color: subtextColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No payments yet',
                    style: TextStyle(color: subtextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payments.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              ),
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return _buildPaymentItem(payment, textColor, subtextColor);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentItem(
    DebtPayment payment,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: Color(0xFF34C759),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(payment.amount),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (payment.note != null && payment.note!.isNotEmpty)
                  Text(
                    payment.note!,
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(payment.date),
            style: TextStyle(color: subtextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, DebtCategory category) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          // Make Payment button
          PremiumButton(
            text: _isOweMe ? 'Record Payment' : 'Make a Payment',
            isLoading: _isProcessing,
            onPressed: _showPaymentModal,
          ),
          const SizedBox(height: 12),

          // Mark as Complete button
          GestureDetector(
            onTap: _isProcessing ? null : _markAsComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF34C759).withOpacity(0.15)
                    : const Color(0xFF34C759).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF34C759).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _isOweMe ? 'Mark as Received' : 'Mark as Paid',
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionOverlay(bool isDark, Color textColor) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromARGB(255, 26, 26, 28)
              : const Color.fromARGB(255, 245, 245, 245),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _checkmarkAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF34C759),
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _checkmarkAnimation,
                child: Text(
                  _isOweMe ? 'Payment Received!' : 'Debt Paid Off!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _checkmarkAnimation,
                child: Text(
                  _formatCurrency(_debt.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34C759),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Helper function to show the debt detail modal
void showDebtDetailModal(BuildContext context, Debt debt) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DebtDetailModal(debt: debt),
  ).then((result) {
    if (result == true) {
      // Debt was updated, parent should refresh
    }
  });
}
