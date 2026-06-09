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
import 'profile_screen.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

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
                _buildHeaderTitle(isDarkMode),
                _buildSearchBar(context, isDarkMode),
                _buildEnhancedFilterBar(context, isDarkMode),
                const SizedBox(height: 8),
                _buildActiveFilters(context, isDarkMode),
                _buildSummaryCards(isDarkMode),
                const SizedBox(height: 8),
                _buildExpenseList(context, isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderTitle(bool isDarkMode) {
    return Container(
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
              color: isDarkMode ? Colors.white70 : darkText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDarkMode) {
    return Padding(
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
          style: TextStyle(color: isDarkMode ? Colors.white : darkText),
          decoration: InputDecoration(
            hintText: 'Search merchant, date, amount...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.grey[500],
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
    );
  }

  Widget _buildActiveFilters(BuildContext context, bool isDarkMode) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        final activeFilters = _getActiveFilters(state);
        if (activeFilters.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Filters',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...activeFilters.map(
                    (filter) => Chip(
                      label: Text(filter),
                      backgroundColor: accentGreen.withOpacity(0.1),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: accentGreen,
                      ),
                      onDeleted: () {
                        if (filter.contains('Category:')) {
                          context.read<ExpenseCubit>().filterByCategory(
                            ExpenseFilter.all,
                          );
                        } else if (filter.contains('Date:')) {
                          context.read<ExpenseCubit>().filterByDateRange(
                            DateRangeFilter.all,
                          );
                        } else if (filter == 'Income Only') {
                          context.read<ExpenseCubit>().filterByCategory(
                            ExpenseFilter.all,
                          );
                        } else if (filter == 'Expenses Only') {
                          context.read<ExpenseCubit>().filterByCategory(
                            ExpenseFilter.all,
                          );
                        } else if (filter.contains('Search:')) {
                          context.read<ExpenseCubit>().searchExpenses('');
                        }
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: accentGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (activeFilters.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        context.read<ExpenseCubit>().filterByCategory(
                          ExpenseFilter.all,
                        );
                        context.read<ExpenseCubit>().filterByDateRange(
                          DateRangeFilter.all,
                        );
                        context.read<ExpenseCubit>().searchExpenses('');
                      },
                      child: Chip(
                        label: const Text('Clear All'),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseList(BuildContext context, bool isDarkMode) {
    return Expanded(
      child: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state.allExpenses.isEmpty) {
            return Center(
              child: Text(
                'No expenses found',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white60 : Colors.grey,
                ),
              ),
            );
          }

          if (state.filteredExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_alt_off,
                    size: 64,
                    color: isDarkMode ? Colors.white38 : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses match your filters',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white60 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.read<ExpenseCubit>().filterByCategory(
                        ExpenseFilter.all,
                      );
                      context.read<ExpenseCubit>().filterByDateRange(
                        DateRangeFilter.all,
                      );
                      context.read<ExpenseCubit>().searchExpenses('');
                    },
                    child: const Text('Clear All Filters'),
                  ),
                ],
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : darkText,
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
    );
  }

  Widget _buildEnhancedFilterBar(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt, color: accentGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton(
                      context,
                      'All',
                      Icons.clear_all,
                      isDarkMode,
                      () {
                        context.read<ExpenseCubit>().filterByCategory(
                          ExpenseFilter.all,
                        );
                        context.read<ExpenseCubit>().filterByDateRange(
                          DateRangeFilter.all,
                        );
                        context.read<ExpenseCubit>().searchExpenses('');
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      context,
                      'Category',
                      Icons.category,
                      isDarkMode,
                      () => _showCategoryFilter(context, isDarkMode),
                      hasDropdown: true,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      context,
                      'Date',
                      Icons.calendar_today,
                      isDarkMode,
                      () => _showDateFilter(context, isDarkMode),
                      hasDropdown: true,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      context,
                      'Type',
                      Icons.trending_up,
                      isDarkMode,
                      () => _showTypeFilter(context, isDarkMode),
                      hasDropdown: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isDarkMode,
    VoidCallback onTap, {
    bool hasDropdown = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentGreen.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accentGreen),
            const SizedBox(width: 6),
            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                String displayText = label;
                if (label == 'Category' &&
                    state.selectedCategory != null &&
                    state.selectedCategory != 'All Categories' &&
                    state.selectedCategory != 'Income Only' &&
                    state.selectedCategory != 'Expenses Only') {
                  displayText = state.selectedCategory!;
                } else if (label == 'Category' &&
                    state.selectedCategory == 'Income Only') {
                  displayText = 'Income';
                } else if (label == 'Category' &&
                    state.selectedCategory == 'Expenses Only') {
                  displayText = 'Expense';
                } else if (label == 'Date' &&
                    state.dateRangeFilter != DateRangeFilter.all) {
                  displayText = _getDateRangeText(state.dateRangeFilter);
                } else if (label == 'Type') {
                  if (state.selectedCategory == 'Income Only') {
                    displayText = 'Income';
                  } else if (state.selectedCategory == 'Expenses Only') {
                    displayText = 'Expenses';
                  }
                }
                return Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: displayText != label
                        ? accentGreen
                        : (isDarkMode ? Colors.white70 : Colors.grey[700]),
                  ),
                );
              },
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: accentGreen),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context, bool isDarkMode) {
    final expenseState = context.read<ExpenseCubit>().state;
    final Set<String> categories = {};

    for (var expense in expenseState.allExpenses) {
      if (expense.category.isNotEmpty) {
        categories.add(expense.category);
      }
    }

    final sortedCategories = categories.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildFilterBottomSheet(context, 'Filter by Category', isDarkMode, [
            _buildFilterOption('All Categories', Icons.clear_all, () {
              context.read<ExpenseCubit>().filterByCategory(ExpenseFilter.all);
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('Income Only', Icons.attach_money, () {
              context.read<ExpenseCubit>().filterByCategory(
                ExpenseFilter.income,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('Expenses Only', Icons.shopping_cart, () {
              context.read<ExpenseCubit>().filterByCategory(
                ExpenseFilter.expense,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildDivider(),
            _buildHeader('Categories'),
            ...sortedCategories.map(
              (category) => _buildFilterOption(
                category,
                _getCategoryIcon(category),
                () {
                  context.read<ExpenseCubit>().filterByCategory(
                    ExpenseFilter.all,
                    specificCategory: category,
                  );
                  Navigator.pop(context);
                },
                iconColor: _getCategoryColor(category),
                isDarkMode: isDarkMode,
              ),
            ),
            if (sortedCategories.isEmpty)
              _buildFilterOption(
                'No categories available',
                Icons.info,
                null,
                enabled: false,
                isDarkMode: isDarkMode,
              ),
          ]),
    );
  }

  void _showDateFilter(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildFilterBottomSheet(context, 'Filter by Date', isDarkMode, [
            _buildFilterOption('All Time', Icons.access_time, () {
              context.read<ExpenseCubit>().filterByDateRange(
                DateRangeFilter.all,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('Today', Icons.today, () {
              context.read<ExpenseCubit>().filterByDateRange(
                DateRangeFilter.today,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('Yesterday', Icons.calendar_view_day, () {
              context.read<ExpenseCubit>().filterByDateRange(
                DateRangeFilter.yesterday,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('This Week', Icons.weekend, () {
              context.read<ExpenseCubit>().filterByDateRange(
                DateRangeFilter.week,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('This Month', Icons.calendar_view_month, () {
              context.read<ExpenseCubit>().filterByDateRange(
                DateRangeFilter.month,
              );
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption('Custom Range', Icons.date_range, () {
              Navigator.pop(context);
              _showCustomDateRangePicker(context, isDarkMode);
            }, isDarkMode: isDarkMode),
          ]),
    );
  }

  void _showTypeFilter(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildFilterBottomSheet(context, 'Filter by Type', isDarkMode, [
            _buildFilterOption('All Types', Icons.list_alt, () {
              context.read<ExpenseCubit>().filterByCategory(ExpenseFilter.all);
              Navigator.pop(context);
            }, isDarkMode: isDarkMode),
            _buildFilterOption(
              'Income Only',
              Icons.trending_up,
              () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.income,
                );
                Navigator.pop(context);
              },
              iconColor: Colors.green,
              isDarkMode: isDarkMode,
            ),
            _buildFilterOption(
              'Expenses Only',
              Icons.trending_down,
              () {
                context.read<ExpenseCubit>().filterByCategory(
                  ExpenseFilter.expense,
                );
                Navigator.pop(context);
              },
              iconColor: Colors.red,
              isDarkMode: isDarkMode,
            ),
          ]),
    );
  }

  Widget _buildFilterBottomSheet(
    BuildContext context,
    String title,
    bool isDarkMode,
    List<Widget> options,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : darkText,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: accentGreen, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: options,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool enabled = true,
    Color? iconColor,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? accentGreen, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? (isDarkMode ? Colors.white : darkText)
              : (isDarkMode ? Colors.white38 : Colors.grey[400]),
          fontSize: 16,
        ),
      ),
      onTap: enabled ? onTap : null,
      enabled: enabled,
      trailing: enabled
          ? Icon(Icons.chevron_right, color: Colors.grey[400], size: 20)
          : null,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accentGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showCustomDateRangePicker(BuildContext context, bool isDarkMode) async {
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Date Range'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    startDate != null
                        ? _formatDate(startDate!)
                        : 'Not selected',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                    endDate != null ? _formatDate(endDate!) : 'Not selected',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (startDate != null && endDate != null) {
                    final filtered = context
                        .read<ExpenseCubit>()
                        .state
                        .allExpenses
                        .where((expense) {
                          final expenseDate = expense.date;
                          return expenseDate.isAfter(
                                startDate!.subtract(const Duration(days: 1)),
                              ) &&
                              expenseDate.isBefore(
                                endDate!.add(const Duration(days: 1)),
                              );
                        })
                        .toList();

                    context.read<ExpenseCubit>().applyCustomDateRange(filtered);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _getActiveFilters(ExpenseState state) {
    final filters = <String>[];

    if (state.selectedCategory != null &&
        state.selectedCategory != 'All Categories' &&
        state.selectedCategory != 'Income Only' &&
        state.selectedCategory != 'Expenses Only') {
      filters.add('Category: ${state.selectedCategory}');
    } else if (state.selectedCategory == 'Income Only') {
      filters.add('Income Only');
    } else if (state.selectedCategory == 'Expenses Only') {
      filters.add('Expenses Only');
    }

    if (state.dateRangeFilter != DateRangeFilter.all &&
        state.dateRangeFilter != DateRangeFilter.custom) {
      filters.add('Date: ${_getDateRangeText(state.dateRangeFilter)}');
    } else if (state.dateRangeFilter == DateRangeFilter.custom) {
      filters.add('Date: Custom Range');
    }

    if (state.searchQuery.isNotEmpty) {
      filters.add('Search: ${state.searchQuery}');
    }

    return filters;
  }

  String _getDateRangeText(DateRangeFilter filter) {
    switch (filter) {
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.yesterday:
        return 'Yesterday';
      case DateRangeFilter.week:
        return 'This Week';
      case DateRangeFilter.month:
        return 'This Month';
      case DateRangeFilter.custom:
        return 'Custom Range';
      default:
        return 'All Time';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => AddExpenseCubit()),
                  BlocProvider.value(
                    value: context.read<budget_cubit.BudgetCubit>(),
                  ),
                  BlocProvider.value(value: context.read<ExpenseCubit>()),
                  BlocProvider.value(value: context.read<ProfileCubit>()),
                ],
                child: const AddExpenseScreen(),
              ),
            ),
          ).then((_) {
            _refreshBudget(context);
            context.read<ExpenseCubit>().loadExpenses();
          });
        },
        child: const Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  void _refreshBudget(BuildContext context) {
    context.read<budget_cubit.BudgetCubit>().loadBudget(forceRefresh: true);
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
                      builder: (context) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(
                            value: context.read<ExpenseCubit>(),
                          ),
                          BlocProvider.value(
                            value: context.read<ProfileCubit>(),
                          ),
                        ],
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

  Widget _buildSummaryCards(bool isDarkMode) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, expenseState) {
        return BlocBuilder<budget_cubit.BudgetCubit, budget_cubit.BudgetState>(
          builder: (context, budgetState) {
            final totalExpenses = expenseState.filteredExpenses.length;

            final expensesTotal = expenseState.filteredExpenses.fold(0.0, (
              sum,
              expense,
            ) {
              final bool isIncome = expense.isIncome ?? false;
              return isIncome ? sum + expense.amount : sum - expense.amount;
            });

            double monthlyBudget = 0;
            if (budgetState is budget_cubit.BudgetLoaded) {
              monthlyBudget = budgetState.budget.monthlyLimit;
            }

            final displayAmount = monthlyBudget > 0
                ? monthlyBudget + expensesTotal
                : expensesTotal;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.white.withOpacity(0.5),
                      ),
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
      direction: DismissDirection.endToStart,
      background: Container(),
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
        if (direction == DismissDirection.endToStart) {
          final confirmed = await _showDeleteConfirmation(context);
          if (confirmed) {
            try {
              _updateBudgetOnDelete(context, expense);
              await context.read<ExpenseCubit>().deleteExpense(expense.id);
              await context.read<ExpenseCubit>().loadExpenses();
              context.read<budget_cubit.BudgetCubit>().loadBudget(
                forceRefresh: true,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              return true;
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting expense: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            }
          }
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => _navigateToEditExpense(context, expense),
        child: _buildExpenseItem(context, expense, isDarkMode),
      ),
    );
  }

  void _updateBudgetOnDelete(BuildContext context, dynamic expense) {
    if (expense.isIncome != true) {
      final budgetCubit = context.read<budget_cubit.BudgetCubit>();
      final budgetState = budgetCubit.state;

      if (budgetState is budget_cubit.BudgetLoaded) {
        final currentBudget = budgetState.budget;
        double currentSpent = 0;

        for (var category in currentBudget.categories) {
          if (category.name == expense.category) {
            currentSpent = category.spent;
            break;
          }
        }

        budgetCubit.updateCategorySpent(
          expense.category,
          currentSpent - expense.amount,
        );
      }
    }
  }

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
                        '${expense.category}',
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
              true,
              isDarkMode,
              activeColor,
              () {},
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
              activeColor,
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

// Navigation helper functions
void _navigateToEditExpense(BuildContext context, dynamic expense) {
  final addExpenseCubit = AddExpenseCubit();

  addExpenseCubit.updateTitle(expense.title);
  addExpenseCubit.updateAmount(expense.amount);
  addExpenseCubit.updateCategory(expense.category);
  addExpenseCubit.updateDate(expense.date);
  addExpenseCubit.updateIsIncome(expense.isIncome ?? false);
  addExpenseCubit.updateNote(expense.note ?? '');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: addExpenseCubit),
          BlocProvider.value(value: context.read<ExpenseCubit>()),
          BlocProvider.value(value: context.read<budget_cubit.BudgetCubit>()),
          BlocProvider.value(value: context.read<ProfileCubit>()),
        ],
        child: AddExpenseScreen(editingExpenseId: expense.id),
      ),
    ),
  ).then((_) {
    context.read<budget_cubit.BudgetCubit>().loadBudget(forceRefresh: true);
    context.read<ExpenseCubit>().loadExpenses();
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
