import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Get reference to current user's transactions collection
  CollectionReference get _transactions => _firestore
      .collection('users')
      .doc(_currentUserId)
      .collection('transactions');

  // Get reference to current user's budgets collection
  CollectionReference get _budgets =>
      _firestore.collection('users').doc(_currentUserId).collection('budgets');

  // Get reference to current user's profile
  DocumentReference get _userProfile =>
      _firestore.collection('users').doc(_currentUserId);

  // ============ USER PROFILE METHODS ============

  // Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'createdAt': Timestamp.now(),
        'totalSpent': 0.0,
        'totalBudget': 0.0,
        'currency': 'RM',
        'theme': 'light',
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile() async {
    try {
      return await _userProfile.get();
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? currency,
    String? theme,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (currency != null) updates['currency'] = currency;
      if (theme != null) updates['theme'] = theme;

      await _userProfile.update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update total spent amount
  Future<void> updateTotalSpent(double amount) async {
    try {
      final doc = await _userProfile.get();
      final currentTotal = doc.data() as Map<String, dynamic>?;
      final newTotal = (currentTotal?['totalSpent'] ?? 0.0) + amount;
      await _userProfile.update({'totalSpent': newTotal});
    } catch (e) {
      print('Error updating total spent: $e');
      rethrow;
    }
  }

  // ============ TRANSACTION METHODS ============

  // Add transaction (expense/income)
  Future<void> addTransaction({
    required double amount,
    required String category,
    required String type, // 'expense' or 'income'
    required String description,
    String? imageUrl,
    DateTime? date,
  }) async {
    try {
      await _transactions.add({
        'amount': amount,
        'category': category,
        'description': description,
        'type': type,
        'imageUrl': imageUrl ?? '',
        'date': date != null ? Timestamp.fromDate(date) : Timestamp.now(),
        'createdAt': Timestamp.now(),
        'userId': _currentUserId,
      });

      // Update total spent if it's an expense
      if (type == 'expense') {
        await updateTotalSpent(amount);
      }
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Get all transactions (real-time stream)
  Stream<QuerySnapshot> getTransactions() {
    return _transactions.orderBy('date', descending: true).snapshots();
  }

  // Get transactions by type (expense or income)
  Stream<QuerySnapshot> getTransactionsByType(String type) {
    return _transactions
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get transactions by category
  Stream<QuerySnapshot> getTransactionsByCategory(String category) {
    return _transactions
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get transactions for a specific date range
  Stream<QuerySnapshot> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Get transactions for current month
  Stream<QuerySnapshot> getCurrentMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // Get transaction by ID
  Future<DocumentSnapshot> getTransaction(String docId) async {
    try {
      return await _transactions.doc(docId).get();
    } catch (e) {
      print('Error getting transaction: $e');
      rethrow;
    }
  }

  // Update transaction
  Future<void> updateTransaction(
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _transactions.doc(docId).update(data);
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String docId) async {
    try {
      final transaction = await _transactions.doc(docId).get();
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;

      await _transactions.doc(docId).delete();

      // Update total spent if deleting an expense
      if (type == 'expense') {
        final doc = await _userProfile.get();
        final currentTotal = doc.data() as Map<String, dynamic>?;
        final newTotal = (currentTotal?['totalSpent'] ?? 0.0) - amount;
        await _userProfile.update({
          'totalSpent': newTotal > 0 ? newTotal : 0.0,
        });
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Get total spending for current month
  Future<double> getMonthlySpending() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await _transactions
          .where('type', isEqualTo: 'expense')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting monthly spending: $e');
      return 0.0;
    }
  }

  // Get spending by category
  Future<Map<String, double>> getSpendingByCategory() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await _transactions
          .where('type', isEqualTo: 'expense')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      Map<String, double> categoryTotals = {};
      for (var doc in snapshot.docs) {
        final category = doc['category'] as String;
        final amount = (doc['amount'] as num).toDouble();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
      return categoryTotals;
    } catch (e) {
      print('Error getting spending by category: $e');
      return {};
    }
  }

  // ============ BUDGET METHODS ============

  // Add or update budget for a category
  Future<void> setBudget({
    required String category,
    required double amount,
    String? period, // 'monthly', 'weekly', 'yearly'
  }) async {
    try {
      final budgetDoc = _budgets.doc(category);
      final doc = await budgetDoc.get();

      if (doc.exists) {
        await budgetDoc.update({
          'amount': amount,
          'period': period ?? 'monthly',
          'updatedAt': Timestamp.now(),
        });
      } else {
        await budgetDoc.set({
          'category': category,
          'amount': amount,
          'period': period ?? 'monthly',
          'spent': 0.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error setting budget: $e');
      rethrow;
    }
  }

  // Get all budgets
  Stream<QuerySnapshot> getBudgets() {
    return _budgets.snapshots();
  }

  // Get budget for specific category
  Future<DocumentSnapshot> getBudget(String category) async {
    try {
      return await _budgets.doc(category).get();
    } catch (e) {
      print('Error getting budget: $e');
      rethrow;
    }
  }

  // Update spent amount for a category
  Future<void> updateBudgetSpent(String category, double amount) async {
    try {
      final budgetDoc = _budgets.doc(category);
      final doc = await budgetDoc.get();

      if (doc.exists) {
        final currentSpent = (doc['spent'] as num?)?.toDouble() ?? 0.0;
        await budgetDoc.update({'spent': currentSpent + amount});
      }
    } catch (e) {
      print('Error updating budget spent: $e');
      rethrow;
    }
  }

  // Delete budget
  Future<void> deleteBudget(String category) async {
    try {
      await _budgets.doc(category).delete();
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Get budget progress (spent vs total)
  Future<Map<String, double>> getBudgetProgress() async {
    try {
      final snapshot = await _budgets.get();
      final spendingByCategory = await getSpendingByCategory();

      Map<String, double> progress = {};
      for (var doc in snapshot.docs) {
        final category = doc['category'] as String;
        final budgetAmount = (doc['amount'] as num).toDouble();
        final spent = spendingByCategory[category] ?? 0.0;
        progress[category] =
            spent / budgetAmount; // Returns percentage (0.0 to 1.0+)
      }
      return progress;
    } catch (e) {
      print('Error getting budget progress: $e');
      return {};
    }
  }

  // ============ HELPER METHODS ============

  // Delete all user data (for account deletion)
  Future<void> deleteAllUserData() async {
    try {
      // Delete all transactions
      final transactionsSnapshot = await _transactions.get();
      for (var doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all budgets
      final budgetsSnapshot = await _budgets.get();
      for (var doc in budgetsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user profile
      await _userProfile.delete();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
