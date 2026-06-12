// lib/services/ml_kit_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../parser/receipt_parser.dart';
import '../models/receipt_model.dart';

class MLKitService {
  final ImagePicker _imagePicker = ImagePicker();

  static const int defaultImageQuality = 100;
  static const bool enableDebugDialog =
      false; // Toggle true to show raw layout dialog maps

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

      final String organizedText = _organizeTextLines(recognizedText);

      if (enableDebugDialog && context != null && context.mounted) {
        _showDebugDialog(context, organizedText);
      }

      final ReceiptModel parsedModel = ReceiptParser.parseRawText(
        organizedText,
        imagePath: imageFile.path,
      );

      return _validateReceiptModel(parsedModel, imageFile.path);
    } catch (e) {
      debugPrint('Error processing image via ML Kit: $e');
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
      await textRecognizer?.close();
    }
  }

  // FIXED: Center-line adaptive row clustering strategy prevents text fragments from merging out of order
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

    // 1. Sort fragments vertically by center point
    allLines.sort((a, b) {
      double aCenter = a.boundingBox.top + a.boundingBox.height / 2;
      double bCenter = b.boundingBox.top + b.boundingBox.height / 2;
      return aCenter.compareTo(bCenter);
    });

    // 2. Classify blocks into layout row rows dynamically
    List<List<TextLine>> rows = [];

    for (var line in allLines) {
      double lineCenter = line.boundingBox.top + line.boundingBox.height / 2;
      bool matchedRow = false;

      for (var row in rows) {
        double rowCenterSum = 0;
        double rowHeightSum = 0;
        for (var rowLine in row) {
          rowCenterSum +=
              rowLine.boundingBox.top + rowLine.boundingBox.height / 2;
          rowHeightSum += rowLine.boundingBox.height;
        }
        double rowAvgCenter = rowCenterSum / row.length;
        double rowAvgHeight = rowHeightSum / row.length;

        if ((rowAvgCenter - lineCenter).abs() <= (rowAvgHeight * 0.35) ||
            (rowAvgCenter - lineCenter).abs() <= 6.0) {
          row.add(line);
          matchedRow = true;
          break;
        }
      }

      if (!matchedRow) {
        rows.add([line]);
      }
    }

    // 3. Keep rows sequenced top-to-bottom
    rows.sort((a, b) {
      double aCenter =
          a
              .map((l) => l.boundingBox.top + l.boundingBox.height / 2)
              .reduce((q, w) => q + w) /
          a.length;
      double bCenter =
          b
              .map((l) => l.boundingBox.top + l.boundingBox.height / 2)
              .reduce((q, w) => q + w) /
          b.length;
      return aCenter.compareTo(bCenter);
    });

    // 4. Join line blocks ordered left-to-right
    StringBuffer rebuiltFullText = StringBuffer();
    for (var row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      String combinedRowText = row.map((l) => l.text).join(" ").trim();
      rebuiltFullText.writeln(combinedRowText);
    }

    return rebuiltFullText.toString();
  }

  ReceiptModel _validateReceiptModel(ReceiptModel model, String imagePath) {
    return ReceiptModel(
      id: model.id.isNotEmpty
          ? model.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      merchantName: model.merchantName?.isNotEmpty == true
          ? model.merchantName
          : 'Unknown Store',
      amount: model.amount > 0 ? model.amount : 0.0,
      subtotal: model.subtotal,
      tax: model.tax,
      serviceCharge: model.serviceCharge,
      date: model.date,
      receiptType: 'image',
      imagePath: imagePath,
      category: model.category.isNotEmpty == true
          ? model.category
          : 'Uncategorized',
      items: model.items ?? [],
      establishmentType: model.establishmentType,
      currency: model.currency,
    );
  }

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

  void dispose() {}
}
