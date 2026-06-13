import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../cubit/budget_cubit.dart' as budget_cubit;
import '../widgets/total_spent_card.dart';
import '../widgets/notification_badge.dart';
import 'dashboard_screen.dart';
import 'expense_history_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';

const Color accentGreen = Color(0xFF32BA32);

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color darkText = Color(0xFF000000);
  static const Color fabBorderColor = Color(0xFFD4E5B0);
  static const Color cardBgColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        bool isDarkMode = (profileState is ProfileLoaded)
            ? profileState.user.isDarkMode
            : false;

        return Theme(
          data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            backgroundColor: isDarkMode ? Colors.black : bgColor,
            body: Column(
              children: [
                _buildTopHeader(context, isDarkMode),
                Expanded(
                  child: BlocBuilder<ExpenseCubit, ExpenseState>(
                    builder: (context, state) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analytics',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : darkText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildPeriodSelector(context, state, isDarkMode),
                            const SizedBox(height: 20),
                            TotalSpentCard(isDarkMode: isDarkMode),
                            const SizedBox(height: 24),
                            Text(
                              'Spending by Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : darkText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryCircleChart(
                              context,
                              state,
                              isDarkMode,
                            ),
                            const SizedBox(height: 24),
                            _buildSpendingInsightsHeader(
                              context,
                              state,
                              isDarkMode,
                            ),
                            const SizedBox(height: 12),
                            _buildEnhancedDailySpendingTrend(
                              context,
                              state,
                              isDarkMode,
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: _buildFab(context, isDarkMode),
            bottomNavigationBar: _buildBottomNavigation(context, isDarkMode),
          ),
        );
      },
    );
  }

  // ============ HELPER METHODS FOR CATEGORY COLORS AND ICONS ============

  Color _getCategoryChartColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'groceries':
      case 'grocery':
      case 'household/groceries':
      case 'household':
        return const Color(0xFF4CAF50); // Green
      case 'food':
      case 'dining':
      case 'restaurant':
        return const Color(0xFFFF9800); // Orange
      case 'beverages':
      case 'beverage':
      case 'drinks':
        return const Color(0xFF2196F3); // Blue
      case 'clothes':
      case 'clothing':
      case 'fashion':
        return const Color(0xFF9C27B0); // Purple
      case 'stationery':
        return const Color(0xFF009688); // Teal
      case 'transport':
      case 'transportation':
      case 'travel':
        return const Color(0xFF795548); // Brown
      case 'entertainment':
      case 'fun':
        return const Color(0xFFE91E63); // Pink
      case 'shopping':
      case 'retail':
        return const Color(0xFFFF5722); // Deep Orange
      case 'pet food':
      case 'pet supplies':
      case 'pets':
        return const Color(0xFF8BC34A); // Light Green
      case 'health':
      case 'healthcare':
      case 'medical':
        return const Color(0xFFF44336); // Red
      case 'snacks & desserts':
      case 'snacks':
      case 'desserts':
        return const Color(0xFFFF6B6B); // Light Red
      case 'cooking ingredients':
        return const Color(0xFFFFA726); // Light Orange
      case 'baking':
        return const Color(0xFFFFB74D); // Golden
      case 'education':
      case 'learning':
        return const Color(0xFF673AB7); // Deep Purple
      case 'bills':
      case 'utilities':
        return const Color(0xFF607D8B); // Blue Grey
      case 'others':
      case 'other':
      case 'misc':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return accentGreen;
    }
  }

  IconData _getCategoryIconForChart(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'groceries':
      case 'grocery':
      case 'household/groceries':
      case 'household':
        return Icons.shopping_cart_outlined;
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'beverages':
      case 'beverage':
        return Icons.local_cafe_outlined;
      case 'clothes':
      case 'clothing':
        return Icons.checkroom_outlined;
      case 'stationery':
        return Icons.edit_note_outlined;
      case 'transport':
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'pet food':
      case 'pet supplies':
        return Icons.pets_outlined;
      case 'health':
      case 'healthcare':
        return Icons.favorite_outlined;
      case 'snacks & desserts':
        return Icons.icecream_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'bills':
      case 'utilities':
        return Icons.receipt_outlined;
      case 'others':
        return Icons.category_outlined;
      default:
        return Icons.label_outlined;
    }
  }

  String _standardizeCategoryName(String category) {
    final Map<String, String> categoryMap = {
      'Grocery': 'Groceries',
      'Groceries': 'Groceries',
      'Household/Groceries': 'Groceries',
      'Household': 'Groceries',
      'Supermarket': 'Groceries',
      'Food': 'Food',
      'Foods': 'Food',
      'Dining': 'Food',
      'Restaurant': 'Food',
      'Beverage': 'Beverages',
      'Beverages': 'Beverages',
      'Drink': 'Beverages',
      'Pet Food': 'Pet Supplies',
      'Pet Supplies': 'Pet Supplies',
      'Pets': 'Pet Supplies',
      'Other': 'Others',
      'Misc': 'Others',
    };
    return categoryMap[category] ?? category;
  }

  // ============ BUILD METHODS ============

  Widget _buildFab(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      height: 70,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
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
    );
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
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : darkText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'SpendWise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : darkText,
            ),
          ),
          IconTheme(
            data: IconThemeData(color: isDarkMode ? Colors.white : darkText),
            child: BlocProvider(
              create: (context) => NotificationCubit(),
              child: const NotificationBadge(iconSize: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    ExpenseState state,
    bool isDarkMode,
  ) {
    final periods = [
      {'label': 'Week', 'icon': Icons.calendar_view_week},
      {'label': 'Month', 'icon': Icons.calendar_view_month},
      {'label': 'Year', 'icon': Icons.calendar_today},
    ];

    final selectedPeriod = _getSelectedPeriod(state.selectedAnalyticsPeriod);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : fabBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
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
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black87),
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
      ],
    );
  }

  Widget _buildSpendingInsightsHeader(
    BuildContext context,
    ExpenseState state,
    bool isDarkMode,
  ) {
    final period = state.selectedAnalyticsPeriod;
    final averageSpending = _calculateAverageSpending(state, period);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daily Spending Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : darkText,
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
    if (dailySpending.isEmpty) return 0.0;
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
      case AnalyticsPeriod.daily:
        startDate = now;
        break;
      case AnalyticsPeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case AnalyticsPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.yearly:
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
        dailySpending[dateKey] =
            (dailySpending[dateKey] ?? 0.0) + expense.amount;
      }
    }

    return dailySpending;
  }

  Widget _buildEnhancedDailySpendingTrend(
    BuildContext context,
    ExpenseState state,
    bool isDarkMode,
  ) {
    final period = state.selectedAnalyticsPeriod;
    final dailySpending = _getDailySpendingData(state, period);
    final sortedDates = dailySpending.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : fabBorderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No spending data for this period',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
              ),
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
        color: isDarkMode ? Colors.grey[850] : cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : fabBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  isDarkMode: isDarkMode,
                ),
                _buildStatChip(
                  icon: Icons.arrow_downward,
                  label: 'Lowest',
                  value: 'RM${minSpending.toStringAsFixed(2)}',
                  color: Colors.green,
                  isDarkMode: isDarkMode,
                ),
                _buildStatChip(
                  icon: Icons.show_chart,
                  label: 'Days',
                  value: '${sortedDates.length}',
                  color: accentGreen,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM${maxSpending.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                      ),
                      Text(
                        'RM${(maxSpending / 2).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                      ),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final amount = dailySpending[date] ?? 0.0;
                      final height = maxSpending > 0
                          ? (amount / maxSpending) * 150
                          : 0.0;
                      final isHighest = amount == maxSpending;
                      final isLowest =
                          amount == minSpending && amount != maxSpending;

                      return Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                                        : (isDarkMode
                                              ? Colors.white60
                                              : Colors.grey.shade600),
                                  ),
                                ),
                              ),
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
                            Text(
                              _getDateLabel(date, period),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey,
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
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
            ),
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
      case AnalyticsPeriod.daily:
        return DateFormat('HH:mm').format(date);
      case AnalyticsPeriod.weekly:
        return DateFormat('E').format(date);
      case AnalyticsPeriod.monthly:
        return DateFormat('d').format(date);
      case AnalyticsPeriod.yearly:
        return DateFormat('MMM').format(date);
    }
  }

  // UPDATED: Category Circle Chart with standardization and colors
  Widget _buildCategoryCircleChart(
    BuildContext context,
    ExpenseState state,
    bool isDarkMode,
  ) {
    // Standardize category names before processing
    final Map<String, double> standardizedCategories = {};
    final rawCategories = state.sortedCategoryTotals;

    for (var entry in rawCategories.entries) {
      final standardName = _standardizeCategoryName(entry.key);
      standardizedCategories[standardName] =
          (standardizedCategories[standardName] ?? 0) + entry.value;
    }

    // Sort again after standardization
    final sortedEntries = standardizedCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double total = sortedEntries.fold(0.0, (sum, e) => sum + e.value);

    if (sortedEntries.isEmpty || total == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : fabBorderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No category data available',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses to see insights',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final List<MapEntry<String, double>> categoryEntries = sortedEntries;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : fabBorderColor,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: CategoryCirclePainter(
                categories: categoryEntries,
                total: total,
                cubit: context.read<ExpenseCubit>(),
                isDarkMode: isDarkMode,
              ),
              size: const Size(200, 200),
            ),
          ),
          const SizedBox(height: 16),
          ...categoryEntries.take(5).map((entry) {
            final percentage = (entry.value / total) * 100;
            final categoryColor = _getCategoryChartColor(entry.key);
            final categoryIcon = _getCategoryIconForChart(entry.key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon, size: 16, color: categoryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : darkText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'RM${entry.value.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (categoryEntries.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${categoryEntries.length - 5} more categories',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDarkMode) {
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
                        BlocProvider.value(value: context.read<ProfileCubit>()),
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
              false,
              isDarkMode,
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
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              isDarkMode,
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
                        BlocProvider.value(value: context.read<ProfileCubit>()),
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
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(value: context.read<ProfileCubit>()),
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
                ? accentGreen
                : (isDarkMode ? Colors.white70 : Colors.black54),
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active
                  ? accentGreen
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedPeriod(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return 'Day';
      case AnalyticsPeriod.weekly:
        return 'Week';
      case AnalyticsPeriod.monthly:
        return 'Month';
      case AnalyticsPeriod.yearly:
        return 'Year';
    }
  }

  void _changePeriod(BuildContext context, String period) {
    final cubit = context.read<ExpenseCubit>();
    if (period == 'Day') cubit.changeAnalyticsPeriod(AnalyticsPeriod.daily);
    if (period == 'Week') cubit.changeAnalyticsPeriod(AnalyticsPeriod.weekly);
    if (period == 'Month') cubit.changeAnalyticsPeriod(AnalyticsPeriod.monthly);
    if (period == 'Year') cubit.changeAnalyticsPeriod(AnalyticsPeriod.yearly);
  }
}

// Custom Painter for Pie Chart
class CategoryCirclePainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final ExpenseCubit cubit;
  final bool isDarkMode;

  // Predefined vibrant colors for categories
  static const List<Color> _vibrantColors = [
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  CategoryCirclePainter({
    required this.categories,
    required this.total,
    required this.cubit,
    this.isDarkMode = false,
  });

  Color _getColorForCategory(String categoryName, int index) {
    switch (categoryName.toLowerCase()) {
      case 'groceries':
      case 'grocery':
      case 'household/groceries':
      case 'household':
        return const Color(0xFF4CAF50);
      case 'food':
      case 'dining':
      case 'restaurant':
        return const Color(0xFFFF9800);
      case 'beverages':
      case 'beverage':
        return const Color(0xFF2196F3);
      case 'clothes':
      case 'clothing':
        return const Color(0xFF9C27B0);
      case 'stationery':
        return const Color(0xFF009688);
      case 'transport':
      case 'transportation':
        return const Color(0xFF795548);
      case 'entertainment':
        return const Color(0xFFE91E63);
      case 'shopping':
        return const Color(0xFFFF5722);
      case 'pet food':
      case 'pet supplies':
        return const Color(0xFF8BC34A);
      case 'health':
      case 'healthcare':
        return const Color(0xFFF44336);
      case 'snacks & desserts':
        return const Color(0xFFFF6B6B);
      case 'others':
        return const Color(0xFF9E9E9E);
      default:
        return _vibrantColors[index % _vibrantColors.length];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -90 * (3.14159 / 180);

    for (int i = 0; i < categories.length; i++) {
      final entry = categories[i];
      final sweepAngle = (entry.value / total) * 360 * (3.14159 / 180);

      final color = _getColorForCategory(entry.key, i);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        Paint()..color = color,
      );
      startAngle += sweepAngle;
    }

    // Draw inner circle (donut hole)
    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()..color = isDarkMode ? Colors.grey[850]! : Colors.white,
    );

    // Draw center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${categories.length}',
        style: TextStyle(
          color: accentGreen,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
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
