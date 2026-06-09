import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_model.dart';
import '../parser/receipt_parser.dart';

part 'receipt_state.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  Timer? _scanTimer;
  String? _lastScannedText;
  static const _scanDelay = Duration(
    milliseconds: 1500,
  ); // Wait for camera to stabilize

  ReceiptCubit() : super(const ReceiptState());

  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    try {
      emit(state.copyWith(status: ReceiptStatus.loading));

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(
          state.copyWith(
            status: ReceiptStatus.error,
            errorMessage: "No cameras found on device",
          ),
        );
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium, // Use medium for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Start automatic scanning when camera is ready
      _startAutoScanning();

      emit(
        state.copyWith(
          status: ReceiptStatus.initial,
          isCameraInitialized: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReceiptStatus.error,
          errorMessage: "Camera initialization failed: $e",
        ),
      );
    }
  }

  void _startAutoScanning() {
    // Listen to camera stream for automatic scanning
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Capture every 1.5 seconds for auto-scan
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanDelay, (timer) async {
      if (state.status == ReceiptStatus.scanning ||
          state.status == ReceiptStatus.success ||
          !_controller!.value.isInitialized) {
        return;
      }
      await captureAndScan();
    });
  }

  Future<void> captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Take picture
      final XFile picture = await _controller!.takePicture();
      await scanReceiptImage(picture);
    } catch (e) {
      // Ignore capture errors, will retry next cycle
      debugPrint("Auto-capture error: $e");
    }
  }

  Future<void> scanReceiptImage(XFile file) async {
    try {
      emit(state.copyWith(status: ReceiptStatus.scanning));

      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      final scannedText = recognizedText.text.trim();

      if (scannedText.isEmpty) {
        emit(
          state.copyWith(
            status: ReceiptStatus.initial,
            errorMessage: "No text detected. Please try again.",
          ),
        );
        return;
      }

      // Avoid duplicate scans of same text
      if (scannedText == _lastScannedText) {
        return;
      }
      _lastScannedText = scannedText;

      // Parse receipt
      final ReceiptModel receipt = ReceiptParser.parseRawText(
        scannedText,
        imagePath: file.path,
      );

      // Check if we found any items or a valid amount
      if ((receipt.items == null || receipt.items!.isEmpty) &&
          receipt.amount == 0.0) {
        // Update blurry count for feedback
        final newBlurryCount = state.blurryCount + 1;
        emit(
          state.copyWith(
            status: ReceiptStatus.initial,
            blurryCount: newBlurryCount,
            errorMessage: newBlurryCount > 3
                ? "Having trouble reading the receipt. Please ensure good lighting and flat surface."
                : null,
          ),
        );
        return;
      }

      // Reset blurry count on successful scan
      final updatedHistory = List<Map<String, dynamic>>.from(state.scanHistory)
        ..add({'path': file.path, 'date': DateTime.now().toIso8601String()});

      final updatedScannedTexts = Set<String>.from(state.scannedTexts)
        ..addAll(
          scannedText
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );

      emit(
        state.copyWith(
          status: ReceiptStatus.success,
          receiptModel: receipt,
          detectedTexts: scannedText.split('\n'),
          scanHistory: updatedHistory,
          scannedTexts: updatedScannedTexts,
          blurryCount: 0, // Reset on success
        ),
      );

      // Pause auto-scanning when successful
      _scanTimer?.cancel();
    } catch (e) {
      emit(
        state.copyWith(
          status: ReceiptStatus.error,
          errorMessage: "OCR processing failed: $e",
        ),
      );
    }
  }

  void resetAndRescan() {
    _lastScannedText = null;
    emit(
      state.copyWith(
        status: ReceiptStatus.initial,
        receiptModel: null,
        errorMessage: null,
        blurryCount: 0,
      ),
    );
    _startAutoScanning();
  }

  void clearError() {
    emit(state.copyWith(status: ReceiptStatus.initial, errorMessage: null));
  }

  void setBlurryCount(int count) {
    emit(state.copyWith(blurryCount: count));
  }

  void toggleDialog(bool isOpen) {
    emit(state.copyWith(isDialogOpen: isOpen));
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _textRecognizer.close();
    return super.close();
  }
}
