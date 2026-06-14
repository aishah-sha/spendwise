import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID (non-nullable with validation)
  String get _currentUserId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return userId;
  }

  bool get isUserLoggedIn => _supabase.auth.currentUser != null;

  // Table names
  static const String profilesTable = 'profiles';
  static const String transactionsTable = 'transactions';
  static const String budgetsTable = 'budgets';
  static const String monthlyBudgetsTable = 'monthly_budgets';
  static const String notificationsTable = 'notifications';
  static const String receiptsTable = 'receipts';

  // ============ USER PROFILE METHODS ============

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      // Check if profile already exists
      final existingProfile = await _supabase
          .from(profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        print('ℹ️ Profile already exists for user: $userId');
        // Update only necessary fields if needed
        await _supabase
            .from(profilesTable)
            .update({
              'email': email,
              'full_name': name,
              'name': name,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
        print('✅ Updated existing profile for: $userId');
        return;
      }

      // Create new profile
      final now = DateTime.now().toIso8601String();
      await _supabase.from(profilesTable).insert({
        'id': userId,
        'email': email,
        'full_name': name,
        'name': name,
        'currency': 'RM',
        'is_dark_mode': false,
        'push_notifications_enabled': true,
        'biometric_enabled': false,
        'small_expenses_limit': 50.0,
        'profile_image_url': '',
        'total_spent': 0.0,
        'total_budget': 0.0,
        'created_at': now,
        'updated_at': now,
      });

      print('✅ User profile created successfully: $userId');
    } catch (e) {
      // Log but don't rethrow - profile creation shouldn't block signup
      print('⚠️ Note: User profile creation issue: $e');
      // The user can still log in; profile might be created by a trigger
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isUserLoggedIn) return null;

    try {
      final response = await _supabase
          .from(profilesTable)
          .select()
          .eq('id', _currentUserId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? name,
    String? currency,
    bool? isDarkMode,
    bool? pushNotificationsEnabled,
    bool? biometricEnabled,
    double? smallExpensesLimit,
    String? profileImageUrl,
  }) async {
    if (!isUserLoggedIn) return;

    try {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (name != null) updates['name'] = name;
      if (currency != null) updates['currency'] = currency;
      if (isDarkMode != null) updates['is_dark_mode'] = isDarkMode;
      if (pushNotificationsEnabled != null) {
        updates['push_notifications_enabled'] = pushNotificationsEnabled;
      }
      if (biometricEnabled != null) {
        updates['biometric_enabled'] = biometricEnabled;
      }
      if (smallExpensesLimit != null) {
        updates['small_expenses_limit'] = smallExpensesLimit;
      }
      if (profileImageUrl != null) {
        updates['profile_image_url'] = profileImageUrl;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from(profilesTable)
          .update(updates)
          .eq('id', _currentUserId);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateTotalSpent(double amount, {bool isAdding = true}) async {
    if (!isUserLoggedIn) return;

    try {
      final profile = await getUserProfile();
      final currentTotal = (profile?['total_spent'] ?? 0.0) as double;
      double newTotal;

      if (isAdding) {
        newTotal = currentTotal + amount;
      } else {
        newTotal = currentTotal - amount;
        if (newTotal < 0) newTotal = 0.0;
      }

      await _supabase
          .from(profilesTable)
          .update({'total_spent': newTotal})
          .eq('id', _currentUserId);
    } catch (e) {
      print('Error updating total spent: $e');
      rethrow;
    }
  }

  // ============ TRANSACTION METHODS ============

  Future<Map<String, dynamic>> addTransaction({
    required double amount,
    required String category,
    required String type,
    required String description,
    String? title,
    String? note,
    String? imageUrl,
    DateTime? date,
  }) async {
    if (!isUserLoggedIn) throw Exception('User not logged in');

    try {
      print('💾 Saving to Supabase:');
      print('   - description: $description');
      print('   - title: ${title ?? description}');
      print('   - amount: $amount');
      print('   - category: $category');

      final result = await _supabase
          .from(transactionsTable)
          .insert({
            'user_id': _currentUserId,
            'amount': amount,
            'category': category,
            'type': type,
            'description': description,
            'title': title ?? description,
            'note': note,
            'image_url': imageUrl ?? '',
            'date': (date ?? DateTime.now()).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('✅ Saved successfully with id: ${result['id']}');

      if (type == 'expense') {
        await updateTotalSpent(amount, isAdding: true);
      }

      return result;
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    if (!isUserLoggedIn) return [];

    final response = await _supabase
        .from(transactionsTable)
        .select()
        .eq('user_id', _currentUserId)
        .order('date', ascending: false);

    print('DEBUG fetchTransactions: Found ${response.length} transactions');
    for (var tx in response) {
      print('DEBUG TX: ${tx['description']} - ${tx['amount']} - ${tx['date']}');
    }

    return List<Map<String, dynamic>>.from(response);
  }

  // REAL-TIME stream (for _listenToExpenses)
  Stream<List<Map<String, dynamic>>> getTransactions() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ getTransactions: No user logged in');
      return Stream.value([]);
    }

    print('📡 Setting up real-time stream for user: $userId');

    return _supabase
        .from(transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .map((event) {
          print('📡 Stream update: ${event.length} transactions');
          return List<Map<String, dynamic>>.from(event);
        });
  }

  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    if (!isUserLoggedIn) return null;

    try {
      final response = await _supabase
          .from(transactionsTable)
          .select()
          .eq('id', transactionId)
          .eq('user_id', _currentUserId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    if (!isUserLoggedIn) return;

    try {
      // Get original transaction to adjust total_spent if needed
      final original = await getTransaction(transactionId);
      final originalAmount = (original?['amount'] ?? 0.0) as double;
      final originalType = original?['type'] as String? ?? '';

      final newAmount = (data['amount'] ?? originalAmount) as double;
      final newType = data['type'] ?? originalType;

      await _supabase
          .from(transactionsTable)
          .update(data)
          .eq('id', transactionId)
          .eq('user_id', _currentUserId);

      // Update total_spent if expense amounts or types changed
      if (originalType == 'expense' && newType == 'expense') {
        final amountDifference = newAmount - originalAmount;
        if (amountDifference != 0) {
          await updateTotalSpent(
            amountDifference.abs(),
            isAdding: amountDifference > 0,
          );
        }
      } else if (originalType == 'expense' && newType != 'expense') {
        // Was expense, now not expense - remove from total
        await updateTotalSpent(originalAmount, isAdding: false);
      } else if (originalType != 'expense' && newType == 'expense') {
        // Was not expense, now expense - add to total
        await updateTotalSpent(newAmount, isAdding: true);
      }
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (!isUserLoggedIn) return;

    try {
      final transaction = await getTransaction(transactionId);
      final amount = (transaction?['amount'] ?? 0.0) as double;
      final type = transaction?['type'] as String? ?? '';

      await _supabase
          .from(transactionsTable)
          .delete()
          .eq('id', transactionId)
          .eq('user_id', _currentUserId);

      if (type == 'expense') {
        await updateTotalSpent(amount, isAdding: false);
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<double> getMonthlySpending() async {
    if (!isUserLoggedIn) return 0.0;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await _supabase
          .from(transactionsTable)
          .select('amount')
          .eq('user_id', _currentUserId)
          .eq('type', 'expense')
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String());

      double total = 0;
      for (var transaction in response) {
        total += (transaction['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting monthly spending: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getSpendingByCategory() async {
    if (!isUserLoggedIn) return {};

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await _supabase
          .from(transactionsTable)
          .select('category, amount')
          .eq('user_id', _currentUserId)
          .eq('type', 'expense')
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String());

      Map<String, double> categoryTotals = {};
      for (var transaction in response) {
        final category = transaction['category'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
      return categoryTotals;
    } catch (e) {
      print('Error getting spending by category: $e');
      return {};
    }
  }

  // ============ BUDGET METHODS ============

  Future<void> setMonthlyBudget(double amount) async {
    if (!isUserLoggedIn) return;

    try {
      final existing = await _supabase
          .from(monthlyBudgetsTable)
          .select()
          .eq('user_id', _currentUserId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from(monthlyBudgetsTable)
            .update({
              'monthly_limit': amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _currentUserId);
      } else {
        await _supabase.from(monthlyBudgetsTable).insert({
          'user_id': _currentUserId,
          'monthly_limit': amount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Update total_budget in profile
      final currentProfile = await getUserProfile();
      final currentBudget = currentProfile?['total_budget'] ?? 0.0;
      await _supabase
          .from(profilesTable)
          .update({'total_budget': amount})
          .eq('id', _currentUserId);
    } catch (e) {
      print('Error setting monthly budget: $e');
      rethrow;
    }
  }

  Future<double> getMonthlyBudget() async {
    if (!isUserLoggedIn) return 0.0;

    try {
      final response = await _supabase
          .from(monthlyBudgetsTable)
          .select('monthly_limit')
          .eq('user_id', _currentUserId)
          .maybeSingle();

      return (response?['monthly_limit'] ?? 0.0) as double;
    } catch (e) {
      print('Error getting monthly budget: $e');
      return 0.0;
    }
  }

  Future<void> setCategoryBudget({
    required String category,
    required double amount,
    String? period,
  }) async {
    if (!isUserLoggedIn) return;

    try {
      final existingBudget = await _supabase
          .from(budgetsTable)
          .select()
          .eq('user_id', _currentUserId)
          .eq('category', category)
          .maybeSingle();

      if (existingBudget != null) {
        await _supabase
            .from(budgetsTable)
            .update({
              'amount': amount,
              'period': period ?? 'monthly',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingBudget['id']);
      } else {
        await _supabase.from(budgetsTable).insert({
          'user_id': _currentUserId,
          'category': category,
          'amount': amount,
          'period': period ?? 'monthly',
          'spent': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error setting category budget: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    if (!isUserLoggedIn) return [];

    try {
      final response = await _supabase
          .from(budgetsTable)
          .select()
          .eq('user_id', _currentUserId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting budgets: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCategoryBudget(String category) async {
    if (!isUserLoggedIn) return null;

    try {
      final response = await _supabase
          .from(budgetsTable)
          .select()
          .eq('user_id', _currentUserId)
          .eq('category', category)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting category budget: $e');
      return null;
    }
  }

  Future<void> updateCategorySpent(String category, double amount) async {
    if (!isUserLoggedIn) return;

    try {
      final budget = await getCategoryBudget(category);
      if (budget != null) {
        await _supabase
            .from(budgetsTable)
            .update({'spent': amount})
            .eq('id', budget['id']);
      }
    } catch (e) {
      print('Error updating budget spent: $e');
      rethrow;
    }
  }

  Future<void> deleteCategoryBudget(String category) async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(budgetsTable)
          .delete()
          .eq('user_id', _currentUserId)
          .eq('category', category);
    } catch (e) {
      print('Error deleting category budget: $e');
      rethrow;
    }
  }

  // ============ NOTIFICATION METHODS ============

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase.from(notificationsTable).insert({
        'user_id': _currentUserId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (!isUserLoggedIn) return [];

    try {
      final response = await _supabase
          .from(notificationsTable)
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(notificationsTable)
          .update({'is_read': true})
          .eq('user_id', _currentUserId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(notificationsTable)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(notificationsTable)
          .delete()
          .eq('user_id', _currentUserId);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // ============ RECEIPT METHODS ============

  Future<void> saveReceipt(ReceiptModel receipt) async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase.from(receiptsTable).insert({
        'user_id': _currentUserId,
        'receipt_type': receipt.receiptType,
        'merchant_name': receipt.merchantName,
        'amount': receipt.amount,
        'date': receipt.date.toIso8601String(),
        'image_path': receipt.imagePath,
        'items': receipt.items?.map((item) => item.toJson()).toList() ?? [],
        'tax': receipt.tax,
        'subtotal': receipt.subtotal,
        'service_charge': receipt.serviceCharge,
        'category': receipt.category,
        'currency': receipt.currency,
        'ocr_status': receipt.ocrStatus,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving receipt: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentReceipts({int limit = 20}) async {
    if (!isUserLoggedIn) return [];

    try {
      final response = await _supabase
          .from(receiptsTable)
          .select()
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting receipts: $e');
      return [];
    }
  }

  // ============ HELPER METHODS ============

  Future<void> deleteAllUserData() async {
    if (!isUserLoggedIn) return;

    try {
      await _supabase
          .from(transactionsTable)
          .delete()
          .eq('user_id', _currentUserId);
      await _supabase.from(budgetsTable).delete().eq('user_id', _currentUserId);
      await _supabase
          .from(monthlyBudgetsTable)
          .delete()
          .eq('user_id', _currentUserId);
      await _supabase
          .from(notificationsTable)
          .delete()
          .eq('user_id', _currentUserId);
      await _supabase
          .from(receiptsTable)
          .delete()
          .eq('user_id', _currentUserId);
      await _supabase.from(profilesTable).delete().eq('id', _currentUserId);
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
