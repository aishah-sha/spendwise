import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_model.dart';

class BudgetStorageService {
  // Get user-specific key
  String _getUserBudgetKey() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return 'saved_budget_$userId';
  }

  // Save budget to SharedPreferences (user-specific)
  Future<void> saveBudget(Budget budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetKey = _getUserBudgetKey();

      // Convert budget to JSON
      final budgetJson = {
        'monthlyLimit': budget.monthlyLimit,
        'totalSpent': budget.totalSpent,
        'categories': budget.categories
            .map(
              (category) => {
                'name': category.name,
                'amount': category.amount,
                'spent': category.spent,
              },
            )
            .toList(),
        // NEW: Date range fields
        'startDate': budget.startDate?.toIso8601String(),
        'endDate': budget.endDate?.toIso8601String(),
        'budgetPeriodLabel': budget.budgetPeriodLabel,
      };

      final budgetString = jsonEncode(budgetJson);
      await prefs.setString(budgetKey, budgetString);
      print('Budget saved successfully for user');
      print('  Period: ${budget.budgetPeriodLabel ?? "No date range"}');
    } catch (e) {
      print('Error saving budget: $e');
      rethrow;
    }
  }

  // Load budget from SharedPreferences (user-specific)
  Future<Budget?> loadBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetKey = _getUserBudgetKey();
      final budgetString = prefs.getString(budgetKey);

      if (budgetString == null) {
        print('No saved budget found for this user');
        return null;
      }

      final budgetJson = jsonDecode(budgetString);

      // Parse categories
      final categoriesJson = budgetJson['categories'] as List;
      final categories = categoriesJson.map((catJson) {
        return BudgetCategory(
          name: catJson['name'],
          amount: (catJson['amount'] as num).toDouble(),
          spent: (catJson['spent'] as num).toDouble(),
        );
      }).toList();

      // NEW: Parse date range
      DateTime? startDate;
      DateTime? endDate;
      if (budgetJson['startDate'] != null) {
        startDate = DateTime.parse(budgetJson['startDate'] as String);
      }
      if (budgetJson['endDate'] != null) {
        endDate = DateTime.parse(budgetJson['endDate'] as String);
      }

      final budget = Budget(
        monthlyLimit: (budgetJson['monthlyLimit'] as num).toDouble(),
        totalSpent: (budgetJson['totalSpent'] as num).toDouble(),
        categories: categories,
        startDate: startDate,
        endDate: endDate,
        budgetPeriodLabel: budgetJson['budgetPeriodLabel'] as String?,
      );

      print('Budget loaded successfully for user: RM${budget.monthlyLimit}');
      print('  Period: ${budget.budgetPeriodLabel ?? "No date range"}');
      return budget;
    } catch (e) {
      print('Error loading budget: $e');
      return null;
    }
  }

  // Clear saved budget for current user
  Future<void> clearBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetKey = _getUserBudgetKey();
      await prefs.remove(budgetKey);
      print('Budget cleared for current user');
    } catch (e) {
      print('Error clearing budget: $e');
    }
  }

  // Clear ALL budget data for all users (for debugging)
  Future<void> clearAllBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('saved_budget_')) {
          await prefs.remove(key);
        }
      }
      print('All budget data cleared');
    } catch (e) {
      print('Error clearing all budgets: $e');
    }
  }
}
