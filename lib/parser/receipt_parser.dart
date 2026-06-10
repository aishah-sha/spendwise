// lib/parser/receipt_parser.dart
import '../models/receipt_model.dart';

class ReceiptParser {
  // 1. IMPROVED PRICE REGEX: Safely allows optional Malaysian tax suffix codes (S, Z, E)
  static final _priceRe = RegExp(
    r'(?:RM|MYR|M\s?Y\s?R)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2}))(?:\s*[A-Z])?\b',
    caseSensitive: false,
  );

  // Date patterns (Malaysian formats: DD/MM/YYYY, DD-MM-YYYY)
  static final _dateRe = RegExp(
    r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
    caseSensitive: false,
  );

  // Merchant patterns
  static final _merchantRe = RegExp(
    r'^([A-Z][A-Z\s&.]{3,50}(?:SDN\s*BHD|BHD|ENTERPRISE|TRADING|STORE|MART|SUPERMARKET)?)',
    caseSensitive: false,
  );

  // Transaction metadata words to skip completely
  static final _skipLineRe = RegExp(
    r'\b(CASH|CHANGE|TUNAI|BAKI|TENDER|PAYMENT|CARD|CREDIT|DEBIT|'
    r'CASHIER|KASIR|OPERATOR|RECEIPT|INVOICE|TABLE|ORDER|SERVER|STAFF|'
    r'DATE|TIME|TARIKH|MASA|TEL|PHONE|FAX|EMAIL|WEBSITE|'
    r'TRANSACTION|REF|REFERENCE|MEMBER|POINT|POINTS|'
    r'DISCOUNT|DISKAUN|TAX|GST|SST|SERVICE\s*CHARGE|'
    r'ITEM\s*COUNT|TOTAL\s*ITEM|TOTAL\s*QTY|'
    r'SUBTOTAL|SUB\s*TOTAL|THANK\s*YOU|TERIMA\s*KASIH|'
    r'JALAN|LOT\s*\d|UNIT\s*\d|SDN\s*BHD|NO\.\s*\d)\b',
    caseSensitive: false,
  );

  // Multi-variant quantity pattern matchers (e.g., "12 x 1.75" or "2 @ RM3.50")
  static final _qtyPatterns = [
    RegExp(r'(\d{1,3})\s*[xX@]\s*(?:RM|MYR)?\s*(\d+(?:\.\d{2})?)'),
    RegExp(r'\b(\d{1,3})\s+(?:RM|MYR)?\s*(\d+(?:\.\d{2})?)$'),
  ];

  static final _totalRe = RegExp(
    r'\b(TOTAL|JUMLAH|GRAND\s*TOTAL|AMOUNT|AMOUNT\s*DUE|BUNDARAN|ROUNDING):?\s*(?:RM|MYR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
    caseSensitive: false,
  );

  static ReceiptModel parseRawText(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final List<ReceiptItem> items = [];

    String merchantName = "Unknown Store";
    DateTime? receiptDate;
    double extractedTotal = 0.0;
    double calculatedSubtotal = 0.0;

    // First Pass: Extract Header Metadata (Merchant and Date)
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];

      if (merchantName == "Unknown Store") {
        final merchantMatch = _merchantRe.firstMatch(line);
        if (merchantMatch != null && line.length > 4) {
          merchantName = merchantMatch
              .group(1)!
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');
        } else if (line.length > 5 &&
            !_skipLineRe.hasMatch(line) &&
            !_priceRe.hasMatch(line) &&
            !line.contains(':')) {
          merchantName = line;
        }
      }

      if (receiptDate == null) {
        final dateMatch = _dateRe.firstMatch(line);
        if (dateMatch != null) {
          receiptDate = _parseMalaysianDate(dateMatch.group(1)!);
        }
      }
    }

    // Second Pass: Parse Items & Totals using a Look-Behind buffering logic
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Grab grand totals if present
      final totalMatch = _totalRe.firstMatch(line);
      if (totalMatch != null) {
        final amountStr = totalMatch.group(2)!.replaceAll(',', '');
        double parsedTotal = double.tryParse(amountStr) ?? 0.0;
        if (parsedTotal > extractedTotal) extractedTotal = parsedTotal;
        continue;
      }

      // If a line doesn't have a visible price metric, don't drop it yet! It might be a detached item name.
      final priceMatch = _priceRe.firstMatch(line);
      if (priceMatch == null) continue;

      // Skip lines that are purely transaction metadata
      if (_skipLineRe.hasMatch(line)) continue;

      final priceStr = priceMatch.group(1)!.replaceAll(',', '');
      double linePrice = double.tryParse(priceStr) ?? 0.0;

      // Determine product text descriptor using context fallback tracking
      String itemText = line.substring(0, priceMatch.start).trim();

      // LOOK-BEHIND MULTI-LINE BUFFERING FIX:
      // If the item text segment on this line is empty or too short, look up to the previous line!
      if ((itemText.isEmpty ||
              RegExp(r'^[\d\s\-•*,.@xX]+$').hasMatch(itemText)) &&
          i > 0) {
        final previousLine = lines[i - 1];
        if (!_skipLineRe.hasMatch(previousLine) &&
            !_priceRe.hasMatch(previousLine)) {
          itemText = previousLine;
        }
      }

      int quantity = 1;
      double unitPrice = linePrice;

      // Parse quantity structures out of the text string
      for (final pattern in _qtyPatterns) {
        final qtyMatch = pattern.firstMatch(itemText);
        if (qtyMatch != null) {
          quantity = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
          unitPrice = double.tryParse(qtyMatch.group(2) ?? '0') ?? linePrice;
          itemText = itemText.replaceAll(qtyMatch.group(0)!, '').trim();
          break;
        }
      }

      // CLEANUP BARCODES: Strip any leftover leading numbers, symbols, dots or index keys
      itemText = itemText.replaceAll(RegExp(r'^[\d\s\-•*,.@xX#]+'), '').trim();
      itemText = itemText.replaceAll(RegExp(r'[\d\s\-•*,.@xX]+$'), '').trim();

      // Final validation guards for your clean items list array
      if (itemText.length < 2 ||
          itemText.length > 80 ||
          itemText.toLowerCase().contains('total')) {
        continue;
      }

      items.add(
        ReceiptItem(
          name: itemText.toUpperCase(),
          price: linePrice,
          quantity: quantity,
          category: categorizeItem(itemText),
          unitPrice: unitPrice,
        ),
      );
      calculatedSubtotal += linePrice;
    }

    return ReceiptModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: receiptDate ?? DateTime.now(),
      amount: extractedTotal > 0 ? extractedTotal : calculatedSubtotal,
      subtotal: calculatedSubtotal,
      tax: 0.0,
      serviceCharge: 0.0,
      imagePath: imagePath,
      receiptType: 'scan',
      merchantName: merchantName,
      category: items.isNotEmpty ? items.first.category : 'Groceries',
      currency: 'RM',
      ocrStatus: 'SUCCESS',
      processed: false,
      items: items, // Fully structured items populated
    );
  }

  static DateTime? _parseMalaysianDate(String dateStr) {
    try {
      final parts = dateStr.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    } catch (e) {}
    return null;
  }

  static String categorizeItem(String itemName) {
    final lower = itemName.toLowerCase();
    if (RegExp(
      r'cili|kobis|lobak|bawang|kentang|tomato|sayur|vegetable|halia|daun|broccoli|carrot',
    ).hasMatch(lower)) {
      return 'Fresh Vegetables';
    }
    if (RegExp(
      r'whiskas|fiskies|pedigree|pet|pad|diaper|cat|dog|tuna\s*wet|puppy|kitten',
    ).hasMatch(lower)) {
      return 'Pet Supplies';
    }
    if (RegExp(
      r'ajinomoto|bihun|gula|garam|kicap|sos|oil|minyak|tepung|beras|rice|flour',
    ).hasMatch(lower)) {
      return 'Cooking Ingredients';
    }
    if (RegExp(
      r'kool\s*fever|panadol|ubat|mask|sanitizer|vitamin|paracetamol|aspirin',
    ).hasMatch(lower)) {
      return 'Health & Medical';
    }
    if (RegExp(
      r'numee|shin|maggi|noodle|cup|indomie|mi\s*goreng',
    ).hasMatch(lower)) {
      return 'Instant Food';
    }
    if (RegExp(
      r'towel|tissue|vinda|kleenex|soap|shampoo|conditioner|clorox|detergent|cleaner',
    ).hasMatch(lower)) {
      return 'Household/Groceries';
    }
    if (RegExp(
      r'coke|pepsi|sprite|fanta|water|mineral|juice|milk|soy|tea|coffee|beverage',
    ).hasMatch(lower)) {
      return 'Beverages';
    }
    if (RegExp(
      r'biscuit|cookie|chocolate|candy|snack|chips|keropok|wafer',
    ).hasMatch(lower)) {
      return 'Snacks';
    }
    return 'Groceries';
  }
}
