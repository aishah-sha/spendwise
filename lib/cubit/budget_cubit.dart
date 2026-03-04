import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/budget_model.dart';

// States
abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final Budget budget;
  final bool isSynced;

  const BudgetLoaded({required this.budget, this.isSynced = true});

  @override
  List<Object> get props => [budget, isSynced];
}

class BudgetSaved extends BudgetState {
  final String message;

  const BudgetSaved({required this.message});

  @override
  List<Object> get props => [message];
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit() : super(BudgetInitial());

  Budget? _cachedBudget;

  Future<void> loadBudget({bool forceRefresh = false}) async {
    // Don't reload if we already have data and not forcing refresh
    if (!forceRefresh && _cachedBudget != null) {
      emit(BudgetLoaded(budget: _cachedBudget!));
      return;
    }

    emit(BudgetLoading());

    try {
      // Simulate API/database fetch
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data - in real app, this would come from a database
      if (_cachedBudget == null) {
        // Create default empty budget if none exists
        final budget = Budget(
          monthlyLimit: 0,
          totalSpent: 0,
          categories: [
            BudgetCategory(name: 'Groceries', amount: 0, spent: 0),
            BudgetCategory(name: 'Food', amount: 0, spent: 0),
            BudgetCategory(name: 'Beverages', amount: 0, spent: 0),
            BudgetCategory(name: 'Clothes', amount: 0, spent: 0),
            BudgetCategory(name: 'Stationery', amount: 0, spent: 0),
            BudgetCategory(name: 'Entertainment', amount: 0, spent: 0),
            BudgetCategory(name: 'Transport', amount: 0, spent: 0),
            BudgetCategory(name: 'Shopping', amount: 0, spent: 0),
          ],
        );
        _cachedBudget = budget;
      }

      emit(BudgetLoaded(budget: _cachedBudget!));
    } catch (e) {
      emit(BudgetError(message: 'Failed to load budget: ${e.toString()}'));
    }
  }

  Future<void> saveBudget({
    required double monthlyLimit,
    required Map<String, double> categoryBudgets,
  }) async {
    emit(BudgetLoading());

    try {
      // Simulate API/database save
      await Future.delayed(const Duration(milliseconds: 500));

      // Create categories list
      final List<BudgetCategory> categories = [];

      // Add all possible categories with their amounts
      final allCategoryNames = [
        'Groceries',
        'Food',
        'Beverages',
        'Clothes',
        'Stationery',
        'Entertainment',
        'Transport',
        'Shopping',
      ];

      for (var name in allCategoryNames) {
        final amount = categoryBudgets[name] ?? 0;
        categories.add(
          BudgetCategory(
            name: name,
            amount: amount,
            spent: 0, // Reset spent when creating new budget
          ),
        );
      }

      // Create new budget
      final newBudget = Budget(
        monthlyLimit: monthlyLimit,
        totalSpent: 0,
        categories: categories,
      );

      _cachedBudget = newBudget;

      // First emit BudgetSaved for the snackbar
      emit(BudgetSaved(message: 'Budget saved successfully!'));

      // Small delay to ensure the saved state is processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Then emit BudgetLoaded with the new budget
      emit(BudgetLoaded(budget: newBudget));
    } catch (e) {
      emit(BudgetError(message: 'Failed to save budget: ${e.toString()}'));
    }
  }

  void updateCategorySpent(String categoryName, double spentAmount) {
    if (state is BudgetLoaded) {
      final currentState = state as BudgetLoaded;
      final currentBudget = currentState.budget;

      final updatedCategories = currentBudget.categories.map((category) {
        if (category.name == categoryName) {
          return BudgetCategory(
            name: category.name,
            amount: category.amount,
            spent: spentAmount,
          );
        }
        return category;
      }).toList();

      final totalSpent = updatedCategories.fold(
        0.0,
        (sum, category) => sum + category.spent,
      );

      final updatedBudget = Budget(
        monthlyLimit: currentBudget.monthlyLimit,
        totalSpent: totalSpent,
        categories: updatedCategories,
      );

      _cachedBudget = updatedBudget;
      emit(BudgetLoaded(budget: updatedBudget, isSynced: false));
    }
  }
}
