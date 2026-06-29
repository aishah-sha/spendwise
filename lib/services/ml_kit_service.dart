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

      // Print debug info
      print('📄 OCR Output Length: ${organizedText.length} characters');
      print(
        '📄 First 200 chars: ${organizedText.substring(0, organizedText.length > 200 ? 200 : organizedText.length)}',
      );

      if (enableDebugDialog && context != null && context.mounted) {
        _showDebugDialog(context, organizedText);
      }

      final ReceiptModel parsedModel = ReceiptParser.parseRawText(
        organizedText,
        imagePath: imageFile.path,
      );

      print('✅ Parsed Receipt:');
      print('   Merchant: ${parsedModel.merchantName}');
      print('   Amount: RM${parsedModel.amount}');
      print('   Items: ${parsedModel.items?.length ?? 0}');
      print('   Establishment: ${parsedModel.establishmentType}');

      return _validateReceiptModel(parsedModel, imageFile.path);
    } catch (e) {
      debugPrint('❌ Error processing image via ML Kit: $e');
      return ReceiptModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        merchantName: 'Error Reading Receipt',
        amount: 0.0,
        date: DateTime.now(),
        receiptType: 'image',
        imagePath: imageFile.path,
        category: 'Uncategorized',
        items: [],
        establishmentType: 'General Retail',
      );
    } finally {
      await textRecognizer?.close();
    }
  }

  // IMPROVED: Center-line adaptive row clustering strategy
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

    // 2. Classify blocks into layout rows dynamically
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

        // Use adaptive tolerance based on text size
        double tolerance = (rowAvgHeight * 0.35).clamp(4.0, 20.0);

        if ((rowAvgCenter - lineCenter).abs() <= tolerance) {
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
      // Sort each row left to right
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      // Join text with appropriate spacing
      String combinedRowText = row.map((l) => l.text).join(" ").trim();

      // Clean up double spaces
      combinedRowText = combinedRowText.replaceAll(RegExp(r'\s+'), ' ');

      if (combinedRowText.isNotEmpty) {
        rebuiltFullText.writeln(combinedRowText);
      }
    }

    return rebuiltFullText.toString();
  }

  ReceiptModel _validateReceiptModel(ReceiptModel model, String imagePath) {
    // Ensure all required fields are set
    final validatedItems = model.items ?? [];

    // If items exist but total is 0, recalculate from items
    double calculatedTotal = validatedItems.fold(
      0.0,
      (sum, item) => sum + item.price,
    );

    final validatedTotal = model.amount > 0
        ? model.amount
        : (calculatedTotal > 0 ? calculatedTotal : 0.0);

    return ReceiptModel(
      id: model.id.isNotEmpty
          ? model.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      merchantName: model.merchantName?.isNotEmpty == true
          ? model.merchantName
          : 'Unknown Store',
      amount: validatedTotal,
      subtotal: model.subtotal ?? validatedTotal,
      tax: model.tax ?? 0.0,
      serviceCharge: model.serviceCharge ?? 0.0,
      date: model.date,
      receiptType: 'image',
      imagePath: imagePath,
      category: model.category.isNotEmpty == true
          ? model.category
          : 'Uncategorized',
      items: validatedItems,
      establishmentType: model.establishmentType.isNotEmpty
          ? model.establishmentType
          : 'General Retail',
      currency: model.currency ?? 'RM',
      ocrStatus: 'SUCCESS',
      processed: false,
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
