import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';

enum ExpenseFilter { all, income, expense }

enum DateRangeFilter { all, today, yesterday, week, month, custom }

enum AnalyticsPeriod { week, month, year }

class ExpenseState extends Equatable {
  final String userName;
  final DateTime currentDate;
  final double totalBalance;
  final double totalSpending;
  final double budget;
  final List<ExpenseModel> allExpenses; // All expenses
  final List<ExpenseModel> filteredExpenses; // Filtered expenses for display
  final String searchQuery;
  final ExpenseFilter categoryFilter;
  final DateRangeFilter dateRangeFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? selectedCategory;

  // Analytics properties
  final AnalyticsPeriod selectedAnalyticsPeriod;
  final DateTime analyticsSelectedDate;

  const ExpenseState({
    required this.userName,
    required this.currentDate,
    required this.totalBalance,
    required this.totalSpending,
    required this.budget,
    required this.allExpenses,
    required this.filteredExpenses,
    this.searchQuery = '',
    this.categoryFilter = ExpenseFilter.all,
    this.dateRangeFilter = DateRangeFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.selectedCategory,
    this.selectedAnalyticsPeriod = AnalyticsPeriod.month,
    required this.analyticsSelectedDate,
  });

  factory ExpenseState.initial() {
    final now = DateTime.now();

    return ExpenseState(
      userName: 'John',
      currentDate: now,
      totalBalance: 0.0, // Start with 0, will be updated when user adds money
      totalSpending: 0.0, // Start with 0, will be calculated from expenses
      budget: 0.0, // Start with 0, will be updated when user sets budget
      allExpenses: [], // Start empty, will be filled when user adds expenses
      filteredExpenses:
          [], // Start empty, will be filled when user adds expenses
      analyticsSelectedDate: now,
    );
  }

  // Computed properties for analytics - all based on actual expenses
  double get totalSpent {
    return getExpensesForAnalytics().fold(0.0, (sum, expense) {
      return expense.isIncome ? sum : sum + expense.amount;
    });
  }

  double get lastMonthTotal {
    // Calculate based on actual expenses from last month
    final now = analyticsSelectedDate;
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    return allExpenses.fold(0.0, (sum, expense) {
      if (!expense.isIncome &&
          expense.date.isAfter(lastMonthStart) &&
          expense.date.isBefore(lastMonthEnd)) {
        return sum + expense.amount;
      }
      return sum;
    });
  }

  double get percentageChange {
    if (lastMonthTotal == 0) return 0;
    return ((totalSpent - lastMonthTotal) / lastMonthTotal) * 100;
  }

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    final analyticsExpenses = getExpensesForAnalytics();

    for (var expense in analyticsExpenses.where((e) => !e.isIncome)) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<MapEntry<String, double>> get sortedCategoryTotals {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<DateTime, double> get dailyTotals {
    final Map<DateTime, double> totals = {};
    final analyticsExpenses = getExpensesForAnalytics();

    for (var expense in analyticsExpenses.where((e) => !e.isIncome)) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      totals[day] = (totals[day] ?? 0) + expense.amount;
    }
    return totals;
  }

  List<ExpenseModel> get smallExpenses {
    return getExpensesForAnalytics()
        .where((e) => !e.isIncome && e.amount < 10)
        .toList();
  }

  double get groceriesTotal {
    return getExpensesForAnalytics()
        .where((e) => !e.isIncome && e.category.toLowerCase() == 'groceries')
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Helper method to get expenses based on selected analytics period
  List<ExpenseModel> getExpensesForAnalytics() {
    final now = analyticsSelectedDate;

    switch (selectedAnalyticsPeriod) {
      case AnalyticsPeriod.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return allExpenses.where((e) => e.date.isAfter(weekAgo)).toList();
      case AnalyticsPeriod.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        return allExpenses.where((e) => e.date.isAfter(monthAgo)).toList();
      case AnalyticsPeriod.year:
        final yearAgo = now.subtract(const Duration(days: 365));
        return allExpenses.where((e) => e.date.isAfter(yearAgo)).toList();
    }
  }

  // Group expenses by date for history view
  Map<String, List<ExpenseModel>> get groupedByDate {
    final grouped = <String, List<ExpenseModel>>{};

    for (var expense in filteredExpenses) {
      final dateKey = _getDateKey(expense.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedGrouped = <String, List<ExpenseModel>>{};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) return 'TODAY';
    if (expenseDate == yesterday) return 'YESTERDAY';
    if (expenseDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'THIS WEEK';
    }
    return '${_getMonthAbbreviation(expenseDate.month)} ${expenseDate.year}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  // Computed properties based on actual data
  double get remaining => budget - totalSpending;
  double get budgetProgress => budget > 0 ? totalSpending / budget : 0;
  int get totalExpensesCount => filteredExpenses.length;

  double get totalAmount {
    return filteredExpenses.fold(0.0, (sum, expense) {
      return expense.isIncome ? sum + expense.amount : sum - expense.amount;
    });
  }

  // Update totalSpending based on all expenses
  double calculateTotalSpending() {
    return allExpenses.fold(0.0, (sum, expense) {
      return expense.isIncome ? sum : sum + expense.amount;
    });
  }

  // Update totalBalance based on income and expenses
  double calculateTotalBalance() {
    double balance = 0.0;
    for (var expense in allExpenses) {
      if (expense.isIncome) {
        balance += expense.amount;
      } else {
        balance -= expense.amount;
      }
    }
    return balance;
  }

  ExpenseState copyWith({
    String? userName,
    DateTime? currentDate,
    double? totalBalance,
    double? totalSpending,
    double? budget,
    List<ExpenseModel>? allExpenses,
    List<ExpenseModel>? filteredExpenses,
    String? searchQuery,
    ExpenseFilter? categoryFilter,
    DateRangeFilter? dateRangeFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? selectedCategory,
    AnalyticsPeriod? selectedAnalyticsPeriod,
    DateTime? analyticsSelectedDate,
  }) {
    return ExpenseState(
      userName: userName ?? this.userName,
      currentDate: currentDate ?? this.currentDate,
      totalBalance: totalBalance ?? this.totalBalance,
      totalSpending: totalSpending ?? this.totalSpending,
      budget: budget ?? this.budget,
      allExpenses: allExpenses ?? this.allExpenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      dateRangeFilter: dateRangeFilter ?? this.dateRangeFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedAnalyticsPeriod:
          selectedAnalyticsPeriod ?? this.selectedAnalyticsPeriod,
      analyticsSelectedDate:
          analyticsSelectedDate ?? this.analyticsSelectedDate,
    );
  }

  @override
  List<Object?> get props => [
    userName,
    currentDate,
    totalBalance,
    totalSpending,
    budget,
    allExpenses,
    filteredExpenses,
    searchQuery,
    categoryFilter,
    dateRangeFilter,
    customStartDate,
    customEndDate,
    selectedCategory,
    selectedAnalyticsPeriod,
    analyticsSelectedDate,
  ];
}
