import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/notification_cubit.dart';
import '../models/expense_model.dart';
import 'add_budget_screen.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'expense_history_screen.dart';
import 'dashboard_screen.dart';
import 'notification_screen.dart';
import '../cubit/add_expense_cubit.dart';
import '../widgets/category_budget_card.dart';
import '../models/budget_model.dart';

import '../cubit/budget_cubit.dart' as cubit;
import 'profile_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

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
          BlocProvider(create: (context) => NotificationCubit()),
        ],
        child: const BudgetView(),
      ),
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
            const SizedBox(width: 40),
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
  static const Color onTrackColor = Color(0xFF2196F3);
  static const Color goodColor = Color(0xFF4CAF50);
  static const Color moderateColor = Color(0xFFFF9800);
  static const Color nearLimitColor = Color(0xFFFF5722);
  static const Color overLimitColor = Color(0xFFF44336);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              final Map<String, double> categorySpending = {};
              double totalSpending = 0;

              for (var expense in expenseState.allExpenses) {
                if (!expense.isIncome) {
                  String categoryName = expense.category;
                  categoryName = _standardizeCategoryName(categoryName);
                  categorySpending[categoryName] =
                      (categorySpending[categoryName] ?? 0) + expense.amount;
                  totalSpending += expense.amount;
                }
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final notificationCubit = context.read<NotificationCubit>();
                final Map<String, double> categoryBudgets = {};
                for (var category in budget.categories) {
                  if (category.amount > 0) {
                    categoryBudgets[category.name] = category.amount;
                  }
                }
                notificationCubit.checkBudgetAndNotify(
                  monthlyBudget: budget.monthlyLimit,
                  totalSpent: totalSpending,
                  categoryBudgets: categoryBudgets,
                  categorySpent: categorySpending,
                );
              });

              return Column(
                children: [
                  _buildTopHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderRow(context),
                          const SizedBox(height: 16),
                          _buildMonthlyBudgetSection(
                            budget,
                            totalSpending,
                            screenWidth,
                            context,
                          ),
                          const SizedBox(height: 20),
                          _buildCategoryHeader(),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 100,
                              maxHeight: screenHeight * 0.5,
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

        return _buildEmptyState(context);
      },
    );
  }

  String _standardizeCategoryName(String category) {
    final Map<String, String> categoryMap = {
      'Food': 'Food',
      'Foods': 'Food',
      'Dining': 'Food',
      'Restaurant': 'Food',
      'Groceries': 'Groceries',
      'Grocery': 'Groceries',
      'Transport': 'Transport',
      'Transportation': 'Transport',
      'Travel': 'Transport',
      'Entertainment': 'Entertainment',
      'Fun': 'Entertainment',
      'Shopping': 'Shopping',
      'Retail': 'Shopping',
      'Bills': 'Bills',
      'Utilities': 'Bills',
      'Healthcare': 'Healthcare',
      'Health': 'Healthcare',
      'Medical': 'Healthcare',
      'Education': 'Education',
      'Learning': 'Education',
      'Other': 'Other',
      'Others': 'Other',
      'Misc': 'Other',
      'Miscellaneous': 'Other',
    };
    return categoryMap[category] ?? category;
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your spending limits',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final budgetState = context.read<BudgetCubit>().state;
            bool isAdding = false;
            if (budgetState is cubit.BudgetLoaded) {
              isAdding = budgetState.budget.monthlyLimit > 0;
            }
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<BudgetCubit>(),
                  child: AddBudgetScreen(isAdding: isAdding),
                ),
              ),
            );
            if (result == true) {
              context.read<BudgetCubit>().loadBudget(forceRefresh: true);
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 126, 223, 106),
                  Color.fromARGB(255, 24, 143, 0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
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
    final double percentage = progress * 100;

    String statusText;
    Color progressColor;
    Color statusBgColor;
    Color statusTextColor;

    if (progress >= 1.0) {
      statusText = 'Over Limit';
      progressColor = overLimitColor;
      statusBgColor = overLimitColor;
      statusTextColor = Colors.white;
    } else if (progress >= 0.8) {
      statusText = 'Near Limit';
      progressColor = nearLimitColor;
      statusBgColor = nearLimitColor;
      statusTextColor = Colors.white;
    } else if (progress >= 0.5) {
      statusText = 'Moderate';
      progressColor = moderateColor;
      statusBgColor = moderateColor;
      statusTextColor = Colors.white;
    } else if (progress > 0) {
      statusText = 'Good';
      progressColor = goodColor;
      statusBgColor = goodColor;
      statusTextColor = Colors.white;
    } else {
      statusText = 'On Track';
      progressColor = onTrackColor;
      statusBgColor = onTrackColor;
      statusTextColor = Colors.white;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'RM ${budget.monthlyLimit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: RM ${totalSpending.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    remaining >= 0
                        ? 'Remaining: RM ${remaining.toStringAsFixed(2)}'
                        : 'Overspent: RM ${(-remaining).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: remaining >= 0
                          ? Colors.white70
                          : Colors.red.shade300,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (progress > 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${((progress - 1) * 100).toStringAsFixed(0)}% over',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
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
        final standardCategoryName = _standardizeCategoryName(category.name);
        double spent = 0;

        if (categorySpending.containsKey(standardCategoryName)) {
          spent = categorySpending[standardCategoryName] ?? 0;
        } else if (categorySpending.containsKey(category.name)) {
          spent = categorySpending[category.name] ?? 0;
        } else {
          for (var entry in categorySpending.entries) {
            if (_standardizeCategoryName(entry.key) == standardCategoryName) {
              spent += entry.value;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CategoryBudgetCard(
            category: BudgetCategory(
              name: category.name,
              amount: category.amount,
              spent: spent,
            ),
            spentAmount: spent,
          ),
        );
      },
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
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, notificationState) {
        return Container(
          padding: const EdgeInsets.only(
            top: 35,
            left: 16,
            right: 16,
            bottom: 12,
          ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => NotificationCubit(),
                            child: const NotificationScreen(),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications, size: 24),
                        if (notificationState.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                notificationState.unreadCount > 9
                                    ? '9+'
                                    : '${notificationState.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
