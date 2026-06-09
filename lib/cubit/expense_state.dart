import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';

enum ExpenseFilter { all, income, expense }

enum DateRangeFilter { all, today, yesterday, week, month, custom }

enum AnalyticsPeriod { daily, weekly, monthly, yearly }

class ExpenseState extends Equatable {
  final List<ExpenseModel> allExpenses;
  final List<ExpenseModel> filteredExpenses;
  final bool isLoading;
  final String? error;
  final double totalSpending;
  final double totalBalance;
  final double budget;
  final String searchQuery;
  final ExpenseFilter categoryFilter;
  final DateRangeFilter dateRangeFilter;
  final String? selectedCategory;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final AnalyticsPeriod selectedAnalyticsPeriod;
  final DateTime analyticsSelectedDate;

  // Additional properties needed for analytics
  double get totalSpent => totalSpending;

  Map<String, double> get sortedCategoryTotals {
    final Map<String, double> categoryTotals = {};

    for (final expense in filteredExpenses) {
      if (!expense.isIncome) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0.0) + expense.amount;
      }
    }

    // Sort by value descending
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // FIXED: Explicitly return double, not num
  double get percentageChange {
    // Calculate spending change compared to previous period
    final now = DateTime.now();
    final currentPeriodStart = DateTime(now.year, now.month, 1);
    final previousPeriodStart = DateTime(now.year, now.month - 1, 1);
    final previousPeriodEnd = DateTime(now.year, now.month, 0);

    double currentSpent = 0.0;
    double previousSpent = 0.0;

    for (final expense in allExpenses) {
      if (!expense.isIncome) {
        if (expense.date.isAfter(currentPeriodStart)) {
          currentSpent += expense.amount;
        } else if (expense.date.isAfter(previousPeriodStart) &&
            expense.date.isBefore(previousPeriodEnd)) {
          previousSpent += expense.amount;
        }
      }
    }

    if (previousSpent == 0.0) return 0.0;
    return ((currentSpent - previousSpent) / previousSpent) * 100.0;
  }

  Map<DateTime, double> get dailyTotals {
    final Map<DateTime, double> totals = {};

    for (final expense in filteredExpenses) {
      if (!expense.isIncome) {
        final date = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        totals[date] = (totals[date] ?? 0.0) + expense.amount;
      }
    }

    return totals;
  }

  List<ExpenseModel> get smallExpenses {
    return filteredExpenses.where((e) => !e.isIncome && e.amount < 10).toList();
  }

  // Grouped expenses by date for UI display
  Map<String, List<ExpenseModel>> get groupedByDate {
    final map = <String, List<ExpenseModel>>{};
    for (final expense in filteredExpenses) {
      final dateKey = _getDateKey(expense.date);
      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(expense);
    }
    return map;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  const ExpenseState({
    this.allExpenses = const [],
    this.filteredExpenses = const [],
    this.isLoading = false,
    this.error,
    this.totalSpending = 0.0,
    this.totalBalance = 0.0,
    this.budget = 0.0,
    this.searchQuery = '',
    this.categoryFilter = ExpenseFilter.all,
    this.dateRangeFilter = DateRangeFilter.all,
    this.selectedCategory,
    this.customStartDate,
    this.customEndDate,
    this.selectedAnalyticsPeriod = AnalyticsPeriod.monthly,
    required this.analyticsSelectedDate,
  });

  factory ExpenseState.initial() {
    return ExpenseState(analyticsSelectedDate: DateTime.now());
  }

  ExpenseState copyWith({
    List<ExpenseModel>? allExpenses,
    List<ExpenseModel>? filteredExpenses,
    bool? isLoading,
    String? Function()? error,
    double? totalSpending,
    double? totalBalance,
    double? budget,
    String? searchQuery,
    ExpenseFilter? categoryFilter,
    DateRangeFilter? dateRangeFilter,
    String? selectedCategory,
    DateTime? customStartDate,
    DateTime? customEndDate,
    AnalyticsPeriod? selectedAnalyticsPeriod,
    DateTime? analyticsSelectedDate,
  }) {
    return ExpenseState(
      allExpenses: allExpenses ?? this.allExpenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      totalSpending: totalSpending ?? this.totalSpending,
      totalBalance: totalBalance ?? this.totalBalance,
      budget: budget ?? this.budget,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      dateRangeFilter: dateRangeFilter ?? this.dateRangeFilter,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      selectedAnalyticsPeriod:
          selectedAnalyticsPeriod ?? this.selectedAnalyticsPeriod,
      analyticsSelectedDate:
          analyticsSelectedDate ?? this.analyticsSelectedDate,
    );
  }

  @override
  List<Object?> get props => [
    allExpenses,
    filteredExpenses,
    isLoading,
    error,
    totalSpending,
    totalBalance,
    budget,
    searchQuery,
    categoryFilter,
    dateRangeFilter,
    selectedCategory,
    customStartDate,
    customEndDate,
    selectedAnalyticsPeriod,
    analyticsSelectedDate,
  ];
}
