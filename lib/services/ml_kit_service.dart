// lib/services/ml_kit_service.dart
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../parser/receipt_parser.dart';
import '../models/receipt_model.dart';

class MLKitService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> processReceiptImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      List<TextLine> allLines = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          allLines.add(line);
        }
      }

      if (allLines.isEmpty) {
        await textRecognizer.close();
        return {
          'merchantName': 'Unknown Store',
          'totalAmount': 0.0,
          'items': [],
          'fullText': '',
          'date': DateTime.now().toIso8601String(),
        };
      }

      // Sort lines vertically from top to bottom
      allLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      // Spatial alignment grid reconstruction
      List<Map<String, dynamic>> structuredRows = [];
      double yTolerance = 14.0;

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

      String rebuiltFullText = '';
      for (var row in structuredRows) {
        List<TextLine> rowLines = List<TextLine>.from(row['lines']);
        // Sort items left to right across the page layout
        rowLines.sort(
          (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
        );

        String combinedRowText = rowLines.map((l) => l.text).join(" ").trim();
        rebuiltFullText += '$combinedRowText\n';
      }

      await textRecognizer.close();

      // We pass the clean text blocks right into your native parser system
      ReceiptModel parsedModel = ReceiptParser.parseRawText(
        rebuiltFullText,
        imagePath: imageFile.path,
      );

      // Convert items into the exact plain-map structures your UI views expect
      List<Map<String, dynamic>> organizedItemsList = [];

      // FIXED: Added a null-coalescing check (?? const []) to handle nullable models safely
      for (var item in parsedModel.items ?? const []) {
        organizedItemsList.add({
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'category': item.category,
        });
      }

      // Return the complete layout payload to satisfy all states
      return {
        'merchantName': parsedModel.merchantName,
        'totalAmount': parsedModel.amount,
        'items': organizedItemsList,
        'fullText': rebuiltFullText,
        'date': parsedModel.date.toIso8601String(),
      };
    } catch (e) {
      print('Error processing image via ML Kit: $e');
      return {
        'merchantName': 'Error Reading',
        'totalAmount': 0.0,
        'items': [],
        'fullText': '',
        'date': DateTime.now().toIso8601String(),
      };
    }
  }

  void dispose() {}
}
