// lib/parser/receipt_parser.dart
import '../models/receipt_model.dart';

class ReceiptParser {
  static final _rawPriceCheck = RegExp(r'\d+\.\d{2}');

  static final _dateRe = RegExp(
    r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
    caseSensitive: false,
  );

  // IMPROVED: Better merchant name patterns
  static final _merchantRe = RegExp(
    r'^(?:[A-Z][A-Z\s&.]{2,50}(?:SDN\s*BHD|BHD|ENTERPRISE|TRADING|STORE|MART|SUPERMARKET|RESTAURANT|CAFE|BAKERY|PHARMACY)?)',
    caseSensitive: false,
  );

  // NEW: Patterns that indicate a line is likely a merchant name
  static final _merchantIndicatorRe = RegExp(
    r'\b(STORE|MART|SUPERMARKET|RESTAURANT|CAFE|BAKERY|PHARMACY|TRADING|ENTERPRISE|SDN|BHD|SHOP)\b',
    caseSensitive: false,
  );

  // NEW: Patterns that should NEVER be merchant names (barcodes, receipt numbers)
  static final _invalidMerchantRe = RegExp(
    r'^\d{10,}$|^\d{3,}[- ]?\d{3,}$|^[A-Z]{2}\d{6,}$|^(?:ITEM|QTY|TOTAL|SUBTOTAL|CASH|CHANGE|VISA|MASTER)',
    caseSensitive: false,
  );

  static final _skipLineRe = RegExp(
    r'\b(CASH|CHANGE|TUNAI|BAKI|TENDER|PAYMENT|CARD|CREDIT|DEBIT|'
    r'CASHIER|KASIR|OPERATOR|RECEIPT|INVOICE|TABLE|ORDER|SERVER|STAFF|'
    r'DATE|TIME|TARIKH|MASA|TEL|PHONE|FAX|EMAIL|WEBSITE|'
    r'TRANSACTION|REF|REFERENCE|MEMBER|POINT|POINTS|'
    r'DISCOUNT|DISKAUN|TAX|GST|SST|SERVICE\s*CHARGE|'
    r'ITEM\s*COUNT|TOTAL\s*ITEM|TOTAL\s*QTY|'
    r'SUBTOTAL|SUB\s*TOTAL|THANK\s*YOU|TERIMA\s*KASIH|'
    r'JALAN|LOT\s*\d|UNIT\s*\d|SDN\s*BHD|NO\.\s*\d|'
    r'VISA|MASTER|AMEX|APPROCODE|APPR|OCODE|ITEN|ITEM|SPEC|DISC|SAVING|ROUNDING)\b',
    caseSensitive: false,
  );

  static final _totalRe = RegExp(
    r'\b(TOTAL|JUMLAH|GRAND\s*TOTAL|AMOUNT|AMOUNT\s*DUE):?\s*(?:RM|MYR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)',
    caseSensitive: false,
  );

  static final _isBarcodeRowRe = RegExp(r'^[\d\s\-•*,.@xX#|/]+[A-Z]?\s*$');

  static final _supermarketKeywords = RegExp(
    r'\b(MART|SUPERMARKET|HYPERMARKET|GROCER|GROCERY|MYDIN|AEON|JASON|LOTUS|GIANT|NSK|SPEEDMART|7-ELEVEN|PASAR|COWBOY)\b',
    caseSensitive: false,
  );

  static final _bookStoreKeywords = RegExp(
    r'\b(BOOK|BOOKS|STATIONERY|POPULAR|KINOKUNIYA|MPH)\b',
    caseSensitive: false,
  );

  static final _restaurantCafeKeywords = RegExp(
    r'\b(RESTAURANT|RESTORAN|CAFE|KOPITIAM|COFFEE|ZUS|TEALIVE|STARBUCKS|MCDONALD|KFC|BURGER|PIZZA|BAKERY)\b',
    caseSensitive: false,
  );

  static final _pharmacyKeywords = RegExp(
    r'\b(PHARMACY|FARMASI|WATSONS|GUARDIAN|CARING|CLINIC|MEDICAL)\b',
    caseSensitive: false,
  );

  static String detectEstablishmentType(String merchantName, String rawText) {
    final searchBlock = '$merchantName \n $rawText'.toLowerCase();
    if (_restaurantCafeKeywords.hasMatch(searchBlock))
      return 'Restaurant / Café';
    if (_pharmacyKeywords.hasMatch(searchBlock)) return 'Pharmacy / Healthcare';
    if (_bookStoreKeywords.hasMatch(searchBlock))
      return 'Book Store / Stationery';
    if (_supermarketKeywords.hasMatch(searchBlock))
      return 'Supermarket / Convenience Store';
    return 'General Retail';
  }

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

    // IMPROVED: Better merchant name extraction
    // First, look for lines that look like merchant names
    for (int i = 0; i < lines.length && i < 15; i++) {
      final line = lines[i];

      // Skip lines that are too short or look like barcodes
      if (line.length < 3 || _invalidMerchantRe.hasMatch(line)) {
        continue;
      }

      // Check if line contains merchant indicators
      if (_merchantIndicatorRe.hasMatch(line)) {
        merchantName = line.replaceAll(RegExp(r'\s+'), ' ').trim();
        print('📦 Found merchant name from indicator: $merchantName');
        break;
      }

      // Try regex match
      final merchantMatch = _merchantRe.firstMatch(line);
      if (merchantMatch != null && line.length > 4 && line.length < 50) {
        merchantName = merchantMatch.group(0)!.trim();
        print('📦 Found merchant name from regex: $merchantName');
        break;
      }
    }

    // If still unknown, try the first non-barcode line
    if (merchantName == "Unknown Store") {
      for (int i = 0; i < lines.length && i < 10; i++) {
        final line = lines[i];
        if (line.length > 3 &&
            line.length < 50 &&
            !_invalidMerchantRe.hasMatch(line) &&
            !_skipLineRe.hasMatch(line) &&
            !line.contains('.') &&
            !line.contains(':')) {
          merchantName = line.trim();
          print('📦 Found merchant name from fallback: $merchantName');
          break;
        }
      }
    }

    // Extract date
    for (int i = 0; i < lines.length && i < 15; i++) {
      if (receiptDate == null) {
        final dateMatch = _dateRe.firstMatch(lines[i]);
        if (dateMatch != null) {
          receiptDate = _parseMalaysianDate(dateMatch.group(1)!);
        }
      }
    }

    final priceFinderRegExp = RegExp(r'\d+[\.,]\d{2}');

    // Process line items
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      if (RegExp(
        r'\b(visa|master|amex|card|\d{4}x+)\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        continue;
      }

      final totalMatch = _totalRe.firstMatch(line);
      if (totalMatch != null) {
        final amountStr = totalMatch.group(2)!.replaceAll(',', '');
        double parsedTotal = double.tryParse(amountStr) ?? 0.0;
        if (parsedTotal > extractedTotal) extractedTotal = parsedTotal;
        continue;
      }

      if (lowerLine.contains('subtotal') ||
          lowerLine.contains('grand total') ||
          lowerLine.contains('amount due') ||
          lowerLine.contains('cash') ||
          lowerLine.contains('change')) {
        continue;
      }

      final Iterable<RegExpMatch> priceMatches = priceFinderRegExp.allMatches(
        line,
      );
      if (priceMatches.isEmpty) {
        continue;
      }

      final lastPriceMatch = priceMatches.last;
      String rawPriceStr = lastPriceMatch.group(0)!;
      double? linePrice = double.tryParse(rawPriceStr.replaceAll(',', '.'));
      if (linePrice == null) continue;

      String itemText = line.substring(0, lastPriceMatch.start).trim();

      int quantity = 1;
      double unitPrice = linePrice;

      final multiplierMatch = RegExp(
        r'(\d+)\s*[xX@]\s*(\d+[\.,]\d{2})',
      ).firstMatch(line);
      if (multiplierMatch != null) {
        quantity = int.tryParse(multiplierMatch.group(1) ?? '1') ?? 1;
        String mPrice = (multiplierMatch.group(2) ?? '0').replaceAll(',', '.');
        unitPrice = double.tryParse(mPrice) ?? linePrice;
        itemText = itemText.replaceAll(multiplierMatch.group(0)!, '').trim();
      }

      // Backtrack for item names
      if (itemText.isEmpty ||
          _isBarcodeRowRe.hasMatch(itemText) ||
          itemText.trim() == '|') {
        String accumulatedDescription = "";
        int lookBack = i - 1;
        int linesCaptured = 0;

        while (lookBack >= 0 && linesCaptured < 3) {
          final targetLine = lines[lookBack];
          final targetLower = targetLine.toLowerCase();

          if (targetLower.contains('total') ||
              targetLower.contains('cash') ||
              priceFinderRegExp.hasMatch(targetLine)) {
            break;
          }

          if (!_isBarcodeRowRe.hasMatch(targetLine) &&
              targetLine.trim().isNotEmpty &&
              targetLine.trim() != '|' &&
              !_invalidMerchantRe.hasMatch(targetLine)) {
            accumulatedDescription = targetLine + " " + accumulatedDescription;
            linesCaptured++;
          }
          lookBack--;
        }

        if (accumulatedDescription.trim().isNotEmpty) {
          itemText = accumulatedDescription.trim();
        }
      }

      // Clean up item text
      itemText = itemText.replaceAll(RegExp(r'^[\s\-•*,.@xX#|/]+'), '').trim();
      itemText = itemText
          .replaceAll(RegExp(r'^\b\d{3,18}\b[\s\-]*'), '')
          .trim();
      itemText = itemText.replaceAll(RegExp(r'[\d\s\-•*,.@xX|/]+$'), '').trim();

      if (itemText.endsWith(' U') ||
          itemText.endsWith(' X') ||
          itemText.endsWith(' |') ||
          itemText.endsWith(' S') ||
          itemText.endsWith(' Z')) {
        itemText = itemText.substring(0, itemText.length - 2).trim();
      }

      if (itemText.length < 2 ||
          itemText.toLowerCase() == 'total' ||
          itemText.toLowerCase() == 'jumlah') {
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

    final establishmentType = detectEstablishmentType(merchantName, rawText);

    print('📋 PARSED RECEIPT:');
    print('   Merchant: $merchantName');
    print(
      '   Amount: ${extractedTotal > 0 ? extractedTotal : calculatedSubtotal}',
    );
    print('   Items: ${items.length}');

    return ReceiptModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
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
      items: items,
      establishmentType: establishmentType,
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
    ).hasMatch(lower))
      return 'Fresh Vegetables';
    if (RegExp(
      r'whiskas|fiskies|pedigree|pet|pad|diaper|cat|dog|tuna\s*wet|puppy|kitten',
    ).hasMatch(lower))
      return 'Pet Supplies';
    if (RegExp(
      r'ajinomoto|bihun|gula|garam|kicap|sos|oil|minyak|tepung|beras|rice|flour',
    ).hasMatch(lower))
      return 'Cooking Ingredients';
    if (RegExp(
      r'kool\s*fever|panadol|ubat|mask|sanitizer|vitamin|paracetamol|aspirin',
    ).hasMatch(lower))
      return 'Health & Medical';
    if (RegExp(
      r'numee|shin|maggi|noodle|cup|indomie|mi\s*goreng',
    ).hasMatch(lower))
      return 'Instant Food';
    if (RegExp(
      r'towel|tissue|vinda|kleenex|soap|shampoo|conditioner|clorox|detergent|cleaner|trash\s*bag|fan|bag',
    ).hasMatch(lower))
      return 'Household/Groceries';
    if (RegExp(
      r'coke|pepsi|sprite|fanta|water|mineral|juice|milk|soy|tea|coffee|beverage',
    ).hasMatch(lower))
      return 'Beverages';
    if (RegExp(
      r'biscuit|cookie|chocolate|candy|snack|chips|keropok|wafer',
    ).hasMatch(lower))
      return 'Snacks';
    return 'Groceries';
  }
}
