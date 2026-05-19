import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import '../models/expense_model.dart';
import 'expense_state.dart';
import '../services/supabase_service.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription? _expensesSubscription;
  final bool _isInitialized = false;

  ExpenseCubit() : super(ExpenseState.initial()) {
    _listenToExpenses();
  }

  void _listenToExpenses() {
    // Cancel existing subscription if any
    _expensesSubscription?.cancel();

    _expensesSubscription = _supabaseService.getTransactions().listen(
      (transactions) {
        final expenses = transactions.map((tx) {
          return ExpenseModel(
            id: tx['id'] as String,
            title: tx['description'] as String? ?? '',
            amount: (tx['amount'] as num).toDouble(),
            category: tx['category'] as String,
            date: DateTime.parse(tx['date'] as String),
            isIncome: (tx['type'] as String) == 'income',
            note: tx['description'] as String?,
          );
        }).toList();

        _updateStateWithExpenses(expenses);
      },
      onError: (error) {
        print('Error listening to expenses: $error');
        if (!isClosed) {
          emit(state.copyWith(error: error.toString(), isLoading: false));
        }
      },
    );
  }

  // Helper method to update state with expenses
  void _updateStateWithExpenses(List<ExpenseModel> expenses) {
    if (isClosed) return;

    final totalSpending = _calculateTotalSpending(expenses);
    final totalBalance = _calculateTotalBalance(expenses);

    final newState = _applyFilters(
      state.copyWith(
        allExpenses: expenses,
        filteredExpenses: expenses,
        totalSpending: totalSpending,
        totalBalance: totalBalance,
        isLoading: false,
        error: null,
      ),
    );

    if (!isClosed) {
      emit(newState);
    }
  }

  // Single loadExpenses method
  Future<void> loadExpenses() async {
    if (isClosed) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final transactions = await _supabaseService.getTransactions().first;
      final expenses = transactions.map((tx) {
        return ExpenseModel(
          id: tx['id'] as String,
          title: tx['description'] as String? ?? '',
          amount: (tx['amount'] as num).toDouble(),
          category: tx['category'] as String,
          date: DateTime.parse(tx['date'] as String),
          isIncome: (tx['type'] as String) == 'income',
          note: tx['description'] as String?,
        );
      }).toList();

      _updateStateWithExpenses(expenses);
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(error: e.toString(), isLoading: false));
      }
    }
  }

  void syncWithBudget(double newMonthlyLimit) {
    if (isClosed) return;
    emit(state.copyWith(budget: newMonthlyLimit));
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _supabaseService.addTransaction(
        amount: expense.amount,
        category: expense.category,
        type: expense.isIncome ? 'income' : 'expense',
        description: expense.title,
        date: expense.date,
      );
      // The stream subscription will automatically update the state
      // Force a refresh to ensure immediate update
      await loadExpenses();
    } catch (e) {
      print('Error adding expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> addIncome(double amount, {String? description}) async {
    if (amount <= 0) return;
    try {
      await _supabaseService.addTransaction(
        amount: amount,
        category: 'Income',
        type: 'income',
        description: description ?? 'Income Added',
        date: DateTime.now(),
      );
      await loadExpenses();
    } catch (e) {
      print('Error adding income: $e');
      if (!isClosed) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> updateExpense(ExpenseModel updatedExpense) async {
    try {
      await _supabaseService.updateTransaction(updatedExpense.id, {
        'amount': updatedExpense.amount,
        'category': updatedExpense.category,
        'description': updatedExpense.title,
        'type': updatedExpense.isIncome ? 'income' : 'expense',
        'date': updatedExpense.date.toIso8601String(),
      });
      // Force a refresh to ensure immediate update
      await loadExpenses();
    } catch (e) {
      print('Error updating expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabaseService.deleteTransaction(id);
      // Force a refresh to ensure immediate update
      await loadExpenses();
    } catch (e) {
      print('Error deleting expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  void searchExpenses(String query) {
    if (isClosed) return;
    final newState = state.copyWith(searchQuery: query);
    emit(_applyFilters(newState));
  }

  void filterByCategory(ExpenseFilter filter, {String? specificCategory}) {
    if (isClosed) return;
    final newState = state.copyWith(
      categoryFilter: filter,
      selectedCategory: specificCategory,
    );
    emit(_applyFilters(newState));
  }

  void filterByDateRange(
    DateRangeFilter range, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (isClosed) return;
    final newState = state.copyWith(
      dateRangeFilter: range,
      customStartDate: startDate,
      customEndDate: endDate,
    );
    emit(_applyFilters(newState));
  }

  void resetFilters() {
    if (isClosed) return;
    final newState = state.copyWith(
      searchQuery: '',
      categoryFilter: ExpenseFilter.all,
      dateRangeFilter: DateRangeFilter.all,
      selectedCategory: null,
      customStartDate: null,
      customEndDate: null,
      filteredExpenses: state.allExpenses,
    );
    emit(newState);
  }

  void updateBudget(double newBudget) {
    if (isClosed) return;
    final totalBalance = _calculateTotalBalance(state.allExpenses);
    emit(state.copyWith(budget: newBudget, totalBalance: totalBalance));
  }

  void changeAnalyticsPeriod(AnalyticsPeriod period) {
    if (isClosed) return;
    emit(state.copyWith(selectedAnalyticsPeriod: period));
  }

  void setAnalyticsDate(DateTime date) {
    if (isClosed) return;
    emit(state.copyWith(analyticsSelectedDate: date));
  }

  // Refresh method to manually trigger update
  Future<void> refreshExpenses() async {
    await loadExpenses();
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      // Food & Dining
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Snacks & Desserts':
        return Icons.icecream_outlined;

      // Shopping & Groceries
      case 'Groceries':
        return Icons.shopping_cart_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Clothes':
        return Icons.checkroom_outlined;

      // Home & Living
      case 'Household':
        return Icons.home_outlined;
      case 'Baking':
        return Icons.cake_outlined;
      case 'Cooking Ingredients':
        return Icons.kitchen_outlined;

      // Transportation
      case 'Transport':
        return Icons.directions_car_outlined;

      // Entertainment
      case 'Entertainment':
        return Icons.movie_outlined;

      // Health & Pets
      case 'Health':
        return Icons.favorite_outlined;
      case 'Pet Food':
        return Icons.pets_outlined;

      // Education & Office
      case 'Stationery':
        return Icons.edit_outlined;

      // Default
      case 'Others':
        return Icons.category_outlined;
      default:
        return Icons.label_outlined;
    }
  }

  Color getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Groceries':
        return const Color(0xFF4CAF50); // Green
      case 'Food':
        return const Color(0xFFFF9800); // Orange
      case 'Beverages':
        return const Color(0xFF2196F3); // Blue
      case 'Clothes':
        return const Color(0xFF9C27B0); // Purple
      case 'Stationery':
        return const Color(0xFF607D8B); // Blue Grey
      case 'Transport':
        return const Color(0xFF00BCD4); // Cyan
      case 'Entertainment':
        return const Color(0xFFE91E63); // Pink
      case 'Shopping':
        return const Color(0xFFFF5722); // Deep Orange
      case 'Household':
        return const Color(0xFF8BC34A); // Light Green
      case 'Pet Food':
        return const Color(0xFF795548); // Brown
      case 'Health':
        return const Color(0xFFF44336); // Red
      case 'Snacks & Desserts':
        return const Color(0xFFFF6B6B); // Light Red
      case 'Cooking Ingredients':
        return const Color(0xFFFFA726); // Orange Light
      case 'Baking':
        return const Color(0xFFFFB74D); // Amber
      case 'Others':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF32BA32); // Default Green
    }
  }

  double _calculateTotalSpending(List<ExpenseModel> expenses) {
    return expenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateTotalBalance(List<ExpenseModel> expenses) {
    double balance = 0.0;
    for (var expense in expenses) {
      if (expense.isIncome) {
        balance += expense.amount;
      } else {
        balance -= expense.amount;
      }
    }
    return balance;
  }

  ExpenseState _applyFilters(ExpenseState state) {
    var filtered = List<ExpenseModel>.from(state.allExpenses);

    // Apply category filter
    if (state.selectedCategory != null) {
      filtered = filtered
          .where((e) => e.category == state.selectedCategory)
          .toList();
    } else {
      switch (state.categoryFilter) {
        case ExpenseFilter.income:
          filtered = filtered.where((e) => e.isIncome).toList();
          break;
        case ExpenseFilter.expense:
          filtered = filtered.where((e) => !e.isIncome).toList();
          break;
        default:
          break;
      }
    }

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query);
      }).toList();
    }

    // Apply date range filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (state.dateRangeFilter) {
      case DateRangeFilter.today:
        filtered = filtered
            .where(
              (e) => DateTime(e.date.year, e.date.month, e.date.day) == today,
            )
            .toList();
        break;
      case DateRangeFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        filtered = filtered
            .where(
              (e) =>
                  DateTime(e.date.year, e.date.month, e.date.day) == yesterday,
            )
            .toList();
        break;
      case DateRangeFilter.week:
        final weekAgo = today.subtract(const Duration(days: 7));
        filtered = filtered.where((e) => e.date.isAfter(weekAgo)).toList();
        break;
      case DateRangeFilter.month:
        final monthAgo = today.subtract(const Duration(days: 30));
        filtered = filtered.where((e) => e.date.isAfter(monthAgo)).toList();
        break;
      case DateRangeFilter.custom:
        if (state.customStartDate != null) {
          filtered = filtered
              .where((e) => e.date.isAfter(state.customStartDate!))
              .toList();
        }
        if (state.customEndDate != null) {
          filtered = filtered
              .where((e) => e.date.isBefore(state.customEndDate!))
              .toList();
        }
        break;
      default:
        break;
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return state.copyWith(filteredExpenses: filtered);
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    return super.close();
  }
}
