import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../cubit/budget_cubit.dart' as budget_cubit;
import '../widgets/notification_badge.dart';
import 'add_expense_screen.dart';
import '../cubit/add_expense_cubit.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  // Same colors as dashboard for consistency
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          bool isDarkMode = (profileState is ProfileLoaded)
              ? profileState.user.isDarkMode
              : false;

          return Theme(
            data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
            child: Scaffold(
              backgroundColor: isDarkMode ? Colors.black : bgColor,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: _buildFab(context, isDarkMode),
              bottomNavigationBar: _buildBottomNavigation(
                context,
                isDarkMode,
                accentGreen,
              ),
              body: Column(
                children: [
                  _buildTopHeader(context, isDarkMode),
                  // Title Section (below header)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense History',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and Review all your expenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white70
                                : darkText.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : darkText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search merchant, date, amount...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.white60
                                : Colors.grey[500],
                          ),
                          prefixIcon: Icon(Icons.search, color: accentGreen),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        onChanged: (query) {
                          context.read<ExpenseCubit>().searchExpenses(query);
                        },
                      ),
                    ),
                  ),

                  // Filter Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All',
                          isSelected: true,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterDropdown(context, 'Category', isDarkMode),
                        const SizedBox(width: 10),
                        _buildFilterDropdown(context, 'Date Range', isDarkMode),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards
                  _buildSummaryCards(isDarkMode),

                  const SizedBox(height: 16),

                  // Expense List
                  Expanded(
                    child: BlocBuilder<ExpenseCubit, ExpenseState>(
                      builder: (context, state) {
                        if (state.allExpenses.isEmpty) {
                          return Center(
                            child: Text(
                              'No expenses found',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey,
                              ),
                            ),
                          );
                        }

                        if (state.filteredExpenses.isEmpty) {
                          return Center(
                            child: Text(
                              'No expenses match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.groupedByDate.length,
                          itemBuilder: (context, index) {
                            final dateKey = state.groupedByDate.keys.elementAt(
                              index,
                            );
                            final expenses = state.groupedByDate[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    dateKey,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : darkText,
                                    ),
                                  ),
                                ),
                                ...expenses.map(
                                  (expense) => _buildDismissibleExpenseItem(
                                    context,
                                    expense,
                                    isDarkMode,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      height: 70,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFD4E5B0), width: 4),
        ),
        onPressed: () {
          // Navigate to add expense screen WITH the provider
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => AddExpenseCubit()),
                  BlocProvider.value(
                    value: context.read<budget_cubit.BudgetCubit>(),
                  ),
                ],
                child: const AddExpenseScreen(),
              ),
            ),
          ).then((_) {
            // When returning from add expense, refresh budget if needed
            _refreshBudget(context);
          });
        },
        child: const Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  // Helper method to refresh budget
  void _refreshBudget(BuildContext context) {
    context.read<budget_cubit.BudgetCubit>().loadBudget(forceRefresh: true);
  }

  // Helper method to update budget when expense is added
  void _updateBudgetFromExpense(BuildContext context, dynamic expense) {
    if (expense.isIncome != true) {
      final budgetCubit = context.read<budget_cubit.BudgetCubit>();
      final budgetState = budgetCubit.state;

      if (budgetState is budget_cubit.BudgetLoaded) {
        // Get current spent amount for this category
        final currentBudget = budgetState.budget;
        double currentSpent = 0;

        for (var category in currentBudget.categories) {
          if (category.name == expense.category) {
            currentSpent = category.spent;
            break;
          }
        }

        // Update with new total spent amount
        budgetCubit.updateCategorySpent(
          expense.category,
          currentSpent + expense.amount,
        );
      }
    }
  }

  // Helper method to update budget when expense is deleted
  void _updateBudgetOnDelete(BuildContext context, dynamic expense) {
    if (expense.isIncome != true) {
      final budgetCubit = context.read<budget_cubit.BudgetCubit>();
      final budgetState = budgetCubit.state;

      if (budgetState is budget_cubit.BudgetLoaded) {
        // Get current spent amount for this category
        final currentBudget = budgetState.budget;
        double currentSpent = 0;

        for (var category in currentBudget.categories) {
          if (category.name == expense.category) {
            currentSpent = category.spent;
            break;
          }
        }

        // Update with new total spent amount (subtract the deleted expense)
        budgetCubit.updateCategorySpent(
          expense.category,
          currentSpent - expense.amount,
        );
      }
    }
  }

  Widget _buildTopHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : headerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'SpendWise',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<ExpenseCubit>(),
                        child: const AnalyticsScreen(),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.bar_chart,
                  size: 28,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
              const SizedBox(width: 15),
              // Notification badge
              IconTheme(
                data: IconThemeData(
                  color: isDarkMode ? Colors.white : darkText,
                ),
                child: BlocProvider(
                  create: (context) => NotificationCubit(),
                  child: const NotificationBadge(iconSize: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    bool isSelected = false,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        // Handle filter tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentGreen
              : (isDarkMode ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentGreen
                : (isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : darkText),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    String label,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () {
        if (label == 'Category') {
          _showCategoryFilterMenu(context, isDarkMode);
        } else if (label == 'Date Range') {
          _showDateFilterMenu(context, isDarkMode);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                String displayText = label;
                if (label == 'Category' && state.selectedCategory != null) {
                  displayText = state.selectedCategory!;
                } else if (label == 'Date Range' &&
                    state.dateRangeFilter != DateRangeFilter.all) {
                  switch (state.dateRangeFilter) {
                    case DateRangeFilter.today:
                      displayText = 'Today';
                      break;
                    case DateRangeFilter.yesterday:
                      displayText = 'Yesterday';
                      break;
                    case DateRangeFilter.week:
                      displayText = 'This Week';
                      break;
                    case DateRangeFilter.month:
                      displayText = 'This Month';
                      break;
                    default:
                      displayText = label;
                  }
                }
                return Text(
                  displayText,
                  style: TextStyle(color: isDarkMode ? Colors.white : darkText),
                );
              },
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: accentGreen, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterMenu(BuildContext context, bool isDarkMode) {
    // Get unique categories from expenses
    final expenseState = context.read<ExpenseCubit>().state;
    final Set<String> categories = {};

    for (var expense in expenseState.allExpenses) {
      if (expense.category.isNotEmpty) {
        categories.add(expense.category);
      }
    }

    // Sort categories alphabetically
    final sortedCategories = categories.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(context, 'All Categories', isDarkMode, () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Income Only', isDarkMode, () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.income,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Expenses Only', isDarkMode, () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.expense,
                );
                Navigator.pop(context);
              }),
              const Divider(),
              Text(
                'Specific Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : darkText,
                ),
              ),
              const SizedBox(height: 8),
              // Dynamically show available categories
              ...sortedCategories.map(
                (category) =>
                    _buildFilterOption(context, category, isDarkMode, () {
                      context.read<ExpenseCubit>().filterByCategory(
                        ExpenseFilter.all,
                        specificCategory: category,
                      );
                      Navigator.pop(context);
                    }),
              ),
              if (sortedCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilterMenu(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(context, 'All Time', isDarkMode, () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.all,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Today', isDarkMode, () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.today,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Yesterday', isDarkMode, () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.yesterday,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'This Week', isDarkMode, () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.week,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'This Month', isDarkMode, () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.month,
                );
                Navigator.pop(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String title,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : darkText),
      ),
      onTap: onTap,
      leading: Icon(
        Icons.filter_list,
        color: title == 'All Categories' || title == 'All Time'
            ? Colors.grey
            : accentGreen,
      ),
    );
  }

  Widget _buildSummaryCards(bool isDarkMode) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, expenseState) {
        return BlocBuilder<budget_cubit.BudgetCubit, budget_cubit.BudgetState>(
          builder: (context, budgetState) {
            final totalExpenses = expenseState.filteredExpenses.length;

            // Calculate total from expenses (income - expenses)
            final expensesTotal = expenseState.filteredExpenses.fold(0.0, (
              sum,
              expense,
            ) {
              final bool isIncome = expense.isIncome ?? false;
              return isIncome ? sum + expense.amount : sum - expense.amount;
            });

            // Get monthly budget if available
            double monthlyBudget = 0;
            if (budgetState is budget_cubit.BudgetLoaded) {
              monthlyBudget = budgetState.budget.monthlyLimit;
            }

            // Calculate the amount to display
            final displayAmount = monthlyBudget > 0
                ? monthlyBudget + expensesTotal
                : expensesTotal;

            // Determine color based on the amount
            Color amountColor = accentGreen;
            if (monthlyBudget > 0) {
              if (displayAmount < 0) {
                amountColor = Colors.red;
              } else if (displayAmount < monthlyBudget * 0.2) {
                amountColor = Colors.orange;
              } else {
                amountColor = const Color.fromARGB(255, 0, 252, 0);
              }
            } else {
              amountColor = expensesTotal >= 0 ? accentGreen : Colors.red;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 24, 143, 0),
                    Color.fromARGB(255, 126, 223, 106),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(
                      255,
                      184,
                      255,
                      170,
                    ).withOpacity(isDarkMode ? 0.2 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TOP ROW - Total Expenses and Total Amount on the same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // TOTAL EXPENSES
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL EXPENSES',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$totalExpenses',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Vertical Divider
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.white.withOpacity(0.5),
                      ),

                      // TOTAL AMOUNT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'RM ${displayAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (monthlyBudget > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Spent: RM${(-expensesTotal).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDismissibleExpenseItem(
    BuildContext context,
    dynamic expense,
    bool isDarkMode,
  ) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.edit, color: Colors.white, size: 30),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to edit
          _navigateToEditExpense(context, expense);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to delete
          final confirm = await _showDeleteConfirmation(context);
          if (confirm) {
            // Update budget before deleting
            _updateBudgetOnDelete(context, expense);
            context.read<ExpenseCubit>().deleteExpense(expense.id);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense deleted'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return confirm;
        }
        return false;
      },
      child: _buildExpenseItem(context, expense, isDarkMode),
    );
  }

  // Helper method to get category icon based on category name
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'groceries':
      case 'grocery':
        return Icons.shopping_cart;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'entertainment':
      case 'fun':
        return Icons.movie;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag;
      case 'bills':
      case 'utilities':
        return Icons.receipt;
      case 'healthcare':
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'education':
      case 'learning':
        return Icons.school;
      case 'other':
      case 'others':
      default:
        return Icons.category;
    }
  }

  // Helper method to get category color based on category name
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Colors.orange;
      case 'groceries':
      case 'grocery':
        return Colors.green;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Colors.blue;
      case 'entertainment':
      case 'fun':
        return Colors.purple;
      case 'shopping':
      case 'retail':
        return Colors.pink;
      case 'bills':
      case 'utilities':
        return Colors.red;
      case 'healthcare':
      case 'health':
      case 'medical':
        return Colors.teal;
      case 'education':
      case 'learning':
        return Colors.indigo;
      case 'other':
      case 'others':
      default:
        return Colors.grey;
    }
  }

  Widget _buildExpenseItem(
    BuildContext context,
    dynamic expense,
    bool isDarkMode,
  ) {
    final bool isIncome = expense.isIncome ?? false;
    final String amountPrefix = isIncome ? '+' : '-';
    final Color amountColor = isIncome ? accentGreen : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category Icon based on category
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Left side - Merchant and Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : darkText,
                  ),
                ),
                const SizedBox(height: 4),
                // Category with count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(
                        expense.category,
                      ).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(expense.category),
                        size: 10,
                        color: _getCategoryColor(expense.category),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1 ${expense.category}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getCategoryColor(expense.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white60
                          : darkText.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Right side - Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix RM${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              Text(
                isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode
                      ? Colors.white38
                      : darkText.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    bool isDarkMode,
    Color activeColor,
  ) {
    return BottomAppBar(
      color: isDarkMode ? Colors.grey[900] : headerColor,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              Icons.home_outlined,
              Icons.home,
              'Home',
              false,
              isDarkMode,
              activeColor,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(
                          value: context.read<budget_cubit.BudgetCubit>(),
                        ),
                      ],
                      child: const DashboardScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.history_outlined,
              Icons.history,
              'History',
              true,
              isDarkMode,
              activeColor,
              () {
                // Already on history screen
              },
            ),
            const SizedBox(width: 40),
            _navItem(
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              isDarkMode,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider(
                          create: (context) => budget_cubit.BudgetCubit(),
                        ),
                      ],
                      child: const BudgetScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.person_outline,
              Icons.person,
              'Profile',
              false,
              isDarkMode,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider(create: (context) => ProfileCubit()),
                      ],
                      child: const ProfileScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    bool active,
    bool isDarkMode,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active
                ? activeColor
                : (isDarkMode ? Colors.white70 : Colors.black54),
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active
                  ? activeColor
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

void _navigateToEditExpense(BuildContext context, dynamic expense) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AddExpenseCubit(expenseToEdit: expense),
          ),
          BlocProvider.value(value: context.read<budget_cubit.BudgetCubit>()),
        ],
        child: const AddExpenseScreen(),
      ),
    ),
  ).then((_) {
    // Refresh budget when returning from edit
    context.read<budget_cubit.BudgetCubit>().loadBudget(forceRefresh: true);
  });
}

Future<bool> _showDeleteConfirmation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Expense'),
      content: const Text('Are you sure you want to delete this expense?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
