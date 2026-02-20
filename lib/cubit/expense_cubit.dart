import 'package:bloc/bloc.dart';
import '../models/expense_model.dart';
import 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit() : super(ExpenseState.initial());

  void addExpense(ExpenseModel expense) {
    final updatedExpenses = List<ExpenseModel>.from(state.expenses)
      ..add(expense);
    final totalSpending = updatedExpenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    emit(
      state.copyWith(expenses: updatedExpenses, totalSpending: totalSpending),
    );
  }

  void updateBudget(double newBudget) {
    emit(state.copyWith(budget: newBudget));
  }

  void setUserName(String name) {
    emit(state.copyWith(userName: name));
  }
}
