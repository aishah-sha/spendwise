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
      category: items.isNotEmpty ? items.first.category : 'Others',
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

    // 1. Fresh Vegetables
    if (RegExp(
      r'cili|kobis|lobak|bawang|kentang|tomato|sayur|vegetable|halia|daun|'
      r'broccoli|carrot|sawi|bayam|kangkung|peria|terung|'
      r'labu|timun|jagung|kacang\s*panjang|pucuk|ulam|seleri|capsicum|'
      r'lettuce|spinach|zucchini|leek|mushroom|cendawan|'
      r'petola|kailan|pakchoy|bendi|rebung|taugeh|salad',
    ).hasMatch(lower))
      return 'Fresh Vegetables';

    // 2. Fresh Meat & Seafood
    if (RegExp(
      r'ayam|chicken|daging|beef|meat|kambing|lamb|lembu|'
      r'ikan|fish|salmon|tuna|kembung|selayang|merah|'
      r'udang|prawn|shrimp|sotong|squid|kekah|cuttlefish|'
      r'ketam|crab|kerang|shellfish|mussel|clams|'
      r'kepah|scallop|bivalve|lobster|'
      r'daging\s*ayam|daging\s*lembu|daging\s*kambing|'
      r'fillet|steak|chop|cutlet|'
      r'seafood|sea\s*food|'
      r'fresh\s*chicken|fresh\s*fish|fresh\s*meat',
    ).hasMatch(lower))
      return 'Fresh Meat & Seafood';

    // 3. Cooking Ingredients (excluding baking items)
    if (RegExp(
      r'ajinomoto|gula|garam|kicap|sos|oil|minyak|santan|serbuk|rempah|'
      r'bawang|halia|bawang\s*putih|bawang\s*merah|kunyit|asam|belacan|'
      r'ikan\s*bilis|udang\s*kering|mentega|marjerin|keju|'
      r'cuka|perasa|daun|kicap\s*pekat|kicap\s*masin|'
      r'sos\s*tiram|sos\s*cili|sos\s*tomato|perencah|kerisik|'
      r'gula\s*merah|gula\s*pasir|garam\s*halus|cili\s*kering|'
      r'lada|lada\s*hitam|lada\s*putih|jintan|ketumbar|'
      r'kayu\s*manis|bunga\s*lawang|pati|esen|'
      r'cendawan|kacang|tauhu|tempe|sagu|tepung\s*jagung|'
      r'pandan|gula\s*melaka|sirap|madu|santan\s*pekat|santan\s*segar|'
      r'beras|rice|mi|mee|laksa|kuey\s*teow|'
      r'telur|susu\s*pekat|susu\s*cair',
    ).hasMatch(lower))
      return 'Cooking Ingredients';

    // 4. Baking Ingredients (NEW - separate from cooking)
    if (RegExp(
      r'tepung\s*gandum|flour|all\s*purpose\s*flour|plain\s*flour|self\s*raising\s*flour|'
      r'bread\s*flour|cake\s*flour|pastry\s*flour|'
      r'baking\s*powder|baking\s*soda|bicarbonate\s*soda|'
      r'yeast|yis|instant\s*yeast|active\s*dry\s*yeast|'
      r'butter|unsalted\s*butter|salted\s*butter|marjerin|margarine|'
      r'chocolate\s*chips|cocoa\s*powder|cacao|'
      r'vanilla\s*essence|vanilla\s*extract|'
      r'food\s*colouring|food\s*color|'
      r'sprinkles|hundreds\s*and\s*thousands|'
      r'icing\s*sugar|powdered\s*sugar|confectioners\s*sugar|'
      r'brown\s*sugar|castor\s*sugar|'
      r'cornflour|corn\s*starch|'
      r'cream\s*of\s*tartar|'
      r'cake\s*mix|brownie\s*mix|cookie\s*mix|'
      r'fondant|marzipan|icing|ganache|'
      r'pastry|puff\s*pastry|shortcrust|'
      r'breadcrumbs|bread\s*crumbs',
    ).hasMatch(lower))
      return 'Baking Ingredients';

    // 5. Instant Food & Drinks
    if (RegExp(
      r'numee|shin|maggi|noodle|cup|indomie|mi\s*goreng|mi\s*sedap|mi\s*segera|instant\s*noodle|'
      r'koka|mamee|mee\s*kuning|paroh|nissin|nongshim|samyang|jin\s*ramen|'
      r'ottogi|paldo|myojo|ichiban|ichiban\s*kia|supermi|sarimi|'
      r'mi\s*goreng\s*kari|cup\s*noodle|cup\s*mi|mug\s*noodle|'
      r'instant\s*soup|tom\s*yam|kari\s*instant|'
      r'bihun\s*sup|bihun\s*goreng|laksa\s*instant|asam\s*laksa\s*instant|'
      r'porridge\s*instant|bubur\s*instant|oat\s*instant|cereal\s*instant|'
      r'3\s*in\s*1|kopi\s*o|milo|nescafe|horlicks|'
      r'sup\s*tulang\s*instant|tomyam\s*cup|seri\s*mi|'
      r'white\s*coffee|teh\s*o|teh\s*tarik\s*instant',
    ).hasMatch(lower))
      return 'Instant Food & Drinks';

    // 6. Beverages (including coffee shop drinks)
    if (RegExp(
      r'coke|pepsi|sprite|fanta|water|mineral|juice|milk|soy|tea|coffee|beverage|'
      r'100\s*plus|f&n|season|ribena|yeos|vitagen|marigold|dutch\s*lady|'
      r'nescafe|milo|horlicks|ovaltine|nutriplus|carbonated|soft\s*drink|soda|'
      r'isotonic|sports\s*drink|energy\s*drink|redbull|red\s*bull|livita|'
      r'ice\s*mountain|spritzer|cactus|evian|aqua|bottled\s*water|'
      r'sparkling\s*water|soda\s*water|tonic\s*water|cordial|syrup|sirap|'
      r'sirap\s*bandung|bandung|teh\s*tarik|teh\s*o|teh\s*c|'
      r'kopi\s*o|kopi\s*c|kopi\s*susu|white\s*coffee|black\s*coffee|'
      r'green\s*tea|oolong|barley|barli|lemon\s*tea|honey\s*lemon|'
      r'chrysanthemum|bunga\s*kekwa|winter\s*melon|tikam\s*tikam|'
      r'asam\s*boi|longan|soya\s*bean|soya\s*milk|almond\s*milk|'
      r'oat\s*milk|coconut\s*water|kelapa|fruit\s*juice|orange\s*juice|'
      r'apple\s*juice|grape\s*juice|mango\s*juice|cranberry|'
      r'tropicana|minute\s*maid|sunkist|schweppes|canada\s*dry|ginger\s*ale|'
      r'root\s*beer|a&w|yakult|calpis|pocari\s*sweat|h2o|evernew|bevvy|'
      r'freshly\s*squeezed|smoothie|milkshake|frappe|'
      r'latte|cappuccino|espresso|americano|mocha|'
      r'frappuccino|flat\s*white|macchiato|affogato|cortado|'
      r'cold\s*brew|nitro|pour\s*over|filter\s*coffee|drip\s*coffee|'
      r'bubble\s*tea|milk\s*tea|pearl\s*tea|boba|'
      r'matcha|green\s*tea\s*latte|chai|chai\s*latte|'
      r'hot\s*chocolate|chocolate\s*drink|'
      r'starbucks|starbuck|starb|tealive|coffee\s*bean|zus\s*coffee|'
      r'beer|stout|wine|whisky|vodka|liquor|alcohol|'
      r'carlsberg|tiger\s*beer|heineken|guinness',
    ).hasMatch(lower))
      return 'Beverages';

    // 7. Snacks (chips, biscuits, candy - NOT desserts)
    if (RegExp(
      r'biscuit|cookie|chips|keropok|wafer|kerepek|munchies|'
      r'potato\s*chip|tortilla\s*chip|nachos|popcorn|pretzel|'
      r'cracker|jacobs|oreo|ritz|tiger\s*biscuit|marie\s*biscuit|'
      r'khong\s*guan|julies|munchys|hup\s*seng|cap\s*ping\s*pong|'
      r'twisties|mister\s*potato|lays|pringles|doritos|cheetos|'
      r'calbee|tao\s*kae\s*noi|seaweed\s*snack|fish\s*snack|'
      r'ikan\s*bilis\s*snack|kacang|peanut|cashew|almond|pistachio|'
      r'mixed\s*nuts|kacang\s*tanah|dried\s*fruit|raisin|prune|apricot|'
      r'jelly|gummy|marshmallow|gum|chewing\s*gum|mentos|polo|'
      r'hacks|fisherman\s*friend|toffee|caramel|nougat|'
      r'chocolate\s*bar|kitkat|cadbury|snickers|twix|mars|'
      r'milky\s*way|ferrero|kinder|toblerone|m&m|skittles|'
      r'haw\s*flakes|white\s*rabbit|beryl|van\s*houten|'
      r'nutella|spread|jam|kaya|peanut\s*butter|honey\s*spread|'
      r'nugget|sosej|sausage\s*roll|'
      r'curry\s*puff|karipap|popiah|spring\s*roll|pau|bun',
    ).hasMatch(lower))
      return 'Snacks';

    // 8. Desserts (NEW - separate from snacks)
    if (RegExp(
      r'cake|kek|sponge|cheesecake|chocolate\s*cake|vanilla\s*cake|'
      r'cupcake|muffin|blueberry\s*muffin|chocolate\s*muffin|'
      r'donut|doughnut|glazed|sprinkles|cronut|'
      r'pastry|choux|eclair|cream\s*puff|profiterole|'
      r'tart|pie|apple\s*pie|lemon\s*tart|pecan\s*pie|'
      r'brownie|blondie|slice|bar|'
      r'scone|shortbread|biscotti|'
      r'cinnamon\s*roll|swiss\s*roll|'
      r'banana\s*bread|pound\s*cake|'
      r'ice\s*cream|popsicle|ice\s*lolly|sorbet|gelato|'
      r'wall\s*street|magnum|cornetto|drumstick|'
      r'pudding|custard|mousse|panna\s*cotta|'
      r'waffle|pancake|crepe|french\s*toast|'
      r'danish|croissant|pain\s*au\s*chocolat|'
      r'meringue|macaron|macaroon|'
      r'flan|crème\s*brûlée|tiramisu',
    ).hasMatch(lower))
      return 'Desserts';

    // 9. Household/Groceries
    if (RegExp(
      r'towel|tissue|vinda|kleenex|soap|shampoo|conditioner|'
      r'clorox|detergent|cleaner|trash\s*bag|fan|bag|'
      r'scotch\s*brite|sponge|dishwashing\s*liquid|dish\s*soap|'
      r'softener|fabric\s*softener|bleach|mop|broom|penyapu|dust\s*pan|'
      r'vacuum|air\s*freshener|freshener|insecticide|ridsect|shieldtox|'
      r'mosquito\s*coil|mosquito\s*repellent|rat\s*poison|cockroach|'
      r'pest\s*control|toilet\s*bowl\s*cleaner|harpic|glass\s*cleaner|'
      r'floor\s*cleaner|multi\s*purpose\s*cleaner|wipes|baby\s*wipes|'
      r'paper\s*towel|kitchen\s*towel|toilet\s*roll|toilet\s*paper|'
      r'napkin|serbet|aluminium\s*foil|plastic\s*wrap|cling\s*wrap|'
      r'ziplock|garbage\s*bag|bin\s*liner|candle|lighter|matches|mancis|'
      r'battery|bateri|light\s*bulb|mentol|extension\s*cord|plug|'
      r'hanger|clothes\s*peg|laundry\s*bag|basket|bekas|container|'
      r'storage\s*box|rak|shelf|broom\s*stick|'
      r'downy|comfort|dynamo|vim|sunlight|lifebuoy|'
      r'dettol\s*soap|head\s*shoulders|sunsilk|pantene|rejoice|clear\s*shampoo',
    ).hasMatch(lower))
      return 'Household/Groceries';

    // 10. Pet Supplies
    if (RegExp(
      r'whiskas|friskies|pedigree|pet|cat|dog|tuna\s*wet|'
      r'puppy|kitten|powercat|royal\s*canin|purina|meow|woof|'
      r'pet\s*food|cat\s*food|dog\s*food|cat\s*litter|pasir\s*kucing|'
      r'sangkar|leash|collar|pet\s*shampoo|flea|tick|'
      r'deworming|vaccination|pet\s*treats|bone|catnip|'
      r'scratching\s*post|aquarium|fish\s*food|hamster|rabbit|'
      r'bird\s*seed|pet\s*cage|grooming',
    ).hasMatch(lower))
      return 'Pet Supplies';

    // 11. Health & Medical
    if (RegExp(
      r'kool\s*fever|panadol|ubat|mask|sanitizer|vitamin|'
      r'paracetamol|aspirin|ibuprofen|antiseptic|plaster|bandage|'
      r'dressing|cotton\s*wool|cotton\s*bud|thermometer|inhaler|'
      r'cough\s*syrup|lozenge|panadol\s*cold|flu|selsema|demam|'
      r'batuk|sakit\s*kepala|migraine|antasid|antacid|gastrik|'
      r'gaviscon|eno|oralit|rehydration|salts|salonpas|counterpain|'
      r'minyak\s*angin|minyak\s*kapak|minyak\s*gamat|balm|cream|'
      r'salap|krim|losyen|lotion|sunblock|sunscreen|'
      r'hand\s*sanitizer|hand\s*wash|disinfectant|dettol|savlon|'
      r'betadine|iodine|alcohol\s*swab|syringe|insulin|glucometer|'
      r'test\s\s*strip|blood\s*pressure|bp\s*monitor|'
      r'stethoscope|first\s*aid|band-aid|antibiotic|ointment|'
      r'gel|toothpaste|toothbrush|mouthwash',
    ).hasMatch(lower))
      return 'Health & Medical';

    // 12. Stationery (NEW - separate from shopping)
    if (RegExp(
      r'book|books|novel|textbook|magazine|comic|'
      r'stationery|pen|pencil|eraser|ruler|sharpener|'
      r'notebook|note\s*book|journal|diary|'
      r'paper|printer\s*ink|ink\s*cartridge|toner|'
      r'envelope|stamp|label|sticker|'
      r'file|folder|binder|ring\s*binder|'
      r'highlighter|marker|whiteboard|marker\s*pen|'
      r'glue|tape|scissors|stapler|hole\s*punch|'
      r'popular|mph|kinokuniya|bookstore|'
      r'gramedia|times\s*bookstore|'
      r'studying|learning|education|'
      r'school\s*supplies|office\s*supplies',
    ).hasMatch(lower))
      return 'Stationery';

    // 13. Transport (NEW - separate category)
    if (RegExp(
      r'petrol|gasoline|diesel|minyak|'
      r'toll|toll\s*charge|highway|toll\s*plaza|'
      r'parking|park\s*ing|carpark|'
      r'grab|uber|taxi|ride|e-hailing|'
      r'car\s*wash|carwash|vehicle\s*service|'
      r'train|ktm|ets|komuter|lrt|mrt|monorail|'
      r'bus|rapid|bas|'
      r'oil\s*change|tyre|tire|battery\s*car|'
      r'road\s*tax|insurance\s*car|'
      r'car\s*repair|vehicle\s*maintenance|'
      r'parking\s*ticket|summon|'
      r'fuel|topup|top\s*up',
    ).hasMatch(lower))
      return 'Transport';

    // 14. Food (prepared/restaurant items)
    if (RegExp(
      r'nasi|ayam\s*goreng|ayam\s*masak|daging\s*masak|ikan\s*masak|'
      r'chicken\s*rice|fried\s*chicken|grilled|steak|burger|pizza|'
      r'mee|noodle|pasta|spaghetti|lasagna|'
      r'sushi|sashimi|tempura|teriyaki|'
      r'taco|burrito|quesadilla|enchilada|'
      r'dim\s*sum|dumpling|bao|bun|pau|'
      r'siew\s*mai|har\s*gao|cheong\s*fun|'
      r'roti|canai|naan|chapati|paratha|'
      r'sandwich|toast|wrap|bagel|'
      r'club\s*sandwich|tuna\s*sandwich|chicken\s*sandwich|'
      r'grilled\s*cheese|panini|sub|hoagie|'
      r'quiche|frittata|strata|'
      r'salad|soup|stew|chowder|'
      r'breakfast|lunch|dinner|brunch|'
      r'meal|plate|bowl|set|combo|'
      r'curry|tandoori|masala|rendang|sambal|'
      r'roast|grill|bake|saute|'
      r'restaurant|bistro|cafe|diner|'
      r'signature|chef|special|'
      r'complete\s*meal|value\s*meal|'
      r'family\s*meal|sharing\s*plate',
    ).hasMatch(lower))
      return 'Food';

    // 15. Clothes
    if (RegExp(
      r'shirt|t-shirt|tshirt|blouse|top|'
      r'pants|jeans|trousers|slacks|'
      r'dress|skirt|suit|blazer|jacket|coat|'
      r'shoes|sneakers|boots|sandals|slippers|'
      r'accessories|belt|tie|scarf|hat|cap|'
      r'bag|handbag|backpack|'
      r'fashion|apparel|clothing|wear|'
      r'underwear|socks|stockings|'
      r'branded|designer|'
      r'uniqlo|zara|h&m|padini|cotton\s*on|'
      r'adidas|nike|puma|'
      r'department\s*store|fashion\s*store|'
      r'shopping|retail',
    ).hasMatch(lower))
      return 'Clothes';

    // 16. Entertainment
    if (RegExp(
      r'movie|cinema|ticket|film|'
      r'concert|show|performance|'
      r'streaming|netflix|spotify|youtube\s*premium|'
      r'game|gaming|playstation|xbox|nintendo|'
      r'board\s*game|card\s*game|'
      r'theme\s*park|amusement|'
      r'bowling|karoake|'
      r'sports|fitness|gym|'
      r'membership|subscription|'
      r'entertainment|leisure|'
      r'book\s*store|popular|mph|'
      r'museum|zoo|aquarium|'
      r'arcade|fun|play|'
      r'event|festival|'
      r'golden\s*screen|tgv|gsc|mmcineplexes',
    ).hasMatch(lower))
      return 'Entertainment';

    // 17. Shopping (general retail)
    if (RegExp(
      r'electrical|appliance|electronic|'
      r'phone|mobile|tablet|laptop|computer|'
      r'tv|television|speaker|headphone|'
      r'furniture|sofa|table|chair|'
      r'mattress|bed|wardrobe|'
      r'kitchen\s*appliance|blender|oven|microwave|'
      r'vacuum\s*cleaner|air\s*conditioner|'
      r'department\s*store|mall|'
      r'shopping|retail|gift|present|'
      r'online\s*shop|shopee|lazada|tiktok\s*shop|'
      r'electronics|gadget|device|'
      r'home\s*improvement|diy|'
      r'hardware|tools|'
      r'jewelry|watch|'
      r'sports\s*equipment|fitness\s*gear|'
      r'babies|kids|toys|'
      r'general\s*store|hypermarket|'
      r'aeon|tesco|lotus|giant|'
      r'mrdiy|diy|hardware\s*store',
    ).hasMatch(lower))
      return 'Shopping';

    // 18. Bills
    if (RegExp(
      r'elektrik|electricity|bill|'
      r'water|air|pba|'
      r'internet|streamyx|unifi|time|'
      r'phone|telekom|celcom|maxis|digi|'
      r'gas|utility|'
      r'rental|rent|sewa|'
      r'insurance|takaful|'
      r'bank|loan|finance|'
      r'credit\s*card|card\s*payment|'
      r'bill\s*payment|utility\s*bill|'
      r'tenaga|tnb|syarikat\s*air|'
      r'strata|maintenance|'
      r'security|guard|'
      r'garbage|waste|'
      r'council|assessment|'
      r'property\s*tax|'
      r'phone\s*bill|internet\s*bill',
    ).hasMatch(lower))
      return 'Bills';

    // 19. Rent
    if (RegExp(
      r'rent|sewa|rental|'
      r'house\s*rent|apartment\s*rent|room\s*rent|'
      r'mortgage|loan\s*payment|'
      r'property|real\s*estate|'
      r'landlord|tenant|'
      r'studio|condo|condominium|'
      r'homestay|airbnb|'
      r'house\s*payment|'
      r'sewa\s*rumah|sewa\s*bilik|'
      r'advance|deposit|'
      r'rental\s*income|property\s*income',
    ).hasMatch(lower))
      return 'Rent';

    // 20. Default
    return 'Others';
  }
}
