import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart'; // ADD THIS
import '../models/expense_model.dart';
import '../models/receipt_model.dart';
import '../services/supabase_service.dart';

// State class (same as before - no changes needed)
class AddExpenseState {
  final List<ReceiptModel> recentUploads;
  final List<ReceiptModel> multipleReceipts;
  final ReceiptModel? scannedReceipt;
  final bool isLoading;
  final String? errorMessage;
  final bool expenseSavedSuccessfully;
  final bool expenseEditedSuccessfully;
  final ExpenseModel? expenseToEdit;

  // These fields for editing
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

// Cubit class
class AddExpenseCubit extends Cubit<AddExpenseState> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid(); // ADD THIS

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  AddExpenseCubit() : super(AddExpenseState()) {
    _loadRecentUploads();
  }

  Future<void> _loadRecentUploads() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('No user logged in, cannot load receipts');
      return;
    }

    try {
      print('Loading receipts for user: $userId');

      final response = await Supabase.instance.client
          .from('receipts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      print('Found ${response.length} receipts for user');

      final receipts = (response as List).map((json) {
        return ReceiptModel.fromDatabaseJson(json);
      }).toList();

      emit(state.copyWith(recentUploads: receipts));
    } catch (e) {
      print('Error loading recent uploads: $e');
    }
  }

  // Set loading state dynamically from UI layers
  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  // Prepend a receipt directly onto the active state list
  void addToRecentUploads(ReceiptModel receipt) {
    final updatedList = List<ReceiptModel>.from(state.recentUploads)
      ..insert(0, receipt);
    emit(state.copyWith(recentUploads: updatedList));
  }

  // Update title for editing
  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  // Update amount for editing
  void updateAmount(double amount) {
    emit(state.copyWith(amount: amount));
  }

  // Update category for editing
  void updateCategory(String category) {
    emit(state.copyWith(category: category));
  }

  // Update date for editing
  void updateDate(DateTime date) {
    emit(state.copyWith(date: date));
  }

  // Update isIncome for editing
  void updateIsIncome(bool isIncome) {
    emit(state.copyWith(isIncome: isIncome));
  }

  // Update note for editing
  void updateNote(String note) {
    emit(state.copyWith(note: note));
  }

  // Set expense to edit
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

  // Add receipt to recent uploads
  Future<void> addReceipt(ReceiptModel receipt) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Save to database
      final receiptWithUserId = receipt.copyWith(userId: userId);
      await Supabase.instance.client
          .from('receipts')
          .insert(receiptWithUserId.toDatabaseJson());

      // Reload recent uploads
      await _loadRecentUploads();
    } catch (e) {
      print('Error adding receipt: $e');
    }
  }

  Future<void> uploadImage() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      final userId = _currentUserId;
      if (userId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'User not authenticated',
          ),
        );
        return;
      }

      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'receipts/$userId/$fileName';

      await Supabase.instance.client.storage
          .from('receipts')
          .upload(filePath, file);

      final imageUrl = Supabase.instance.client.storage
          .from('receipts')
          .getPublicUrl(filePath);

      // FIXED: Use UUID instead of timestamp
      final receipt = ReceiptModel(
        id: _uuid.v4(), // ✅ CHANGED
        date: DateTime.now(),
        amount: 0.0,
        receiptType: 'image',
        imagePath: imageUrl,
        merchantName: null,
        userId: userId,
        processed: false,
      );

      await Supabase.instance.client
          .from('receipts')
          .insert(receipt.toDatabaseJson());

      await _loadRecentUploads();

      emit(state.copyWith(isLoading: false, scannedReceipt: receipt));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload image: $e',
        ),
      );
    }
  }

  Future<void> uploadMultipleImages() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      final userId = _currentUserId;
      if (userId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'User not authenticated',
          ),
        );
        return;
      }

      final List<ReceiptModel> receipts = [];

      for (XFile image in images) {
        final file = File(image.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final filePath = 'receipts/$userId/$fileName';

        await Supabase.instance.client.storage
            .from('receipts')
            .upload(filePath, file);

        final imageUrl = Supabase.instance.client.storage
            .from('receipts')
            .getPublicUrl(filePath);

        // FIXED: Use UUID instead of timestamp
        final receipt = ReceiptModel(
          id: _uuid.v4(), // ✅ CHANGED
          date: DateTime.now(),
          amount: 0.0,
          receiptType: 'image',
          imagePath: imageUrl,
          merchantName: null,
          userId: userId,
          processed: false,
        );

        await Supabase.instance.client
            .from('receipts')
            .insert(receipt.toDatabaseJson());
        receipts.add(receipt);
      }

      await _loadRecentUploads();

      emit(state.copyWith(isLoading: false, multipleReceipts: receipts));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload multiple images: $e',
        ),
      );
    }
  }

  Future<void> confirmManualEntry(double amount, String merchantName) async {
    final receipt = state.scannedReceipt;
    if (receipt == null) return;

    final userId = _currentUserId;
    if (userId == null) return;

    final updatedReceipt = receipt.copyWith(
      amount: amount,
      merchantName: merchantName,
    );

    await Supabase.instance.client
        .from('receipts')
        .update({'amount': amount, 'merchant_name': merchantName})
        .eq('id', receipt.id)
        .eq('user_id', userId);

    await _loadRecentUploads();

    emit(state.copyWith(scannedReceipt: updatedReceipt));
  }

  Future<void> saveExpenseFromReceipt({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required String note,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final userId = _currentUserId;
      if (userId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'User not authenticated',
          ),
        );
        return;
      }

      // FIXED: Use UUID for expense ID too
      final expense = ExpenseModel(
        id: _uuid.v4(), // ✅ CHANGED
        title: title,
        amount: amount,
        category: category,
        date: date,
        isIncome: false,
        note: note,
        userId: userId,
      );

      await _supabaseService.addTransaction(
        amount: expense.amount,
        category: expense.category,
        type: 'expense',
        description: expense.title,
        date: expense.date,
      );

      final receipt = state.scannedReceipt;
      if (receipt != null) {
        await Supabase.instance.client
            .from('receipts')
            .update({'processed': true, 'expense_id': expense.id})
            .eq('id', receipt.id)
            .eq('user_id', userId);
      }

      await _loadRecentUploads();

      emit(
        state.copyWith(
          isLoading: false,
          expenseSavedSuccessfully: true,
          scannedReceipt: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to save expense: $e',
        ),
      );
    }
  }

  // Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    emit(state.copyWith(isLoading: true));

    try {
      final userId = _currentUserId;
      if (userId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'User not authenticated',
          ),
        );
        return;
      }

      await _supabaseService.updateTransaction(expense.id, {
        'amount': expense.amount,
        'category': expense.category,
        'description': expense.title,
        'type': expense.isIncome ? 'income' : 'expense',
        'date': expense.date.toIso8601String(),
      });

      emit(
        state.copyWith(
          isLoading: false,
          expenseEditedSuccessfully: true,
          expenseToEdit: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update expense: $e',
        ),
      );
    }
  }

  void clearScannedReceipt() {
    emit(state.copyWith(scannedReceipt: null, multipleReceipts: const []));
  }

  void resetSavedFlag() {
    emit(state.copyWith(expenseSavedSuccessfully: false));
  }

  void resetEditedFlag() {
    emit(state.copyWith(expenseEditedSuccessfully: false));
  }

  void viewAll() {
    // Navigate to all receipts screen
  }
}
