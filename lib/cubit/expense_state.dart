import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';

enum ExpenseFilter { all, income, expense }

enum DateRangeFilter { all, today, yesterday, week, month, custom }

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
  });

  factory ExpenseState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final initialExpenses = [
      ExpenseModel(
        id: '1',
        title: 'Mydin',
        category: 'Food',
        amount: 23.00,
        date: today,
        isIncome: false,
      ),
      ExpenseModel(
        id: '2',
        title: 'Tunas Manja Group',
        category: 'Detergent',
        amount: 19.00,
        date: yesterday,
        isIncome: false,
      ),
      ExpenseModel(
        id: '3',
        title: 'SM budget',
        category: 'Supplies',
        amount: 50.00,
        date: twoDaysAgo,
        isIncome: true,
        note: 'Recent Supplies',
      ),
      ExpenseModel(
        id: '4',
        title: 'SMO Bookstore',
        category: 'Stationery',
        amount: 13.00,
        date: twoDaysAgo,
        isIncome: false,
      ),
    ];

    final totalSpending = initialExpenses.fold(
      0.0,
      (sum, item) => item.isIncome ? sum - item.amount : sum + item.amount,
    );

    return ExpenseState(
      userName: 'John',
      currentDate: now,
      totalBalance: 1000.00,
      totalSpending: totalSpending.abs(),
      budget: 2000.00,
      allExpenses: initialExpenses,
      filteredExpenses: initialExpenses,
    );
  }

  // Computed properties
  double get remaining => budget - totalSpending;
  double get budgetProgress => totalSpending / budget;

  int get totalExpensesCount => filteredExpenses.length;

  double get totalAmount {
    return filteredExpenses.fold(0.0, (sum, expense) {
      return expense.isIncome ? sum + expense.amount : sum - expense.amount;
    });
  }

  // Group expenses by date for display
  Map<String, List<ExpenseModel>> get groupedByDate {
    final grouped = <String, List<ExpenseModel>>{};

    for (var expense in filteredExpenses) {
      final dateKey = _getDateKey(expense.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    // Sort dates in descending order
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

    // Check if within last 7 days
    if (expenseDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'THIS WEEK';
    }

    // Return formatted date for older entries
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
  ];
}
