import '../models/receipt_model.dart';
import 'package:flutter/foundation.dart';

class ReceiptParser {
  // Matches a decimal amount: optional RM/MYR prefix, digits, dot, 2 digits
  static final _priceRe = RegExp(
    r'(?:RM|MYR)?\s*(\d{1,6}\.\d{2})\b',
    caseSensitive: false,
  );

  // Lines to skip entirely — these are never items
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

  // Total-label lines — tells us the next/same-line amount is the grand total
  static final _totalLabelRe = RegExp(
    r'\b(GRAND\s*TOTAL|TOTAL\s*AMOUNT|NET\s*TOTAL|TOTAL|JUMLAH|AMAUN)\b',
    caseSensitive: false,
  );

  // Lines that look like only a decimal number (amount on its own line)
  static final _amountOnlyRe = RegExp(
    r'^\s*(?:RM|MYR)?\s*\d{1,6}\.\d{2}\s*$',
    caseSensitive: false,
  );

  // Strip leading quantity markers on receipts like "1x ", "2X ", "x "
  static final _qtyPrefixRe = RegExp(r'^\s*\d*[xXlL×]\s+');

  static ReceiptData parse(List<String> lines) {
    debugPrint("=== RECEIPT PARSER V2 ===");
    for (int i = 0; i < lines.length; i++) {
      debugPrint("Line $i: '${lines[i]}'");
    }

    final merchant = _extractMerchant(lines);
    final total = _extractTotal(lines);
    final items = _extractItems(lines, total);

    debugPrint("=== FINAL RESULT ===");
    debugPrint("Merchant: $merchant");
    debugPrint("Total: RM$total");
    debugPrint("Items (${items.length}):");
    for (final item in items) {
      debugPrint("  - ${item.name} [${item.category}]: RM${item.price}");
    }

    return ReceiptData(merchant: merchant, total: total, items: items);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOTAL EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────
  static double _extractTotal(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!_totalLabelRe.hasMatch(line)) continue;

      debugPrint("🔍 Total label found on line $i: $line");

      // Same-line price?
      final sameLinePrice = _lastPrice(line);
      if (sameLinePrice != null && sameLinePrice > 0) {
        debugPrint("💰 Total (same line): $sameLinePrice");
        return sameLinePrice;
      }

      // Next non-empty line price?
      for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
        final next = lines[j].trim();
        if (next.isEmpty) continue;
        final nextPrice = _lastPrice(next);
        if (nextPrice != null && nextPrice > 0) {
          debugPrint("💰 Total (next line): $nextPrice");
          return nextPrice;
        }
        break;
      }
    }

    // Fallback: largest price in the bottom third of the receipt,
    // skipping lines that look like cash-paid / change amounts.
    debugPrint("⚠️ No total label found, using fallback.");
    final startIdx = (lines.length * 2 / 3).floor();
    double largest = 0.0;
    for (int i = startIdx; i < lines.length; i++) {
      final line = lines[i];
      if (_skipLineRe.hasMatch(line.toUpperCase())) continue;
      final prices = _allPrices(line);
      for (final p in prices) {
        if (p > largest) largest = p;
      }
    }

    if (largest > 0) {
      debugPrint("💰 Total fallback: $largest");
      return largest;
    }

    return 0.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ITEM EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────
  static List<ReceiptItemOld> _extractItems(List<String> lines, double total) {
    final items = <ReceiptItemOld>[];
    final usedIndices = <int>{};

    // Pass A: same-line items
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (_skipLineRe.hasMatch(line.toUpperCase())) continue;
      if (_totalLabelRe.hasMatch(line)) continue;

      // Must contain at least one letter (so it's not a pure amount line)
      if (!line.contains(RegExp(r'[A-Za-z]'))) continue;

      final price = _lastPrice(line);
      if (price == null || price <= 0) continue;
      if (total > 0 && price >= total) continue; // skip subtotals / the total

      final description = _cleanName(line);
      if (description.length < 2) continue;

      items.add(_makeItem(description, price));
      usedIndices.add(i);
      debugPrint("✅ [A] $description: RM$price");
    }

    // Pass B: split items — name line followed by an amount-only line
    if (items.length < 2) {
      for (int i = 0; i < lines.length - 1; i++) {
        if (usedIndices.contains(i)) continue;

        final nameLine = lines[i].trim();
        if (nameLine.isEmpty) continue;
        if (!nameLine.contains(RegExp(r'[A-Za-z]'))) continue;
        if (_skipLineRe.hasMatch(nameLine.toUpperCase())) continue;
        if (_totalLabelRe.hasMatch(nameLine)) continue;

        // Check next non-empty line for an amount-only value
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          if (usedIndices.contains(j)) continue;
          final priceLine = lines[j].trim();
          if (priceLine.isEmpty) continue;

          if (_amountOnlyRe.hasMatch(priceLine)) {
            final price = _lastPrice(priceLine);
            if (price != null && price > 0 && (total == 0 || price < total)) {
              final description = _cleanName(nameLine);
              if (description.length >= 2) {
                items.add(_makeItem(description, price));
                usedIndices.add(i);
                usedIndices.add(j);
                debugPrint("✅ [B] $description: RM$price");
              }
            }
            break;
          }
          break;
        }
      }
    }

    return items;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MERCHANT EXTRACTION
  // ─────────────────────────────────────────────────────────────────────────
  static String _extractMerchant(List<String> lines) {
    final searchLimit = lines.length < 10 ? lines.length : 10;

    for (int i = 0; i < searchLimit; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (!line.contains(RegExp(r'[A-Za-z]'))) continue;
      if (_skipLineRe.hasMatch(line.toUpperCase())) continue;
      if (_totalLabelRe.hasMatch(line)) continue;

      final digitRatio =
          line.replaceAll(RegExp(r'[^0-9]'), '').length /
          line.replaceAll(' ', '').length;
      if (digitRatio > 0.5) continue;
      if (line.replaceAll(RegExp(r'\s'), '').length < 3) continue;

      // Deep clean Malaysian corporate suffixes and registration brackets
      String merchant = line
          .replaceAll(
            RegExp(r'\(?\d{6,}\)?'),
            '',
          ) // Long SSM or registration IDs
          .replaceAll(
            RegExp(r'\b(SDN\s*BHD|BHD|S\/B)\b', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'\(?[\d\-]{5,}\-[A-Z]\)?'),
            '',
          ) // (123456-X) formats
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

      if (merchant.length > 2) {
        // Enforce readable casing formatting
        return merchant
            .split(' ')
            .map((w) {
              return w.isEmpty
                  ? w
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
            })
            .join(' ');
      }
    }

    return "Unknown Store";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS & GRANULAR LOCAL CATEGORIZATION
  // ─────────────────────────────────────────────────────────────────────────
  static double? _lastPrice(String line) {
    final matches = _priceRe.allMatches(line);
    if (matches.isEmpty) return null;
    return double.tryParse(matches.last.group(1)!);
  }

  static List<double> _allPrices(String line) {
    return _priceRe
        .allMatches(line)
        .map((m) => double.tryParse(m.group(1)!) ?? 0.0)
        .where((v) => v > 0)
        .toList();
  }

  static String _cleanName(String line) {
    String name = line
        .replaceAll(
          RegExp(r'(?:RM|MYR)?\s*\d{1,6}\.\d{2}\s*$', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    // Strip leading receipt inline multiplier syntax (e.g., "2x Item")
    return name.replaceAll(_qtyPrefixRe, '').trim();
  }

  static ReceiptItemOld _makeItem(String name, double price) {
    // Normalizes "MEE KUNING CAP REBORD" -> "Mee Kuning Cap Rebord"
    final formattedName = name
        .toLowerCase()
        .split(' ')
        .map((w) {
          return w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}';
        })
        .join(' ');

    return ReceiptItemOld(
      name: formattedName,
      price: price,
      category: categorize(name),
      quantity: 1,
      unitPrice: price,
    );
  }

  static String categorize(String name) {
    final lower = name.toLowerCase();

    // 1. PET FOOD & SUPPLIES
    if (RegExp(
      r'cat|dog|pet|whiskas|makanan kucing|makanan anjing|kibble|pedigree|friskies|purina|royal canin',
    ).hasMatch(lower)) {
      return 'Pet Food';
    }

    // 2. HOUSEHOLD & PERSONAL HYGIENE
    if (RegExp(
      r'daia|softener|hand\s*wash|recycle\s*bag|detergen|sabun|syampu|shampoo|ubat\s*gigi|toothpaste|pencuci|cleaner|'
      r'soap|dishwash|floor\s*clean|febreze|dettol|dynamo|attack|rinso|harpic|breez|clorox|glo|colgate|sensodyne|darlie|'
      r'pad|tuala\s*wanita|sanitary|kotex|whisper|laurier|sofy|libresse|'
      r'tissue|tisu|wet\s*tissue|wet\s*wipes|facial\s*tisu|pocket\s*tisu|pop\s*up\s*tisu|kleenex|vinda|scott|premier|cutie|royal\s*gold|paseo',
    ).hasMatch(lower)) {
      return 'Household';
    }

    // 3. MALAYSIAN BEVERAGES
    if (RegExp(
      r'milo|nescafe|teh|kopi|coffee|tea|mineral|jus|soda|minuman|coca|pepsi|cola|juice|water|drink|beverage|100plus|100\s*plus|'
      r'isotonic|vitagen|yakult|ribena|f&n|pokka|spritzer|season|heaven\s*&\s*earth|yeo|marigold|chrysanthemum|susu\s*kotak|'
      r'dutch\s*lady|fernleaf|goodday|milklab|sirap|ros|bandung|cincau|soya|vico|horlicks|neslo',
    ).hasMatch(lower)) {
      return 'Beverages';
    }

    // 4. BAKING SUPPLIES & BAKERY
    if (RegExp(
      r'tepung\s*gandum|tepung\s*kek|tepung\s*jagung|tepung\s*beras|tepung\s*pulut|flour|baking\s*powder|baking\s*soda|'
      r'soda\s*bikarbonat|yeast|yis|mauripan|cucur|jemput\s*jemput|fritter|tepung\s*wangi|tepung\s*gorang|'
      r'gardenia|massimo|roti|loaf|classic\s*white|bonanza|somerset|wholemeal|twiggies|muffins|waffles|delicia|toastem|quick\s*bites|'
      r'butter|mentega|anchor|scb|buttercup|marjerin|margarine|planta|ghee|minyak\s*sapi|vanilla|esen|cocoa\s*powder|serbuk\s*koko|'
      r'icing\s*sugar|gula\s*aising|whipping\s*cream|whip\s*cream|cheese\s*cream|cream\s*cheese|tatura|philadelphia|mozzarella|cheddar|choc\s*chip',
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
      r'sardine|sardin|tuna|tinned|tin|adabi|baba|brahim|faiza|alagappa|mak\s*nyonya|perencah|pes\s*segera|paste|serbuk\s*kari|curry\s*powder|'
      r'rempah|kurma|sup|soto|rendang|bunga\s*cengkih|clove|kayu\s*manis|cinnamon|bunga\s*lawang|star\s*anise|buah\s*pelaga|cardamom|'
      r'jintan|cummin|fennel|ketumbar|coriander|lada|pepper|kunyit|turmeric|halba|fenugreek|kas-kas|asam\s*jawa|tamarind|asam\s*keping|'
      r'kerisik|gula\s*melaka|palm\s*sugar|telur|egg|gred\s*[a-f]|grade\s*[a-f]|omega|nutriplus|ltkm|ql\s*eggs|eco\s*egg|'
      r'ayam|chicken|daging|beef|kambing|mutton|ikan|fish|udang|prawn|sotong|squid|bawang|onion|garlic|halia|ginger|cili|chili|serai|lemongrass|'
      r'daun\s*bawang|spring\s*onion|daun\s*sup|celery\s*leaf|cilantro|pudina|mint|sayur|vegetable|kobis|sawi|bayam|carrot|kentang|potato|tomato|'
      r'garam|salt|gula|sugar|ajinomoto|msg|perasa|kiub|cube|santan|coconut\s*milk',
    ).hasMatch(lower)) {
      return 'Cooking Ingredients';
    }

    // 6. SNACKS, BISCUITS & READY-TO-EAT DESSERTS
    if (RegExp(
      r'cracker|snack|biscuit|biskut|munchys|hup\s*seng|lexus|oreo|tiger|cooki|cake|kek|chocolate|coklat|candy|gula\s*gula|'
      r'keropok|lekor|kuih|dodol|chips|lays|pringles|mister\s*potato|potato\s*chip|mamee|twisties|super\s*ring|ice\s*cream|aiskrim|nestle|walls|yogurt',
    ).hasMatch(lower)) {
      return 'Snacks & Desserts';
    }

    // 7. HEALTH & PHARMACY
    if (RegExp(
      r'ubat|medicine|vitamin|supplement|panadol|pharmacy|farmasi|mask|sanitizer|antiseptic|bandage|plaster|hurix|gaviscon|eno|strepsils|vicks',
    ).hasMatch(lower)) {
      return 'Health';
    }

    // 8. TRANSPORT & FUEL
    if (RegExp(
      r'parking|petrol|toll|transport|grab|bus|mrt|ktm|touch\s*n\s*go|tng|petron|shell|caltex|petronas|bhp\s*fuel',
    ).hasMatch(lower)) {
      return 'Transport';
    }

    return 'Others';
  }
}
