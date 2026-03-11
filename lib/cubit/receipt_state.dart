part of 'receipt_cubit.dart';

enum ReceiptStatus { initial, loading, scanning, success, error }

class ReceiptState extends Equatable {
  final ReceiptStatus status;
  final ReceiptModel? receiptModel;
  final String? errorMessage;
  final List<String> detectedTexts;
  final bool isCameraInitialized;
  final bool isDialogOpen;
  final int blurryCount;
  final List<Map<String, dynamic>> scanHistory;
  final Set<String> scannedTexts;

  const ReceiptState({
    this.status = ReceiptStatus.initial,
    this.receiptModel,
    this.errorMessage,
    this.detectedTexts = const [],
    this.isCameraInitialized = false,
    this.isDialogOpen = false,
    this.blurryCount = 0,
    this.scanHistory = const [],
    this.scannedTexts = const {},
  });

  ReceiptState copyWith({
    ReceiptStatus? status,
    ReceiptModel? receiptModel,
    String? errorMessage,
    List<String>? detectedTexts,
    bool? isCameraInitialized,
    bool? isDialogOpen,
    int? blurryCount,
    List<Map<String, dynamic>>? scanHistory,
    Set<String>? scannedTexts,
  }) {
    return ReceiptState(
      status: status ?? this.status,
      receiptModel: receiptModel ?? this.receiptModel,
      errorMessage: errorMessage ?? this.errorMessage,
      detectedTexts: detectedTexts ?? this.detectedTexts,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isDialogOpen: isDialogOpen ?? this.isDialogOpen,
      blurryCount: blurryCount ?? this.blurryCount,
      scanHistory: scanHistory ?? this.scanHistory,
      scannedTexts: scannedTexts ?? this.scannedTexts,
    );
  }

  @override
  List<Object?> get props => [
    status,
    receiptModel,
    errorMessage,
    detectedTexts,
    isCameraInitialized,
    isDialogOpen,
    blurryCount,
    scanHistory,
    scannedTexts,
  ];
}
