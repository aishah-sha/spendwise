import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/budget_cubit.dart' as budget_cubit;
import 'add_expense_screen.dart';
import '../cubit/add_expense_cubit.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
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
    return Scaffold(
      backgroundColor: bgColor,
      // Centered Floating Action Button with custom border (same as dashboard)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 30),
        height: 70,
        width: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
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
      ),
      bottomNavigationBar: _buildBottomNavigation(
        context,
        headerColor,
        accentGreen,
      ),
      body: Column(
        children: [
          _buildTopHeader(context),
          // Title Section (below header)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense History',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and Review all your expenses',
                  style: TextStyle(
                    fontSize: 14,
                    color: darkText.withOpacity(0.7),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search merchant, date, amount...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
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
                _buildFilterChip('All', isSelected: true),
                const SizedBox(width: 10),
                _buildFilterDropdown(context, 'Category'),
                const SizedBox(width: 10),
                _buildFilterDropdown(context, 'Date Range'),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards - FIXED to show correct total amount
          _buildSummaryCards(),

          const SizedBox(height: 16),

          // Expense List
          Expanded(
            child: BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                if (state.allExpenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                if (state.filteredExpenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses match your filters',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.groupedByDate.length,
                  itemBuilder: (context, index) {
                    final dateKey = state.groupedByDate.keys.elementAt(index);
                    final expenses = state.groupedByDate[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            dateKey,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ),
                        ...expenses.map(
                          (expense) =>
                              _buildDismissibleExpenseItem(context, expense),
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

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: headerColor),
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
              const Text(
                'SpendWise',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                child: const Icon(Icons.bar_chart, size: 28),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  _showNotificationsDialog(context);
                },
                child: const Icon(Icons.notifications, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        // Handle filter tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentGreen : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : darkText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        if (label == 'Category') {
          _showCategoryFilterMenu(context);
        } else if (label == 'Date Range') {
          _showDateFilterMenu(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
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
                  style: const TextStyle(color: darkText),
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

  void _showCategoryFilterMenu(BuildContext context) {
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
              const Text(
                'Filter by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(context, 'All Categories', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Income Only', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.income,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Expenses Only', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.expense,
                );
                Navigator.pop(context);
              }),
              const Divider(),
              const Text(
                'Specific Categories',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              // Dynamically show available categories
              ...sortedCategories.map(
                (category) => _buildFilterOption(context, category, () {
                  context.read<ExpenseCubit>().filterByCategory(
                    ExpenseFilter.all,
                    specificCategory: category,
                  );
                  Navigator.pop(context);
                }),
              ),
              if (sortedCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No categories available'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
              const Text(
                'Filter by Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(context, 'All Time', () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.all,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Today', () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.today,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Yesterday', () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.yesterday,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'This Week', () {
                context.read<ExpenseCubit>().filterByDateRange(
                  DateRangeFilter.week,
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'This Month', () {
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
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      onTap: onTap,
      leading: Icon(
        Icons.filter_list,
        color: title == 'All Categories' || title == 'All Time'
            ? Colors.grey
            : accentGreen,
      ),
    );
  }

  Widget _buildSummaryCards() {
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
            // If budget exists, show remaining budget (monthlyBudget + expensesTotal)
            // If no budget, show expenses total
            final displayAmount = monthlyBudget > 0
                ? monthlyBudget +
                      expensesTotal // This gives remaining budget
                : expensesTotal;

            // Determine color based on the amount
            Color amountColor = accentGreen;
            if (monthlyBudget > 0) {
              if (displayAmount < 0) {
                amountColor = Colors.red; // Over budget
              } else if (displayAmount < monthlyBudget * 0.2) {
                amountColor = Colors.orange; // Less than 20% remaining
              } else {
                amountColor = const Color.fromARGB(
                  255,
                  0,
                  252,
                  0,
                ); // Good amount remaining
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
                    ).withOpacity(0.3),
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
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align to the right
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

  Widget _buildDismissibleExpenseItem(BuildContext context, dynamic expense) {
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
      child: _buildExpenseItem(context, expense),
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

  Widget _buildExpenseItem(BuildContext context, dynamic expense) {
    final bool isIncome = expense.isIncome ?? false;
    final String amountPrefix = isIncome ? '+' : '-';
    final Color amountColor = isIncome ? accentGreen : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                // Category with count (always 1 for now since we don't have item data)
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
                      color: darkText.withOpacity(0.5),
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
              // Since we don't have item count, we can show something else or nothing
              // For now, we'll just show a small indicator
              Text(
                isIncome ? 'Income' : 'Expense',
                style: TextStyle(
                  fontSize: 10,
                  color: darkText.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No new notifications',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for updates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

Widget _buildBottomNavigation(
  BuildContext context,
  Color headerColor,
  Color activeColor,
) {
  return BottomAppBar(
    color: headerColor,
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
          color: active ? activeColor : Colors.black54,
          size: 26,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? activeColor : Colors.black54,
          ),
        ),
      ],
    ),
  );
}

double _calculateTotalAmount(ExpenseState state) {
  return state.filteredExpenses.fold(0.0, (sum, expense) {
    final bool isIncome = expense.isIncome ?? false;
    return isIncome ? sum + expense.amount : sum - expense.amount;
  });
}
