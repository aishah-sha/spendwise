import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import '../services/ml_kit_service.dart';
import 'expense_cubit.dart';
import '../services/image_picker_service.dart';

// State
class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final File? capturedImage;
  final ExpenseModel? expenseToEdit;
  final bool expenseSavedSuccessfully;
  final bool expenseEditedSuccessfully;
  final List<ReceiptModel> multipleReceipts; // For multiple uploads
  final int currentReceiptIndex; // Track which receipt is being processed

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImage,
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
      capturedImage: null,
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
    File? capturedImage,
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
      scannedReceipt: scannedReceipt,
      capturedImage: capturedImage ?? this.capturedImage,
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

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImage,
    expenseToEdit,
    expenseSavedSuccessfully,
    expenseEditedSuccessfully,
    multipleReceipts,
    currentReceiptIndex,
  ];
}

// Cubit
class AddExpenseCubit extends Cubit<AddExpenseState> {
  final MLKitService _mlKitService = MLKitService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  static const String _receiptsStorageKey = 'recent_receipts';

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
      _initializeWithExpense(expenseToEdit);
      emit(state.copyWith(expenseToEdit: expenseToEdit));
    }
    _loadSavedReceipts();
  }

  // Load receipts from SharedPreferences
  Future<void> _loadSavedReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? receiptsJson = prefs.getString(_receiptsStorageKey);

      if (receiptsJson != null && receiptsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(receiptsJson);
        final List<ReceiptModel> receipts = decoded
            .map((item) => ReceiptModel.fromJson(item as Map<String, dynamic>))
            .toList();

        emit(state.copyWith(recentUploads: receipts));
      }
    } catch (e) {
      print('Error loading saved receipts: $e');
    }
  }

  // Save receipts to SharedPreferences
  Future<void> _saveReceiptsToStorage(List<ReceiptModel> receipts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> encoded = receipts
          .map((r) => r.toJson())
          .toList();
      await prefs.setString(_receiptsStorageKey, json.encode(encoded));
    } catch (e) {
      print('Error saving receipts: $e');
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

  // Reset saved flags
  void resetSavedFlag() {
    emit(state.copyWith(expenseSavedSuccessfully: false));
  }

  void resetEditedFlag() {
    emit(state.copyWith(expenseEditedSuccessfully: false));
  }

  // Add receipt to recent uploads
  Future<void> addReceipt(ReceiptModel receipt) async {
    final updatedUploads = List<ReceiptModel>.from(state.recentUploads);

    final existingIndex = updatedUploads.indexWhere((r) => r.id == receipt.id);
    if (existingIndex != -1) {
      updatedUploads[existingIndex] = receipt;
    } else {
      updatedUploads.insert(0, receipt);
    }

    if (updatedUploads.length > 20) {
      updatedUploads.removeLast();
    }

    await _saveReceiptsToStorage(updatedUploads);
    emit(state.copyWith(recentUploads: updatedUploads, isLoading: false));
  }

  // Remove receipt from recent uploads
  Future<void> removeReceipt(String receiptId) async {
    final updatedUploads = state.recentUploads
        .where((r) => r.id != receiptId)
        .toList();

    await _saveReceiptsToStorage(updatedUploads);
    emit(state.copyWith(recentUploads: updatedUploads));
  }

  // Clear all recent uploads
  Future<void> clearRecentUploads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_receiptsStorageKey);
    emit(state.copyWith(recentUploads: []));
  }

  void clearMultipleReceipts() {
    emit(state.copyWith(multipleReceipts: [], currentReceiptIndex: 0));
  }

  // NEW: Upload multiple images at once
  Future<void> uploadMultipleImages() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Pick multiple images from gallery
      final List<XFile>? images = await ImagePicker().pickMultiImage();

      if (images == null || images.isEmpty) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'No images selected'),
        );
        return;
      }

      List<ReceiptModel> processedReceipts = [];

      for (XFile image in images) {
        final File imageFile = File(image.path);

        // Process each image with ML Kit
        final receiptData = await _mlKitService.processReceiptImage(imageFile);

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

        final scannedReceipt = ReceiptModel(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              '_${processedReceipts.length}',
          date: DateTime.now(),
          amount: (receiptData['totalAmount'] as num?)?.toDouble() ?? 0.0,
          imagePath: image.path,
          receiptType: 'upload',
          merchantName:
              receiptData['merchantName']?.toString() ?? 'Unknown Store',
          items: items,
        );

        processedReceipts.add(scannedReceipt);
      }

      // Save all processed receipts to recent uploads
      for (var receipt in processedReceipts) {
        await addReceipt(receipt);
      }

      emit(
        state.copyWith(
          isLoading: false,
          multipleReceipts: processedReceipts,
          errorMessage: processedReceipts.length > 0
              ? 'Successfully processed ${processedReceipts.length} receipts'
              : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Error uploading multiple images: $e',
        ),
      );
    }
  }

  // NEW: Upload single image (original method but improved)
  Future<void> uploadImage() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final File? image = await _imagePickerService.pickImageFromGallery();

      if (image == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'No image selected'),
        );
        return;
      }

      emit(state.copyWith(capturedImage: image, isLoading: true));

      final receiptData = await _mlKitService.processReceiptImage(image);

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

  Future<void> scanReceipt() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
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

      final receiptData = await _mlKitService.processReceiptImage(imageFile);

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
    emit(state.copyWith(errorMessage: null));
  }

  // Save expense (add or update) - UPDATED with success flags
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

      // Save to ExpenseCubit
      if (state.expenseToEdit != null) {
        expenseCubit.updateExpense(expense);
        // Set success flag for edit
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: null,
            expenseEditedSuccessfully: true,
          ),
        );
      } else {
        expenseCubit.addExpense(expense);
        // Set success flag for save
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: null,
            expenseSavedSuccessfully: true,
          ),
        );
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
        tax: state.scannedReceipt?.tax,
        subtotal: state.scannedReceipt?.subtotal,
        serviceCharge: state.scannedReceipt?.serviceCharge,
        category: category,
        currency: 'RM',
        ocrStatus: state.scannedReceipt?.ocrStatus,
      );

      await addReceipt(receipt);
      resetForm();
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
