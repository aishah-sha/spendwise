import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class CategoryBudgetCard extends StatelessWidget {
  final BudgetCategory category;
  final double spentAmount;
  final bool isDarkMode;

  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.spentAmount,
    this.isDarkMode = false,
  });

  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final double budgetAmount = category.amount;
    final double progress = budgetAmount > 0 ? spentAmount / budgetAmount : 0;
    final double remaining = budgetAmount - spentAmount;
    final double spentPercentage = progress * 100;

    // Determine color based on progress
    Color progressColor = _getCategoryColor(category.name);
    String statusText = _getStatusText(progress);

    if (progress >= 1.0) {
      progressColor = Colors.red;
      statusText = 'Over Limit';
    } else if (progress >= 0.8) {
      progressColor = Colors.orange;
      statusText = 'Near Limit';
    } else if (progress >= 0.5) {
      statusText = 'Moderate';
    } else if (progress > 0) {
      statusText = 'Good';
    } else {
      statusText = 'On Track';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  progressColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                  progressColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(category.name),
              color: progressColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Category details - Expanded to take remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Category name and status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : darkText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(
                          isDarkMode ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Budget amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white60 : Colors.grey,
                      ),
                    ),
                    Text(
                      'RM ${budgetAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Row 3: Spent amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 11,
                        color: progress >= 1.0
                            ? Colors.red
                            : (isDarkMode ? Colors.white60 : Colors.grey),
                      ),
                    ),
                    Text(
                      'RM ${spentAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: progress >= 1.0
                            ? Colors.red
                            : (isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar with percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(
                          isDarkMode ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${spentPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Remaining/Overspent indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: remaining >= 0
                        ? (isDarkMode
                              ? const Color(0xFF2196F3).withOpacity(0.15)
                              : const Color(0xFF2196F3).withOpacity(0.08))
                        : (isDarkMode
                              ? Colors.red.withOpacity(0.15)
                              : Colors.red.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            remaining >= 0
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: remaining >= 0
                                ? const Color(0xFF2196F3)
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            remaining >= 0 ? 'Remaining' : 'Overspent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: remaining >= 0
                                  ? const Color(0xFF2196F3)
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Text(
                          'RM ${remaining >= 0 ? remaining.toStringAsFixed(2) : (-remaining).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: remaining >= 0
                                ? const Color(0xFF2196F3)
                                : Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Warning if significantly over budget
                if (progress > 1.2) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.red.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Exceeded by ${((progress - 1) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(double progress) {
    if (progress >= 1.0) return 'Over Limit';
    if (progress >= 0.8) return 'Near Limit';
    if (progress >= 0.5) return 'Moderate';
    if (progress > 0) return 'Good';
    return 'On Track';
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Groceries':
        return const Color(0xFF4CAF50);
      case 'Food':
        return const Color(0xFFFF9800);
      case 'Beverages':
        return const Color(0xFF2196F3);
      case 'Clothes':
        return const Color(0xFF9C27B0);
      case 'Stationery':
        return const Color(0xFF009688);
      case 'Entertainment':
        return const Color(0xFFE91E63);
      case 'Transport':
        return const Color(0xFF795548);
      case 'Shopping':
        return const Color(0xFF673AB7);
      default:
        return accentGreen;
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
