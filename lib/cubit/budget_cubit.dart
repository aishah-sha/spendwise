import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/budget_model.dart';
import '../services/budget_storage_service.dart';

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
  final BudgetStorageService _storageService = BudgetStorageService();

  BudgetCubit() : super(BudgetInitial()) {
    _loadSavedBudget();
  }

  Future<void> _loadSavedBudget() async {
    emit(BudgetLoading());
    try {
      final savedBudget = await _storageService.loadBudget();
      if (savedBudget != null) {
        emit(BudgetLoaded(budget: savedBudget));
      } else {
        // Create default empty budget if none exists
        final defaultBudget = Budget(
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
            BudgetCategory(name: 'Other', amount: 0, spent: 0),
          ],
        );
        emit(BudgetLoaded(budget: defaultBudget));
      }
    } catch (e) {
      emit(BudgetError(message: 'Failed to load budget: ${e.toString()}'));
    }
  }

  Future<void> loadBudget({bool forceRefresh = false}) async {
    if (!forceRefresh && state is BudgetLoaded) {
      return;
    }

    emit(BudgetLoading());

    try {
      final savedBudget = await _storageService.loadBudget();
      if (savedBudget != null) {
        emit(BudgetLoaded(budget: savedBudget));
      } else {
        // Create default empty budget if none exists
        final defaultBudget = Budget(
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
            BudgetCategory(name: 'Other', amount: 0, spent: 0),
          ],
        );
        emit(BudgetLoaded(budget: defaultBudget));
      }
    } catch (e) {
      emit(BudgetError(message: 'Failed to load budget: ${e.toString()}'));
    }
  }

  // Updated saveBudget method with isAdditional parameter
  Future<void> saveBudget({
    required double monthlyLimit,
    required Map<String, double> categoryBudgets,
    bool isAdditional = false, // Add this parameter
  }) async {
    emit(BudgetLoading());

    try {
      // Get current budget if it exists
      Budget? currentBudget;
      if (state is BudgetLoaded) {
        currentBudget = (state as BudgetLoaded).budget;
      } else {
        currentBudget = await _storageService.loadBudget();
      }

      // If this is additional budget and we have existing budget, add to it
      if (isAdditional && currentBudget != null) {
        // Add to monthly limit
        final newMonthlyLimit = currentBudget.monthlyLimit + monthlyLimit;

        // Update categories
        final List<BudgetCategory> updatedCategories = [];

        // First, add all existing categories with their spent amounts preserved
        for (var existingCategory in currentBudget.categories) {
          final additionalAmount = categoryBudgets[existingCategory.name] ?? 0;
          updatedCategories.add(
            BudgetCategory(
              name: existingCategory.name,
              amount: existingCategory.amount + additionalAmount,
              spent: existingCategory.spent, // Preserve spent amount
            ),
          );
        }

        // Add any new categories that might not exist in current budget
        for (var entry in categoryBudgets.entries) {
          final exists = updatedCategories.any((c) => c.name == entry.key);
          if (!exists) {
            updatedCategories.add(
              BudgetCategory(name: entry.key, amount: entry.value, spent: 0),
            );
          }
        }

        // Calculate total spent
        final totalSpent = updatedCategories.fold(
          0.0,
          (sum, category) => sum + category.spent,
        );

        final newBudget = Budget(
          monthlyLimit: newMonthlyLimit,
          totalSpent: totalSpent,
          categories: updatedCategories,
        );

        // Save to storage
        await _storageService.saveBudget(newBudget);

        emit(BudgetSaved(message: 'Budget updated successfully!'));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BudgetLoaded(budget: newBudget));
      } else {
        // This is a new budget (replace existing)
        final List<BudgetCategory> categories = [];

        // Add all categories
        final allCategoryNames = [
          'Groceries',
          'Food',
          'Beverages',
          'Clothes',
          'Stationery',
          'Entertainment',
          'Transport',
          'Shopping',
          'Other',
        ];

        for (var name in allCategoryNames) {
          final amount = categoryBudgets[name] ?? 0;
          // If we have existing budget with spent amounts, preserve them
          double spent = 0;
          if (currentBudget != null) {
            final existingCat = currentBudget.categories.firstWhere(
              (c) => c.name == name,
              orElse: () => BudgetCategory(name: name, amount: 0, spent: 0),
            );
            spent = existingCat.spent;
          }
          categories.add(
            BudgetCategory(name: name, amount: amount, spent: spent),
          );
        }

        final totalSpent = categories.fold(
          0.0,
          (sum, category) => sum + category.spent,
        );

        final newBudget = Budget(
          monthlyLimit: monthlyLimit,
          totalSpent: totalSpent,
          categories: categories,
        );

        await _storageService.saveBudget(newBudget);
        emit(BudgetSaved(message: 'Budget saved successfully!'));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BudgetLoaded(budget: newBudget));
      }
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

      // Save to storage
      _storageService.saveBudget(updatedBudget);

      emit(BudgetLoaded(budget: updatedBudget, isSynced: false));
    }
  }

  // New method to add additional budget
  Future<void> addToBudget({
    required double additionalAmount,
    Map<String, double>? additionalCategoryBudgets,
  }) async {
    if (state is BudgetLoaded) {
      final currentState = state as BudgetLoaded;
      final currentBudget = currentState.budget;

      await saveBudget(
        monthlyLimit: additionalAmount,
        categoryBudgets: additionalCategoryBudgets ?? {},
        isAdditional: true,
      );
    }
  }

  // Reset budget method
  Future<void> resetBudget() async {
    await _storageService.clearBudget();
    await loadBudget(forceRefresh: true);
  }
}
