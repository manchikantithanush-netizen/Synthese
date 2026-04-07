import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents where money is stored (e.g., Cash, Bank, Card)
class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final int iconCodePoint;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.iconCodePoint,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: CupertinoIcons.iconFont, fontPackage: CupertinoIcons.iconFontPackage);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      type: map['type'] as String? ?? 'other',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xf3ec,
    );
  }
}

/// Represents transaction categories (expense or income)
class Category {
  final String id;
  final String name;
  final String type;
  final int iconCodePoint;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.color,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: CupertinoIcons.iconFont, fontPackage: CupertinoIcons.iconFontPackage);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconCodePoint': iconCodePoint,
      // ignore: deprecated_member_use
      'color': color.value,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      type: map['type'] as String? ?? 'expense',
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xf3ec,
      color: Color(map['color'] as int? ?? 0xFF8E8E93),
    );
  }
}

/// Represents an individual financial transaction
class FinanceTransaction {
  final String id;
  final double amount;
  final String accountId;
  final String categoryId;
  final DateTime date;
  final String? note;
  final String type;
  final bool isRecurring;
  final String? recurrenceType; // 'daily', 'weekly', 'monthly'

  FinanceTransaction({
    required this.id,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.date,
    this.note,
    required this.type,
    this.isRecurring = false,
    this.recurrenceType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'type': type,
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
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
    
    return FinanceTransaction(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: map['accountId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      date: date,
      note: map['note'] as String?,
      type: map['type'] as String? ?? 'expense',
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceType: map['recurrenceType'] as String?,
    );
  }
}

// Default Accounts
final List<Account> defaultAccounts = [
  Account(
    id: 'cash',
    name: 'Cash',
    type: 'cash',
    balance: 0.0,
    iconCodePoint: CupertinoIcons.money_dollar_circle_fill.codePoint,
  ),
  Account(
    id: 'bank',
    name: 'Bank',
    type: 'bank',
    balance: 0.0,
    iconCodePoint: CupertinoIcons.building_2_fill.codePoint,
  ),
  Account(
    id: 'card',
    name: 'Card',
    type: 'card',
    balance: 0.0,
    iconCodePoint: CupertinoIcons.creditcard_fill.codePoint,
  ),
];

// Default Expense Categories - using muted iOS-style colors
final List<Category> defaultExpenseCategories = [
  Category(
    id: 'food',
    name: 'Food',
    type: 'expense',
    iconCodePoint: CupertinoIcons.cart_fill.codePoint,
    color: const Color(0xFFFF9500), // iOS Orange
  ),
  Category(
    id: 'transport',
    name: 'Transport',
    type: 'expense',
    iconCodePoint: CupertinoIcons.car_fill.codePoint,
    color: const Color(0xFF5AC8FA), // iOS Light Blue
  ),
  Category(
    id: 'shopping',
    name: 'Gear & Shopping',
    type: 'expense',
    iconCodePoint: CupertinoIcons.bag_fill.codePoint,
    color: const Color(0xFFFF6B9D), // Muted Pink
  ),
  Category(
    id: 'entertainment',
    name: 'Entertainment',
    type: 'expense',
    iconCodePoint: CupertinoIcons.tv_fill.codePoint,
    color: const Color(0xFFAF52DE), // iOS Purple
  ),
  Category(
    id: 'bills',
    name: 'Bills',
    type: 'expense',
    iconCodePoint: CupertinoIcons.doc_text_fill.codePoint,
    color: const Color(0xFFFF6B6B), // Muted Red
  ),
  Category(
    id: 'health',
    name: 'Health & Recovery',
    type: 'expense',
    iconCodePoint: CupertinoIcons.heart_fill.codePoint,
    color: const Color(0xFF34C759), // iOS Green
  ),
  Category(
    id: 'other_expense',
    name: 'Other',
    type: 'expense',
    iconCodePoint: CupertinoIcons.ellipsis_circle_fill.codePoint,
    color: const Color(0xFF8E8E93), // iOS Gray
  ),
];

/// Represents a debt (money owed or owed to you)
class Debt {
  final String id;
  final String title;
  final String type; // 'owe' or 'owedToMe'
  final double totalAmount;
  final double remainingAmount;
  final DateTime? dueDate;
  final String linkedAccountId;
  final String category; // 'loan', 'credit_card', 'personal', 'mortgage', 'other'
  final String? notes;
  final bool isRecurring;
  final double? installmentAmount;
  final DateTime createdAt;
  final bool isPaid;

  Debt({
    required this.id,
    required this.title,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    this.dueDate,
    required this.linkedAccountId,
    required this.category,
    this.notes,
    this.isRecurring = false,
    this.installmentAmount,
    required this.createdAt,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'linkedAccountId': linkedAccountId,
      'category': category,
      'notes': notes,
      'isRecurring': isRecurring,
      'installmentAmount': installmentAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPaid': isPaid,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    // Handle potential null or missing createdAt field
    DateTime createdAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else {
      createdAt = DateTime.now();
    }

    return Debt(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      type: map['type'] as String? ?? 'owe',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      linkedAccountId: map['linkedAccountId'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      notes: map['notes'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      installmentAmount: map['installmentAmount'] != null 
          ? (map['installmentAmount'] as num).toDouble() 
          : null,
      createdAt: createdAt,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }
}

/// Represents a debt category with icon and color
class DebtCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final Color color;

  const DebtCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.color,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: CupertinoIcons.iconFont, fontPackage: CupertinoIcons.iconFontPackage);
}

// Default Income Categories - using muted iOS-style colors
final List<Category> defaultIncomeCategories = [
  Category(
    id: 'salary',
    name: 'Contract',
    type: 'income',
    iconCodePoint: CupertinoIcons.money_dollar_circle_fill.codePoint,
    color: const Color(0xFF30D158), // iOS Green
  ),
  Category(
    id: 'freelance',
    name: 'Appearance Fee',
    type: 'income',
    iconCodePoint: CupertinoIcons.briefcase_fill.codePoint,
    color: const Color(0xFF64D2FF), // iOS Cyan
  ),
  Category(
    id: 'investment',
    name: 'Sponsorship',
    type: 'income',
    iconCodePoint: CupertinoIcons.graph_square_fill.codePoint,
    color: const Color(0xFF5E5CE6), // iOS Indigo
  ),
  Category(
    id: 'gift',
    name: 'Gift',
    type: 'income',
    iconCodePoint: CupertinoIcons.gift_fill.codePoint,
    color: const Color(0xFFFFD60A), // iOS Yellow
  ),
  Category(
    id: 'other_income',
    name: 'Other',
    type: 'income',
    iconCodePoint: CupertinoIcons.ellipsis_circle_fill.codePoint,
    color: const Color(0xFF8E8E93), // iOS Gray
  ),
];

// Default Debt Categories - using muted iOS-style colors
final List<DebtCategory> defaultDebtCategories = [
  DebtCategory(
    id: 'loan',
    name: 'Loan',
    iconCodePoint: CupertinoIcons.doc_text_fill.codePoint,
    color: const Color(0xFF5E5CE6), // iOS Indigo
  ),
  DebtCategory(
    id: 'credit_card',
    name: 'Credit Card',
    iconCodePoint: CupertinoIcons.creditcard_fill.codePoint,
    color: const Color(0xFFFF6B6B), // Muted Red
  ),
  DebtCategory(
    id: 'personal',
    name: 'Personal',
    iconCodePoint: CupertinoIcons.person_fill.codePoint,
    color: const Color(0xFF64D2FF), // iOS Cyan
  ),
  DebtCategory(
    id: 'mortgage',
    name: 'Mortgage',
    iconCodePoint: CupertinoIcons.house_fill.codePoint,
    color: const Color(0xFF34C759), // iOS Green
  ),
  DebtCategory(
    id: 'other',
    name: 'Other',
    iconCodePoint: CupertinoIcons.ellipsis_circle_fill.codePoint,
    color: const Color(0xFF8E8E93), // iOS Gray
  ),
];

/// Severity levels for financial insights
enum InsightSeverity {
  positive, // Green - good news, celebrations
  warning,  // Amber/Orange - needs attention
  info,     // Blue - informational, neutral
}

/// Represents a contextual financial insight/tip
class FinanceInsight {
  final String id;
  final String title;
  final String message;
  final InsightSeverity severity;
  final String dataHash; // Hash of underlying data for change detection
  final IconData icon;

  const FinanceInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.dataHash,
    required this.icon,
  });

  /// Get colors based on severity (light mode)
  Color get backgroundColor {
    switch (severity) {
      case InsightSeverity.warning:
        return const Color(0xFFFFF4E5); // Light amber
      case InsightSeverity.positive:
        return const Color(0xFFE8F8EE); // Light green
      case InsightSeverity.info:
        return const Color(0xFFE5F1FF); // Light blue
    }
  }

  /// Get colors based on severity (dark mode)
  Color get backgroundColorDark {
    switch (severity) {
      case InsightSeverity.warning:
        return const Color(0xFF2A1F10); // Dark amber
      case InsightSeverity.positive:
        return const Color(0xFF1A2F1F); // Dark green
      case InsightSeverity.info:
        return const Color(0xFF1A2535); // Dark blue
    }
  }

  /// Get border color (light mode)
  Color get borderColor {
    switch (severity) {
      case InsightSeverity.warning:
        return const Color(0xFFFFD8A8); // Amber border
      case InsightSeverity.positive:
        return const Color(0xFFB8E5C8); // Green border
      case InsightSeverity.info:
        return const Color(0xFFB8D4F0); // Blue border
    }
  }

  /// Get border color (dark mode)
  Color get borderColorDark {
    switch (severity) {
      case InsightSeverity.warning:
        return const Color(0xFF4A3215); // Dark amber border
      case InsightSeverity.positive:
        return const Color(0xFF2A4A35); // Dark green border
      case InsightSeverity.info:
        return const Color(0xFF2A3A4A); // Dark blue border
    }
  }

  /// Get icon color
  Color get iconColor {
    switch (severity) {
      case InsightSeverity.warning:
        return const Color(0xFFF57C00); // Amber
      case InsightSeverity.positive:
        return const Color(0xFF34C759); // iOS Green
      case InsightSeverity.info:
        return const Color(0xFF007AFF); // iOS Blue
    }
  }
}
