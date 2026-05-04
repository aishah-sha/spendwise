import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import '../models/expense_model.dart';
import 'expense_state.dart';
import '../services/supabase_service.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription? _expensesSubscription;

  ExpenseCubit() : super(ExpenseState.initial()) {
    _listenToExpenses(); // Start listening to real-time updates
  }

  // Listen to real-time expense updates from Supabase
  void _listenToExpenses() {
    _expensesSubscription = _supabaseService.getTransactions().listen(
      (transactions) {
        // Convert Supabase transactions to ExpenseModel
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

        // Update state with new data
        final totalSpending = _calculateTotalSpending(expenses);
        final totalBalance = _calculateTotalBalance(expenses, state.budget);

        emit(
          _applyFilters(
            state.copyWith(
              allExpenses: expenses,
              totalSpending: totalSpending,
              totalBalance: totalBalance,
            ),
          ),
        );
      },
      onError: (error) {
        print('Error listening to expenses: $error');
      },
    );
  }

  // Load expenses from Supabase (initial load)
  Future<void> loadExpenses() async {
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

      final totalSpending = _calculateTotalSpending(expenses);
      final totalBalance = _calculateTotalBalance(expenses, state.budget);

      emit(
        _applyFilters(
          state.copyWith(
            allExpenses: expenses,
            totalSpending: totalSpending,
            totalBalance: totalBalance,
          ),
        ),
      );
    } catch (e) {
      print('Error loading expenses: $e');
    }
  }

  // Add expense to Supabase
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _supabaseService.addTransaction(
        amount: expense.amount,
        category: expense.category,
        type: expense.isIncome ? 'income' : 'expense',
        description: expense.title,
        date: expense.date,
      );
      // No need to manually update state - real-time stream will handle it
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  // Add income to Supabase
  Future<void> addIncome(double amount, {String? description}) async {
    if (amount <= 0) return;

    try {
      await _supabaseService.addTransaction(
        amount: amount,
        category: 'Income',
        type: 'income',
        description: description ?? 'Income',
        date: DateTime.now(),
      );
      // No need to manually update state - real-time stream will handle it
    } catch (e) {
      print('Error adding income: $e');
    }
  }

  // Update expense in Supabase
  Future<void> updateExpense(ExpenseModel updatedExpense) async {
    try {
      await _supabaseService.updateTransaction(updatedExpense.id, {
        'amount': updatedExpense.amount,
        'category': updatedExpense.category,
        'description': updatedExpense.title,
        'type': updatedExpense.isIncome ? 'income' : 'expense',
        'date': updatedExpense.date.toIso8601String(),
      });
      // No need to manually update state - real-time stream will handle it
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  // Delete expense from Supabase
  Future<void> deleteExpense(String id) async {
    try {
      await _supabaseService.deleteTransaction(id);
      // No need to manually update state - real-time stream will handle it
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  // Refresh analytics (trigger rebuild)
  void refreshAnalytics() {
    // Re-emit current state to trigger rebuild
    emit(state.copyWith());
  }

  // Search expenses (local filtering)
  void searchExpenses(String query) {
    final newState = state.copyWith(searchQuery: query);
    emit(_applyFilters(newState));
  }

  // Filter by category (local filtering)
  void filterByCategory(ExpenseFilter filter, {String? specificCategory}) {
    final newState = state.copyWith(
      categoryFilter: filter,
      selectedCategory: specificCategory,
    );
    emit(_applyFilters(newState));
  }

  // Filter by date range (local filtering)
  void filterByDateRange(
    DateRangeFilter range, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final newState = state.copyWith(
      dateRangeFilter: range,
      customStartDate: startDate,
      customEndDate: endDate,
    );
    emit(_applyFilters(newState));
  }

  // Reset all filters
  void resetFilters() {
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

  // Update budget locally (will be synced via ProfileCubit)
  void updateBudget(double newBudget) {
    final totalBalance = _calculateTotalBalance(state.allExpenses, newBudget);
    emit(state.copyWith(budget: newBudget, totalBalance: totalBalance));
  }

  // Set user name (local only - use ProfileCubit for persistence)
  void setUserName(String name) {
    emit(state.copyWith(userName: name));
  }

  // Update total balance
  void updateTotalBalance(double newBalance) {
    emit(state.copyWith(totalBalance: newBalance));
  }

  // Analytics period methods
  void changeAnalyticsPeriod(AnalyticsPeriod period) {
    emit(state.copyWith(selectedAnalyticsPeriod: period));
  }

  void setAnalyticsDate(DateTime date) {
    emit(state.copyWith(analyticsSelectedDate: date));
  }

  void previousPeriod() {
    final currentDate = state.analyticsSelectedDate;
    DateTime newDate;

    switch (state.selectedAnalyticsPeriod) {
      case AnalyticsPeriod.week:
        newDate = currentDate.subtract(const Duration(days: 7));
        break;
      case AnalyticsPeriod.month:
        newDate = DateTime(
          currentDate.year,
          currentDate.month - 1,
          currentDate.day,
        );
        break;
      case AnalyticsPeriod.year:
        newDate = DateTime(
          currentDate.year - 1,
          currentDate.month,
          currentDate.day,
        );
        break;
    }

    emit(state.copyWith(analyticsSelectedDate: newDate));
  }

  void nextPeriod() {
    final currentDate = state.analyticsSelectedDate;
    DateTime newDate;

    switch (state.selectedAnalyticsPeriod) {
      case AnalyticsPeriod.week:
        newDate = currentDate.add(const Duration(days: 7));
        break;
      case AnalyticsPeriod.month:
        newDate = DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
        break;
      case AnalyticsPeriod.year:
        newDate = DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
        break;
    }

    // Don't allow future dates
    if (newDate.isAfter(DateTime.now())) {
      return;
    }

    emit(state.copyWith(analyticsSelectedDate: newDate));
  }

  // Get category color mapping
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Colors.blue;
      case 'stationery':
        return Colors.purple;
      case 'clothes':
        return Colors.orange;
      case 'beverages':
        return Colors.green;
      case 'food':
        return Colors.red;
      case 'groceries':
        return Colors.blue;
      case 'supplies':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Get category icon
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Icons.home;
      case 'stationery':
        return Icons.edit;
      case 'clothes':
        return Icons.shopping_bag;
      case 'beverages':
        return Icons.local_drink;
      case 'food':
        return Icons.fastfood;
      case 'groceries':
        return Icons.shopping_cart;
      case 'supplies':
        return Icons.inventory;
      default:
        return Icons.more_horiz;
    }
  }

  // Get filtered expenses for the selected analytics period
  List<ExpenseModel> getFilteredExpensesForPeriod() {
    final now = DateTime.now();
    final selectedDate = state.analyticsSelectedDate;

    return state.allExpenses.where((expense) {
      switch (state.selectedAnalyticsPeriod) {
        case AnalyticsPeriod.week:
          final startOfWeek = selectedDate.subtract(
            Duration(days: selectedDate.weekday - 1),
          );
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return expense.date.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              expense.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        case AnalyticsPeriod.month:
          return expense.date.year == selectedDate.year &&
              expense.date.month == selectedDate.month;
        case AnalyticsPeriod.year:
          return expense.date.year == selectedDate.year;
      }
    }).toList();
  }

  // Private helper methods
  double _calculateTotalSpending(List<ExpenseModel> expenses) {
    return expenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double _calculateTotalBalance(List<ExpenseModel> expenses, double budget) {
    double balance = budget;
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

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query) ||
            expense.amount.toString().contains(query);
      }).toList();
    }

    // Apply category filter
    if (state.categoryFilter == ExpenseFilter.income) {
      filtered = filtered.where((e) => e.isIncome).toList();
    } else if (state.categoryFilter == ExpenseFilter.expense) {
      filtered = filtered.where((e) => !e.isIncome).toList();
    } else if (state.selectedCategory != null) {
      filtered = filtered
          .where((e) => e.category == state.selectedCategory)
          .toList();
    }

    // Apply date range filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (state.dateRangeFilter) {
      case DateRangeFilter.today:
        filtered = filtered.where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          return expenseDate == today;
        }).toList();
        break;
      case DateRangeFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        filtered = filtered.where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          return expenseDate == yesterday;
        }).toList();
        break;
      case DateRangeFilter.week:
        final weekAgo = today.subtract(const Duration(days: 7));
        filtered = filtered.where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          return expenseDate.isAfter(weekAgo) || expenseDate == weekAgo;
        }).toList();
        break;
      case DateRangeFilter.month:
        final monthAgo = today.subtract(const Duration(days: 30));
        filtered = filtered.where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          return expenseDate.isAfter(monthAgo) || expenseDate == monthAgo;
        }).toList();
        break;
      case DateRangeFilter.custom:
        if (state.customStartDate != null && state.customEndDate != null) {
          filtered = filtered.where((e) {
            return e.date.isAfter(state.customStartDate!) &&
                e.date.isBefore(
                  state.customEndDate!.add(const Duration(days: 1)),
                );
          }).toList();
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
