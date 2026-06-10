// lib/services/ml_kit_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../parser/receipt_parser.dart';
import '../models/receipt_model.dart';

class MLKitService {
  final ImagePicker _imagePicker = ImagePicker();

  // Configuration constants
  static const double yTolerance = 14.0;
  static const int defaultImageQuality = 100;
  static const bool enableDebugDialog = false; // Set to true for debugging

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: defaultImageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: defaultImageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Process a receipt image and extract structured data
  /// Returns a ReceiptModel with parsed information
  Future<ReceiptModel> processReceiptImage(
    File imageFile, {
    BuildContext? context,
  }) async {
    TextRecognizer? textRecognizer;

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Extract and organize text lines
      final String organizedText = _organizeTextLines(recognizedText);

      // Debug dialog (only when explicitly enabled)
      if (enableDebugDialog && context != null && context.mounted) {
        _showDebugDialog(context, organizedText);
      }

      // Parse using your receipt parser
      final ReceiptModel parsedModel = ReceiptParser.parseRawText(
        organizedText,
        imagePath: imageFile.path,
      );

      // Validate and ensure data integrity
      return _validateReceiptModel(parsedModel, imageFile.path);
    } catch (e) {
      debugPrint('Error processing image via ML Kit: $e');
      // Return a default receipt model instead of throwing
      return ReceiptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchantName: 'Error Reading Receipt',
        amount: 0.0,
        date: DateTime.now(),
        receiptType: 'image',
        imagePath: imageFile.path,
        category: 'Uncategorized',
        items: [],
      );
    } finally {
      // Ensure proper cleanup of resources
      await textRecognizer?.close();
    }
  }

  /// Organize text lines with spatial awareness
  String _organizeTextLines(RecognizedText recognizedText) {
    List<TextLine> allLines = [];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        allLines.add(line);
      }
    }

    if (allLines.isEmpty) {
      return '';
    }

    // Sort lines vertically from top to bottom
    allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Spatial alignment grid reconstruction
    List<_StructuredRow> structuredRows = [];

    for (var line in allLines) {
      double currentTop = line.boundingBox.top.toDouble();
      bool matchedRow = false;

      for (var row in structuredRows) {
        if ((row.yTop - currentTop).abs() <= yTolerance) {
          row.lines.add(line);
          matchedRow = true;
          break;
        }
      }

      if (!matchedRow) {
        structuredRows.add(_StructuredRow(yTop: currentTop, lines: [line]));
      }
    }

    // Build the organized text
    StringBuffer rebuiltFullText = StringBuffer();
    for (var row in structuredRows) {
      // Sort items left to right across the page layout
      row.lines.sort(
        (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
      );

      String combinedRowText = row.lines.map((l) => l.text).join(" ").trim();
      rebuiltFullText.writeln(combinedRowText);
    }

    return rebuiltFullText.toString();
  }

  /// Validate and ensure ReceiptModel has all required fields
  ReceiptModel _validateReceiptModel(ReceiptModel model, String imagePath) {
    return ReceiptModel(
      id: model.id.isNotEmpty
          ? model.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      merchantName: model.merchantName?.isNotEmpty == true
          ? model.merchantName
          : 'Unknown Store',
      amount: model.amount > 0 ? model.amount : 0.0,
      date: model.date,
      receiptType: 'image',
      imagePath: imagePath,
      category: model.category?.isNotEmpty == true
          ? model.category
          : 'Uncategorized',
      items: model.items?.where((item) => item != null).toList() ?? [],
    );
  }

  /// Optional debug dialog for troubleshooting
  void _showDebugDialog(BuildContext context, String recognizedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🔍 OCR Raw Output"),
        content: SingleChildScrollView(
          child: Text(
            recognizedText.isEmpty ? "[No Text Found]" : recognizedText,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void dispose() {
    // Clean up any resources if needed
  }
}

/// Helper class for structured row data
class _StructuredRow {
  final double yTop;
  final List<TextLine> lines;

  _StructuredRow({required this.yTop, required this.lines});
}
