import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/add_expense_cubit.dart'; // Add this import
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Precise hex codes extracted from your interface image
  static const Color bgColor = Color(0xFFE8F7CB); // Main background light green
  static const Color headerColor = Color(
    0xFFC5D997,
  ); // Header and Card muted green
  static const Color accentGreen = Color(
    0xFF32BA32,
  ); // Bright green for buttons/icons
  static const Color darkText = Color(
    0xFF000000,
  ); // Black text for high contrast

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // Centered Floating Action Button with custom border
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
      bottomNavigationBar: _buildBottomNavigation(),
      body: Column(
        children: [
          _buildTopHeader(), // Custom top bar with logo
          Expanded(
            child: Stack(
              children: [
                // 1. Background Image Layer
                Positioned(
                  top: -80,
                  right: -40,
                  child: Opacity(
                    opacity:
                        0.5, // Subtle transparency as seen in the interface
                    child: Image.asset(
                      'assets/FYP2.png',
                      width: 400, // Adjust size to match the UI screenshot
                    ),
                  ),
                ),

                // 2. Foreground Content Layer
                BlocBuilder<ExpenseCubit, ExpenseState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(state),
                          const SizedBox(height: 20),
                          _buildTotalBalanceCard(
                            state,
                            context,
                          ), // Pass context
                          const SizedBox(height: 20),
                          _buildStatsRow(state),
                          const SizedBox(height: 20),
                          _buildBudgetProgress(state),
                          const SizedBox(height: 25),
                          _buildRecentExpensesSection(
                            state,
                            context,
                          ), // Pass context
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header matching the brand bar at the top
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

  Widget _buildWelcomeSection(ExpenseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${state.userName}!',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          DateFormat('dd MMMM yyyy').format(state.currentDate),
          style: TextStyle(fontSize: 16, color: darkText.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(ExpenseState state, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 22, 22, 22),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM${state.totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 24, 143, 0),
                ),
              ),
              // Add icon in total balance card - Clickable
              GestureDetector(
                onTap: () {
                  // Navigate to add money screen or show dialog
                  print('Add money icon tapped');
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
    IconData icon, {
    bool isClickable = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row makes the Icon and Label sit side-by-side
            Row(
              children: [
                if (isClickable)
                  // Icon is clickable
                  GestureDetector(
                    onTap: () {
                      print('$label icon tapped');
                    },
                    child: Icon(icon, size: 18, color: accentGreen),
                  )
                else
                  // Icon is not clickable
                  Icon(icon, size: 18, color: accentGreen),
                const SizedBox(width: 6), // Space between icon and text
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10, // Slightly smaller to fit side-by-side
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow
                        .ellipsis, // Prevents text crashing if too long
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ExpenseState state) {
    return Row(
      children: [
        // Total Spending icon is NOT clickable (isClickable: false by default)
        _statItem(
          'Total Spending',
          'RM${state.totalSpending.toStringAsFixed(2)}',
          Icons.trending_down,
        ),
        const SizedBox(width: 10),
        // Budget icon is NOT clickable
        _statItem(
          'Budget',
          'RM${state.budget.toStringAsFixed(2)}',
          Icons.account_balance,
        ),
        const SizedBox(width: 10),
        // Remaining icon is NOT clickable
        _statItem(
          'Remaining',
          'RM${(state.budget - state.totalSpending).toStringAsFixed(2)}',
          Icons.wallet,
        ),
      ],
    );
  }

  Widget _buildBudgetProgress(ExpenseState state) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${(state.budgetProgress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: state.budgetProgress,
            backgroundColor: Colors.white,
            color: accentGreen,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'RM${state.totalSpending.toStringAsFixed(2)} of RM${state.budget.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpensesSection(ExpenseState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentExpensesHeader(context), // Pass context
        const SizedBox(height: 1),
        _buildRecentExpensesList(state),
      ],
    );
  }

  Widget _buildRecentExpensesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Expenses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // "See All" text is clickable
        GestureDetector(
          onTap: () {
            // Navigate to all expenses screen
            print('See All tapped');
          },
          child: const Text(
            'See All',
            style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpensesList(ExpenseState state) {
    if (state.expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            'No expenses yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.expenses.length > 5 ? 5 : state.expenses.length,
      itemBuilder: (context, index) {
        final expense = state.expenses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(15),
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
              // Category icon - NOT clickable for Food, Detergent, Stationery
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.category,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(expense.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
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
            _navItem(Icons.home, 'Home', true, () {
              print('Home tapped');
            }),
            // History nav item - Clickable
            _navItem(Icons.history, 'History', false, () {
              print('History tapped');
            }),
            const SizedBox(width: 40),
            // Budget nav item - Clickable
            _navItem(Icons.savings, 'Budget', false, () {
              print('Budget tapped');
            }),
            // Profile nav item - Clickable
            _navItem(Icons.person, 'Profile', false, () {
              print('Profile tapped');
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
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'detergent':
        return Icons.local_laundry_service;
      case 'stationery':
        return Icons.edit;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'detergent':
        return Colors.blue;
      case 'stationery':
        return Colors.purple;
      case 'transport':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
