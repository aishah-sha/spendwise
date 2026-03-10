import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import '../models/expense_model.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit() : super(ExpenseState.initial());

  // Existing methods (addExpense, addIncome, updateExpense, deleteExpense, etc.)
  void addExpense(ExpenseModel expense) {
    final updatedExpenses = List<ExpenseModel>.from(state.allExpenses)
      ..add(expense);

    final totalSpending = _calculateTotalSpending(updatedExpenses);
    final totalBalance = _calculateTotalBalance(updatedExpenses, state.budget);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
      totalBalance: totalBalance,
    );

    emit(_applyFilters(newState));
  }

  void addIncome(double amount) {
    if (amount <= 0) return;

    final income = ExpenseModel(
      id: DateTime.now().toString(),
      title: 'Income',
      amount: amount,
      category: 'Income',
      date: DateTime.now(),
      isIncome: true,
    );

    final updatedExpenses = List<ExpenseModel>.from(state.allExpenses)
      ..add(income);

    final totalSpending = _calculateTotalSpending(updatedExpenses);
    final totalBalance = _calculateTotalBalance(updatedExpenses, state.budget);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
      totalBalance: totalBalance,
    );

    emit(_applyFilters(newState));
  }

  void updateExpense(ExpenseModel updatedExpense) {
    final updatedExpenses = state.allExpenses.map((expense) {
      return expense.id == updatedExpense.id ? updatedExpense : expense;
    }).toList();

    final totalSpending = _calculateTotalSpending(updatedExpenses);
    final totalBalance = _calculateTotalBalance(updatedExpenses, state.budget);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
      totalBalance: totalBalance,
    );

    emit(_applyFilters(newState));
  }

  void deleteExpense(String id) {
    final updatedExpenses = state.allExpenses
        .where((expense) => expense.id != id)
        .toList();

    final totalSpending = _calculateTotalSpending(updatedExpenses);
    final totalBalance = _calculateTotalBalance(updatedExpenses, state.budget);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
      totalBalance: totalBalance,
    );

    emit(_applyFilters(newState));
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

  void setUserName(String name) {
    emit(state.copyWith(userName: name));
  }

  void updateTotalBalance(double newBalance) {
    emit(state.copyWith(totalBalance: newBalance));
  }

  // NEW ANALYTICS METHODS
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

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query) ||
            expense.amount.toString().contains(query);
      }).toList();
    }

    if (state.categoryFilter == ExpenseFilter.income) {
      filtered = filtered.where((e) => e.isIncome).toList();
    } else if (state.categoryFilter == ExpenseFilter.expense) {
      filtered = filtered.where((e) => !e.isIncome).toList();
    } else if (state.selectedCategory != null) {
      filtered = filtered
          .where((e) => e.category == state.selectedCategory)
          .toList();
    }

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
}
