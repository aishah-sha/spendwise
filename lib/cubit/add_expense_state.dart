// lib/cubit/add_expense_state.dart
import 'package:equatable/equatable.dart';
import '../models/receipt_model.dart';

class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final String? capturedImagePath;

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImagePath,
  });

  factory AddExpenseState.initial() {
    return AddExpenseState(
      recentUploads: _getMockRecentUploads(),
      isLoading: false,
      errorMessage: null,
      scannedReceipt: null,
      capturedImagePath: null,
    );
  }

  static List<ReceiptModel> _getMockRecentUploads() {
    return [
      ReceiptModel(
        id: '1',
        date: DateTime(2023, 1, 5),
        amount: 1000.00,
        receiptType: 'scan',
        merchantName: 'Tesco',
      ),
      ReceiptModel(
        id: '2',
        date: DateTime(2023, 1, 6),
        amount: 2000.00,
        receiptType: 'upload',
        merchantName: 'Giant',
      ),
      ReceiptModel(
        id: '3',
        date: DateTime(2023, 1, 7),
        amount: 3000.00,
        receiptType: 'manual',
        merchantName: 'AEON',
      ),
      ReceiptModel(
        id: '4',
        date: DateTime(2023, 1, 8),
        amount: 4000.00,
        receiptType: 'scan',
        merchantName: 'Starbucks',
      ),
      ReceiptModel(
        id: '5',
        date: DateTime(2023, 1, 9),
        amount: 5000.00,
        receiptType: 'upload',
        merchantName: 'McDonalds',
      ),
      ReceiptModel(
        id: '6',
        date: DateTime(2023, 1, 10),
        amount: 6000.00,
        receiptType: 'manual',
        merchantName: 'KFC',
      ),
      ReceiptModel(
        id: '7',
        date: DateTime(2023, 1, 11),
        amount: 7000.00,
        receiptType: 'scan',
        merchantName: 'Pizza Hut',
      ),
      ReceiptModel(
        id: '8',
        date: DateTime(2023, 1, 12),
        amount: 8000.00,
        receiptType: 'upload',
        merchantName: 'Dominos',
      ),
      ReceiptModel(
        id: '9',
        date: DateTime(2023, 1, 13),
        amount: 9000.00,
        receiptType: 'manual',
        merchantName: 'Secret Recipe',
      ),
      ReceiptModel(
        id: '10',
        date: DateTime(2023, 1, 14),
        amount: 10000.00,
        receiptType: 'scan',
        merchantName: 'Old Town',
      ),
    ];
  }

  AddExpenseState copyWith({
    List<ReceiptModel>? recentUploads,
    bool? isLoading,
    String? errorMessage,
    ReceiptModel? scannedReceipt,
    String? capturedImagePath,
  }) {
    return AddExpenseState(
      recentUploads: recentUploads ?? this.recentUploads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scannedReceipt: scannedReceipt ?? this.scannedReceipt,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
    );
  }

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImagePath,
  ];
}
