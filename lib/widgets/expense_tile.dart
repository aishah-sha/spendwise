import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final dynamic
  expense; // Using dynamic since ExpenseModel might have different structure
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Check if expense has isIncome property (from your updated model)
    final bool isIncome = expense.isIncome ?? false;
    final String amountPrefix = isIncome ? '+' : '-';
    final Color amountColor = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Expense Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.category,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (expense.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Amount and Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix RM${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Button
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'detergent':
        return Icons.local_laundry_service;
      case 'stationery':
        return Icons.edit;
      case 'supplies':
        return Icons.inventory;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'detergent':
        return Colors.blue;
      case 'stationery':
        return Colors.purple;
      case 'supplies':
        return Colors.teal;
      case 'transport':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
