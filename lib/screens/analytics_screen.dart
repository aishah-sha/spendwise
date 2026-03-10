import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/add_expense_cubit.dart';
import '../widgets/total_spent_card.dart';
import '../widgets/daily_spending_trend.dart';
import '../widgets/category_legend.dart';
import 'dashboard_screen.dart';
import 'expense_history_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // --- THEME COLORS (Matching BudgetScreen) ---
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);
  static const Color fabBorderColor = Color(0xFFD4E5B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Matching Header
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

                      const Text(
                        'Daily Spending Trend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DailySpendingTrend(state: state),
                      const SizedBox(height: 16),

                      const CategoryLegend(),
                      const SizedBox(height: 20),

                      _buildYAxisLabels(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // --- MATCHING FLOATING ACTION BUTTON ---
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

      // --- MATCHING BOTTOM NAVIGATION ---
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // --- HEADER WIDGET ---
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 28, color: darkText),
              const SizedBox(width: 15),
              const Icon(Icons.notifications, size: 28, color: darkText),
            ],
          ),
        ],
      ),
    );
  }

  // --- NAVIGATION WIDGET ---
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
            const SizedBox(width: 40), // Gap for FAB
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

  // --- ANALYTICS SPECIFIC WIDGETS (Updated Colors) ---
  Widget _buildPeriodSelector(BuildContext context, ExpenseState state) {
    final periods = ['Week', 'Month', 'Year'];
    final selectedPeriod = _getSelectedPeriod(state.selectedAnalyticsPeriod);

    return Center(
      child: Container(
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
            final isSelected = selectedPeriod == period;
            return GestureDetector(
              onTap: () => _changePeriod(context, period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? accentGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryCircleChart(BuildContext context, ExpenseState state) {
    final categories = state.sortedCategoryTotals;
    final total = state.totalSpent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildYAxisLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        Text('300', style: TextStyle(color: Colors.grey)),
        Text('250', style: TextStyle(color: Colors.grey)),
        Text('200', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// Custom Painter (Update text color to accentGreen)
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
      textDirection: TextDirection.ltr,
    )..layout();
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
