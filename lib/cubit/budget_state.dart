import '../models/budget_model.dart';

abstract class BudgetState {}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final Budget budget;
  BudgetLoaded(this.budget);
}

class BudgetError extends BudgetState {
  final String message;
  BudgetError(this.message);
}

class BudgetSaved extends BudgetState {
  final String message;
  BudgetSaved(this.message);
}
