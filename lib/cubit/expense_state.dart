import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';

class ExpenseState extends Equatable {
  final String userName;
  final DateTime currentDate;
  final double totalBalance;
  final double totalSpending;
  final double budget;
  final List<ExpenseModel> expenses;

  const ExpenseState({
    required this.userName,
    required this.currentDate,
    required this.totalBalance,
    required this.totalSpending,
    required this.budget,
    required this.expenses,
  });

  factory ExpenseState.initial() {
    return ExpenseState(
      userName: 'John',
      currentDate: DateTime.now(),
      totalBalance: 1000.00,
      totalSpending: 1000.00,
      budget: 2000.00,
      expenses: [
        ExpenseModel(
          title: 'Mydin',
          category: 'Food',
          amount: 23.00,
          date: DateTime(2025, 12, 10),
        ),
        ExpenseModel(
          title: 'Tunas Manja Group',
          category: 'Detergent',
          amount: 19.00,
          date: DateTime(2025, 12, 9),
        ),
        ExpenseModel(
          title: 'SMO Bookstore',
          category: 'Stationery',
          amount: 13.00,
          date: DateTime(2025, 12, 8),
        ),
      ],
    );
  }

  double get remaining => budget - totalSpending;
  double get budgetProgress => totalSpending / budget;

  ExpenseState copyWith({
    String? userName,
    DateTime? currentDate,
    double? totalBalance,
    double? totalSpending,
    double? budget,
    List<ExpenseModel>? expenses,
  }) {
    return ExpenseState(
      userName: userName ?? this.userName,
      currentDate: currentDate ?? this.currentDate,
      totalBalance: totalBalance ?? this.totalBalance,
      totalSpending: totalSpending ?? this.totalSpending,
      budget: budget ?? this.budget,
      expenses: expenses ?? this.expenses,
    );
  }

  @override
  List<Object?> get props => [
    userName,
    currentDate,
    totalBalance,
    totalSpending,
    budget,
    expenses,
  ];
}
