// lib/cubit/receipt_cubit.dart
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      emit(
        state.copyWith(
          status: ReceiptStatus.initial,
          isCameraInitialized: true,
        ),
      );

      _startAutoScanning();
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
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(_scanDelay, (timer) async {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isTakingPicture &&
          state.status != ReceiptStatus.success &&
          !state.isDialogOpen) {
        await _captureAndProcessFrame();
      }
    });
  }

  Future<void> _captureAndProcessFrame() async {
    if (state.status == ReceiptStatus.scanning) return;

    try {
      emit(state.copyWith(status: ReceiptStatus.scanning, isScanning: true));

      final XFile file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // 1. EXTRACT ALL RAW TEXT LINES
      List<TextLine> allLines = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          allLines.add(line);
        }
      }

      // FIXED: Use allLines.length instead of lines.length to prevent the null error!
      if (allLines.length < 3) {
        int currentBlurry = state.blurryCount + 1;
        emit(
          state.copyWith(
            status: currentBlurry >= 3
                ? ReceiptStatus.error
                : ReceiptStatus.initial,
            isScanning: false,
            blurryCount: currentBlurry,
            errorMessage: currentBlurry >= 3
                ? "Poor photo quality. Adjust lighting."
                : null,
          ),
        );
        return;
      }

      // 2. SPATIAL RECONSTRUCTION GRID (Matches Item Name on left with Price on right)
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      List<Map<String, dynamic>> structuredRows = [];
      double yTolerance = 14.0; // Margin in pixels to map elements horizontally

      for (var line in allLines) {
        double currentTop = line.boundingBox.top.toDouble();
        bool matchedRow = false;

        for (var row in structuredRows) {
          double rowTop = row['yTop'];
          if ((rowTop - currentTop).abs() <= yTolerance) {
            row['lines'].add(line);
            matchedRow = true;
            break;
          }
        }

        if (!matchedRow) {
          structuredRows.add({
            'yTop': currentTop,
            'lines': [line],
          });
        }
      }

      // 3. REBUILD THE PERFECT HORIZONTAL RAW TEXT
      String rebuiltFullText = '';
      for (var row in structuredRows) {
        List<TextLine> rowLines = List<TextLine>.from(row['lines']);
        rowLines.sort(
          (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
        );

        String combinedRowText = rowLines.map((l) => l.text).join(" ").trim();
        rebuiltFullText += '$combinedRowText\n';
      }

      // Prevent processing duplicates of the exact same frame scan
      if (_lastScannedText == rebuiltFullText) {
        emit(state.copyWith(status: ReceiptStatus.initial, isScanning: false));
        return;
      }
      _lastScannedText = rebuiltFullText;

      print("--- Cleaned Spatial Scanning Output ---");
      print(rebuiltFullText);

      // 4. PARSE STRINGS INTO THE SYSTEM ECOSYSTEM MODEL
      ReceiptModel receipt = ReceiptParser.parseRawText(
        rebuiltFullText,
        imagePath: file.path,
      );

      // Update recent history arrays
      final Map<String, dynamic> historyItem = {
        'id': receipt.id,
        'merchantName': receipt.merchantName,
        'amount': receipt.amount,
        'date': receipt.date.toIso8601String(),
        'itemCount': receipt.items?.length,
      };

      final updatedHistory = List<Map<String, dynamic>>.from(state.scanHistory)
        ..insert(0, historyItem);
      final updatedScannedTexts = Set<String>.from(state.scannedTexts)
        ..add(rebuiltFullText);

      // 5. ASSIGN BOTH model AND scannedReceipt TO SYNC WITH UI
      emit(
        state.copyWith(
          status: ReceiptStatus.success,
          isScanning: false,
          receiptModel: receipt, // Syncs old layouts
          scannedReceipt: receipt, // Syncs your UI item table lists!
          detectedTexts: rebuiltFullText.split('\n'),
          scanHistory: updatedHistory,
          scannedTexts: updatedScannedTexts,
          blurryCount: 0,
        ),
      );

      _scanTimer?.cancel(); // Successfully scanned! Stop timer loops.
    } catch (e) {
      print("OCR process error: $e");
      emit(
        state.copyWith(
          status: ReceiptStatus.error,
          isScanning: false,
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
        scannedReceipt: null, // Clear out
        errorMessage: null,
        blurryCount: 0,
        isScanning: false,
      ),
    );
    _startAutoScanning();
  }

  void clearError() {
    emit(
      state.copyWith(
        status: ReceiptStatus.initial,
        errorMessage: null,
        isScanning: false,
      ),
    );
  }

  void setBlurryCount(int count) {
    emit(state.copyWith(blurryCount: count));
  }

  void toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      bool currentFlash = state.isFlashOn;
      await _controller!.setFlashMode(
        currentFlash ? FlashMode.off : FlashMode.torch,
      );
      emit(state.copyWith(isFlashOn: !currentFlash));
    }
  }

  void setDialogOpen(bool isOpen) {
    emit(state.copyWith(isDialogOpen: isOpen));
    if (!isOpen && state.status != ReceiptStatus.success) {
      _startAutoScanning();
    }
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    _controller?.dispose();
    _textRecognizer.close();
    return super.close();
  }
}
