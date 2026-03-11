// lib/cubit/add_expense_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import '../services/ml_kit_service.dart';
import 'expense_cubit.dart'; // Add this import

// State
class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final File? capturedImage;
  final ExpenseModel? expenseToEdit;

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImage,
    this.expenseToEdit,
  });

  factory AddExpenseState.initial() {
    return AddExpenseState(
      recentUploads: [], // Start with empty list
      isLoading: false,
      errorMessage: null,
      scannedReceipt: null,
      capturedImage: null,
      expenseToEdit: null,
    );
  }

  AddExpenseState copyWith({
    List<ReceiptModel>? recentUploads,
    bool? isLoading,
    String? errorMessage,
    ReceiptModel? scannedReceipt,
    File? capturedImage,
    ExpenseModel? expenseToEdit,
    bool clearExpenseToEdit = false,
  }) {
    return AddExpenseState(
      recentUploads: recentUploads ?? this.recentUploads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      scannedReceipt: scannedReceipt,
      capturedImage: capturedImage,
      expenseToEdit: clearExpenseToEdit
          ? null
          : (expenseToEdit ?? this.expenseToEdit),
    );
  }

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImage,
    expenseToEdit,
  ];
}

// Cubit
class AddExpenseCubit extends Cubit<AddExpenseState> {
  final MLKitService _mlKitService = MLKitService();

  // Form fields for manual entry
  String title = '';
  String category = 'Food';
  double amount = 0.0;
  DateTime date = DateTime.now();
  bool isIncome = false;
  String? note;

  // Constructor with optional expense to edit
  AddExpenseCubit({ExpenseModel? expenseToEdit})
    : super(AddExpenseState.initial()) {
    if (expenseToEdit != null) {
      // Initialize with expense data for editing
      _initializeWithExpense(expenseToEdit);
      emit(state.copyWith(expenseToEdit: expenseToEdit));
    }
  }

  // Initialize form fields with expense data for editing
  void _initializeWithExpense(ExpenseModel expense) {
    title = expense.title;
    category = expense.category;
    amount = expense.amount;
    date = expense.date;
    isIncome = expense.isIncome ?? false;
    note = expense.note;
  }

  // Form field update methods
  void updateTitle(String value) {
    title = value;
  }

  void updateCategory(String value) {
    category = value;
  }

  void updateAmount(double value) {
    amount = value;
  }

  void updateDate(DateTime value) {
    date = value;
  }

  void updateIsIncome(bool value) {
    isIncome = value;
  }

  void updateNote(String value) {
    note = value;
  }

  // Reset form fields
  void resetForm() {
    title = '';
    category = 'Food';
    amount = 0.0;
    date = DateTime.now();
    isIncome = false;
    note = null;
    emit(
      state.copyWith(
        expenseToEdit: null,
        scannedReceipt: null,
        capturedImage: null,
      ),
    );
  }

  // Add receipt to recent uploads
  void addReceipt(ReceiptModel receipt) {
    final updatedUploads = List<ReceiptModel>.from(state.recentUploads);

    // Check if receipt already exists (avoid duplicates)
    final existingIndex = updatedUploads.indexWhere((r) => r.id == receipt.id);
    if (existingIndex != -1) {
      // Replace existing
      updatedUploads[existingIndex] = receipt;
    } else {
      // Add new at the beginning
      updatedUploads.insert(0, receipt);
    }

    // Keep only the 20 most recent uploads
    if (updatedUploads.length > 20) {
      updatedUploads.removeLast();
    }

    emit(state.copyWith(recentUploads: updatedUploads, isLoading: false));
  }

  // Remove receipt from recent uploads
  void removeReceipt(String receiptId) {
    final updatedUploads = state.recentUploads
        .where((r) => r.id != receiptId)
        .toList();
    emit(state.copyWith(recentUploads: updatedUploads));
  }

  // Clear all recent uploads
  void clearRecentUploads() {
    emit(state.copyWith(recentUploads: []));
  }

  Future<void> scanReceipt() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Pick image from camera
      final XFile? image = await _mlKitService.pickImageFromCamera();

      if (image == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Camera cancelled or no image captured',
          ),
        );
        return;
      }

      final File imageFile = File(image.path);
      emit(state.copyWith(capturedImage: imageFile, isLoading: true));

      // Process with ML Kit
      final receiptData = await _mlKitService.processReceiptImage(imageFile);

      // Handle items safely
      List<ReceiptItem> items = [];
      if (receiptData['items'] != null) {
        try {
          items = (receiptData['items'] as List).map((item) {
            return ReceiptItem(
              name: item['name']?.toString() ?? '',
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              category: item['category']?.toString() ?? 'Food',
            );
          }).toList();
        } catch (e) {
          print('Error parsing items: $e');
        }
      }

      // Create receipt model from scanned data
      final scannedReceipt = ReceiptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: (receiptData['totalAmount'] as num?)?.toDouble() ?? 0.0,
        imagePath: image.path,
        receiptType: 'scan',
        merchantName:
            receiptData['merchantName']?.toString() ?? 'Unknown Store',
        items: items,
      );

      // Auto-fill form fields with scanned data
      title = scannedReceipt.merchantName ?? '';
      amount = scannedReceipt.amount;

      emit(
        state.copyWith(
          isLoading: false,
          scannedReceipt: scannedReceipt,
          errorMessage: scannedReceipt.amount == 0.0
              ? 'Could not detect amount. Please verify and edit.'
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Error scanning receipt: $e',
        ),
      );
    }
  }

  Future<void> uploadImage() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Pick image from gallery
      final XFile? image = await _mlKitService.pickImageFromGallery();

      if (image == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'No image selected'),
        );
        return;
      }

      final File imageFile = File(image.path);
      emit(state.copyWith(capturedImage: imageFile, isLoading: true));

      // Process with ML Kit
      final receiptData = await _mlKitService.processReceiptImage(imageFile);

      // Handle items safely
      List<ReceiptItem> items = [];
      if (receiptData['items'] != null) {
        try {
          items = (receiptData['items'] as List).map((item) {
            return ReceiptItem(
              name: item['name']?.toString() ?? '',
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
              category: item['category']?.toString() ?? 'Food',
            );
          }).toList();
        } catch (e) {
          print('Error parsing items: $e');
        }
      }

      // Create receipt model from processed data
      final scannedReceipt = ReceiptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        amount: (receiptData['totalAmount'] as num?)?.toDouble() ?? 0.0,
        imagePath: image.path,
        receiptType: 'upload',
        merchantName:
            receiptData['merchantName']?.toString() ?? 'Unknown Store',
        items: items,
      );

      // Auto-fill form fields
      title = scannedReceipt.merchantName ?? '';
      amount = scannedReceipt.amount;

      emit(
        state.copyWith(
          isLoading: false,
          scannedReceipt: scannedReceipt,
          errorMessage: scannedReceipt.amount == 0.0
              ? 'Could not detect amount. Please verify and edit.'
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Error uploading image: $e',
        ),
      );
    }
  }

  void manualEntry() {
    emit(
      state.copyWith(
        isLoading: false,
        scannedReceipt: ReceiptModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          amount: 0.0,
          receiptType: 'manual',
          merchantName: '',
          items: [],
        ),
      ),
    );
  }

  void confirmManualEntry(double amount, String merchantName) {
    this.amount = amount;
    title = merchantName;

    final receipt = ReceiptModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: amount,
      receiptType: 'manual',
      merchantName: merchantName,
      imagePath: state.capturedImage?.path,
      items: [],
    );

    emit(state.copyWith(scannedReceipt: receipt, isLoading: false));
  }

  void clearScannedReceipt() {
    emit(
      state.copyWith(
        scannedReceipt: null,
        errorMessage: null,
        capturedImage: null,
      ),
    );
  }

  void viewAll() {
    // This would navigate to a screen showing all receipts
    // For now, just emit a state that could be listened to
    emit(state.copyWith(errorMessage: null));
  }

  // Save expense (add or update)
  Future<void> saveExpense(ExpenseCubit expenseCubit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Validate
      if (title.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Please enter a title',
          ),
        );
        return;
      }

      if (amount <= 0) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Please enter a valid amount',
          ),
        );
        return;
      }

      // Create expense model
      final expense = ExpenseModel(
        id:
            state.expenseToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: category,
        amount: amount,
        date: date,
        isIncome: isIncome,
        note:
            note ??
            (state.scannedReceipt?.items != null &&
                    state.scannedReceipt!.items!.isNotEmpty
                ? '${state.scannedReceipt!.items!.length} items'
                : null),
      );

      // Save to ExpenseCubit (for Dashboard and History)
      if (state.expenseToEdit != null) {
        expenseCubit.updateExpense(expense);
      } else {
        expenseCubit.addExpense(expense);
      }

      // Create receipt for recent uploads
      final receipt = ReceiptModel(
        id: expense.id,
        date: expense.date,
        amount: expense.amount,
        receiptType: state.scannedReceipt?.receiptType ?? 'manual',
        merchantName: expense.title,
        items: state.scannedReceipt?.items ?? [],
        imagePath: state.capturedImage?.path ?? state.scannedReceipt?.imagePath,
      );

      // Add to recent uploads
      addReceipt(receipt);

      // Clear editing state
      resetForm();

      emit(state.copyWith(isLoading: false, errorMessage: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Error saving expense: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _mlKitService.dispose();
    return super.close();
  }
}
