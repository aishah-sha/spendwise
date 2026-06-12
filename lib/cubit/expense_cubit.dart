import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'dart:async';
import '../models/expense_model.dart';
import 'expense_state.dart';
import '../services/supabase_service.dart';
import 'budget_cubit.dart';
import 'notification_cubit.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final SupabaseService _supabaseService = SupabaseService();
  final BudgetCubit budgetCubit;
  final NotificationCubit notificationCubit;
  StreamSubscription? _expensesSubscription;
  bool _isInitialLoad = true;

  ExpenseCubit({required this.budgetCubit, required this.notificationCubit})
    : super(ExpenseState.initial()) {
    _listenToExpenses();
  }

  void _listenToExpenses() {
    _expensesSubscription?.cancel();

    _expensesSubscription = _supabaseService.getTransactions().listen(
      (transactions) {
        print('🔄 Real-time update: ${transactions.length} transactions');

        // FIX: Don't override with empty data if we already have data
        if (transactions.isEmpty &&
            !_isInitialLoad &&
            state.allExpenses.isNotEmpty) {
          print('⚠️ Ignoring empty stream to prevent data loss');
          return;
        }

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
        _isInitialLoad = false;
      },
      onError: (error) {
        debugPrint('Error listening to expenses: $error');
        if (!isClosed) {
          emit(state.copyWith(error: () => error.toString(), isLoading: false));
        }
      },
    );
  }

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
        error: () => null,
      ),
    );

    if (!isClosed) {
      emit(newState);
      _checkThresholds(totalSpending, expenses);
    }
  }

  void _checkThresholds(double totalSpent, List<ExpenseModel> expenses) {
    final budgetState = budgetCubit.state;
    if (budgetState is BudgetLoaded) {
      final budget = budgetState.budget;

      final Map<String, double> categoryBudgets = {
        for (var cat in budget.categories) cat.name: cat.amount,
      };

      final Map<String, double> categorySpent = {};
      for (final exp in expenses) {
        if (!exp.isIncome) {
          categorySpent[exp.category] =
              (categorySpent[exp.category] ?? 0.0) + exp.amount;
        }
      }

      notificationCubit.checkBudgetAndNotify(
        monthlyBudget: budget.monthlyLimit,
        totalSpent: totalSpent,
        categoryBudgets: categoryBudgets,
        categorySpent: categorySpent,
      );
    }
  }

  void applyCustomDateRange(List<ExpenseModel> filteredExpenses) {
    if (isClosed) return;
    emit(
      state.copyWith(
        filteredExpenses: filteredExpenses,
        dateRangeFilter: DateRangeFilter.custom,
        selectedCategory: null,
      ),
    );
  }

  Future<void> loadExpenses() async {
    if (isClosed) return;
    print('📊 loadExpenses() called');
    emit(state.copyWith(isLoading: true, error: () => null));

    try {
      final transactions = await _supabaseService.fetchTransactions();
      print('📦 Fetched ${transactions.length} transactions');

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
      print('❌ Error loading expenses: $e');
      if (!isClosed) {
        emit(state.copyWith(error: () => e.toString(), isLoading: false));
      }
    }
  }

  void syncWithBudget(double newMonthlyLimit) {
    if (isClosed) return;
    emit(state.copyWith(budget: newMonthlyLimit));
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      print('📝 Adding expense: ${expense.title} - RM${expense.amount}');
      await _supabaseService.addTransaction(
        amount: expense.amount,
        category: expense.category,
        type: expense.isIncome ? 'income' : 'expense',
        description: expense.title,
        title: expense.title,
        note: expense.note,
        date: expense.date,
      );
      print('✅ Expense added to database');

      // Wait a moment for the database to sync
      await Future.delayed(const Duration(milliseconds: 500));
      await loadExpenses();
    } catch (e) {
      print('❌ Error adding expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: () => e.toString()));
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
        title: description ?? 'Income Added',
        date: DateTime.now(),
      );
      await loadExpenses();
    } catch (e) {
      debugPrint('Error adding income: $e');
      if (!isClosed) {
        emit(state.copyWith(error: () => e.toString()));
      }
    }
  }

  Future<void> updateExpense(ExpenseModel updatedExpense) async {
    try {
      await _supabaseService.updateTransaction(updatedExpense.id, {
        'amount': updatedExpense.amount,
        'category': updatedExpense.category,
        'description': updatedExpense.title,
        'title': updatedExpense.title,
        'note': updatedExpense.note,
        'type': updatedExpense.isIncome ? 'income' : 'expense',
        'date': updatedExpense.date.toIso8601String(),
      });
      await loadExpenses();
    } catch (e) {
      debugPrint('Error updating expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: () => e.toString()));
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabaseService.deleteTransaction(id);
      await loadExpenses();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      if (!isClosed) {
        emit(state.copyWith(error: () => e.toString()));
      }
    }
  }

  Future<void> refreshExpenses() async {
    print('🔄 refreshExpenses() called');
    await loadExpenses();
    print('✅ refreshExpenses() completed');
  }

  void updateSearchQuery(String query) {
    if (isClosed) return;
    final newState = state.copyWith(searchQuery: query);
    emit(_applyFilters(newState));
  }

  void updateCategoryFilter(ExpenseFilter filter) {
    if (isClosed) return;
    final newState = state.copyWith(categoryFilter: filter);
    emit(_applyFilters(newState));
  }

  void searchExpenses(String query) {
    updateSearchQuery(query);
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
    emit(_applyFilters(newState));
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

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Snacks & Desserts':
        return Icons.icecream_outlined;
      case 'Groceries':
        return Icons.shopping_cart_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Clothes':
        return Icons.checkroom_outlined;
      case 'Household':
        return Icons.home_outlined;
      case 'Baking':
        return Icons.cake_outlined;
      case 'Cooking Ingredients':
        return Icons.kitchen_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Health':
        return Icons.favorite_outlined;
      case 'Pet Food':
        return Icons.pets_outlined;
      case 'Stationery':
        return Icons.edit_outlined;
      case 'Others':
        return Icons.category_outlined;
      default:
        return Icons.label_outlined;
    }
  }

  Color getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Groceries':
        return const Color(0xFF4CAF50);
      case 'Food':
        return const Color(0xFFFF9800);
      case 'Beverages':
        return const Color(0xFF2196F3);
      case 'Clothes':
        return const Color(0xFF9C27B0);
      case 'Stationery':
        return const Color(0xFF607D8B);
      case 'Transport':
        return const Color(0xFF00BCD4);
      case 'Entertainment':
        return const Color(0xFFE91E63);
      case 'Shopping':
        return const Color(0xFFFF5722);
      case 'Household':
        return const Color(0xFF8BC34A);
      case 'Pet Food':
        return const Color(0xFF795548);
      case 'Health':
        return const Color(0xFFF44336);
      case 'Snacks & Desserts':
        return const Color(0xFFFF6B6B);
      case 'Cooking Ingredients':
        return const Color(0xFFFFA726);
      case 'Baking':
        return const Color(0xFFFFB74D);
      case 'Others':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF32BA32);
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

    if (state.selectedCategory != null &&
        state.selectedCategory != 'All Categories' &&
        state.selectedCategory != 'Income Only' &&
        state.selectedCategory != 'Expenses Only') {
      filtered = filtered
          .where((e) => e.category == state.selectedCategory)
          .toList();
    } else if (state.selectedCategory == 'Income Only') {
      filtered = filtered.where((e) => e.isIncome).toList();
    } else if (state.selectedCategory == 'Expenses Only') {
      filtered = filtered.where((e) => !e.isIncome).toList();
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

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query);
      }).toList();
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
