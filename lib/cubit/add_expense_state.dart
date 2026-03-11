// lib/cubit/add_expense_state.dart
import 'package:equatable/equatable.dart';
import '../models/expense_model.dart';
import '../models/receipt_model.dart';

class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final String? capturedImagePath;
  final ExpenseModel? expenseToEdit; // Add this for editing

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImagePath,
    this.expenseToEdit,
  });

  factory AddExpenseState.initial() {
    return AddExpenseState(
      recentUploads:
          [], // Start with empty list - will be populated from user data
      isLoading: false,
      errorMessage: null,
      scannedReceipt: null,
      capturedImagePath: null,
      expenseToEdit: null,
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
    );
  }

  // Helper method to add a receipt to recent uploads
  AddExpenseState addReceipt(ReceiptModel receipt) {
    final updatedList = List<ReceiptModel>.from(recentUploads);

    // Add new receipt at the beginning
    updatedList.insert(0, receipt);

    // Keep only last 20 receipts to avoid memory issues
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

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImagePath,
    expenseToEdit,
  ];
}
