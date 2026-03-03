// lib/cubit/add_expense_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_model.dart';
import '../services/ml_kit_service.dart';

// State
class AddExpenseState extends Equatable {
  final List<ReceiptModel> recentUploads;
  final bool isLoading;
  final String? errorMessage;
  final ReceiptModel? scannedReceipt;
  final File? capturedImage;

  const AddExpenseState({
    required this.recentUploads,
    required this.isLoading,
    this.errorMessage,
    this.scannedReceipt,
    this.capturedImage,
  });

  factory AddExpenseState.initial() {
    return AddExpenseState(
      recentUploads: _getMockRecentUploads(),
      isLoading: false,
      errorMessage: null,
      scannedReceipt: null,
      capturedImage: null,
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
    File? capturedImage,
  }) {
    return AddExpenseState(
      recentUploads: recentUploads ?? this.recentUploads,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      scannedReceipt: scannedReceipt ?? this.scannedReceipt,
      capturedImage: capturedImage ?? this.capturedImage,
    );
  }

  @override
  List<Object?> get props => [
    recentUploads,
    isLoading,
    errorMessage,
    scannedReceipt,
    capturedImage,
  ];
}

// Cubit
class AddExpenseCubit extends Cubit<AddExpenseState> {
  final MLKitService _mlKitService = MLKitService();

  AddExpenseCubit() : super(AddExpenseState.initial());

  void addReceipt(ReceiptModel receipt) {
    final updatedUploads = List<ReceiptModel>.from(state.recentUploads)
      ..insert(0, receipt);

    // Keep only the 10 most recent uploads
    if (updatedUploads.length > 10) {
      updatedUploads.removeLast();
    }

    emit(
      state.copyWith(
        recentUploads: updatedUploads,
        scannedReceipt: null,
        capturedImage: null,
      ),
    );
  }

  Future<void> scanReceipt() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Pick image from camera
      final XFile? image = await _mlKitService.pickImageFromCamera();

      if (image == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: 'No image captured'),
        );
        return;
      }

      final File imageFile = File(image.path);
      emit(state.copyWith(capturedImage: imageFile));

      // Process with ML Kit
      final receiptData = await _mlKitService.processReceiptImage(imageFile);

      if (receiptData['totalAmount'] == 0.0) {
        // If scanning failed, show manual entry dialog with extracted text
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Could not detect amount. Please enter manually.',
            scannedReceipt: ReceiptModel(
              id: DateTime.now().toString(),
              date: DateTime.now(),
              amount: 0.0,
              imagePath: image.path,
              receiptType: 'scan',
              merchantName: receiptData['merchantName'],
            ),
          ),
        );
      } else {
        // Successfully scanned
        final newReceipt = ReceiptModel(
          id: DateTime.now().toString(),
          date: DateTime.now(),
          amount: receiptData['totalAmount'],
          imagePath: image.path,
          receiptType: 'scan',
          merchantName: receiptData['merchantName'],
          items: receiptData['items']
              ?.map(
                (item) => ReceiptItem(
                  name: item['name'],
                  price: item['price'],
                  quantity: item['quantity'],
                ),
              )
              .toList(),
        );

        addReceipt(newReceipt);
        emit(state.copyWith(isLoading: false));
      }
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
      emit(state.copyWith(capturedImage: imageFile));

      // Process with ML Kit
      final receiptData = await _mlKitService.processReceiptImage(imageFile);

      if (receiptData['totalAmount'] == 0.0) {
        // If processing failed, show manual entry dialog with extracted text
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Could not detect amount. Please enter manually.',
            scannedReceipt: ReceiptModel(
              id: DateTime.now().toString(),
              date: DateTime.now(),
              amount: 0.0,
              imagePath: image.path,
              receiptType: 'upload',
              merchantName: receiptData['merchantName'],
            ),
          ),
        );
      } else {
        // Successfully processed
        final newReceipt = ReceiptModel(
          id: DateTime.now().toString(),
          date: DateTime.now(),
          amount: receiptData['totalAmount'],
          imagePath: image.path,
          receiptType: 'upload',
          merchantName: receiptData['merchantName'],
          items: receiptData['items']
              ?.map(
                (item) => ReceiptItem(
                  name: item['name'],
                  price: item['price'],
                  quantity: item['quantity'],
                ),
              )
              .toList(),
        );

        addReceipt(newReceipt);
        emit(state.copyWith(isLoading: false));
      }
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
          id: DateTime.now().toString(),
          date: DateTime.now(),
          amount: 0.0,
          receiptType: 'manual',
        ),
      ),
    );
  }

  void confirmManualEntry(double amount, String merchantName) {
    final newReceipt = ReceiptModel(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      amount: amount,
      receiptType: 'manual',
      merchantName: merchantName,
      imagePath: state.capturedImage?.path,
    );

    addReceipt(newReceipt);
  }

  void clearScannedReceipt() {
    emit(state.copyWith(scannedReceipt: null, errorMessage: null));
  }

  void viewAll() {
    // Navigate to all receipts screen
  }

  @override
  Future<void> close() {
    _mlKitService.dispose();
    return super.close();
  }
}
