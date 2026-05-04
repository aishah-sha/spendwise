// lib/models/expense_model.dart
class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String? note;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.isIncome = false,
    this.note,
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
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'ExpenseModel(id: $id, title: $title, category: $category, amount: $amount, date: $date, isIncome: $isIncome)';
  }
}
