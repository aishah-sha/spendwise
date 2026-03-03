import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // All filter chip
              FilterChip(
                label: Text(
                  'All',
                  style: TextStyle(
                    color: state.categoryFilter == ExpenseFilter.all
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                selected: state.categoryFilter == ExpenseFilter.all,
                selectedColor: Colors.blue,
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  if (selected) {
                    context.read<ExpenseCubit>().filterByCategory(
                      ExpenseFilter.all,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),

              // Category dropdown chip
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.selectedCategory ?? 'Category',
                      style: TextStyle(
                        color: state.selectedCategory != null
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: state.selectedCategory != null
                          ? Colors.white
                          : Colors.black,
                    ),
                  ],
                ),
                selected: state.selectedCategory != null,
                selectedColor: Colors.blue,
                onSelected: (selected) {
                  _showCategoryMenu(context);
                },
              ),
              const SizedBox(width: 8),

              // Date range chip
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getDateRangeLabel(state),
                      style: TextStyle(
                        color: state.dateRangeFilter != DateRangeFilter.all
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: state.dateRangeFilter != DateRangeFilter.all
                          ? Colors.white
                          : Colors.black,
                    ),
                  ],
                ),
                selected: state.dateRangeFilter != DateRangeFilter.all,
                selectedColor: Colors.blue,
                onSelected: (selected) {
                  _showDateRangeMenu(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDateRangeLabel(ExpenseState state) {
    switch (state.dateRangeFilter) {
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.yesterday:
        return 'Yesterday';
      case DateRangeFilter.week:
        return 'This Week';
      case DateRangeFilter.month:
        return 'This Month';
      case DateRangeFilter.custom:
        return 'Custom';
      default:
        return 'Date Range';
    }
  }

  void _showCategoryMenu(BuildContext context) {
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
              _buildCategoryOption(context, 'All Categories', null),
              const Divider(),
              _buildCategoryOption(context, 'Income Only', 'income'),
              _buildCategoryOption(context, 'Expenses Only', 'expense'),
              const Divider(),
              const Text(
                'Specific Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryOption(context, 'Food', 'Food'),
              _buildCategoryOption(context, 'Detergent', 'Detergent'),
              _buildCategoryOption(context, 'Stationery', 'Stationery'),
              _buildCategoryOption(context, 'Supplies', 'Supplies'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(
    BuildContext context,
    String label,
    String? category,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        if (category == 'income') {
          context.read<ExpenseCubit>().filterByCategory(ExpenseFilter.income);
        } else if (category == 'expense') {
          context.read<ExpenseCubit>().filterByCategory(ExpenseFilter.expense);
        } else {
          context.read<ExpenseCubit>().filterByCategory(
            ExpenseFilter.all,
            specificCategory: category,
          );
        }
        Navigator.pop(context);
      },
    );
  }

  void _showDateRangeMenu(BuildContext context) {
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
              _buildDateOption(context, 'All Time', DateRangeFilter.all),
              _buildDateOption(context, 'Today', DateRangeFilter.today),
              _buildDateOption(context, 'Yesterday', DateRangeFilter.yesterday),
              _buildDateOption(context, 'This Week', DateRangeFilter.week),
              _buildDateOption(context, 'This Month', DateRangeFilter.month),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateOption(
    BuildContext context,
    String label,
    DateRangeFilter filter,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        context.read<ExpenseCubit>().filterByDateRange(filter);
        Navigator.pop(context);
      },
    );
  }
}
