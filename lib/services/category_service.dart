import 'package:flutter/material.dart';

class CategoryService {
  // Singleton pattern
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  // Category to Icon mapping
  static const Map<String, IconData> _categoryIcons = {
    'Groceries': Icons.shopping_cart_outlined,
    'Food': Icons.restaurant_outlined,
    'Beverages': Icons.local_cafe_outlined,
    'Clothes': Icons.shopping_bag_outlined,
    'Stationery': Icons.edit_outlined,
    'Transport': Icons.directions_car_outlined,
    'Entertainment': Icons.movie_outlined,
    'Shopping': Icons.local_mall_outlined,
    'Household': Icons.home_outlined,
    'Pet Food': Icons.pets_outlined,
    'Health': Icons.favorite_outlined,
    'Snacks & Desserts': Icons.icecream_outlined,
    'Cooking Ingredients': Icons.kitchen_outlined,
    'Baking': Icons.cake_outlined,
    'Others': Icons.category_outlined,
  };

  // Category to Color mapping (from your ExpenseCubit)
  static const Map<String, Color> _categoryColors = {
    'Groceries': Color(0xFF4CAF50),
    'Food': Color(0xFFFF9800),
    'Beverages': Color(0xFF2196F3),
    'Clothes': Color(0xFF9C27B0),
    'Stationery': Color(0xFF607D8B),
    'Transport': Color(0xFF00BCD4),
    'Entertainment': Color(0xFFE91E63),
    'Shopping': Color(0xFFFF5722),
    'Household': Color(0xFF8BC34A),
    'Pet Food': Color(0xFF795548),
    'Health': Color(0xFFF44336),
    'Snacks & Desserts': Color(0xFFFF6B6B),
    'Cooking Ingredients': Color(0xFFFFA726),
    'Baking': Color(0xFFFFB74D),
    'Others': Color(0xFF9E9E9E),
  };

  // Get icon for category
  IconData getIcon(String category) {
    return _categoryIcons[category] ?? Icons.label_outlined;
  }

  // Get color for category
  Color getColor(String category) {
    return _categoryColors[category] ?? Colors.grey;
  }

  // Get all categories
  List<String> getAllCategories() {
    return _categoryIcons.keys.toList()..sort();
  }

  // Check if category exists
  bool isValidCategory(String category) {
    return _categoryIcons.containsKey(category);
  }

  // Get category display name with icon widget
  Widget getCategoryChip(String category, {bool isDarkMode = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getColor(category).withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getColor(category).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(category), size: 14, color: getColor(category)),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              color: getColor(category),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
