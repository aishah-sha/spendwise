import 'dart:math';
import '../models/receipt_model.dart';
import 'package:flutter/foundation.dart';

class ReceiptParser {
  static ReceiptData parse(List<String> lines) {
    debugPrint("=== RECEIPT PARSER - LOOKING FOR 'TOTAL' ===");
    for (int i = 0; i < lines.length; i++) {
      debugPrint("Line $i: '${lines[i]}'");
    }

    String merchant = _extractMerchant(lines);
    List<ReceiptItemOld> items = []; // Changed to ReceiptItemOld
    List<double> itemPrices = [];
    List<String> productNames = [];
    double total = 0.0;

    // Keywords that indicate NON-item lines (to COMPLETELY IGNORE)
    final ignorePatterns = [
      // Payment related
      "CASH",
      "CHANGE",
      "TUNAI",
      "BAKI",
      "AMOUNT DUE",
      "PAYMENT",
      "TENDER",
      "CA",
      "CARD",
      "CREDIT",
      "DEBIT",

      // Receipt headers
      "INVOICE",
      "NO",
      "BILL",
      "RECEIPT",
      "ORDER",
      "TABLE",
      "SERVER",
      "STAFF",

      // Cashier info
      "CASHIER",
      "KASIR",
      "OPERATOR",
      "SALES PERSON",
      "ASSISTANT",

      // Date/Time
      "DATE",
      "TIME",
      "TARIKH",
      "MASA",

      // Store info
      "TEL",
      "TELP",
      "PHONE",
      "FAX",
      "EMAIL",
      "WEBSITE",
      "JALAN",
      "PAHANG",
      "PI",
      "NO.",
      "LOT",
      "UNIT",

      // Transaction details
      "TRANSACTION",
      "REF",
      "REFERENCE",
      "ID",
      "MEMBER",
      "POINT",
      "POINTS",

      // Summary lines (except TOTAL)
      "SUB TOTAL",
      "SUBTOTAL",
      "DISCOUNT",
      "ROUNDING",
      "TAX",
      "GST",
      "SST",
      "SERVICE",
      "ITEM COUNT",
      "TOTAL ITEM",
      "TOTAL QTY",

      // Others
      "Page",
      "Kuala",
      "Selangor",
      "Sdn Bhd",
      "Bhd",
    ];

    // First pass: Identify product names and their prices
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      // SPECIAL CASE: If line contains "Total" or "TOTAL", handle it separately for total amount
      if (line.contains("Total") || line.contains("TOTAL")) {
        debugPrint("💰 Found potential TOTAL line: $line");
        // We'll handle total separately in _extractTotal
        continue;
      }

      // Check if line should be IGNORED completely
      bool shouldIgnore = false;
      String upperLine = line.toUpperCase();

      for (var pattern in ignorePatterns) {
        if (upperLine.contains(pattern)) {
          shouldIgnore = true;
          debugPrint("🚫 Ignoring line (contains '$pattern'): $line");
          break;
        }
      }

      if (shouldIgnore) continue;

      // Skip lines that start with numbers (barcode lines)
      if (line.contains(RegExp(r'^\d'))) {
        // Check if this line contains price information (has numbers with decimal)
        if (line.contains(RegExp(r'\d+\.\d+'))) {
          // Extract the last number in the line (this is usually the total price)
          final matches = RegExp(r'(\d+\.\d+)').allMatches(line);
          if (matches.isNotEmpty) {
            // Get the last match (last number in the line)
            final lastMatch = matches.last;
            double itemPrice = double.parse(lastMatch.group(1)!);

            // Only add if price is reasonable (between RM0.50 and RM1000)
            if (itemPrice > 0.5 && itemPrice < 1000) {
              itemPrices.add(itemPrice);
              debugPrint("💰 Found price: RM$itemPrice from line: $line");
            }
          }
        }
        continue; // Skip barcode lines after extracting price
      }

      // Check if this line is a product name (contains letters)
      if (_isProductName(line) && line.contains(RegExp(r'[A-Za-z]'))) {
        // Clean up the product name
        String cleanName = _cleanProductName(line);
        productNames.add(cleanName);
        debugPrint("📝 Found product: $cleanName");
      }
    }

    debugPrint(
      "Found ${productNames.length} products and ${itemPrices.length} prices",
    );

    // Match products with their prices (they should be in sequence)
    // If we have more prices than products, use as many as we have products
    int minCount = min(productNames.length, itemPrices.length);

    for (int i = 0; i < minCount; i++) {
      String productName = productNames[i];
      double itemPrice = itemPrices[i];

      items.add(
        _createReceiptItemOld(productName, itemPrice),
      ); // Changed method name
      debugPrint("✅ Added: $productName = RM$itemPrice");
    }

    // If we have more products than prices, add remaining products with price 0
    if (productNames.length > itemPrices.length) {
      for (int i = itemPrices.length; i < productNames.length; i++) {
        items.add(
          _createReceiptItemOld(productNames[i], 0.0),
        ); // Changed method name
        debugPrint("⚠️ Added product without price: ${productNames[i]}");
      }
    }

    // Look for total in the lines - SPECIFICALLY looking for "Total" word
    total = _extractTotalFromWord(lines);

    // If still no total found with "Total" word, try other methods as fallback
    if (total == 0) {
      debugPrint("⚠️ No 'Total' word found, trying fallback methods...");
      total = _extractTotalFallback(lines, items);
    }

    debugPrint("=== FINAL RESULT ===");
    debugPrint("Merchant: $merchant");
    debugPrint("Total items found: ${items.length}");
    for (var item in items) {
      debugPrint("  - ${item.name}: RM${item.price}");
    }
    debugPrint("Total amount: RM$total");

    return ReceiptData(merchant: merchant, total: total, items: items);
  }

  // NEW METHOD: Specifically look for lines containing "Total" word
  static double _extractTotalFromWord(List<String> lines) {
    // Patterns that specifically contain the word "Total" (case insensitive)
    final totalPatterns = [
      r'TOTAL\s*:?\s*(\d+\.\d+)',
      r'TOTAL\s+(\d+\.\d+)',
      r'TOTAL\s*RM\s*(\d+\.\d+)',
      r'TOTAL\s*:\s*RM\s*(\d+\.\d+)',
      r'^TOTAL\s+(\d+\.\d+)',
      r'TOTAL\s+AMOUNT\s*:?\s*(\d+\.\d+)',
      r'GRAND\s+TOTAL\s*:?\s*(\d+\.\d+)',
    ];

    // First, look for lines that contain the word "Total" or "TOTAL"
    for (String line in lines) {
      String upperLine = line.toUpperCase();

      // Check if line contains "TOTAL" word
      if (upperLine.contains("TOTAL")) {
        debugPrint("🔍 Found line with 'TOTAL': $line");

        // Try each pattern to extract the number
        for (var pattern in totalPatterns) {
          final totalMatch = RegExp(
            pattern,
            caseSensitive: false,
          ).firstMatch(line);
          if (totalMatch != null) {
            double total = double.parse(totalMatch.group(1)!);
            debugPrint("💰 Found total from 'TOTAL' word: $total");
            return total;
          }
        }

        // If patterns didn't match, try to find any number in the line
        final numberMatch = RegExp(r'(\d+\.\d+)').firstMatch(line);
        if (numberMatch != null) {
          double total = double.parse(numberMatch.group(1)!);
          debugPrint("💰 Found total from line with 'TOTAL' word: $total");
          return total;
        }
      }
    }

    return 0.0;
  }

  // Fallback method if "Total" word not found
  static double _extractTotalFallback(
    List<String> lines,
    List<ReceiptItemOld> items, // Changed to ReceiptItemOld
  ) {
    // Look for numbers in the last few lines (but ignore CASH, CHANGE lines)
    List<double> possibleTotals = [];

    for (int i = lines.length - 1; i >= lines.length - 10 && i >= 0; i--) {
      String line = lines[i].toUpperCase();

      // Skip lines that contain payment keywords
      if (line.contains("CASH") ||
          line.contains("CHANGE") ||
          line.contains("TUNAI") ||
          line.contains("BAKI") ||
          line.contains("PAYMENT") ||
          line.contains("TENDER")) {
        debugPrint("🚫 Skipping payment line for total: ${lines[i]}");
        continue;
      }

      final matches = RegExp(r'(\d+\.\d+)').allMatches(lines[i]);
      for (var match in matches) {
        double num = double.parse(match.group(1)!);
        // Total is usually > 10
        if (num > 10 && num < 10000) {
          possibleTotals.add(num);
          debugPrint(
            "💰 Found possible total number: $num from line: ${lines[i]}",
          );
        }
      }
    }

    if (possibleTotals.isNotEmpty) {
      possibleTotals.sort();
      double largest = possibleTotals.last;
      debugPrint("💰 Using largest number as total (fallback): $largest");
      return largest;
    }

    // Last resort: sum all item prices
    if (items.isNotEmpty) {
      double sum = items.fold(0, (sum, item) => sum + item.price);
      debugPrint("💰 Using sum of items as total: $sum");
      return sum;
    }

    return 0.0;
  }

  static String _extractMerchant(List<String> lines) {
    // Common merchant indicators
    final merchantPatterns = [
      "MART",
      "STORE",
      "SHOP",
      "SUPER",
      "MINI",
      "TF",
      "VALUE",
      "MARKET",
      "GROCER",
      "RESTAURANT",
      "CAFE",
      "KEDAI",
      "PASAR",
    ];

    // Skip these when looking for merchant
    final ignoreMerchantPatterns = [
      "CASHIER",
      "INVOICE",
      "RECEIPT",
      "TEL",
      "DATE",
      "TIME",
    ];

    for (String line in lines) {
      String upperLine = line.toUpperCase();

      // Skip if line contains ignore patterns
      bool shouldIgnore = false;
      for (var pattern in ignoreMerchantPatterns) {
        if (upperLine.contains(pattern)) {
          shouldIgnore = true;
          break;
        }
      }
      if (shouldIgnore) continue;

      for (var pattern in merchantPatterns) {
        if (upperLine.contains(pattern)) {
          // Clean up merchant name
          String merchant = line.trim();
          // Remove common noise
          merchant = merchant
              .replaceAll(RegExp(r'Sdn Bhd|\(|\)|\d+'), '')
              .trim();
          if (merchant.isNotEmpty && merchant.length > 3) {
            debugPrint("🏪 Found merchant: $merchant");
            return merchant;
          }
        }
      }
    }
    return "Unknown Store";
  }

  // Create ReceiptItemOld instead of ReceiptItem
  static ReceiptItemOld _createReceiptItemOld(String name, double price) {
    return ReceiptItemOld(
      name: name,
      price: price,
      category: _categorizeItem(name),
      quantity: 1,
      unitPrice: price,
    );
  }

  static String _cleanProductName(String line) {
    // Remove any trailing numbers that might be prices
    String cleaned = line.replaceAll(RegExp(r'\s+\d+\.\d+\s*$'), '');
    // Remove multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  static bool _isProductName(String line) {
    String upper = line.toUpperCase();

    // Skip if line is too short
    if (line.length < 4) return false;

    // Must contain letters
    if (!line.contains(RegExp(r'[A-Za-z]'))) return false;

    // Expanded list of known products
    final knownProducts = [
      "CRISPO",
      "MINYAK SAPI",
      "DAIA",
      "POWDER",
      "SOFTENING",
      "EVA",
      "HONEY",
      "GOODMAID",
      "HAND WASH",
      "MERIAH",
      "ALMOND",
      "TF RECYCLE BAG",
      "WHISKAS",
      "ROSE",
      "FLOUR",
      "WINDMILL",
      "GHEEBLEND",
      "BUTTERCUP",
      "DAIRY SPREAD",
      "SUSU",
      "TELUR",
      "AYAM",
      "IKAN",
      "ROTI",
      "BERAS",
      "GULA",
      "GARAM",
      "MINYAK MASAK",
      "DETERGEN",
      "SYAMPU",
      "UBAT GIGI",
      "SABUN",
      "COCA COLA",
      "PEPSI",
      "MILO",
      "NESCAFE",
      "TEH",
      "KOPI",
      "AIR",
      "JUS",
    ];

    // Check if line contains any known product
    for (var product in knownProducts) {
      if (upper.contains(product)) {
        return true;
      }
    }

    // Check for product indicators (units of measurement)
    if (line.contains(
      RegExp(
        r'\d+(?:\.\d+)?\s*(?:G|KG|ML|L|PCS|PC|BTL|PKT|BKS|GRAM)',
        caseSensitive: false,
      ),
    )) {
      return true;
    }

    // Check for product indicators
    if (line.contains("G ") ||
        line.contains("G-") ||
        line.contains("G,") ||
        line.contains("KG") ||
        line.contains("ML") ||
        line.contains("GR") ||
        line.contains("PCS") ||
        line.contains("PC") ||
        line.contains("BTL") ||
        line.contains("PKT") ||
        line.contains("&") ||
        line.contains("(") ||
        line.contains(")")) {
      return true;
    }

    return false;
  }

  static String _categorizeItem(String name) {
    String lower = name.toLowerCase();

    // Pet Food & Supplies
    if (lower.contains("whiskas") ||
        lower.contains("cat") ||
        lower.contains("dog") ||
        lower.contains("pet") ||
        lower.contains("makanan kucing") ||
        lower.contains("makanan anjing")) {
      return "Pet Food";
    }

    // Household & Cleaning
    if (lower.contains("daia") ||
        lower.contains("powder") ||
        lower.contains("softergent") ||
        lower.contains("hand wash") ||
        lower.contains("recycle bag") ||
        lower.contains("detergen") ||
        lower.contains("sabun") ||
        lower.contains("syampu") ||
        lower.contains("ubat gigi") ||
        lower.contains("pencuci") ||
        lower.contains("cleaner") ||
        lower.contains("soap") ||
        lower.contains("wash")) {
      return "Household";
    }

    // Groceries & Food Items
    if (lower.contains("crispo") ||
        lower.contains("minyak") ||
        lower.contains("sapi") ||
        lower.contains("honey") ||
        lower.contains("almond") ||
        lower.contains("rose") ||
        lower.contains("flour") ||
        lower.contains("ghee") ||
        lower.contains("butter") ||
        lower.contains("dairy") ||
        lower.contains("spread") ||
        lower.contains("eva") ||
        lower.contains("goodmaid") ||
        lower.contains("meriah") ||
        lower.contains("windmill") ||
        lower.contains("buttercup") ||
        lower.contains("susu") ||
        lower.contains("telur") ||
        lower.contains("ayam") ||
        lower.contains("ikan") ||
        lower.contains("roti") ||
        lower.contains("beras") ||
        lower.contains("gula") ||
        lower.contains("garam") ||
        lower.contains("tepung") ||
        lower.contains("bawang") ||
        lower.contains("cili") ||
        lower.contains("sayur") ||
        lower.contains("buah")) {
      return "Groceries";
    }

    // Beverages
    if (lower.contains("milo") ||
        lower.contains("nescafe") ||
        lower.contains("teh") ||
        lower.contains("kopi") ||
        lower.contains("air") ||
        lower.contains("jus") ||
        lower.contains("soda") ||
        lower.contains("minuman") ||
        lower.contains("coca") ||
        lower.contains("pepsi") ||
        lower.contains("cola")) {
      return "Beverages";
    }

    return "Others";
  }
}
