import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../models/receipt_model.dart';
import '../parser/receipt_parser.dart';

part 'receipt_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal enum for OCR quality gating
// ─────────────────────────────────────────────────────────────────────────────
enum _TextQuality { good, poor }

class ReceiptCubit extends Cubit<ReceiptState> {
  CameraController? _controller;

  // Use Latin script recognizer — handles English, Malay, and most receipt text.
  // If you need Chinese/Tamil support, switch to TextRecognizer() with no script arg.
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  DateTime _lastProcessed = DateTime.now();
  final int _processIntervalMs = 2000;
  final int _maxHistorySize = 5;

  // ── Store device sensor orientation so we can compute the correct rotation ──
  int _sensorOrientation = 90;

  CameraController? get controller => _controller;

  ReceiptCubit() : super(const ReceiptState());

  @override
  Future<void> close() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _textRecognizer.close();
    return super.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CAMERA INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────
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

      final camera = cameras.first;
      _sensorOrientation = camera.sensorOrientation;

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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

  bool _isProcessing = false;

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN CAMERA FRAME PROCESSOR
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _processCameraImage(CameraImage image) async {
    if (state.isDialogOpen || _isProcessing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _processIntervalMs) {
      return;
    }

    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // ── Quality gate: skip frames that are too blurry / unreadable ──
      final quality = _assessTextQuality(recognizedText);
      if (quality == _TextQuality.poor) {
        final newCount = state.blurryCount + 1;
        debugPrint("⚠️ Poor quality frame, blurryCount → $newCount");
        emit(state.copyWith(blurryCount: newCount));
        return;
      }

      // Good frame — reset blur counter and continue
      emit(state.copyWith(blurryCount: 0));

      if (recognizedText.text.isNotEmpty && recognizedText.text.length > 10) {
        _lastProcessed = now;
        await _processScannedText(recognizedText, now);
      }
    } catch (e) {
      debugPrint("Processing error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT QUALITY ASSESSMENT
  // Prevents the parser from receiving garbage OCR output from blurry frames.
  // ─────────────────────────────────────────────────────────────────────────
  _TextQuality _assessTextQuality(RecognizedText recognized) {
    final text = recognized.text.trim();

    // Too short to be a real receipt
    if (text.length < 20) {
      debugPrint("🔴 Quality: too short (${text.length} chars)");
      return _TextQuality.poor;
    }

    // A receipt must have at least one price (e.g. "2.50", "12.00")
    final hasPrices = RegExp(r'\d+\.\d{2}').hasMatch(text);
    if (!hasPrices) {
      debugPrint("🔴 Quality: no prices detected");
      return _TextQuality.poor;
    }

    // Check gibberish ratio — blurry text produces consonant-only tokens
    final words = text.split(RegExp(r'\s+'));
    final gibberishCount = words.where((w) {
      if (w.length <= 2) return false; // short tokens are fine
      final hasVowelOrDigit = RegExp(r'[aeiouAEIOU0-9]').hasMatch(w);
      return !hasVowelOrDigit;
    }).length;

    final gibberishRatio = gibberishCount / words.length.clamp(1, 99999);
    if (gibberishRatio > 0.6) {
      debugPrint(
        "🔴 Quality: high gibberish ratio (${(gibberishRatio * 100).toStringAsFixed(0)}%)",
      );
      return _TextQuality.poor;
    }

    // Confidence check via ML Kit block confidence scores
    if (recognized.blocks.isNotEmpty) {
      final avgConfidence =
          recognized.blocks
              .map(
                (b) => b.lines.fold<double>(
                  0,
                  (sum, l) =>
                      sum + (l.recognizedLanguages.isNotEmpty ? 1.0 : 0.5),
                ),
              )
              .fold<double>(0, (a, b) => a + b) /
          recognized.blocks.length;

      // Very low overall confidence suggests blur or glare
      if (avgConfidence < 0.3) {
        debugPrint("🔴 Quality: low block confidence ($avgConfidence)");
        return _TextQuality.poor;
      }
    }

    debugPrint("🟢 Quality: good");
    return _TextQuality.good;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE PREPROCESSING — Boosts contrast before OCR for faded/dark receipts
  // Requires: image: ^4.1.0 in pubspec.yaml
  // ─────────────────────────────────────────────────────────────────────────
  Uint8List? _preprocessImage(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      // 1. Grayscale — removes colour noise, reduces file size
      var processed = img.grayscale(decoded);

      // 2. Contrast boost — helps with faded thermal paper
      processed = img.adjustColor(processed, contrast: 1.5);

      // 3. Slight sharpening — helps with soft focus
      processed = img.convolution(
        processed,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
        offset: 0,
      );

      return Uint8List.fromList(img.encodePng(processed));
    } catch (e) {
      debugPrint("⚠️ Image preprocessing failed: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD InputImage FOR ML KIT (Android NV21 / iOS BGRA8888)
  // ─────────────────────────────────────────────────────────────────────────
  InputImage? _buildInputImage(CameraImage image) {
    final rotation = _getInputImageRotation();
    if (rotation == null) return null;

    if (Platform.isAndroid) {
      final plane = image.planes[0];
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else if (Platform.isIOS) {
      final plane = image.planes[0];
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROTATION HELPER
  // ─────────────────────────────────────────────────────────────────────────
  InputImageRotation? _getInputImageRotation() {
    switch (_sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation90deg;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROCESS RECOGNIZED TEXT → emit ReceiptModel
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _processScannedText(
    RecognizedText recognizedText,
    DateTime now,
  ) async {
    String scannedText = recognizedText.text;

    debugPrint("\n" + "=" * 50);
    debugPrint("📸 RAW OCR TEXT DETECTED:");
    debugPrint("=" * 50);
    debugPrint(scannedText);
    debugPrint("=" * 50);
    debugPrint("Text length: ${scannedText.length} characters");
    debugPrint("=" * 50);

    final newHistory = List<Map<String, dynamic>>.from(state.scanHistory);
    newHistory.add({'text': scannedText, 'timestamp': now});
    if (newHistory.length > _maxHistorySize) newHistory.removeAt(0);

    final newDetectedTexts = List<String>.from(state.detectedTexts);
    newDetectedTexts.add(scannedText);
    if (newDetectedTexts.length > 10) newDetectedTexts.removeAt(0);

    final newScannedTexts = Set<String>.from(state.scannedTexts);
    final textHash = scannedText.length > 100
        ? scannedText.substring(0, 100)
        : scannedText;

    if (!newScannedTexts.contains(textHash)) {
      newScannedTexts.add(textHash);
      if (newScannedTexts.length > 10) {
        newScannedTexts.remove(newScannedTexts.first);
      }

      final lines = scannedText.split('\n');
      debugPrint("📄 Lines to parse: ${lines.length}");

      final receiptData = ReceiptParserV2.parseFromRecognizedText(
        recognizedText,
        fallbackLines: lines,
      );

      debugPrint("📊 PARSER RESULT:");
      debugPrint("   - Items found: ${receiptData.items.length}");
      debugPrint("   - Total amount: RM${receiptData.total}");

      ReceiptModel receiptModel = ReceiptModel.fromReceiptData(receiptData);

      // Merchant name override from structured ML Kit blocks
      String? merchantName = _extractMerchantName(recognizedText, lines);
      if (merchantName != null &&
          (receiptModel.merchantName == null ||
              receiptModel.merchantName == 'Unknown Store')) {
        receiptModel = receiptModel.copyWith(merchantName: merchantName);
        debugPrint("📝 Extracted merchant: $merchantName");
      }

      emit(
        state.copyWith(
          scanHistory: newHistory,
          detectedTexts: newDetectedTexts,
          scannedTexts: newScannedTexts,
          receiptModel: receiptModel,
          status: ReceiptStatus.success,
          isDialogOpen: true,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MERCHANT EXTRACTION (from ML Kit structured blocks)
  // ─────────────────────────────────────────────────────────────────────────
  String? _extractMerchantName(
    RecognizedText recognizedText,
    List<String> fallbackLines,
  ) {
    final _merchantSkipRe = RegExp(
      r'\b(TOTAL|AMOUNT|DATE|TIME|RECEIPT|INVOICE|TAX|GST|SST|'
      r'SUBTOTAL|CASH|CHANGE|BALANCE|DISCOUNT|ROUNDING|'
      r'CASHIER|OPERATOR|MEMBER|POINT|REF|TRANSACTION)\b',
      caseSensitive: false,
    );

    // Try structured ML Kit blocks first (sorted top-to-bottom)
    for (final block in recognizedText.blocks) {
      final text = block.text.trim();
      if (text.isEmpty || text.length < 3 || text.length > 60) continue;
      if (text.contains(RegExp(r'\d{4,}'))) continue;
      if (_merchantSkipRe.hasMatch(text)) continue;
      final letters = text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
      if (letters.trim().length >= text.trim().length * 0.5) {
        return text;
      }
    }

    // Fallback: line-by-line scan
    for (final line in fallbackLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length < 3 || trimmed.length > 50) {
        continue;
      }
      if (trimmed.contains(RegExp(r'[\d]'))) continue;
      if (trimmed.contains(
        RegExp(r'RM|TOTAL|AMOUNT|DATE|TIME', caseSensitive: false),
      )) {
        continue;
      }
      return trimmed;
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MANUAL FOCUS TRIGGER
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> focusAndCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      // Force the next frame to be processed immediately
      _lastProcessed = DateTime.now().subtract(
        const Duration(milliseconds: 3000),
      );
      // Also reset blur count to give the user a fresh start
      emit(state.copyWith(blurryCount: 0));
      debugPrint("📸 Manual focus triggered");
    } catch (e) {
      debugPrint("Focus error: $e");
    }
  }

  void closeDialog() {
    emit(state.copyWith(isDialogOpen: false, status: ReceiptStatus.initial));
  }

  void updateBlurryCount(int count) {
    emit(state.copyWith(blurryCount: count));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null, status: ReceiptStatus.initial));
  }

  ReceiptModel? getReceiptModel() => state.receiptModel;
  ReceiptData? getReceiptData() => state.receiptModel?.toReceiptData();
}

// ─────────────────────────────────────────────────────────────────────────────
// ReceiptParserV2: uses ML Kit's structured block/line/element data
// ─────────────────────────────────────────────────────────────────────────────
class ReceiptParserV2 {
  // Malaysian receipt amount pattern: RM optional, digits, dot, 2 decimals
  static final _amountRe = RegExp(r'(?:RM\s*)?(\d+\.\d{2})\b');

  // Total label lines
  static final _totalLabelRe = RegExp(
    r'\b(TOTAL|JUMLAH|AMOUNT|AMAUN|GRAND\s*TOTAL|NET\s*TOTAL)\b',
    caseSensitive: false,
  );

  // Lines to skip entirely as item candidates
  static final _skipLabelRe = RegExp(
    r'\b(DISCOUNT|DISKAUN|TAX|GST|SST|ROUNDING|ROUN|CHANGE|BAKI|'
    r'CASH|TUNAI|TENDER|PAYMENT|CARD|CREDIT|DEBIT|'
    r'CASHIER|KASIR|OPERATOR|RECEIPT|INVOICE|'
    r'DATE|TIME|TARIKH|MASA|TEL|PHONE|FAX|EMAIL|WEBSITE|'
    r'TRANSACTION|REF|REFERENCE|MEMBER|POINT|POINTS|'
    r'SUBTOTAL|SUB\s*TOTAL|THANK\s*YOU|TERIMA\s*KASIH|'
    r'ITEM\s*COUNT|TOTAL\s*ITEM|TOTAL\s*QTY|SERVICE\s*CHARGE)\b',
    caseSensitive: false,
  );

  // Quantity-only lines like "1x", "2x", "x", "1X", "lx" (OCR misread of 1x)
  static final _qtyOnlyRe = RegExp(r'^\s*\d*[xXlL×]\s*$');

  // Leading quantity prefix to strip from item names: "1x ", "2X ", "x ", etc.
  static final _qtyPrefixRe = RegExp(r'^\s*\d*[xXlL×]\s+');

  static ReceiptData parseFromRecognizedText(
    RecognizedText recognized, {
    required List<String> fallbackLines,
  }) {
    // ── Build parsed lines from ML Kit blocks ──────────────────────────────
    final List<_ParsedLine> parsedLines = [];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final amounts = _amountRe
            .allMatches(text)
            .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
            .where((v) => v > 0)
            .toList();
        parsedLines.add(_ParsedLine(text: text, amounts: amounts));
      }
    }

    // Fallback: raw string split if ML Kit returned nothing
    if (parsedLines.isEmpty) {
      for (final line in fallbackLines) {
        final text = line.trim();
        if (text.isEmpty) continue;
        final amounts = _amountRe
            .allMatches(text)
            .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
            .where((v) => v > 0)
            .toList();
        parsedLines.add(_ParsedLine(text: text, amounts: amounts));
      }
    }

    // ── Step 1: Find the total ─────────────────────────────────────────────
    double total = 0.0;

    // Pass 1: labelled total line (same line or next line)
    for (int i = 0; i < parsedLines.length; i++) {
      final line = parsedLines[i];
      if (!_totalLabelRe.hasMatch(line.text)) continue;
      if (_skipLabelRe.hasMatch(line.text)) continue;

      if (line.amounts.isNotEmpty) {
        final candidate = line.amounts.last;
        if (candidate > total) total = candidate;
      } else if (i + 1 < parsedLines.length) {
        final next = parsedLines[i + 1];
        if (next.amounts.isNotEmpty) {
          final candidate = next.amounts.last;
          if (candidate > total) total = candidate;
        }
      }
    }

    // Pass 2: fallback — largest amount on any non-skip line
    if (total == 0.0) {
      for (final line in parsedLines) {
        if (_skipLabelRe.hasMatch(line.text)) continue;
        for (final amt in line.amounts) {
          if (amt > total) total = amt;
        }
      }
    }

    // ── Step 2: Extract line items ─────────────────────────────────────────
    //
    // Malaysian thermal receipts have TWO common layouts:
    //
    //   Layout A — inline (name + price on same line):
    //     "MILO KOTAK              2.00"
    //
    //   Layout B — split (name on one line, price on the next):
    //     "MILO KOTAK"
    //     "1x            2.00"

    final List<ReceiptItem> items = [];
    final Set<int> usedIndices = {};

    for (int i = 0; i < parsedLines.length; i++) {
      final line = parsedLines[i];

      if (_totalLabelRe.hasMatch(line.text)) continue;
      if (_skipLabelRe.hasMatch(line.text)) continue;
      if (line.amounts.length != 1) continue;

      final price = line.amounts.first;
      if (price <= 0 || price >= total) continue;
      if (usedIndices.contains(i)) continue;

      // Raw description: strip the price portion
      String rawDesc = line.text
          .replaceAll(_amountRe, '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

      // If description is empty or just a qty token, look at surrounding lines
      if (rawDesc.isEmpty || _qtyOnlyRe.hasMatch(rawDesc)) {
        String? foundName;

        // Check previous line first (most common: name then price-line)
        if (i > 0 && !usedIndices.contains(i - 1)) {
          final prev = parsedLines[i - 1];
          if (prev.amounts.isEmpty &&
              !_totalLabelRe.hasMatch(prev.text) &&
              !_skipLabelRe.hasMatch(prev.text) &&
              !_qtyOnlyRe.hasMatch(prev.text) &&
              prev.text.contains(RegExp(r'[A-Za-z]'))) {
            foundName = prev.text.trim();
            usedIndices.add(i - 1);
          }
        }

        // Check next line if prev didn't work
        if (foundName == null &&
            i + 1 < parsedLines.length &&
            !usedIndices.contains(i + 1)) {
          final next = parsedLines[i + 1];
          if (next.amounts.isEmpty &&
              !_totalLabelRe.hasMatch(next.text) &&
              !_skipLabelRe.hasMatch(next.text) &&
              !_qtyOnlyRe.hasMatch(next.text) &&
              next.text.contains(RegExp(r'[A-Za-z]'))) {
            foundName = next.text.trim();
            usedIndices.add(i + 1);
          }
        }

        if (foundName == null) continue;
        rawDesc = foundName;
      }

      // Strip any leading quantity prefix ("1x ", "2X ", "x ")
      final description = rawDesc.replaceAll(_qtyPrefixRe, '').trim();
      if (description.length < 2) continue;

      usedIndices.add(i);
      items.add(
        ReceiptItem(
          name: _toTitleCase(description),
          price: price,
          quantity: 1,
          category: categorize(description),
        ),
      );
    }

    // ── Step 3: Extract date ───────────────────────────────────────────────
    DateTime? date;
    final dateRe = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    for (final line in parsedLines) {
      final m = dateRe.firstMatch(line.text);
      if (m != null) {
        try {
          int day = int.parse(m.group(1)!);
          int month = int.parse(m.group(2)!);
          int year = int.parse(m.group(3)!);
          if (year < 100) year += 2000;
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            date = DateTime(year, month, day);
            break;
          }
        } catch (_) {}
      }
    }

    // ── Step 4: Extract merchant ───────────────────────────────────────────
    final _merchantSkipRe = RegExp(
      r'\b(TOTAL|AMOUNT|DATE|TIME|RECEIPT|INVOICE|TAX|GST|SST|'
      r'SUBTOTAL|CASH|CHANGE|BALANCE|DISCOUNT|ROUNDING|'
      r'CASHIER|OPERATOR|MEMBER|POINT|REF|TRANSACTION)\b',
      caseSensitive: false,
    );
    String merchant = 'Unknown Store';
    for (final line in parsedLines) {
      final text = line.text.trim();
      if (text.length < 3 || text.length > 60) continue;
      if (line.amounts.isNotEmpty) continue;
      if (text.contains(RegExp(r'\d{4,}'))) continue;
      if (_merchantSkipRe.hasMatch(text)) continue;
      final letters = text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
      if (letters.length >= text.replaceAll(' ', '').length * 0.5) {
        merchant = text;
        break;
      }
    }

    debugPrint("🏪 Merchant: $merchant");
    debugPrint("💰 Total: RM$total");
    debugPrint("🛒 Items (${items.length}):");
    for (final item in items) {
      debugPrint("   - ${item.name} [${item.category}]: RM${item.price}");
    }

    return ReceiptData(
      merchant: merchant,
      items: items.map((item) => item.toReceiptItemOld()).toList(),
      total: total,
      date: date ?? DateTime.now(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Convert "MILO KOTAK" → "Milo Kotak"
  static String _toTitleCase(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Categorize an item name into specific Malaysian spending categories.
  static String categorize(String name) {
    final lower = name.toLowerCase();

    // 1. PET SUPPLIES
    if (RegExp(
      r'cat|dog|pet|whiskas|makanan kucing|makanan anjing|kibble|pedigree|friskies|purina|royal canin|hamster|bird|rabbit',
    ).hasMatch(lower)) {
      return 'Pet Food';
    }

    // 2. HOUSEHOLD & PERSONAL CARE
    if (RegExp(
      r'daia|softener|hand\s*wash|recycle\s*bag|detergen|sabun|'
      r'syampu|shampoo|ubat\s*gigi|toothpaste|pencuci|cleaner|'
      r'soap|dishwash|floor\s*clean|febreze|dettol|dynamo|attack|rinso|harpic|breez|clorox|glo|'
      r'colgate|sensodyne|darlie|pantene|sunsilk|rejoice|dove|lifebuoy|'
      r'pad|tuala\s*wanita|sanitary|kotex|whisper|laurier|sofy|libresse|'
      r'tissue|tisu|wet\s*tissue|wet\s*wipes|facial\s*tisu|pocket\s*tisu|pop\s*up\s*tisu|'
      r'kleenex|vinda|scott|premier|cutie|royal\s*gold|paseo|'
      r'pampers|huggies|mamypoko|mamy\s*poko',
    ).hasMatch(lower)) {
      return 'Household';
    }

    // 3. MALAYSIAN BEVERAGES
    if (RegExp(
      r'milo|nescafe|teh|kopi|coffee|tea|mineral|jus|soda|minuman|'
      r'coca.cola|pepsi|cola|juice|drink|beverage|100plus|100\s*plus|'
      r'isotonic|vitagen|yakult|ribena|f&n|f\s*&\s*n|pokka|spritzer|season|'
      r'heaven\s*&\s*earth|yeo|marigold|chrysanthemum|kundur|sea\s*coconut|'
      r'ayataka|susu\s*kotak|dutch\s*lady|fernleaf|goodday|good\s*day|milklab|'
      r'sirap|ros|bandung|cincau|soya|soya\s*bean|malt|vico|horlicks|neslo',
    ).hasMatch(lower)) {
      return 'Beverages';
    }

    // 4. BAKING SUPPLIES & BAKERY
    if (RegExp(
      r'tepung\s*gandum|tepung\s*kek|tepung\s*jagung|tepung\s*beras|tepung\s*pulut|'
      r'flour|baking\s*powder|baking\s*soda|soda\s*bikarbonat|yeast|yis|mauripan|'
      r'cucur|jemput\s*jemput|fritter|tepung\s*wangi|tepung\s*gorang|'
      r'gardenia|massimo|roti|loaf|classic\s*white|bonanza|somerset|wholemeal|'
      r'twiggies|muffins|waffles|delicia|toastem|quick\s*bites|'
      r'butter|mentega|anchor|scb|buttercup|marjerin|margarine|planta|ghee|minyak\s*sapi|'
      r'vanilla|esen|cocoa\s*powder|serbuk\s*koko|icing\s*sugar|gula\s*aising|'
      r'whipping\s*cream|whip\s*cream|krim\s*putar|cheese\s*cream|cream\s*cheese|'
      r'tatura|philadelphia|mozzarella|cheddar|chocolate\s*chips|choc\s*chip',
    ).hasMatch(lower)) {
      return 'Baking';
    }

    // 5. COOKING PRODUCTS / FRESH INGREDIENTS
    if (RegExp(
      r'minyak|cooking\s*oil|seri\s*murni|buruh|saji|vesawit|knife\s*oil|naturel|mazola|carotino|'
      r'kicap|sos|sauce|chili\s*paste|cili\s*giling|sambal|belacan|kaya|'
      r'maggi|indo\s*mee|indomie|mee|pasta|noodle|bihun|bee\s*hoon|beehoon|kuey\s*teow|kway\s*teow|kuetiau|'
      r'mee\s*kuning|yellow\s*mee|suun|glass\s*noodle|yee\s*mee|cin\s*mee|pan\s*mee|instant\s*mee|'
      r'spaghetti|fettuccine|linguine|angel\s*hair|macaroni|penne|pasta\s*sauce|prego|kimball|bolognese|carbonara|'
      r'sardine|sardin|tuna|tinned|tin|adabi|baba|brahim|faiza|alagappa|mak\s*nyonya|'
      r'perencah|pes\s*segera|paste|serbuk\s*kari|curry\s*powder|rempah|kurma|sup|soto|rendang|'
      r'bunga\s*cengkih|clove|kayu\s*manis|cinnamon|bunga\s*lawang|star\s*anise|'
      r'buah\s*pelaga|cardamom|jintan|cummin|fennel|ketumbar|coriander|lada|pepper|'
      r'kunyit|turmeric|halba|fenugreek|kas-kas|poppy\s*seed|asam\s*jawa|tamarind|'
      r'asam\s*keping|asam\s*gelugur|kerisik|gula\s*melaka|palm\s*sugar|'
      r'telur|egg|gred\s*[a-f]|grade\s*[a-f]|omega|nutriplus|ltkm|ql\s*eggs|eco\s*egg|'
      r'ayam|chicken|daging|beef|kambing|mutton|ikan|fish|udang|prawn|sotong|squid|'
      r'bawang|onion|garlic|halia|ginger|cili|chili|serai|lemongrass|'
      r'daun\s*bawang|spring\s*onion|daun\s*sup|celery\s*leaf|ketumbar|cilantro|pudina|mint|'
      r'sayur|vegetable|kobis|sawi|bayam|carrot|kentang|potato|tomato|'
      r'garam|salt|gula|sugar|ajinomoto|msg|perasa|kiub|cube|santan|coconut\s*milk',
    ).hasMatch(lower)) {
      return 'Cooking Ingredients';
    }

    // 6. SNACKS, BISCUITS & READY-TO-EAT DESSERTS
    if (RegExp(
      r'cracker|snack|biscuit|biskut|munchys|hup\s*seng|lexus|oreo|tiger|'
      r'cooki|cake|kek|chocolate|coklat|candy|gula\s*gula|'
      r'keropok|lekor|kuih|dodol|chips|lays|pringles|mister\s*potato|potato\s*chip|mamee|twisties|'
      r'super\s*ring|ice\s*cream|aiskrim|nestle|walls|haagen|king|yogurt|yoghurt',
    ).hasMatch(lower)) {
      return 'Snacks & Desserts';
    }

    // 7. HEALTH & PHARMACY
    if (RegExp(
      r'ubat|medicine|vitamin|supplement|panadol|pharmacy|farmasi|'
      r'mask|sanitizer|antiseptic|bandage|plaster|thermometer|'
      r'probiotik|omega|collagen|calcium|zinc|iron\s*suppl|hurix|'
      r'gaviscon|eno|strepsils|woods|vicks',
    ).hasMatch(lower)) {
      return 'Health';
    }

    // 8. TRANSPORT & FUEL
    if (RegExp(
      r'parking|petrol|toll|transport|grab|bus|mrt|ktm|commuter|taxi|'
      r'myrapid|touch\s*n\s*go|tng|petron|shell|caltex|petronas|bhp\s*fuel',
    ).hasMatch(lower)) {
      return 'Transport';
    }

    // 9. CLOTHING & ACCESSORIES
    if (RegExp(
      r'shirt|baju|seluar|pants|kasut|shoes|sandal|dress|tudung|hijab|'
      r'beg|bag|wallet|dompet|accessories|stokin|socks|underwear|'
      r'tshirt|t-shirt|jacket|jaket|sweater',
    ).hasMatch(lower)) {
      return 'Clothing';
    }

    // 10. STATIONERY
    if (RegExp(
      r'pen|pensil|buku|book|folder|staple|file|envelope|pita|'
      r'marker|highlighter|ruler|pembaris|gunting|scissors',
    ).hasMatch(lower)) {
      return 'Stationery';
    }

    return 'Others';
  }
}

class _ParsedLine {
  final String text;
  final List<double> amounts;
  const _ParsedLine({required this.text, required this.amounts});
}
