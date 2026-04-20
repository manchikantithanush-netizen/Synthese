import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:synthese/finance/models/finance_models.dart';
import 'package:synthese/services/data_aggregation_service.dart';

/// Service class for handling Finance feature Firebase operations
class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references helper
  CollectionReference _accountsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('finance_accounts');

  CollectionReference _categoriesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('finance_categories');

  CollectionReference _transactionsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('finance_transactions');

  CollectionReference _debtsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('finance_debts');

  CollectionReference _debtPaymentsRef(String uid, String debtId) =>
      _debtsRef(uid).doc(debtId).collection('payments');

  // ============================================================
  // ACCOUNT METHODS
  // ============================================================

  /// Creates default accounts if none exist for the user
  Future<void> initializeDefaultAccounts(String uid) async {
    final snapshot = await _accountsRef(uid).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final account in defaultAccounts) {
      final docRef = _accountsRef(uid).doc(account.id);
      batch.set(docRef, account.toMap());
    }
    await batch.commit();
  }

  /// Returns a real-time stream of all accounts for the user
  Stream<QuerySnapshot> getAccountsStream(String uid) {
    return _accountsRef(uid).snapshots();
  }

  /// Updates the balance of a specific account
  Future<void> updateAccountBalance(
      String uid, String accountId, double newBalance) async {
    await _accountsRef(uid).doc(accountId).update({'balance': newBalance});
  }

  /// Fetches a single account by ID
  Future<Account?> getAccount(String uid, String accountId) async {
    final doc = await _accountsRef(uid).doc(accountId).get();
    if (!doc.exists) return null;
    return Account.fromMap(doc.data() as Map<String, dynamic>);
  }

  // ============================================================
  // CATEGORY METHODS
  // ============================================================

  /// Creates default categories (expense + income) if none exist
  Future<void> initializeDefaultCategories(String uid) async {
    final snapshot = await _categoriesRef(uid).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    
    // Add expense categories
    for (final category in defaultExpenseCategories) {
      final docRef = _categoriesRef(uid).doc(category.id);
      batch.set(docRef, category.toMap());
    }
    
    // Add income categories
    for (final category in defaultIncomeCategories) {
      final docRef = _categoriesRef(uid).doc(category.id);
      batch.set(docRef, category.toMap());
    }
    
    await batch.commit();
  }

  /// Returns a real-time stream of all categories for the user
  Stream<QuerySnapshot> getCategoriesStream(String uid) {
    return _categoriesRef(uid).snapshots();
  }

  /// Returns a list of expense categories
  Future<List<Category>> getExpenseCategories(String uid) async {
    final snapshot =
        await _categoriesRef(uid).where('type', isEqualTo: 'expense').get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Returns a list of income categories
  Future<List<Category>> getIncomeCategories(String uid) async {
    final snapshot =
        await _categoriesRef(uid).where('type', isEqualTo: 'income').get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // TRANSACTION METHODS
  // ============================================================

  /// Adds a transaction and updates the associated account balance
  Future<void> addTransaction(String uid, FinanceTransaction transaction) async {
    final batch = _firestore.batch();

    // Add transaction document
    final transRef = _transactionsRef(uid).doc(transaction.id);
    batch.set(transRef, transaction.toMap());

    // Update account balance
    final accountRef = _accountsRef(uid).doc(transaction.accountId);
    final accountDoc = await accountRef.get();
    
    if (accountDoc.exists) {
      final currentBalance =
          (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
      final balanceChange = transaction.type == 'income'
          ? transaction.amount
          : -transaction.amount;
      batch.update(accountRef, {'balance': currentBalance + balanceChange});
    }

    await batch.commit();
    if (transaction.type == 'expense') {
      await DataAggregationService.updateFinanceMonthlyExpense(
        uid: uid,
        when: transaction.date,
        amountDelta: transaction.amount,
      );
    }
  }

  /// Returns a real-time stream of transactions ordered by date descending
  Stream<QuerySnapshot> getTransactionsStream(String uid) {
    return _transactionsRef(uid).orderBy('date', descending: true).snapshots();
  }

  /// Fetches the most recent transactions
  Future<List<FinanceTransaction>> getRecentTransactions(String uid,
      {int limit = 10}) async {
    final snapshot = await _transactionsRef(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) =>
            FinanceTransaction.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a transaction and reverses the balance change on the account
  Future<void> deleteTransaction(String uid, String transactionId, FinanceTransaction transaction) async {
    final batch = _firestore.batch();

    // Reverse the balance change
    final accountRef = _accountsRef(uid).doc(transaction.accountId);
    final accountDoc = await accountRef.get();
    
    if (accountDoc.exists) {
      final currentBalance =
          (accountDoc.data() as Map<String, dynamic>)['balance'] as num;
      final balanceChange = transaction.type == 'income'
          ? -transaction.amount
          : transaction.amount;
      batch.update(accountRef, {'balance': currentBalance + balanceChange});
    }

    // Delete the transaction
    final transRef = _transactionsRef(uid).doc(transactionId);
    batch.delete(transRef);

    await batch.commit();
    if (transaction.type == 'expense') {
      await DataAggregationService.updateFinanceMonthlyExpense(
        uid: uid,
        when: transaction.date,
        amountDelta: -transaction.amount,
      );
    }
  }

  // ============================================================
  // BALANCE METHODS
  // ============================================================

  /// Calculates the total balance across all accounts
  Future<double> getTotalBalance(String uid) async {
    final snapshot = await _accountsRef(uid).get();
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final balance = (doc.data() as Map<String, dynamic>)['balance'] as num;
      total += balance.toDouble();
    }
    return total;
  }

  /// Gets the balance of a specific account
  Future<double> getBalanceByAccount(String uid, String accountId) async {
    final doc = await _accountsRef(uid).doc(accountId).get();
    if (!doc.exists) return 0.0;
    return ((doc.data() as Map<String, dynamic>)['balance'] as num).toDouble();
  }

  // ============================================================
  // TRANSFER METHODS
  // ============================================================

  /// Transfers funds between two accounts
  Future<void> transferBetweenAccounts(
      String uid, String fromId, String toId, double amount) async {
    // Validate amount
    if (amount <= 0) {
      throw Exception('Transfer amount must be greater than zero');
    }
    
    final batch = _firestore.batch();

    final fromRef = _accountsRef(uid).doc(fromId);
    final toRef = _accountsRef(uid).doc(toId);

    // Get current balances
    final fromDoc = await fromRef.get();
    final toDoc = await toRef.get();

    if (!fromDoc.exists || !toDoc.exists) {
      throw Exception('One or both accounts do not exist');
    }

    final fromBalance =
        ((fromDoc.data() as Map<String, dynamic>)['balance'] as num).toDouble();
    final toBalance =
        ((toDoc.data() as Map<String, dynamic>)['balance'] as num).toDouble();

    // Decrease from account, increase to account
    batch.update(fromRef, {'balance': fromBalance - amount});
    batch.update(toRef, {'balance': toBalance + amount});

    await batch.commit();
  }

  // ============================================================
  // DEBT METHODS
  // ============================================================

  /// Returns a real-time stream of all debts for the user
  Stream<QuerySnapshot> getDebtsStream(String uid) {
    return _debtsRef(uid).snapshots();
  }

  /// Adds a new debt to Firestore
  Future<void> addDebt(String uid, Debt debt) async {
    await _debtsRef(uid).doc(debt.id).set(debt.toMap());
  }

  /// Updates an existing debt
  Future<void> updateDebt(String uid, Debt debt) async {
    await _debtsRef(uid).doc(debt.id).update(debt.toMap());
  }

  /// Deletes a debt and its payment history
  Future<void> deleteDebt(String uid, String debtId) async {
    // Delete all payments in subcollection first
    final paymentsSnapshot = await _debtPaymentsRef(uid, debtId).get();
    final batch = _firestore.batch();
    
    for (final doc in paymentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the debt document
    batch.delete(_debtsRef(uid).doc(debtId));
    
    await batch.commit();
  }

  /// Makes a payment on a debt
  /// - Deducts amount from linked account balance
  /// - Updates debt's remainingAmount
  /// - Adds payment to debt's payment history subcollection
  Future<void> makePayment(
      String uid, String debtId, double amount, String accountId) async {
    // Validate amount
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero');
    }

    // Get the debt
    final debtDoc = await _debtsRef(uid).doc(debtId).get();
    if (!debtDoc.exists) {
      throw Exception('Debt not found');
    }
    
    final debt = Debt.fromMap(debtDoc.data() as Map<String, dynamic>);
    
    // Check if debt is already paid
    if (debt.isPaid) {
      throw Exception('Debt is already paid');
    }

    // Get the account to check balance
    final accountDoc = await _accountsRef(uid).doc(accountId).get();
    if (!accountDoc.exists) {
      throw Exception('Account not found');
    }
    
    final accountBalance =
        ((accountDoc.data() as Map<String, dynamic>)['balance'] as num).toDouble();
    
    // Check for insufficient balance
    if (accountBalance < amount) {
      throw Exception('Insufficient balance in account');
    }

    // Validate payment doesn't exceed remaining amount
    if (amount > debt.remainingAmount) {
      throw Exception('Payment amount exceeds remaining debt');
    }

    final batch = _firestore.batch();

    // Deduct from account balance
    batch.update(_accountsRef(uid).doc(accountId), {
      'balance': accountBalance - amount,
    });

    // Update debt's remaining amount
    final newRemainingAmount = debt.remainingAmount - amount;
    final updates = <String, dynamic>{
      'remainingAmount': newRemainingAmount,
    };
    
    // Mark as paid if fully paid off
    if (newRemainingAmount <= 0) {
      updates['isPaid'] = true;
      updates['remainingAmount'] = 0;
    }
    
    batch.update(_debtsRef(uid).doc(debtId), updates);

    // Add payment to subcollection
    final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
    final paymentRef = _debtPaymentsRef(uid, debtId).doc(paymentId);
    batch.set(paymentRef, {
      'id': paymentId,
      'amount': amount,
      'accountId': accountId,
      'date': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  /// Marks a debt as fully paid
  Future<void> markDebtAsPaid(String uid, String debtId) async {
    // Get the debt to check if it exists and isn't already paid
    final debtDoc = await _debtsRef(uid).doc(debtId).get();
    if (!debtDoc.exists) {
      throw Exception('Debt not found');
    }
    
    final debt = Debt.fromMap(debtDoc.data() as Map<String, dynamic>);
    
    if (debt.isPaid) {
      throw Exception('Debt is already marked as paid');
    }

    await _debtsRef(uid).doc(debtId).update({
      'isPaid': true,
      'remainingAmount': 0,
    });
  }

  /// Marks a debt as received (for "owedToMe" debts)
  /// - Adds the remaining amount to the linked account
  /// - Sets isPaid = true
  Future<void> markDebtAsReceived(
      String uid, String debtId, String accountId) async {
    // Get the debt
    final debtDoc = await _debtsRef(uid).doc(debtId).get();
    if (!debtDoc.exists) {
      throw Exception('Debt not found');
    }
    
    final debt = Debt.fromMap(debtDoc.data() as Map<String, dynamic>);
    
    // Validate debt type
    if (debt.type != 'owedToMe') {
      throw Exception('Only "owedToMe" debts can be marked as received');
    }
    
    // Check if already paid
    if (debt.isPaid) {
      throw Exception('Debt is already marked as received');
    }

    // Get the account
    final accountDoc = await _accountsRef(uid).doc(accountId).get();
    if (!accountDoc.exists) {
      throw Exception('Account not found');
    }
    
    final accountBalance =
        ((accountDoc.data() as Map<String, dynamic>)['balance'] as num).toDouble();

    final batch = _firestore.batch();

    // Add remaining amount to account
    batch.update(_accountsRef(uid).doc(accountId), {
      'balance': accountBalance + debt.remainingAmount,
    });

    // Mark debt as paid
    batch.update(_debtsRef(uid).doc(debtId), {
      'isPaid': true,
      'remainingAmount': 0,
    });

    await batch.commit();
  }

  // ============================================================
  // INSIGHT DISMISSAL METHODS
  // ============================================================

  /// Dismisses an insight with its current data hash
  /// The insight won't reappear until the data hash changes
  Future<void> dismissInsight(String uid, String insightId, String dataHash) async {
    await _firestore.collection('users').doc(uid).set({
      'dismissedFinanceInsights': {
        insightId: {
          'hash': dataHash,
          'dismissedAt': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true));
  }

  /// Gets all dismissed insights for the user
  Future<Map<String, dynamic>> getDismissedInsights(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data();
    return (data?['dismissedFinanceInsights'] as Map<String, dynamic>?) ?? {};
  }

  /// Checks if an insight is currently dismissed
  /// Returns true only if the insight is dismissed AND the data hash matches
  bool isInsightDismissed(
    Map<String, dynamic> dismissedInsights,
    String insightId,
    String currentDataHash,
  ) {
    final dismissed = dismissedInsights[insightId] as Map<String, dynamic>?;
    if (dismissed == null) return false;
    return dismissed['hash'] == currentDataHash;
  }

  /// Clears all dismissed insights (e.g., on month change)
  Future<void> clearDismissedInsights(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'dismissedFinanceInsights': FieldValue.delete(),
    });
  }

  // ============================================================
  // STREAK TRACKING METHODS
  // ============================================================

  /// Gets the user's finance streaks data
  Future<Map<String, dynamic>> getFinanceStreaks(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {};
    final data = doc.data();
    return (data?['financeStreaks'] as Map<String, dynamic>?) ?? {};
  }

  /// Updates the under-budget streak counter
  /// Call this at the end of each month with the month's spending data
  Future<void> updateUnderBudgetStreak(
    String uid, {
    required double totalExpenses,
    required double monthlyBudget,
    required String monthKey, // e.g., "2024-03"
  }) async {
    if (monthlyBudget <= 0) return; // No budget set

    final streaks = await getFinanceStreaks(uid);
    final lastChecked = streaks['lastMonthChecked'] as String?;
    int currentStreak = (streaks['underBudgetStreak'] as int?) ?? 0;

    // Prevent double-counting the same month
    if (lastChecked == monthKey) return;

    if (totalExpenses < monthlyBudget) {
      currentStreak++;
    } else {
      currentStreak = 0; // Reset streak
    }

    await _firestore.collection('users').doc(uid).set({
      'financeStreaks': {
        'underBudgetStreak': currentStreak,
        'lastMonthChecked': monthKey,
      }
    }, SetOptions(merge: true));
  }

  /// Counts no-spend days in the current week (Mon-Sun)
  Future<int> getNoSpendDaysThisWeek(String uid) async {
    final now = DateTime.now();
    // Get start of week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDate = startOfWeekDate.add(const Duration(days: 7));

    // Get all transactions this week
    final snapshot = await _transactionsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeekDate))
        .get();

    // Group by date and check for expense transactions
    final Map<String, bool> daysWithExpenses = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'expense') {
        final timestamp = data['date'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month}-${date.day}';
          daysWithExpenses[dateKey] = true;
        }
      }
    }

    // Count days without expenses (up to today)
    int noSpendDays = 0;
    for (int i = 0; i < now.weekday; i++) {
      final checkDate = startOfWeekDate.add(Duration(days: i));
      final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (!daysWithExpenses.containsKey(dateKey)) {
        noSpendDays++;
      }
    }

    return noSpendDays;
  }

  /// Gets the under-budget streak count
  Future<int> getUnderBudgetStreak(String uid) async {
    final streaks = await getFinanceStreaks(uid);
    return (streaks['underBudgetStreak'] as int?) ?? 0;
  }
}
