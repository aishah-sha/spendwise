// lib/services/ml_kit_service.dart
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class MLKitService {
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Process receipt image with ML Kit
  Future<Map<String, dynamic>> processReceiptImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textDetector = GoogleMlKit.vision.textRecognizer();

      // Recognize text from image
      final RecognizedText recognizedText = await textDetector.processImage(
        inputImage,
      );

      // Extract receipt information from recognized text
      final receiptData = _extractReceiptInfo(recognizedText);

      await textDetector.close();

      return receiptData;
    } catch (e) {
      print('Error processing image: $e');
      return {};
    }
  }

  // Extract receipt information from recognized text
  Map<String, dynamic> _extractReceiptInfo(RecognizedText recognizedText) {
    String fullText = '';
    List<String> lines = [];
    double totalAmount = 0.0;
    String? merchantName;
    List<Map<String, dynamic>> items = [];

    // Collect all text from recognized blocks
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        fullText += line.text + '\n';
        lines.add(line.text);
      }
    }

    // Extract total amount (look for patterns like "Total", "Amount", "RM", "$")
    for (String line in lines) {
      // Check for total amount patterns
      if (line.toLowerCase().contains('total') ||
          line.toLowerCase().contains('amount') ||
          line.toLowerCase().contains('rm') ||
          line.contains('\$')) {
        // Extract numbers from the line
        RegExp amountRegex = RegExp(r'(\d+\.?\d*)');
        Iterable<Match> matches = amountRegex.allMatches(line);

        for (Match match in matches) {
          double amount = double.tryParse(match.group(0) ?? '0') ?? 0;
          if (amount > totalAmount) {
            totalAmount = amount;
          }
        }
      }

      // Try to extract merchant name (usually first line)
      if (merchantName == null &&
          line.length > 3 &&
          !line.contains(RegExp(r'\d'))) {
        merchantName = line;
      }

      // Try to extract items (lines with price at the end)
      RegExp itemRegex = RegExp(r'(.+?)\s+(\d+\.?\d*)\s*$');
      Match? itemMatch = itemRegex.firstMatch(line);
      if (itemMatch != null) {
        String itemName = itemMatch.group(1)?.trim() ?? '';
        double itemPrice = double.tryParse(itemMatch.group(2) ?? '0') ?? 0;

        if (itemName.isNotEmpty && itemPrice > 0) {
          items.add({'name': itemName, 'price': itemPrice, 'quantity': 1});
        }
      }
    }

    // If total amount not found, try to find the largest number
    if (totalAmount == 0.0) {
      RegExp numberRegex = RegExp(r'(\d+\.?\d*)');
      Iterable<Match> matches = numberRegex.allMatches(fullText);

      for (Match match in matches) {
        double amount = double.tryParse(match.group(0) ?? '0') ?? 0;
        if (amount > totalAmount && amount < 100000) {
          // Reasonable receipt amount
          totalAmount = amount;
        }
      }
    }

    return {
      'fullText': fullText,
      'merchantName': merchantName,
      'totalAmount': totalAmount,
      'items': items,
    };
  }

  // Clean up resources
  void dispose() {
    // Clean up if needed
  }
}
