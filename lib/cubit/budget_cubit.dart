import 'dart:async'; // Add this import for StreamSubscription
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  StreamSubscription? _authSubscription;

  BudgetCubit() : super(BudgetInitial()) {
    _listenToAuthChanges();
  }

  // Listen to auth changes to clear/load user-specific data
  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (!isClosed) {
        final session = data.session;
        if (session != null) {
          // User logged in - load their budget
          print('User logged in, loading their budget...');
          loadBudget(forceRefresh: true);
        } else {
          // User logged out - clear state
          print('User logged out, clearing budget...');
          final emptyBudget = Budget(
            monthlyLimit: 0,
            totalSpent: 0,
            categories: [],
          );
          emit(BudgetLoaded(budget: emptyBudget));
        }
      }
    });
  }

  Future<void> loadBudget({bool forceRefresh = false}) async {
    if (!forceRefresh && state is BudgetLoaded) {
      return;
    }

    emit(BudgetLoading());

    try {
      final savedBudget = await _storageService.loadBudget();
      if (savedBudget != null && savedBudget.monthlyLimit > 0) {
        emit(BudgetLoaded(budget: savedBudget));
      } else {
        final emptyBudget = Budget(
          monthlyLimit: 0,
          totalSpent: 0,
          categories: [],
        );
        emit(BudgetLoaded(budget: emptyBudget));
      }
    } catch (e) {
      // If user not logged in, just show empty budget
      final emptyBudget = Budget(
        monthlyLimit: 0,
        totalSpent: 0,
        categories: [],
      );
      emit(BudgetLoaded(budget: emptyBudget));
    }
  }

  Future<void> saveBudget({
    required double monthlyLimit,
    required Map<String, double> categoryBudgets,
    bool isAdditional = false,
  }) async {
    emit(BudgetLoading());

    try {
      Budget? currentBudget;
      if (state is BudgetLoaded) {
        currentBudget = (state as BudgetLoaded).budget;
      } else {
        currentBudget = await _storageService.loadBudget();
      }

      if (isAdditional &&
          currentBudget != null &&
          currentBudget.monthlyLimit > 0) {
        final newMonthlyLimit = currentBudget.monthlyLimit + monthlyLimit;
        final List<BudgetCategory> updatedCategories = [];

        for (var existingCategory in currentBudget.categories) {
          final additionalAmount = categoryBudgets[existingCategory.name] ?? 0;
          updatedCategories.add(
            BudgetCategory(
              name: existingCategory.name,
              amount: existingCategory.amount + additionalAmount,
              spent: existingCategory.spent,
            ),
          );
        }

        for (var entry in categoryBudgets.entries) {
          if (entry.value > 0) {
            final exists = updatedCategories.any((c) => c.name == entry.key);
            if (!exists) {
              updatedCategories.add(
                BudgetCategory(name: entry.key, amount: entry.value, spent: 0),
              );
            }
          }
        }

        final totalSpent = updatedCategories.fold(
          0.0,
          (sum, category) => sum + category.spent,
        );

        final newBudget = Budget(
          monthlyLimit: newMonthlyLimit,
          totalSpent: totalSpent,
          categories: updatedCategories,
        );

        await _storageService.saveBudget(newBudget);
        emit(BudgetSaved(message: 'Budget updated successfully!'));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(BudgetLoaded(budget: newBudget));
      } else {
        final List<BudgetCategory> categories = [];

        for (var entry in categoryBudgets.entries) {
          if (entry.value > 0) {
            double spent = 0;
            if (currentBudget != null && currentBudget.monthlyLimit > 0) {
              final existingCat = currentBudget.categories.firstWhere(
                (c) => c.name == entry.key,
                orElse: () =>
                    BudgetCategory(name: entry.key, amount: 0, spent: 0),
              );
              spent = existingCat.spent;
            }
            categories.add(
              BudgetCategory(
                name: entry.key,
                amount: entry.value,
                spent: spent,
              ),
            );
          }
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

      _storageService.saveBudget(updatedBudget);
      emit(BudgetLoaded(budget: updatedBudget, isSynced: false));
    }
  }

  Future<void> addToBudget({
    required double additionalAmount,
    Map<String, double>? additionalCategoryBudgets,
  }) async {
    if (state is BudgetLoaded) {
      await saveBudget(
        monthlyLimit: additionalAmount,
        categoryBudgets: additionalCategoryBudgets ?? {},
        isAdditional: true,
      );
    }
  }

  Future<void> resetBudget() async {
    await _storageService.clearBudget();
    final emptyBudget = Budget(monthlyLimit: 0, totalSpent: 0, categories: []);
    emit(BudgetLoaded(budget: emptyBudget));
  }

  Future<void> forceClearAllBudgetData() async {
    try {
      await _storageService.clearBudget();
      final emptyBudget = Budget(
        monthlyLimit: 0,
        totalSpent: 0,
        categories: [],
      );
      emit(BudgetLoaded(budget: emptyBudget));
      print('All budget data has been cleared for current user');
    } catch (e) {
      print('Error clearing budget data: $e');
    }
  }

  Future<void> refreshBudget() async {
    await loadBudget(forceRefresh: true);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
