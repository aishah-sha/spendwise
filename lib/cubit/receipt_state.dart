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

  // FIXED: Added fields requested by UI components and updated cubit
  final bool isScanning;
  final bool isFlashOn;
  final int blurScore;
  final ReceiptModel? scannedReceipt;

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
    // FIXED: Initialized new fields with safe defaults
    this.isScanning = false,
    this.isFlashOn = false,
    this.blurScore = 0,
    this.scannedReceipt,
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
    // FIXED: Added to copyWith arguments
    bool? isScanning,
    bool? isFlashOn,
    int? blurScore,
    ReceiptModel? scannedReceipt,
  }) {
    return ReceiptState(
      status: status ?? this.status,
      receiptModel: receiptModel ?? this.receiptModel,
      errorMessage:
          errorMessage ?? this.errorMessage, // Clear error if explicitly null
      detectedTexts: detectedTexts ?? this.detectedTexts,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isDialogOpen: isDialogOpen ?? this.isDialogOpen,
      blurryCount: blurryCount ?? this.blurryCount,
      scanHistory: scanHistory ?? this.scanHistory,
      scannedTexts: scannedTexts ?? this.scannedTexts,
      // FIXED: Assigned copy values or state fallbacks
      isScanning: isScanning ?? this.isScanning,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      blurScore: blurScore ?? this.blurScore,
      scannedReceipt: scannedReceipt ?? this.scannedReceipt,
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
    // FIXED: Registered fields inside Equatable for change-detection evaluations
    isScanning,
    isFlashOn,
    blurScore,
    scannedReceipt,
  ];
}
