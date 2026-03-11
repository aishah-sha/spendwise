import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class CategoryBudgetCard extends StatelessWidget {
  final BudgetCategory category;
  final double spentAmount; // Add this parameter

  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.spentAmount, // Make it required
  });

  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final double budgetAmount = category.amount;
    final double progress = budgetAmount > 0 ? spentAmount / budgetAmount : 0;
    final double remaining = budgetAmount - spentAmount;
    final double spentPercentage = (progress * 100).clamp(0, 100);

    // Determine color based on progress
    Color progressColor = _getCategoryColor(category.name);
    if (progress >= 1.0) {
      progressColor = Colors.red;
    } else if (progress >= 0.8) {
      progressColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Category icon with gradient background
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      progressColor.withOpacity(0.2),
                      progressColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  color: progressColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Category details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkText,
                          ),
                        ),
                        Text(
                          'RM ${budgetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar with percentage
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (progress).clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        progressColor,
                                        progressColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: progressColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${spentPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Spent and remaining info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Spent amount
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Spent: RM${spentAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Remaining/Overspent indicator
                        if (remaining >= 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Left: RM${remaining.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Overspent: RM${(-remaining).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Groceries':
        return const Color(0xFF4CAF50); // Green
      case 'Food':
        return const Color(0xFFFF9800); // Orange
      case 'Beverages':
        return const Color(0xFF2196F3); // Blue
      case 'Clothes':
        return const Color(0xFF9C27B0); // Purple
      case 'Stationery':
        return const Color(0xFF009688); // Teal
      case 'Entertainment':
        return const Color(0xFFE91E63); // Pink
      case 'Transport':
        return const Color(0xFF795548); // Brown
      case 'Shopping':
        return const Color(0xFF673AB7); // Deep Purple
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Groceries':
        return Icons.shopping_cart_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Clothes':
        return Icons.shopping_bag_outlined;
      case 'Stationery':
        return Icons.edit_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Shopping':
        return Icons.local_mall_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
