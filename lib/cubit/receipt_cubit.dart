import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../models/receipt_model.dart';
import '../../parser/receipt_parser.dart';

// ALL imports must be here, not in the part file
part 'receipt_state.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  DateTime _lastProcessed = DateTime.now();
  final int _processIntervalMs = 2000;
  final int _maxHistorySize = 5;
  final double _minConfidence = 0.1;

  CameraController? get controller => _controller;

  ReceiptCubit() : super(const ReceiptState());

  @override
  Future<void> close() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _textRecognizer.close();
    return super.close();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(
          state.copyWith(
            errorMessage: "No cameras available",
            status: ReceiptStatus.error,
          ),
        );
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.startImageStream(_processCameraImage);

      emit(
        state.copyWith(
          isCameraInitialized: true,
          status: ReceiptStatus.initial,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "Camera initialization error: $e",
          status: ReceiptStatus.error,
        ),
      );
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (state.isDialogOpen) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _processIntervalMs) {
      return;
    }

    if (state.status == ReceiptStatus.loading) return;

    emit(state.copyWith(status: ReceiptStatus.loading));
    _lastProcessed = now;

    try {
      final inputImage = _convertYUV420ToInputImage(image);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      if (recognizedText.text.isNotEmpty) {
        await _processScannedText(recognizedText, now);
      }
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "Processing error: $e",
          status: ReceiptStatus.error,
        ),
      );
    } finally {
      if (!state.isDialogOpen) {
        emit(state.copyWith(status: ReceiptStatus.scanning));
      }
    }
  }

  Future<void> _processScannedText(
    RecognizedText recognizedText,
    DateTime now,
  ) async {
    String scannedText = recognizedText.text;
    double textQuality = _assessTextQuality(recognizedText);

    debugPrint("\n=== SCAN ATTEMPT ===");
    debugPrint("Text quality: ${(textQuality * 100).toStringAsFixed(1)}%");
    debugPrint("Text length: ${scannedText.length}");

    // Update scan history
    final newHistory = List<Map<String, dynamic>>.from(state.scanHistory);
    newHistory.add({
      'text': scannedText,
      'quality': textQuality,
      'timestamp': now,
    });

    if (newHistory.length > _maxHistorySize) {
      newHistory.removeAt(0);
    }

    // Update detected texts
    final newDetectedTexts = List<String>.from(state.detectedTexts);
    newDetectedTexts.add(scannedText);

    // Update scanned texts set
    final newScannedTexts = Set<String>.from(state.scannedTexts);
    String textHash = scannedText.substring(0, min(100, scannedText.length));

    if (!newScannedTexts.contains(textHash)) {
      newScannedTexts.add(textHash);
      if (newScannedTexts.length > 10) {
        newScannedTexts.remove(newScannedTexts.first);
      }

      // Parse the receipt - this returns ReceiptData with ReceiptItemOld items
      List<String> lines = scannedText.split('\n');
      final receiptData = ReceiptParser.parse(lines);

      debugPrint(
        "📊 PARSER RESULT: ${receiptData.items.length} items, Total: RM${receiptData.total}",
      );

      // Convert to ReceiptModel for better state management
      final receiptModel = ReceiptModel.fromReceiptData(receiptData);

      // Update state with new data
      emit(
        state.copyWith(
          scanHistory: newHistory,
          detectedTexts: newDetectedTexts,
          scannedTexts: newScannedTexts,
          receiptModel: receiptModel,
          status: ReceiptStatus.scanning,
        ),
      );

      // Show dialog if we have items or total
      if ((receiptData.items.isNotEmpty || receiptData.total > 0) &&
          !state.isDialogOpen) {
        emit(
          state.copyWith(
            receiptModel: receiptModel,
            isDialogOpen: true,
            status: ReceiptStatus.success,
          ),
        );
      }
    } else {
      emit(
        state.copyWith(scanHistory: newHistory, status: ReceiptStatus.scanning),
      );
    }
  }

  double _assessTextQuality(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    int totalElements = 0;
    int validElements = 0;

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        totalElements++;
        String text = line.text;

        if (text.length > 2) {
          if (text.contains(RegExp(r'[A-Za-z]'))) {
            validElements++;
          } else if (text.contains(RegExp(r'^\d+\.\d+$'))) {
            validElements++;
          }
        }
      }
    }

    return totalElements > 0 ? validElements / totalElements : 0.0;
  }

  InputImage _convertYUV420ToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> focusAndCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      _lastProcessed = DateTime.now().subtract(
        const Duration(milliseconds: 3000),
      );
      debugPrint("📸 Manual focus triggered");
    } catch (e) {
      debugPrint("Focus error: $e");
    }
  }

  void closeDialog() {
    emit(
      state.copyWith(
        isDialogOpen: false,
        receiptModel: null,
        status: ReceiptStatus.scanning,
      ),
    );
  }

  void updateBlurryCount(int count) {
    emit(state.copyWith(blurryCount: count));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null, status: ReceiptStatus.scanning));
  }

  ReceiptModel? getReceiptModel() {
    return state.receiptModel;
  }

  // Helper method to get receipt data in old format if needed
  ReceiptData? getReceiptData() {
    return state.receiptModel?.toReceiptData();
  }
}
