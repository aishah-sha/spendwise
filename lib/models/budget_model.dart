import 'dart:ui';

class BudgetCategory {
  final String name;
  final double amount;
  final double spent;
  final String iconPath;
  final Color? color; // Optional color for UI

  const BudgetCategory({
    required this.name,
    required this.amount,
    this.spent = 0.0,
    this.iconPath = '',
    this.color,
  });

  // Computed properties
  double get remaining => amount - spent;
  double get spentPercentage => amount > 0 ? (spent / amount) * 100 : 0;
  double get remainingPercentage => amount > 0 ? (remaining / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;
  bool get isNearLimit => spentPercentage >= 80 && spentPercentage < 100;
  bool get isExactBudget => spent == amount;

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedSpent => '\$${spent.toStringAsFixed(2)}';
  String get formattedRemaining => '\$${remaining.toStringAsFixed(2)}';

  // Validation
  bool get isValid => amount >= 0 && spent >= 0 && name.isNotEmpty;

  BudgetCategory copyWith({
    String? name,
    double? amount,
    double? spent,
    String? iconPath,
    Color? color,
  }) {
    return BudgetCategory(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      iconPath: iconPath ?? this.iconPath,
      color: color ?? this.color,
    );
  }

  // Factory method to create from JSON
  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      iconPath: json['iconPath'] as String? ?? '',
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'spent': spent,
      'iconPath': iconPath,
      if (color != null) 'color': color!.value,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetCategory &&
        other.name == name &&
        other.amount == amount &&
        other.spent == spent &&
        other.iconPath == iconPath &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(name, amount, spent, iconPath, color);

  @override
  String toString() =>
      'BudgetCategory(name: $name, amount: $amount, spent: $spent, remaining: $remaining)';
}

class Budget {
  final double monthlyLimit;
  final double totalSpent;
  final List<BudgetCategory> categories;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? currency;

  const Budget({
    required this.monthlyLimit,
    required this.totalSpent,
    required this.categories,
    this.createdAt,
    this.updatedAt,
    this.currency = 'USD',
  });

  // Computed properties
  double get remainingBudget => monthlyLimit - totalSpent;
  double get spentPercentage =>
      monthlyLimit > 0 ? (totalSpent / monthlyLimit) * 100 : 0;
  double get remainingPercentage =>
      monthlyLimit > 0 ? (remainingBudget / monthlyLimit) * 100 : 0;

  bool get isOverBudget => totalSpent > monthlyLimit;
  bool get isNearLimit => spentPercentage >= 80 && spentPercentage < 100;
  bool get isExactBudget => totalSpent == monthlyLimit;

  int get categoryCount => categories.length;
  int get overBudgetCategories =>
      categories.where((c) => c.isOverBudget).length;
  int get activeCategories => categories.where((c) => c.amount > 0).length;

  String get formattedMonthlyLimit =>
      '$currency${monthlyLimit.toStringAsFixed(2)}';
  String get formattedTotalSpent => '$currency${totalSpent.toStringAsFixed(2)}';
  String get formattedRemaining =>
      '$currency${remainingBudget.toStringAsFixed(2)}';

  // Summary statistics
  Map<String, double> get categorySpendingBreakdown {
    final breakdown = <String, double>{};
    for (final category in categories) {
      if (category.spent > 0) {
        breakdown[category.name] = category.spent;
      }
    }
    return breakdown;
  }

  Map<String, double> get categoryBudgetBreakdown {
    final breakdown = <String, double>{};
    for (final category in categories) {
      if (category.amount > 0) {
        breakdown[category.name] = category.amount;
      }
    }
    return breakdown;
  }

  // Validation
  bool get isValid {
    if (monthlyLimit <= 0) return false;
    if (totalSpent < 0) return false;

    // Check if any category is invalid
    for (final category in categories) {
      if (!category.isValid) return false;
    }

    return true;
  }

  // Get category by name
  BudgetCategory? getCategory(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  // Check if category exists
  bool hasCategory(String name) {
    return categories.any((c) => c.name == name);
  }

  // Update category spent amount
  Budget updateCategorySpent(String categoryName, double newSpent) {
    final updatedCategories = categories.map((category) {
      if (category.name == categoryName) {
        return category.copyWith(spent: newSpent);
      }
      return category;
    }).toList();

    final newTotalSpent = updatedCategories.fold(
      0.0,
      (sum, category) => sum + category.spent,
    );

    return copyWith(
      totalSpent: newTotalSpent,
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );
  }

  // Update category budget amount
  Budget updateCategoryAmount(String categoryName, double newAmount) {
    final updatedCategories = categories.map((category) {
      if (category.name == categoryName) {
        return category.copyWith(amount: newAmount);
      }
      return category;
    }).toList();

    return copyWith(categories: updatedCategories, updatedAt: DateTime.now());
  }

  // Add new category
  Budget addCategory(BudgetCategory category) {
    final newCategories = List<BudgetCategory>.from(categories)..add(category);
    return copyWith(categories: newCategories, updatedAt: DateTime.now());
  }

  // Remove category
  Budget removeCategory(String categoryName) {
    final newCategories = categories
        .where((c) => c.name != categoryName)
        .toList();
    final newTotalSpent = newCategories.fold(
      0.0,
      (sum, category) => sum + category.spent,
    );

    return copyWith(
      totalSpent: newTotalSpent,
      categories: newCategories,
      updatedAt: DateTime.now(),
    );
  }

  // Factory method to create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      categories: (json['categories'] as List)
          .map((c) => BudgetCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'monthlyLimit': monthlyLimit,
      'totalSpent': totalSpent,
      'categories': categories.map((c) => c.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'currency': currency,
    };
  }

  Budget copyWith({
    double? monthlyLimit,
    double? totalSpent,
    List<BudgetCategory>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
  }) {
    return Budget(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      totalSpent: totalSpent ?? this.totalSpent,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.monthlyLimit == monthlyLimit &&
        other.totalSpent == totalSpent &&
        listEquals(other.categories, categories) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(
    monthlyLimit,
    totalSpent,
    Object.hashAll(categories),
    createdAt,
    updatedAt,
    currency,
  );

  @override
  String toString() {
    return 'Budget(monthlyLimit: $monthlyLimit, totalSpent: $totalSpent, '
        'categories: $categoryCount, remaining: $remainingBudget)';
  }
}

// Helper function for list equality
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
