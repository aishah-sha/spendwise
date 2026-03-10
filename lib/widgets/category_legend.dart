import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';

class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();

    final categories = [
      'Groceries',
      'Food',
      'Beverages',
      'Clothes',
      'Stationery',
      'Rent',
      'Supplies',
      'Others',
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categories.map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: cubit.getCategoryColor(category),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              category,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }
}
