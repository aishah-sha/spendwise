import 'dart:ui';

class BudgetCategory {
  final String name;
  final double amount;
  final double spent;
  final String iconPath;
  final Color? color;

  const BudgetCategory({
    required this.name,
    required this.amount,
    this.spent = 0.0,
    this.iconPath = '',
    this.color,
  });

  double get remaining => amount - spent;
  double get spentPercentage => amount > 0 ? (spent / amount) * 100 : 0;
  double get remainingPercentage => amount > 0 ? (remaining / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;
  bool get isNearLimit => spentPercentage >= 80 && spentPercentage < 100;
  bool get isExactBudget => spent == amount;

  String get formattedAmount => 'RM${amount.toStringAsFixed(2)}';
  String get formattedSpent => 'RM${spent.toStringAsFixed(2)}';
  String get formattedRemaining => 'RM${remaining.toStringAsFixed(2)}';

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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'spent': spent,
      'icon_path': iconPath,
      if (color != null) 'color': color!.value,
    };
  }

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      iconPath: json['icon_path'] as String? ?? '',
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
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

  // NEW: Date range fields
  final DateTime? startDate;
  final DateTime? endDate;
  final String? budgetPeriodLabel;

  const Budget({
    required this.monthlyLimit,
    required this.totalSpent,
    required this.categories,
    this.createdAt,
    this.updatedAt,
    this.currency = 'RM',
    this.startDate,
    this.endDate,
    this.budgetPeriodLabel,
  });

  // Helper getters for date range
  bool get hasDateRange => startDate != null && endDate != null;

  String get formattedDateRange {
    if (!hasDateRange) return 'No date range set';
    return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
  }

  String get shortDateRange {
    if (!hasDateRange) return '';
    return '${_formatShortDate(startDate!)} - ${_formatShortDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  // Check if a date falls within the budget period
  bool isDateInRange(DateTime date) {
    if (!hasDateRange) return true;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return dateOnly.isAfter(startOnly.subtract(const Duration(days: 1))) &&
        dateOnly.isBefore(endOnly.add(const Duration(days: 1)));
  }

  // Get remaining days in the budget period
  int get remainingDays {
    if (!hasDateRange) return 0;
    final now = DateTime.now();
    final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
    final difference = endOnly.difference(now);
    return difference.inDays + 1;
  }

  // Get total days in the budget period
  int get totalDays {
    if (!hasDateRange) return 0;
    final startOnly = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return endOnly.difference(startOnly).inDays + 1;
  }

  // Get days elapsed in the budget period
  int get daysElapsed {
    if (!hasDateRange) return 0;
    final now = DateTime.now();
    final startOnly = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final difference = now.difference(startOnly);
    return difference.inDays + 1;
  }

  // Calculate daily budget target
  double get dailyBudgetTarget {
    if (!hasDateRange || totalDays == 0)
      return monthlyLimit / 30; // fallback to 30 days
    return monthlyLimit / totalDays;
  }

  // Calculate projected total spending based on current pace
  double get projectedTotal {
    if (!hasDateRange || daysElapsed == 0) return totalSpent;
    final dailyRate = totalSpent / daysElapsed;
    return dailyRate * totalDays;
  }

  // Check if on track to meet budget
  bool get isOnTrack {
    if (!hasDateRange || totalDays == 0) return true;
    final projected = projectedTotal;
    return projected <= monthlyLimit;
  }

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

  bool get hasMonthlyBudget => monthlyLimit > 0;
  bool get hasCategories => categories.any((c) => c.amount > 0);

  String get formattedMonthlyLimit =>
      '$currency${monthlyLimit.toStringAsFixed(2)}';
  String get formattedTotalSpent => '$currency${totalSpent.toStringAsFixed(2)}';
  String get formattedRemaining =>
      '$currency${remainingBudget.toStringAsFixed(2)}';

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

  bool get isValid {
    if (monthlyLimit < 0) return false;
    if (totalSpent < 0) return false;
    for (final category in categories) {
      if (!category.isValid) return false;
    }
    return true;
  }

  BudgetCategory? getCategory(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  bool hasCategory(String name) {
    return categories.any((c) => c.name == name);
  }

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

  Budget updateCategoryAmount(String categoryName, double newAmount) {
    final updatedCategories = categories.map((category) {
      if (category.name == categoryName) {
        return category.copyWith(amount: newAmount);
      }
      return category;
    }).toList();

    return copyWith(categories: updatedCategories, updatedAt: DateTime.now());
  }

  Budget addCategory(BudgetCategory category) {
    final newCategories = List<BudgetCategory>.from(categories)..add(category);
    return copyWith(categories: newCategories, updatedAt: DateTime.now());
  }

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

  Map<String, dynamic> toJson() {
    return {
      'monthly_limit': monthlyLimit,
      'total_spent': totalSpent,
      'categories': categories.map((c) => c.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'currency': currency,
      // NEW: Date range fields
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (budgetPeriodLabel != null) 'budget_period_label': budgetPeriodLabel,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      categories: (json['categories'] as List)
          .map((c) => BudgetCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      currency: json['currency'] as String? ?? 'RM',
      // NEW: Date range fields
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      budgetPeriodLabel: json['budget_period_label'] as String?,
    );
  }

  Budget copyWith({
    double? monthlyLimit,
    double? totalSpent,
    List<BudgetCategory>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? budgetPeriodLabel,
  }) {
    return Budget(
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      totalSpent: totalSpent ?? this.totalSpent,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetPeriodLabel: budgetPeriodLabel ?? this.budgetPeriodLabel,
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
        other.currency == currency &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.budgetPeriodLabel == budgetPeriodLabel;
  }

  @override
  int get hashCode => Object.hash(
    monthlyLimit,
    totalSpent,
    Object.hashAll(categories),
    createdAt,
    updatedAt,
    currency,
    startDate,
    endDate,
    budgetPeriodLabel,
  );

  @override
  String toString() {
    return 'Budget(monthlyLimit: $monthlyLimit, totalSpent: $totalSpent, '
        'categories: $categoryCount, remaining: $remainingBudget, '
        'period: ${budgetPeriodLabel ?? "No date range"})';
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
