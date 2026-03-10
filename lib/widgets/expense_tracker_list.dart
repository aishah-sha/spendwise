import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/expense_state.dart';
import '../models/expense_model.dart';

class ExpenseTrackerList extends StatelessWidget {
  final ExpenseState state;

  const ExpenseTrackerList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Get small expenses (under RM10) from the state
    final smallExpenses = state.smallExpenses;

    if (smallExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No small expenses found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: smallExpenses.length > 3 ? 3 : smallExpenses.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final expense = smallExpenses[index];
          final cubit = context.read<ExpenseCubit>();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cubit
                  .getCategoryColor(expense.category)
                  .withOpacity(0.1),
              child: Icon(
                cubit.getCategoryIcon(expense.category),
                color: cubit.getCategoryColor(expense.category),
                size: 20,
              ),
            ),
            title: Text(
              expense.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              'RM${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
