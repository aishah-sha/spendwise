class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;
  final String? note;
  final String? userId;
  final String itemBreakdown; // New field for "2 Groceries +1 other"
  final int itemCount; // New field for "3 items"

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isIncome = false,
    this.note,
    this.userId,
    this.itemBreakdown = '',
    this.itemCount = 0,
  });

  // Convert to Supabase transaction format
  Map<String, dynamic> toTransactionJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'type': isIncome ? 'income' : 'expense',
      'description': title,
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'user_id': userId,
      'item_breakdown': itemBreakdown,
      'item_count': itemCount,
    };
  }

  // Create from Supabase transaction response
  factory ExpenseModel.fromTransactionJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['description'] as String? ?? '',
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isIncome: (json['type'] as String) == 'income',
      note: json['note'] as String?,
      itemBreakdown: json['item_breakdown'] as String? ?? '',
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      isIncome: json['isIncome'] ?? false,
      note: json['note'],
      itemBreakdown: json['itemBreakdown'] ?? '',
      itemCount: json['itemCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'note': note,
      'itemBreakdown': itemBreakdown,
      'itemCount': itemCount,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    bool? isIncome,
    String? note,
    String? itemBreakdown,
    int? itemCount,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      itemBreakdown: itemBreakdown ?? this.itemBreakdown,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, title: $title, category: $category, amount: $amount, date: $date, isIncome: $isIncome)';
  }
}
