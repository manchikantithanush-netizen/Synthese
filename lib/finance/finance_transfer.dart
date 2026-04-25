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

class TransferModal extends StatefulWidget {
  const TransferModal({super.key});

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal> {
  final FinanceService _financeService = FinanceService();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;
  bool _isTransferring = false;
  String? _errorMessage;
  Timer? _errorTimer;

  Account? _fromAccount;
  Account? _toAccount;
  List<Account> _accounts = [];
  String _currencySymbol = '\$';

  static const Color transferColor = Color(0xFF007AFF); // iOS Blue

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _fetchUserCurrency();
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

  @override
  void dispose() {
    _errorTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      await _financeService.initializeDefaultAccounts(uid);

      final accountsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('finance_accounts')
          .get();

      _accounts = accountsSnapshot.docs
          .map((doc) => Account.fromMap(doc.data()))
          .toList();

      if (_accounts.length >= 2) {
        _fromAccount = _accounts[0];
        _toAccount = _accounts[1];
      } else if (_accounts.isNotEmpty) {
        _fromAccount = _accounts[0];
      }
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _executeTransfer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Validation
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_fromAccount == null) {
      _showError('Please select a source account');
      return;
    }
    if (_toAccount == null) {
      _showError('Please select a destination account');
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      _showError('Cannot transfer to the same account');
      return;
    }

    // Fetch latest balance for from account
    final latestFromAccount = await _financeService.getAccount(
      uid,
      _fromAccount!.id,
    );
    if (latestFromAccount == null) {
      _showError('Source account not found');
      return;
    }
    if (latestFromAccount.balance < amount) {
      _showError('Insufficient Funds');
      return;
    }

    setState(() => _isTransferring = true);

    try {
      await _financeService.transferBetweenAccounts(
        uid,
        _fromAccount!.id,
        _toAccount!.id,
        amount,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        AppToast.success(context, 'Transfer completed', icon: Icons.swap_horiz_rounded);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error transferring: $e');
      _showError('Failed to transfer funds');
    }

    if (mounted) {
      setState(() => _isTransferring = false);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    final cardColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    return FractionallySizedBox(
      heightFactor: 0.65,
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
                      "Transfer",
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

            const SizedBox(height: 20),

            // --- CONTENT ---
            Expanded(
              child: _isLoading
                  ? Center(
                      child: BouncingDotsLoader(color: transferColor),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- AMOUNT INPUT ---
                          _buildAmountInput(isDark, cardColor, textColor),

                          const SizedBox(height: 20),

                          // --- FROM ACCOUNT ---
                          _buildSectionLabel('From', subtextColor),
                          const SizedBox(height: 8),
                          _buildAccountDropdown(
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            selectedAccount: _fromAccount,
                            onChanged: (account) {
                              setState(() => _fromAccount = account);
                              HapticFeedback.selectionClick();
                            },
                          ),

                          const SizedBox(height: 20),

                          // --- TO ACCOUNT ---
                          _buildSectionLabel('To', subtextColor),
                          const SizedBox(height: 8),
                          _buildAccountDropdown(
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            selectedAccount: _toAccount,
                            onChanged: (account) {
                              setState(() => _toAccount = account);
                              HapticFeedback.selectionClick();
                            },
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),

            // --- TRANSFER BUTTON ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: PremiumButton(
                text: 'Transfer',
                isLoading: _isTransferring,
                onPressed: _executeTransfer,
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

  Widget _buildAmountInput(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            _currencySymbol,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: transferColor,
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDropdown({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Account? selectedAccount,
    required ValueChanged<Account?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => _showAccountPicker(
        isDark: isDark,
        selectedAccount: selectedAccount,
        onChanged: onChanged,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedAccount != null
                ? transferColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (selectedAccount != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transferColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selectedAccount.icon,
                  color: transferColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedAccount.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_currencySymbol${selectedAccount.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select account',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountPicker({
    required bool isDark,
    required Account? selectedAccount,
    required ValueChanged<Account?> onChanged,
  }) {
    HapticFeedback.lightImpact();

    final bgColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Select Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  UniversalCloseButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Account list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  final isSelected = selectedAccount?.id == account.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(account);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? transferColor.withOpacity(0.12)
                            : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? transferColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? transferColor.withOpacity(0.15)
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.black.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              account.icon,
                              color: isSelected
                                  ? transferColor
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? transferColor
                                        : textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$_currencySymbol${account.balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: transferColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
