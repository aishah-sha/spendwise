import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';

class CategoryChart extends StatelessWidget {
  final ExpenseState state;

  const CategoryChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final categories = state.sortedCategoryTotals;
    final total = state.totalSpent;

    if (categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No expenses in this period',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: categories.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        final percentage = (amount / total) * 100;
        final cubit = context.read<ExpenseCubit>();
        final color = cubit.getCategoryColor(category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 8,
                          width:
                              (percentage / 100) *
                              MediaQuery.of(context).size.width *
                              0.6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount.toStringAsFixed(0),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
