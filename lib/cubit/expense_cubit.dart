import 'package:bloc/bloc.dart';
import '../models/expense_model.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit() : super(ExpenseState.initial());

  // Add new expense
  void addExpense(ExpenseModel expense) {
    final updatedExpenses = List<ExpenseModel>.from(state.allExpenses)
      ..add(expense);

    final totalSpending = _calculateTotalSpending(updatedExpenses);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
    );

    // Apply current filters to update filtered expenses
    emit(_applyFilters(newState));
  }

  // Update existing expense
  void updateExpense(ExpenseModel updatedExpense) {
    final updatedExpenses = state.allExpenses.map((expense) {
      return expense.id == updatedExpense.id ? updatedExpense : expense;
    }).toList();

    final totalSpending = _calculateTotalSpending(updatedExpenses);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
    );

    emit(_applyFilters(newState));
  }

  // Delete expense
  void deleteExpense(String id) {
    final updatedExpenses = state.allExpenses
        .where((expense) => expense.id != id)
        .toList();

    final totalSpending = _calculateTotalSpending(updatedExpenses);

    final newState = state.copyWith(
      allExpenses: updatedExpenses,
      totalSpending: totalSpending,
    );

    emit(_applyFilters(newState));
  }

  // Search expenses
  void searchExpenses(String query) {
    final newState = state.copyWith(searchQuery: query);
    emit(_applyFilters(newState));
  }

  // Filter by category
  void filterByCategory(ExpenseFilter filter, {String? specificCategory}) {
    final newState = state.copyWith(
      categoryFilter: filter,
      selectedCategory: specificCategory,
    );
    emit(_applyFilters(newState));
  }

  // Filter by date range
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

  // Update budget
  void updateBudget(double newBudget) {
    emit(state.copyWith(budget: newBudget));
  }

  // Set user name
  void setUserName(String name) {
    emit(state.copyWith(userName: name));
  }

  // Update total balance
  void updateTotalBalance(double newBalance) {
    emit(state.copyWith(totalBalance: newBalance));
  }

  // Private helper methods
  double _calculateTotalSpending(List<ExpenseModel> expenses) {
    return expenses
        .fold(
          0.0,
          (sum, item) => item.isIncome ? sum - item.amount : sum + item.amount,
        )
        .abs();
  }

  ExpenseState _applyFilters(ExpenseState state) {
    // Start with all expenses
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

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return state.copyWith(filteredExpenses: filtered);
  }
}
