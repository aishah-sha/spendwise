import '../models/receipt_model.dart';

class ReceiptParser {
  // Price patterns - supports RM, MYR, and plain numbers
  static final _priceRe = RegExp(
    r'(?:RM|MYR|M\s?Y\s?R)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\b',
    caseSensitive: false,
  );

  // Date patterns (Malaysian format: DD/MM/YYYY, DD-MM-YYYY, etc.)
  static final _dateRe = RegExp(
    r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
    caseSensitive: false,
  );

  // Merchant patterns
  static final _merchantRe = RegExp(
    r'^([A-Z][A-Z\s&.]{3,50}(?:SDN\s*BHD|BHD|ENTERPRISE|TRADING|STORE|MART|SUPERMARKET)?)',
    caseSensitive: false,
  );

  // Skip patterns
  static final _skipLineRe = RegExp(
    r'\b(CASH|CHANGE|TUNAI|BAKI|TENDER|PAYMENT|CARD|CREDIT|DEBIT|'
    r'CASHIER|KASIR|OPERATOR|RECEIPT|INVOICE|TABLE|ORDER|SERVER|STAFF|'
    r'DATE|TIME|TARIKH|MASA|TEL|PHONE|FAX|EMAIL|WEBSITE|'
    r'TRANSACTION|REF|REFERENCE|MEMBER|POINT|POINTS|'
    r'DISCOUNT|DISKAUN|ROUNDING|TAX|GST|SST|SERVICE\s*CHARGE|'
    r'ITEM\s*COUNT|TOTAL\s*ITEM|TOTAL\s*QTY|'
    r'SUBTOTAL|SUB\s*TOTAL|THANK\s*YOU|TERIMA\s*KASIH|'
    r'JALAN|LOT\s*\d|UNIT\s*\d|SDN\s*BHD|NO\.\s*\d)\b',
    caseSensitive: false,
  );

  // Quantity patterns
  static final _qtyPatterns = [
    RegExp(r'^(\d{1,3})\s*[xX@]\s*(?:RM|MYR)?\s*(\d+(?:\.\d{2})?)'),
    RegExp(r'^(\d{1,3})\s+(?:RM|MYR)?\s*(\d+(?:\.\d{2})?)$'),
    RegExp(r'(\d{1,3})\s*[xX]\s*(?:RM|MYR)?\s*(\d+(?:\.\d{2})?)'),
  ];

  // Total amount indicators
  static final _totalRe = RegExp(
    r'\b(TOTAL|JUMLAH|GRAND\s*TOTAL|AMOUNT|AMOUNT\s*DUE):?\s*(?:RM|MYR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
    caseSensitive: false,
  );

  static ReceiptModel parseRawText(String rawText, {String? imagePath}) {
    final lines = rawText.split('\n');
    final List<ReceiptItem> items = [];

    String merchantName = "Unknown Merchant";
    DateTime? receiptDate;
    double extractedTotal = 0.0;
    double calculatedSubtotal = 0.0;

    // First pass: Extract merchant and date
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Extract merchant name
      if (merchantName == "Unknown Merchant") {
        final merchantMatch = _merchantRe.firstMatch(line);
        if (merchantMatch != null && line.length > 5 && line.length < 100) {
          merchantName = merchantMatch.group(1)!.trim();
          merchantName = merchantName.replaceAll(RegExp(r'\s+'), ' ').trim();
        } else if (line.length > 5 &&
            line.length < 80 &&
            !_skipLineRe.hasMatch(line) &&
            !_priceRe.hasMatch(line) &&
            !line.contains(':')) {
          merchantName = line.trim();
        }
      }

      // Extract date
      if (receiptDate == null) {
        final dateMatch = _dateRe.firstMatch(line);
        if (dateMatch != null) {
          receiptDate = _parseMalaysianDate(dateMatch.group(1)!);
        }
      }
    }

    // Second pass: Process items
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check for total amount
      final totalMatch = _totalRe.firstMatch(trimmed);
      if (totalMatch != null) {
        final amountStr = totalMatch.group(2)!.replaceAll(',', '');
        extractedTotal = double.tryParse(amountStr) ?? 0.0;
        continue;
      }

      // Skip lines without prices
      final priceMatch = _priceRe.firstMatch(trimmed);
      if (priceMatch == null) continue;

      // Skip non-item lines
      if (_skipLineRe.hasMatch(trimmed)) continue;

      final priceStr = priceMatch.group(1)!.replaceAll(',', '');
      double linePrice = double.tryParse(priceStr) ?? 0.0;

      // Get item text
      String itemText = trimmed.substring(0, priceMatch.start).trim();
      if (itemText.isEmpty) {
        itemText = trimmed.replaceAll(priceMatch.group(0)!, '').trim();
      }

      int quantity = 1;
      double unitPrice = linePrice;

      // Extract quantity
      for (final pattern in _qtyPatterns) {
        final qtyMatch = pattern.firstMatch(itemText);
        if (qtyMatch != null) {
          final qtyStr = qtyMatch.group(1);
          final priceStr2 = qtyMatch.group(2);

          if (qtyStr != null && priceStr2 != null) {
            quantity = int.tryParse(qtyStr) ?? 1;
            final extractedPrice = double.tryParse(
              priceStr2.replaceAll(',', ''),
            );
            if (extractedPrice != null) {
              unitPrice = extractedPrice;
              linePrice = unitPrice * quantity;
            }
            itemText = itemText.replaceAll(qtyMatch.group(0)!, '').trim();
          }
          break;
        }
      }

      // Clean up item text
      itemText = itemText
          .replaceAll(RegExp(r'^[\d\s\-•*,.@xX]+|[\d\s\-•*,.@xX]+$'), '')
          .trim();

      // Validate item
      if (itemText.length < 2 ||
          itemText.length > 100 ||
          itemText.contains('PROMO') ||
          itemText.contains('DISCOUNT')) {
        continue;
      }

      final category = categorizeItem(itemText);

      items.add(
        ReceiptItem(
          name: itemText,
          price: linePrice,
          quantity: quantity,
          category: category,
          unitPrice: unitPrice,
        ),
      );

      calculatedSubtotal += linePrice;
    }

    // Fallback: simpler parsing if no items found
    if (items.isEmpty) {
      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final priceMatch = _priceRe.firstMatch(trimmed);
        if (priceMatch != null && !_skipLineRe.hasMatch(trimmed)) {
          final priceStr = priceMatch.group(1)!.replaceAll(',', '');
          double linePrice = double.tryParse(priceStr) ?? 0.0;

          String itemText = trimmed.replaceAll(priceMatch.group(0)!, '').trim();
          itemText = itemText
              .replaceAll(RegExp(r'^[\d\s\-•*,.]+|[\d\s\-•*,.]+$'), '')
              .trim();

          if (itemText.isNotEmpty &&
              itemText.length >= 2 &&
              itemText.length <= 100) {
            items.add(
              ReceiptItem(
                name: itemText,
                price: linePrice,
                quantity: 1,
                category: categorizeItem(itemText),
                unitPrice: linePrice,
              ),
            );
            calculatedSubtotal += linePrice;
          }
        }
      }
    }

    // Use extracted total or calculated subtotal
    final finalAmount = extractedTotal > 0
        ? extractedTotal
        : calculatedSubtotal;

    return ReceiptModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: receiptDate ?? DateTime.now(),
      amount: finalAmount,
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
      items: items,
    );
  }

  static DateTime? _parseMalaysianDate(String dateStr) {
    try {
      final parts = dateStr.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        if (year < 100) {
          year += 2000;
        }

        return DateTime(year, month, day);
      }
    } catch (e) {
      // Ignore parsing errors
    }
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
