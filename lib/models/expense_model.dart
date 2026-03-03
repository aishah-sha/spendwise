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
