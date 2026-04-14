import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/notification_cubit.dart';
import '../widgets/total_spent_card.dart';
import '../widgets/category_legend.dart';
import '../widgets/notification_badge.dart';
import 'dashboard_screen.dart';
import 'expense_history_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // --- THEME COLORS ---
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);
  static const Color fabBorderColor = Color(0xFFD4E5B0);
  static const Color cardBgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPeriodSelector(context, state),
                      const SizedBox(height: 20),
                      const TotalSpentCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryCircleChart(context, state),
                      const SizedBox(height: 24),
                      _buildSpendingInsightsHeader(context, state),
                      const SizedBox(height: 12),
                      _buildEnhancedDailySpendingTrend(context, state),
                      const SizedBox(height: 16),
                      const CategoryLegend(),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: headerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Notification Badge only (removed refresh button to avoid error)
              BlocProvider(
                create: (context) => NotificationCubit(),
                child: const NotificationBadge(iconSize: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ExpenseState state) {
    final periods = [
      {'label': 'Week', 'icon': Icons.calendar_view_week},
      {'label': 'Month', 'icon': Icons.calendar_view_month},
      {'label': 'Year', 'icon': Icons.calendar_today},
    ];

    final selectedPeriod = _getSelectedPeriod(state.selectedAnalyticsPeriod);
    final periodInfo = _getPeriodInfo(state.selectedAnalyticsPeriod);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: fabBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((period) {
              final periodLabel = period['label'] as String;
              final isSelected = selectedPeriod == periodLabel;
              return GestureDetector(
                onTap: () => _changePeriod(context, periodLabel),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? accentGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        period['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Period info card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fabBorderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: accentGreen),
                  const SizedBox(width: 8),
                  Text(
                    periodInfo['title'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  periodInfo['dateRange'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, String> _getPeriodInfo(AnalyticsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case AnalyticsPeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return {
          'title': 'This Week\'s Spending',
          'dateRange':
              '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}',
        };
      case AnalyticsPeriod.month:
        return {
          'title': 'This Month\'s Spending',
          'dateRange': DateFormat('MMMM yyyy').format(now),
        };
      case AnalyticsPeriod.year:
        return {
          'title': 'This Year\'s Spending',
          'dateRange': DateFormat('yyyy').format(now),
        };
    }
  }

  // --- SPENDING INSIGHTS HEADER ---
  Widget _buildSpendingInsightsHeader(
    BuildContext context,
    ExpenseState state,
  ) {
    final period = state.selectedAnalyticsPeriod;
    final totalSpent = state.totalSpent;
    final averageSpending = _calculateAverageSpending(state, period);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daily Spending Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: accentGreen),
              const SizedBox(width: 4),
              Text(
                'Avg: RM${averageSpending.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accentGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateAverageSpending(ExpenseState state, AnalyticsPeriod period) {
    final dailySpending = _getDailySpendingData(state, period);
    if (dailySpending.isEmpty) return 0;
    final total = dailySpending.values.reduce((a, b) => a + b);
    return total / dailySpending.length;
  }

  Map<DateTime, double> _getDailySpendingData(
    ExpenseState state,
    AnalyticsPeriod period,
  ) {
    final Map<DateTime, double> dailySpending = {};
    final now = DateTime.now();

    DateTime startDate;
    switch (period) {
      case AnalyticsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case AnalyticsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    final endDate = now;

    for (var expense in state.allExpenses) {
      if (!expense.isIncome &&
          expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateKey = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + expense.amount;
      }
    }

    return dailySpending;
  }

  // --- ENHANCED DAILY SPENDING TREND ---
  Widget _buildEnhancedDailySpendingTrend(
    BuildContext context,
    ExpenseState state,
  ) {
    final period = state.selectedAnalyticsPeriod;
    final dailySpending = _getDailySpendingData(state, period);
    final sortedDates = dailySpending.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fabBorderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No spending data for this period',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final maxSpending = dailySpending.values.reduce((a, b) => a > b ? a : b);
    final minSpending = dailySpending.values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fabBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  icon: Icons.arrow_upward,
                  label: 'Highest',
                  value: 'RM${maxSpending.toStringAsFixed(2)}',
                  color: Colors.red,
                ),
                _buildStatChip(
                  icon: Icons.arrow_downward,
                  label: 'Lowest',
                  value: 'RM${minSpending.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                _buildStatChip(
                  icon: Icons.show_chart,
                  label: 'Days',
                  value: '${sortedDates.length}',
                  color: accentGreen,
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM${maxSpending.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'RM${(maxSpending / 2).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '0',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bars
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final amount = dailySpending[date] ?? 0;
                      final height = (amount / maxSpending) * 150;
                      final isHighest = amount == maxSpending;
                      final isLowest =
                          amount == minSpending && amount != maxSpending;

                      return Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Amount label
                            if (amount > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'RM${amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isHighest
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isHighest
                                        ? Colors.red
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            // Bar
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isHighest
                                      ? [Colors.red, Colors.red.shade300]
                                      : isLowest
                                      ? [Colors.green, Colors.green.shade300]
                                      : [
                                          accentGreen,
                                          accentGreen.withOpacity(0.7),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Date label
                            Text(
                              _getDateLabel(date, period),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateLabel(DateTime date, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return DateFormat('E').format(date); // Mon, Tue, etc.
      case AnalyticsPeriod.month:
        return DateFormat('d').format(date); // 1, 2, 3, etc.
      case AnalyticsPeriod.year:
        return DateFormat('MMM').format(date); // Jan, Feb, etc.
    }
  }

  // --- CATEGORY CIRCLE CHART ---
  Widget _buildCategoryCircleChart(BuildContext context, ExpenseState state) {
    final categories = state.sortedCategoryTotals;
    final total = state.totalSpent;

    if (categories.isEmpty || total == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fabBorderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No category data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses to see insights',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fabBorderColor),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: CategoryCirclePainter(
                categories: categories,
                total: total,
                cubit: context.read<ExpenseCubit>(),
              ),
              size: const Size(200, 200),
            ),
          ),
          const SizedBox(height: 16),
          ...categories.take(5).map((entry) {
            final percentage = (entry.value / total) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.read<ExpenseCubit>().getCategoryColor(
                        entry.key,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'RM${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (categories.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${categories.length - 5} more categories',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  // --- BOTTOM NAVIGATION ---
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
            _navItem(
              context,
              Icons.home_outlined,
              Icons.home,
              'Home',
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
            _navItem(
              context,
              Icons.history_outlined,
              Icons.history,
              'History',
              false,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseHistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 40),
            _navItem(
              context,
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                );
              },
            ),
            _navItem(
              context,
              Icons.person_outline,
              Icons.person,
              'Profile',
              false,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
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
    BuildContext context,
    IconData icon,
    IconData activeIcon,
    String label,
    bool active,
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
            color: active ? accentGreen : Colors.black54,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? accentGreen : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedPeriod(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }

  void _changePeriod(BuildContext context, String period) {
    final cubit = context.read<ExpenseCubit>();
    if (period == 'Week') cubit.changeAnalyticsPeriod(AnalyticsPeriod.week);
    if (period == 'Month') cubit.changeAnalyticsPeriod(AnalyticsPeriod.month);
    if (period == 'Year') cubit.changeAnalyticsPeriod(AnalyticsPeriod.year);
  }
}

// Custom Painter
class CategoryCirclePainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final ExpenseCubit cubit;

  CategoryCirclePainter({
    required this.categories,
    required this.total,
    required this.cubit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty || total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -90 * (3.14159 / 180);

    for (var entry in categories) {
      final sweepAngle = (entry.value / total) * 360 * (3.14159 / 180);
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        Paint()..color = cubit.getCategoryColor(entry.key),
      );
      startAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.6, Paint()..color = Colors.white);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${categories.length}',
        style: const TextStyle(
          color: Color(0xFF32BA32),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr, // ✅ Fixed with ui prefix
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
