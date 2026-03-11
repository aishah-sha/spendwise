import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/profile_cubit.dart';
import 'add_budget_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'expense_history_screen.dart';
import 'dashboard_screen.dart';
import '../cubit/add_expense_cubit.dart';
import '../widgets/category_budget_card.dart';
import '../models/budget_model.dart';

// Import states with prefix
import '../cubit/budget_cubit.dart' as cubit;
import 'profile_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  // Theme colors
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);
  static const Color fabBorderColor = Color(0xFFD4E5B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<BudgetCubit>()),
          BlocProvider.value(value: context.read<ExpenseCubit>()),
        ],
        child: const BudgetView(),
      ),

      // FAB centered and notched
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 30),
        height: 70,
        width: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(
            side: BorderSide(color: fabBorderColor, width: 4),
          ),
          onPressed: () {
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

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(
        context,
        headerColor,
        accentGreen,
      ),
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
              false,
              activeColor,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<ExpenseCubit>(),
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
              true,
              activeColor,
              () {},
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
}

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Load budget when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetCubit>().loadBudget(forceRefresh: true);
    });

    return BlocBuilder<BudgetCubit, cubit.BudgetState>(
      builder: (context, budgetState) {
        if (budgetState is cubit.BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: accentGreen),
          );
        }

        if (budgetState is cubit.BudgetError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${budgetState.message}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<BudgetCubit>().loadBudget(
                    forceRefresh: true,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (budgetState is cubit.BudgetLoaded) {
          final budget = budgetState.budget;

          return BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, expenseState) {
              // Calculate actual spending from expenses
              final Map<String, double> categorySpending = {};
              double totalSpending = 0;

              for (var expense in expenseState.allExpenses) {
                if (!expense.isIncome) {
                  categorySpending[expense.category] =
                      (categorySpending[expense.category] ?? 0) +
                      expense.amount;
                  totalSpending += expense.amount;
                }
              }

              return Column(
                children: [
                  _buildTopHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        16.0,
                      ), // Reduced padding for smaller screens
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section with Title and Add Button
                          _buildHeaderRow(context),
                          const SizedBox(height: 16), // Reduced spacing
                          // Monthly Budget Card - FIXED FOR PIXEL
                          _buildMonthlyBudgetSection(
                            budget,
                            totalSpending,
                            screenWidth,
                            context,
                          ),
                          const SizedBox(height: 20), // Reduced spacing
                          // Category Budgets Header
                          _buildCategoryHeader(),
                          const SizedBox(height: 12), // Reduced spacing
                          // Category List with proper constraints
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 100,
                              maxHeight:
                                  screenHeight * 0.4, // Responsive max height
                            ),
                            child: _buildCategoryList(
                              budget,
                              categorySpending,
                              context,
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }

        // BudgetInitial state
        return _buildEmptyState(context);
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          // Added Expanded to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget',
                style: TextStyle(
                  fontSize: 28, // Slightly reduced for smaller screens
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your spending limits',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ), // Slightly reduced
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12), // Added spacing
        // Add Budget Button
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<BudgetCubit>(),
                  child: const AddBudgetScreen(),
                ),
              ),
            );
            if (result == true) {
              context.read<BudgetCubit>().loadBudget(forceRefresh: true);
            }
          },
          child: Container(
            width: 44, // Slightly smaller for Pixel
            height: 44, // Slightly smaller for Pixel
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 126, 223, 106),
                  Color.fromARGB(255, 24, 143, 0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ), // Slightly smaller radius
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 26,
            ), // Slightly smaller icon
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBudgetSection(
    Budget budget,
    double totalSpending,
    double screenWidth,
    BuildContext context,
  ) {
    if (budget.monthlyLimit <= 0) {
      return _buildNoBudgetCard(context);
    }

    final double progress = budget.monthlyLimit > 0
        ? totalSpending / budget.monthlyLimit
        : 0;
    final double remaining = budget.monthlyLimit - totalSpending;

    Color progressColor = accentGreen;
    String statusText = 'On Track';

    if (progress >= 1.0) {
      progressColor = Colors.red;
      statusText = 'Exceeded';
    } else if (progress >= 0.8) {
      progressColor = Colors.orange;
      statusText = 'Near Limit';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // Reduced padding for Pixel
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 126, 223, 106),
            Color.fromARGB(255, 24, 143, 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20), // Slightly smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row with icon and amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Smaller padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18, // Smaller icon
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                // Added Expanded
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ), // Smaller text
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      // Make text scale if needed
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'RM ${budget.monthlyLimit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24, // Smaller for Pixel
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // Smaller text
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spent percentage row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: RM ${totalSpending.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10, // Slightly smaller
                ),
              ),
              const SizedBox(height: 6),
              // Remaining row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: RM ${remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: remaining >= 0
                          ? Colors.white70
                          : Colors.red.shade300,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (remaining < 0)
                    Text(
                      'Overspent: RM ${(-remaining).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Category Budgets',
          style: TextStyle(
            fontSize: 18, // Slightly reduced
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        // Fixed dropdown to prevent overflow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This Month',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
    Budget budget,
    Map<String, double> categorySpending,
    BuildContext context,
  ) {
    // Filter active categories (amount > 0)
    final List<BudgetCategory> activeCategories = [];
    for (var category in budget.categories) {
      if (category.amount > 0) {
        activeCategories.add(category);
      }
    }

    if (activeCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No category budgets set',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to set category budgets',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<BudgetCubit>(),
                      child: const AddBudgetScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Add Categories',
                style: TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentGreen,
                side: BorderSide(color: accentGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeCategories.length,
      itemBuilder: (context, index) {
        final category = activeCategories[index];
        final spent = categorySpending[category.name] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CategoryBudgetCard(category: category, spentAmount: spent),
        );
      },
    );
  }

  Widget _buildAddToBudgetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<BudgetCubit>(),
                child: const AddBudgetScreen(isAdding: true),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add to Budget', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildNoBudgetCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Monthly Budget Set',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to set your monthly budget',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<BudgetCubit>(),
                    child: const AddBudgetScreen(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Set Budget', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: darkText.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: darkText.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Budget Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a budget to get started',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<BudgetCubit>(),
                      child: const AddBudgetScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Create Budget',
                style: TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 16, right: 16, bottom: 12),
      decoration: const BoxDecoration(color: headerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SpendWise',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
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
                child: const Icon(Icons.bar_chart, size: 24),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _showNotificationsDialog(context);
                },
                child: const Icon(Icons.notifications, size: 24),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notifications', style: TextStyle(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No new notifications',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check back later for updates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
