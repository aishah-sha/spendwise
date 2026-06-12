import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../models/receipt_model.dart';
import '../services/supabase_service.dart';

class AddExpenseState {
  final List<ReceiptModel> recentUploads;
  final List<ReceiptModel> multipleReceipts;
  final ReceiptModel? scannedReceipt;
  final bool isLoading;
  final String? errorMessage;
  final bool expenseSavedSuccessfully;
  final bool expenseEditedSuccessfully;
  final ExpenseModel? expenseToEdit;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;
  final String note;

  AddExpenseState({
    this.recentUploads = const [],
    this.multipleReceipts = const [],
    this.scannedReceipt,
    this.isLoading = false,
    this.errorMessage,
    this.expenseSavedSuccessfully = false,
    this.expenseEditedSuccessfully = false,
    this.expenseToEdit,
    this.title = '',
    this.amount = 0.0,
    this.category = 'Food',
    DateTime? date,
    this.isIncome = false,
    this.note = '',
  }) : date = date ?? DateTime.now();

  AddExpenseState copyWith({
    List<ReceiptModel>? recentUploads,
    List<ReceiptModel>? multipleReceipts,
    ReceiptModel? scannedReceipt,
    bool? isLoading,
    String? errorMessage,
    bool? expenseSavedSuccessfully,
    bool? expenseEditedSuccessfully,
    ExpenseModel? expenseToEdit,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isIncome,
    String? note,
  }) {
    return AddExpenseState(
      recentUploads: recentUploads ?? this.recentUploads,
      multipleReceipts: multipleReceipts ?? this.multipleReceipts,
      scannedReceipt: scannedReceipt ?? this.scannedReceipt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      expenseSavedSuccessfully:
          expenseSavedSuccessfully ?? this.expenseSavedSuccessfully,
      expenseEditedSuccessfully:
          expenseEditedSuccessfully ?? this.expenseEditedSuccessfully,
      expenseToEdit: expenseToEdit ?? this.expenseToEdit,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
    );
  }
}

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  AddExpenseCubit() : super(AddExpenseState()) {
    _loadRecentUploads();
  }

  Future<void> _loadRecentUploads() async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      final List<ReceiptModel> receipts = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => ReceiptModel.fromDatabaseJson(json))
          .toList();
      emit(state.copyWith(recentUploads: receipts));
    } catch (e) {
      print('Error loading recent uploads: $e');
    }
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void addToRecentUploads(ReceiptModel receipt) {
    final updatedList = List<ReceiptModel>.from(state.recentUploads)
      ..insert(0, receipt);
    emit(state.copyWith(recentUploads: updatedList));
  }

  void updateTitle(String title) => emit(state.copyWith(title: title));
  void updateAmount(double amount) => emit(state.copyWith(amount: amount));
  void updateCategory(String category) =>
      emit(state.copyWith(category: category));
  void updateDate(DateTime date) => emit(state.copyWith(date: date));
  void updateIsIncome(bool isIncome) =>
      emit(state.copyWith(isIncome: isIncome));
  void updateNote(String note) => emit(state.copyWith(note: note));
  void setEditingExpense(ExpenseModel expense) => setExpenseToEdit(expense);
  void setExpenseToEdit(ExpenseModel expense) {
    emit(
      state.copyWith(
        expenseToEdit: expense,
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        isIncome: expense.isIncome,
        note: expense.note ?? '',
      ),
    );
  }

  void clearScannedReceipt() =>
      emit(state.copyWith(scannedReceipt: null, multipleReceipts: const []));
  void resetSavedFlag() =>
      emit(state.copyWith(expenseSavedSuccessfully: false));
  void resetEditedFlag() =>
      emit(state.copyWith(expenseEditedSuccessfully: false));
  void viewAll() {}
}
