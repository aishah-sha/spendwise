// lib/screens/expense_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../widgets/expense_tile.dart';
import '../widgets/filter_chips.dart';
import '../widgets/summary_cards.dart';
import 'add_expense_screen.dart';
import '../cubit/add_expense_cubit.dart';
import 'dashboard_screen.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  // Same colors as dashboard for consistency
  static const Color bgColor = Color(0xFFE8F7CB); // Main background light green
  static const Color headerColor = Color(0xFFC5D997); // Header muted green
  static const Color accentGreen = Color(0xFF32BA32); // Bright green
  static const Color darkText = Color(0xFF000000); // Black text

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
                builder: (context) => BlocProvider(
                  create: (context) => AddExpenseCubit(),
                  child: const AddExpenseScreen(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add, color: accentGreen, size: 45),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Column(
        children: [
          _buildTopHeader(), // Same header as dashboard
          // Title Section (below header)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            color: Colors
                .transparent, // Make transparent since header already has color
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
                _buildFilterDropdown(context, 'Category'), // Pass context here
                const SizedBox(width: 10),
                _buildFilterDropdown(
                  context,
                  'Date Range',
                ), // Pass context here
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
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

  // EXACT SAME HEADER AS DASHBOARD
  Widget _buildTopHeader() {
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
              // Chart icon - Clickable
              GestureDetector(
                onTap: () {
                  // Navigate to statistics screen
                  print('Chart icon tapped');
                },
                child: const Icon(Icons.bar_chart, size: 28),
              ),
              const SizedBox(width: 15),
              // Notifications icon - Clickable
              GestureDetector(
                onTap: () {
                  // Navigate to notifications screen
                  print('Notifications icon tapped');
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

  // In _buildFilterDropdown method, add BuildContext parameter
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
              _buildFilterOption(context, 'Food', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                  specificCategory: 'Food',
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Detergent', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                  specificCategory: 'Detergent',
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Stationery', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                  specificCategory: 'Stationery',
                );
                Navigator.pop(context);
              }),
              _buildFilterOption(context, 'Supplies', () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.all,
                  specificCategory: 'Supplies',
                );
                Navigator.pop(context);
              }),
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
      leading: const Icon(Icons.filter_list),
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        final totalAmount = _calculateTotalAmount(state);
        final Color amountColor = totalAmount >= 0 ? accentGreen : Colors.red;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: headerColor, // Same as dashboard cards
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // TOTAL EXPENSES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL EXPENSES',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkText.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.filteredExpenses.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider
              Container(height: 40, width: 1, color: darkText.withOpacity(0.2)),

              // TOTAL AMOUNT with dynamic color
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkText.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            context.read<ExpenseCubit>().deleteExpense(expense.id);
          }
          return confirm;
        }
        return false;
      },
      child: _buildExpenseItem(context, expense),
    );
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
                Text(
                  expense.category,
                  style: TextStyle(
                    fontSize: 14,
                    color: darkText.withOpacity(0.6),
                  ),
                ),
                if (expense.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkText.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right side - Amount
          Text(
            '$amountPrefix RM${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditExpense(BuildContext context, dynamic expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddExpenseCubit(expenseToEdit: expense),
          child: const AddExpenseScreen(),
        ),
      ),
    );
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

  // EXACT SAME BOTTOM NAVIGATION AS DASHBOARD
  Widget _buildBottomNavigation(BuildContext context) {
    return BottomAppBar(
      color: headerColor,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home nav item - Clickable
            _navItem(Icons.home, 'Home', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ExpenseCubit>(),
                    child: const DashboardScreen(),
                  ),
                ),
              );
            }),
            // History nav item - Active
            _navItem(Icons.history, 'History', true, () {
              // Already on history screen
            }),
            const SizedBox(width: 40), // Space for FAB
            // Budget nav item - Clickable
            _navItem(Icons.savings, 'Budget', false, () {
              print('Budget tapped');
              // Navigate to budget screen when implemented
            }),
            // Profile nav item - Clickable
            _navItem(Icons.person, 'Profile', false, () {
              print('Profile tapped');
              // Navigate to profile screen when implemented
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.black : Colors.black54),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.black : Colors.black54,
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
}
