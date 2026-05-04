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
    _listenToExpenses();
  }

  // FIX: Real-time update logic includes recalculated balance based on current state budget
  void _listenToExpenses() {
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

  // FIX: Added a sync method for when BudgetCubit changes
  void syncWithBudget(double newMonthlyLimit) {
    final totalBalance = _calculateTotalBalance(
      state.allExpenses,
      newMonthlyLimit,
    );
    emit(state.copyWith(budget: newMonthlyLimit, totalBalance: totalBalance));
  }

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

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _supabaseService.addTransaction(
        amount: expense.amount,
        category: expense.category,
        type: expense.isIncome ? 'income' : 'expense',
        description: expense.title,
        date: expense.date,
      );
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

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
    } catch (e) {
      print('Error adding income: $e');
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
    } catch (e) {
      print('Error updating expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabaseService.deleteTransaction(id);
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  void searchExpenses(String query) {
    final newState = state.copyWith(searchQuery: query);
    emit(_applyFilters(newState));
  }

  void filterByCategory(ExpenseFilter filter, {String? specificCategory}) {
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
    final newState = state.copyWith(
      dateRangeFilter: range,
      customStartDate: startDate,
      customEndDate: endDate,
    );
    emit(_applyFilters(newState));
  }

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

  void updateBudget(double newBudget) {
    final totalBalance = _calculateTotalBalance(state.allExpenses, newBudget);
    emit(state.copyWith(budget: newBudget, totalBalance: totalBalance));
  }

  void changeAnalyticsPeriod(AnalyticsPeriod period) {
    emit(state.copyWith(selectedAnalyticsPeriod: period));
  }

  void setAnalyticsDate(DateTime date) {
    emit(state.copyWith(analyticsSelectedDate: date));
  }

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

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query);
      }).toList();
    }

    if (state.categoryFilter == ExpenseFilter.income) {
      filtered = filtered.where((e) => e.isIncome).toList();
    } else if (state.categoryFilter == ExpenseFilter.expense) {
      filtered = filtered.where((e) => !e.isIncome).toList();
    }

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
      case DateRangeFilter.week:
        final weekAgo = today.subtract(const Duration(days: 7));
        filtered = filtered.where((e) => e.date.isAfter(weekAgo)).toList();
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
