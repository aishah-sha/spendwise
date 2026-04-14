import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../models/receipt_model.dart';

class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final String? capturedImagePath;
  final ExpenseModel? expenseToEdit;
  final bool expenseSavedSuccessfully;
  final bool expenseEditedSuccessfully;
  final List<ReceiptModel> multipleReceipts;
  final int currentReceiptIndex;

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImagePath,
    this.expenseToEdit,
    this.expenseSavedSuccessfully = false,
    this.expenseEditedSuccessfully = false,
    this.multipleReceipts = const [],
    this.currentReceiptIndex = 0,
  });

  factory AddExpenseState.initial() {
    return AddExpenseState(
      recentUploads: [],
      isLoading: false,
      errorMessage: null,
      scannedReceipt: null,
      capturedImagePath: null,
      expenseToEdit: null,
      expenseSavedSuccessfully: false,
      expenseEditedSuccessfully: false,
      multipleReceipts: [],
      currentReceiptIndex: 0,
    );
  }

  AddExpenseState copyWith({
    List<ReceiptModel>? recentUploads,
    bool? isLoading,
    String? errorMessage,
    ReceiptModel? scannedReceipt,
    String? capturedImagePath,
    ExpenseModel? expenseToEdit,
    bool clearExpenseToEdit = false,
    bool? expenseSavedSuccessfully,
    bool? expenseEditedSuccessfully,
    List<ReceiptModel>? multipleReceipts,
    int? currentReceiptIndex,
  }) {
    return AddExpenseState(
      recentUploads: recentUploads ?? this.recentUploads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scannedReceipt: scannedReceipt ?? this.scannedReceipt,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      expenseToEdit: clearExpenseToEdit
          ? null
          : (expenseToEdit ?? this.expenseToEdit),
      expenseSavedSuccessfully:
          expenseSavedSuccessfully ?? this.expenseSavedSuccessfully,
      expenseEditedSuccessfully:
          expenseEditedSuccessfully ?? this.expenseEditedSuccessfully,
      multipleReceipts: multipleReceipts ?? this.multipleReceipts,
      currentReceiptIndex: currentReceiptIndex ?? this.currentReceiptIndex,
    );
  }

  // Helper method to add a receipt to recent uploads
  AddExpenseState addReceipt(ReceiptModel receipt) {
    final updatedList = List<ReceiptModel>.from(recentUploads);
    updatedList.insert(0, receipt);
    if (updatedList.length > 20) {
      updatedList.removeLast();
    }
    return copyWith(recentUploads: updatedList);
  }

  // Helper method to remove a receipt from recent uploads
  AddExpenseState removeReceipt(String receiptId) {
    final updatedList = recentUploads.where((r) => r.id != receiptId).toList();
    return copyWith(recentUploads: updatedList);
  }

  // Helper method to clear all recent uploads
  AddExpenseState clearRecentUploads() {
    return copyWith(recentUploads: []);
  }

  // Helper method to get next receipt from multiple uploads
  ReceiptModel? getNextReceipt() {
    if (currentReceiptIndex + 1 < multipleReceipts.length) {
      return multipleReceipts[currentReceiptIndex + 1];
    }
    return null;
  }

  // Helper method to advance to next receipt
  AddExpenseState advanceToNextReceipt() {
    if (currentReceiptIndex + 1 < multipleReceipts.length) {
      return copyWith(
        currentReceiptIndex: currentReceiptIndex + 1,
        scannedReceipt: multipleReceipts[currentReceiptIndex + 1],
      );
    }
    return copyWith(
      multipleReceipts: [],
      currentReceiptIndex: 0,
      scannedReceipt: null,
    );
  }

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImagePath,
    expenseToEdit,
    expenseSavedSuccessfully,
    expenseEditedSuccessfully,
    multipleReceipts,
    currentReceiptIndex,
  ];
}
