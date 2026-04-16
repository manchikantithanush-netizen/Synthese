import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';

class OnboardingFinance extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingFinance({super.key, required this.onContinue});

  @override
  State<OnboardingFinance> createState() => _OnboardingFinanceState();
}

class _OnboardingFinanceState extends State<OnboardingFinance> {
  int _currentPage = 0;
  bool _isSaving = false;
  String _currencySymbol = '\$';

  // Account setup state
  bool _cashEnabled = true;
  bool _bankEnabled = true;
  bool _cardEnabled = true;
  final TextEditingController _cashNameController = TextEditingController(
    text: 'Cash',
  );
  final TextEditingController _bankNameController = TextEditingController(
    text: 'Bank',
  );
  final TextEditingController _cardNameController = TextEditingController(
    text: 'Card',
  );

  // Budget state
  final TextEditingController _budgetController = TextEditingController();

  static const Color greenColor = Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
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
    _cashNameController.dispose();
    _bankNameController.dispose();
    _cardNameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
  }

  void _previousPage() {
    setState(() {
      _currentPage--;
    });
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final accountsRef = userRef.collection('accounts');

      // Parse budget amount
      final budgetText = _budgetController.text.replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      final monthlyBudget = double.tryParse(budgetText) ?? 0.0;

      // Save user settings
      batch.set(userRef, {
        'financeSetupCompleted': true,
        'monthlyBudget': monthlyBudget,
      }, SetOptions(merge: true));

      // Create selected accounts
      if (_cashEnabled) {
        final account = Account(
          id: 'cash',
          name: _cashNameController.text.trim().isEmpty
              ? 'Cash'
              : _cashNameController.text.trim(),
          type: 'cash',
          balance: 0.0,
          iconCodePoint: CupertinoIcons.money_dollar_circle_fill.codePoint,
        );
        batch.set(accountsRef.doc(account.id), account.toMap());
      }

      if (_bankEnabled) {
        final account = Account(
          id: 'bank',
          name: _bankNameController.text.trim().isEmpty
              ? 'Bank'
              : _bankNameController.text.trim(),
          type: 'bank',
          balance: 0.0,
          iconCodePoint: CupertinoIcons.building_2_fill.codePoint,
        );
        batch.set(accountsRef.doc(account.id), account.toMap());
      }

      if (_cardEnabled) {
        final account = Account(
          id: 'card',
          name: _cardNameController.text.trim().isEmpty
              ? 'Card'
              : _cardNameController.text.trim(),
          type: 'card',
          balance: 0.0,
          iconCodePoint: CupertinoIcons.creditcard_fill.codePoint,
        );
        batch.set(accountsRef.doc(account.id), account.toMap());
      }

      await batch.commit();

      HapticFeedback.mediumImpact();
      widget.onContinue();
    } catch (e) {
      debugPrint("Error saving finance data: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedTextScale.toDouble()),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentPage(isDark, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage(bool isDark, Color textColor) {
    switch (_currentPage) {
      case 0:
        return _buildWelcomePage(isDark, textColor);
      case 1:
        return _buildAccountSetupPage(isDark, textColor);
      case 2:
        return _buildBudgetPage(isDark, textColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScrollablePage({
    required Key key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return KeyedSubtree(
      key: key,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 760;
          final horizontalPadding = constraints.maxWidth < 370 ? 20.0 : 28.0;
          final mediaQuery = MediaQuery.of(context);
          final bottomSpacing =
              mediaQuery.viewInsets.bottom + (isCompact ? 12 : 24);
          final resolvedPadding =
              padding ??
              EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 8 : 12,
                horizontalPadding,
                bottomSpacing,
              );
          final verticalPadding = resolvedPadding.vertical;
          return Padding(
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - verticalPadding).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    Widget buildFeature(
      String title,
      String desc,
      IconData iconData,
      Color iconColor,
    ) {
      return Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 18 : 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isCompact ? 48 : 56,
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: isCompact ? 30 : 35,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: isCompact ? 14 : 15,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildScrollablePage(
      key: const ValueKey('welcome'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isCompact ? 14 : 32),
          Text(
            "Welcome to\nFinance Tracker",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 30 : 34,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
          buildFeature(
            "Track expenses",
            "Log every transaction and see where your money goes. Categorize spending to understand your habits.",
            CupertinoIcons.money_dollar_circle_fill,
            const Color(0xFF34C759),
          ),
          buildFeature(
            "Set budgets",
            "Set monthly spending limits and get alerts when you're close to reaching them.",
            CupertinoIcons.chart_pie_fill,
            const Color(0xFF5E5CE6),
          ),
          buildFeature(
            "Privacy first",
            "Your financial data stays on your device and is never shared with third parties.",
            CupertinoIcons.lock_shield_fill,
            const Color(0xFFFF9F0A),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Text(
              "This app is for personal finance tracking only and does not provide financial advice.",
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            text: "Get Started",
            onPressed: _nextPage,
            color: greenColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPill(
    String title,
    bool isSelected,
    VoidCallback onTap, {
    TextEditingController? nameController,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF34C759) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: nameController != null
                  ? TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: title,
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: Color(0xFF34C759),
                      size: 22,
                      key: ValueKey('checked'),
                    )
                  : const SizedBox(
                      width: 22,
                      height: 22,
                      key: ValueKey('unchecked'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSetupPage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    return _buildScrollablePage(
      key: const ValueKey('accounts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          UniversalBackButton(onPressed: _previousPage),
          const SizedBox(height: 24),
          Text(
            "Set up your accounts",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Choose which accounts you want to track. You can rename them or add more later.",
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: isCompact ? 15 : 16,
              height: 1.4,
            ),
          ),
          const Spacer(),
          _buildAccountPill(
            'Cash',
            _cashEnabled,
            () => setState(() => _cashEnabled = !_cashEnabled),
            nameController: _cashNameController,
          ),
          _buildAccountPill(
            'Bank',
            _bankEnabled,
            () => setState(() => _bankEnabled = !_bankEnabled),
            nameController: _bankNameController,
          ),
          _buildAccountPill(
            'Card',
            _cardEnabled,
            () => setState(() => _cardEnabled = !_cardEnabled),
            nameController: _cardNameController,
          ),
          const Spacer(),
          PremiumButton(
            text: "Continue",
            onPressed: (_cashEnabled || _bankEnabled || _cardEnabled)
                ? _nextPage
                : () {},
            color: greenColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPage(bool isDark, Color textColor) {
    final isCompact = MediaQuery.of(context).size.height < 760;
    return _buildScrollablePage(
      key: const ValueKey('budget'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          UniversalBackButton(onPressed: _previousPage),
          const SizedBox(height: 24),
          Text(
            "Set your monthly budget",
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "How much do you want to spend each month? We'll help you stay on track.",
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: isCompact ? 15 : 16,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currencySymbol,
                  style: TextStyle(
                    color: greenColor,
                    fontSize: isCompact ? 40 : 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isCompact ? 40 : 48,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PremiumButton(
            text: "Finish Setup",
            isLoading: _isSaving,
            onPressed: _isSaving ? () {} : _saveData,
            color: greenColor,
          ),
        ],
      ),
    );
  }
}
