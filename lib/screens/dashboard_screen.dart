import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/add_expense_cubit.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';
import 'expense_history_screen.dart';

// Import budget cubit
import '../cubit/budget_cubit.dart';
import '../cubit/budget_cubit.dart' as budget_cubit;

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
          child: const Icon(
            Icons.add,
            color: Color.fromRGBO(50, 186, 50, 1),
            size: 45,
          ),
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
          Expanded(
            child: Stack(
              children: [
                // Background Image Layer
                Positioned(
                  top: -80,
                  right: -40,
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset('assets/FYP2.png', width: 400),
                  ),
                ),
                // Foreground Content Layer - Listen to both cubits
                MultiBlocListener(
                  listeners: [
                    BlocListener<BudgetCubit, budget_cubit.BudgetState>(
                      listener: (context, budgetState) {
                        // When budget changes, refresh expense cubit if needed
                        if (budgetState is budget_cubit.BudgetLoaded) {
                          // You can update expense cubit with budget data here
                          // For example, update the budget amount in expense cubit
                          context.read<ExpenseCubit>().updateBudget(
                            budgetState.budget.monthlyLimit,
                          );
                        }
                      },
                    ),
                  ],
                  child: BlocBuilder<ExpenseCubit, ExpenseState>(
                    builder: (context, expenseState) {
                      return BlocBuilder<BudgetCubit, budget_cubit.BudgetState>(
                        builder: (context, budgetState) {
                          // Get budget data
                          double monthlyBudget = expenseState.budget;
                          double totalSpent = expenseState.totalSpending;

                          // If budget is loaded, use that data
                          if (budgetState is budget_cubit.BudgetLoaded) {
                            monthlyBudget = budgetState.budget.monthlyLimit;
                            // You might want to calculate total spent from categories
                            // or keep using expenseState.totalSpending
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(expenseState),
                                const SizedBox(height: 20),
                                _buildTotalBalanceCard(expenseState, context),
                                const SizedBox(height: 20),
                                _buildStatsRow(
                                  expenseState,
                                  context,
                                  monthlyBudget,
                                  totalSpent,
                                ),
                                const SizedBox(height: 20),
                                _buildBudgetProgress(
                                  expenseState,
                                  monthlyBudget,
                                  totalSpent,
                                ),
                                const SizedBox(height: 25),
                                _buildRecentExpensesSection(
                                  expenseState,
                                  context,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header matching the brand bar at the top
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
              // Chart icon - Clickable
              GestureDetector(
                onTap: () {
                  _showStatisticsDialog(context);
                },
                child: const Icon(Icons.bar_chart, size: 28),
              ),
              const SizedBox(width: 15),
              // Notifications icon - Clickable
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
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 126, 223, 106),
            Color.fromARGB(255, 24, 143, 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              color: Color.fromARGB(255, 255, 255, 255),
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
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              // Add icon in total balance card - Clickable
              GestureDetector(
                onTap: () {
                  _showAddMoneyDialog(context);
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
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isClickable ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accentGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    ExpenseState expenseState,
    BuildContext context,
    double monthlyBudget,
    double totalSpent,
  ) {
    double remainingBudget = monthlyBudget - totalSpent;

    return Row(
      children: [
        _statItem(
          'Total Spending',
          'RM${totalSpent.toStringAsFixed(2)}',
          Icons.trending_down,
        ),
        const SizedBox(width: 10),
        // Budget icon - Clickable to navigate to budget screen
        _statItem(
          'Budget',
          'RM${monthlyBudget.toStringAsFixed(2)}',
          Icons.account_balance,
          isClickable: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<ExpenseCubit>()),
                    BlocProvider(create: (context) => BudgetCubit()),
                  ],
                  child: const BudgetScreen(),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _statItem(
          'Remaining',
          'RM${remainingBudget.toStringAsFixed(2)}',
          Icons.wallet,
        ),
      ],
    );
  }

  Widget _buildBudgetProgress(
    ExpenseState expenseState,
    double monthlyBudget,
    double totalSpent,
  ) {
    double progress = monthlyBudget > 0 ? totalSpent / monthlyBudget : 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 126, 223, 106),
            Color.fromARGB(255, 24, 143, 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            color: accentGreen,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'RM${totalSpent.toStringAsFixed(2)} of RM${monthlyBudget.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.white),
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
        _buildRecentExpensesHeader(context),
        const SizedBox(height: 1),
        _buildRecentExpensesList(state, context),
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<ExpenseCubit>(),
                  child: const ExpenseHistoryScreen(),
                ),
              ),
            );
          },
          child: const Text(
            'See All',
            style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpensesList(ExpenseState state, BuildContext context) {
    final recentExpenses = state.allExpenses.length > 5
        ? state.allExpenses.sublist(0, 5)
        : state.allExpenses;

    if (recentExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No expenses yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Tap the + button to add an expense',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentExpenses.length,
      itemBuilder: (context, index) {
        final expense = recentExpenses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
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
              // Category icon
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense.category).withOpacity(0.1),
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
                    if (expense.isIncome ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 11,
                            color: accentGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(expense.isIncome ?? false) ? '+' : '-'}RM${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (expense.isIncome ?? false)
                          ? accentGreen
                          : Colors.red,
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
              true,
              activeColor,
              () {
                // Already on home screen
              },
            ),
            _navItem(
              Icons.history_outlined,
              Icons.history,
              'History',
              false,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<ExpenseCubit>(),
                      child: const ExpenseHistoryScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 40), // Gap for the FAB notch
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
                        BlocProvider(create: (context) => BudgetCubit()),
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
                _showProfileDialog(context);
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

  // Helper methods for dialogs
  void _showStatisticsDialog(BuildContext context) {
    final expenseState = context.read<ExpenseCubit>().state;
    final budgetState = context.read<BudgetCubit>().state;

    double monthlyBudget = expenseState.budget;
    if (budgetState is budget_cubit.BudgetLoaded) {
      monthlyBudget = budgetState.budget.monthlyLimit;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 60, color: accentGreen),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Spending:',
              'RM${expenseState.totalSpending.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Monthly Budget:',
              'RM${monthlyBudget.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Budget Used:',
              '${monthlyBudget > 0 ? (expenseState.totalSpending / monthlyBudget * 100).toInt() : 0}%',
            ),
            _buildStatRow(
              'Transactions:',
              '${expenseState.allExpenses.length}',
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

  void _showAddMoneyDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'RM ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: accentGreen, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  // Add to total balance using addIncome method
                  context.read<ExpenseCubit>().addIncome(amount);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added RM${amount.toStringAsFixed(2)} to balance',
                      ),
                      backgroundColor: accentGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: accentGreen.withOpacity(0.2),
              child: const Icon(Icons.person, size: 40, color: accentGreen),
            ),
            const SizedBox(height: 16),
            const Text(
              'User Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'user@example.com',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.settings, color: accentGreen),
              title: Text('Settings'),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.help, color: accentGreen),
              title: Text('Help & Support'),
              dense: true,
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
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
      case 'supplies':
        return Icons.inventory;
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
      case 'supplies':
        return Colors.teal;
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
