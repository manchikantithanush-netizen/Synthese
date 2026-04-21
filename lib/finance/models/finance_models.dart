import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Returns a Material icon directly from the well-known id string.
/// No Firestore lookup needed — ids never change.
IconData iconForId(String id) {
  switch (id) {
    case 'cash':          return Icons.account_balance_wallet;
    case 'bank':          return Icons.account_balance;
    case 'card':          return Icons.credit_card;
    case 'food':          return Icons.shopping_cart;
    case 'transport':     return Icons.directions_car;
    case 'shopping':      return Icons.shopping_bag;
    case 'entertainment': return Icons.tv;
    case 'bills':         return Icons.description;
    case 'health':        return Icons.favorite;
    case 'other_expense': return Icons.more_horiz;
    case 'salary':        return Icons.account_balance_wallet;
    case 'freelance':     return Icons.work;
    case 'investment':    return Icons.show_chart;
    case 'gift':          return Icons.card_giftcard;
    case 'other_income':  return Icons.more_horiz;
    case 'loan':          return Icons.description;
    case 'credit_card':   return Icons.credit_card;
    case 'personal':      return Icons.person;
    case 'mortgage':      return Icons.home;
    case 'other':         return Icons.more_horiz;
    default:              return Icons.attach_money;
  }
}

/// Represents where money is stored (e.g., Cash, Bank, Card)
class Account {
  final String id;
  final String name;
  final String type;
  final double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  IconData get icon => iconForId(id);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'balance': balance,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Unknown',
    type: map['type'] as String? ?? 'other',
    balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Represents transaction categories (expense or income)
class Category {
  final String id;
  final String name;
  final String type;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  IconData get icon => iconForId(id);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    // ignore: deprecated_member_use
    'color': color.value,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? 'Unknown',
    type: map['type'] as String? ?? 'expense',
    color: Color(map['color'] as int? ?? 0xFF8E8E93),
  );
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
  final String? recurrenceType;

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

  Map<String, dynamic> toMap() => {
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

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
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
  Account(id: 'cash', name: 'Cash', type: 'cash', balance: 0.0),
  Account(id: 'bank', name: 'Bank', type: 'bank', balance: 0.0),
  Account(id: 'card', name: 'Card', type: 'card', balance: 0.0),
];

// Default Expense Categories
final List<Category> defaultExpenseCategories = [
  Category(id: 'food',          name: 'Food',             type: 'expense', color: const Color(0xFFFF9500)),
  Category(id: 'transport',     name: 'Transport',        type: 'expense', color: const Color(0xFF5AC8FA)),
  Category(id: 'shopping',      name: 'Gear & Shopping',  type: 'expense', color: const Color(0xFFFF6B9D)),
  Category(id: 'entertainment', name: 'Entertainment',    type: 'expense', color: const Color(0xFFAF52DE)),
  Category(id: 'bills',         name: 'Bills',            type: 'expense', color: const Color(0xFFFF6B6B)),
  Category(id: 'health',        name: 'Health & Recovery',type: 'expense', color: const Color(0xFF34C759)),
  Category(id: 'other_expense', name: 'Other',            type: 'expense', color: const Color(0xFF8E8E93)),
];

// Default Income Categories
final List<Category> defaultIncomeCategories = [
  Category(id: 'salary',       name: 'Contract',       type: 'income', color: const Color(0xFF30D158)),
  Category(id: 'freelance',    name: 'Appearance Fee', type: 'income', color: const Color(0xFF64D2FF)),
  Category(id: 'investment',   name: 'Sponsorship',    type: 'income', color: const Color(0xFF5E5CE6)),
  Category(id: 'gift',         name: 'Gift',           type: 'income', color: const Color(0xFFFFD60A)),
  Category(id: 'other_income', name: 'Other',          type: 'income', color: const Color(0xFF8E8E93)),
];

/// Represents a debt (money owed or owed to you)
class Debt {
  final String id;
  final String title;
  final String type;
  final double totalAmount;
  final double remainingAmount;
  final DateTime? dueDate;
  final String linkedAccountId;
  final String category;
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

  Map<String, dynamic> toMap() => {
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

  factory Debt.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    final v = map['createdAt'];
    if (v is Timestamp) {
      createdAt = v.toDate();
    } else if (v is DateTime) {
      createdAt = v;
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
  final Color color;

  const DebtCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  IconData get icon => iconForId(id);
}

// Default Debt Categories
final List<DebtCategory> defaultDebtCategories = [
  DebtCategory(id: 'loan',        name: 'Loan',        color: const Color(0xFF5E5CE6)),
  DebtCategory(id: 'credit_card', name: 'Credit Card', color: const Color(0xFFFF6B6B)),
  DebtCategory(id: 'personal',    name: 'Personal',    color: const Color(0xFF64D2FF)),
  DebtCategory(id: 'mortgage',    name: 'Mortgage',    color: const Color(0xFF34C759)),
  DebtCategory(id: 'other',       name: 'Other',       color: const Color(0xFF8E8E93)),
];

/// Severity levels for financial insights
enum InsightSeverity { positive, warning, info }

/// Represents a contextual financial insight/tip
class FinanceInsight {
  final String id;
  final String title;
  final String message;
  final InsightSeverity severity;
  final String dataHash;
  final IconData icon;

  const FinanceInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.dataHash,
    required this.icon,
  });

  Color get backgroundColor {
    switch (severity) {
      case InsightSeverity.warning:  return const Color(0xFFFFF4E5);
      case InsightSeverity.positive: return const Color(0xFFE8F8EE);
      case InsightSeverity.info:     return const Color(0xFFE5F1FF);
    }
  }

  Color get backgroundColorDark {
    switch (severity) {
      case InsightSeverity.warning:  return const Color(0xFF2A1F10);
      case InsightSeverity.positive: return const Color(0xFF1A2F1F);
      case InsightSeverity.info:     return const Color(0xFF1A2535);
    }
  }

  Color get borderColor {
    switch (severity) {
      case InsightSeverity.warning:  return const Color(0xFFFFD8A8);
      case InsightSeverity.positive: return const Color(0xFFB8E5C8);
      case InsightSeverity.info:     return const Color(0xFFB8D4F0);
    }
  }

  Color get borderColorDark {
    switch (severity) {
      case InsightSeverity.warning:  return const Color(0xFF4A3215);
      case InsightSeverity.positive: return const Color(0xFF2A4A35);
      case InsightSeverity.info:     return const Color(0xFF2A3A4A);
    }
  }

  Color get iconColor {
    switch (severity) {
      case InsightSeverity.warning:  return const Color(0xFFF57C00);
      case InsightSeverity.positive: return const Color(0xFF34C759);
      case InsightSeverity.info:     return const Color(0xFF007AFF);
    }
  }
}
