import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';

class BudgetStorageService {
  static const String _budgetKey = 'saved_budget';

  // Save budget to SharedPreferences
  Future<void> saveBudget(Budget budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();

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
      };

      final budgetString = jsonEncode(budgetJson);
      await prefs.setString(_budgetKey, budgetString);
      print('Budget saved successfully');
    } catch (e) {
      print('Error saving budget: $e');
      rethrow;
    }
  }

  // Load budget from SharedPreferences
  Future<Budget?> loadBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetString = prefs.getString(_budgetKey);

      if (budgetString == null) {
        print('No saved budget found');
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

      final budget = Budget(
        monthlyLimit: (budgetJson['monthlyLimit'] as num).toDouble(),
        totalSpent: (budgetJson['totalSpent'] as num).toDouble(),
        categories: categories,
      );

      print('Budget loaded successfully: RM${budget.monthlyLimit}');
      return budget;
    } catch (e) {
      print('Error loading budget: $e');
      return null;
    }
  }

  // Clear saved budget
  Future<void> clearBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_budgetKey);
      print('Budget cleared');
    } catch (e) {
      print('Error clearing budget: $e');
    }
  }
}
