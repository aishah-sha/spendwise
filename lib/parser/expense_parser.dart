class ParsedExpense {
  final String formattedBreakdown; // e.g. "2 Food + 1 Beverage"
  final String primaryCategory; // The category with the highest item count
  final int itemCount; // New field: Total sum of all item quantities

  ParsedExpense({
    required this.formattedBreakdown,
    required this.primaryCategory,
    required this.itemCount, // Make it required
  });
}

class ExpenseParser {
  /// Parses input like "2 food + 1 beverage" or "1 stationery + 3 supplies"
  static ParsedExpense parse(String input) {
    if (input.trim().isEmpty) {
      return ParsedExpense(
        formattedBreakdown: '',
        primaryCategory: 'Food',
        itemCount: 0,
      );
    }

    // Match numbers followed by words (e.g., '2 food', '1 beverage')
    final RegExp expression = RegExp(r'(\d+)\s*([a-zA-Z]+)');
    final Iterable<RegExpMatch> matches = expression.allMatches(
      input.toLowerCase(),
    );

    Map<String, int> categoryWeights = {};
    List<String> formattedSegments = [];
    int totalItemsCalculated = 0; // Track total quantity

    for (final match in matches) {
      final int quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
      final String word = match.group(2) ?? 'food';

      // Accumulate total items count
      totalItemsCalculated += quantity;

      // Standardize input categories to match the styles expected by your app
      String standardCategory = _standardizeCategory(word);

      // Keep track of counts to decide which category dominates the transaction
      categoryWeights[standardCategory] =
          (categoryWeights[standardCategory] ?? 0) + quantity;

      // Capitalize first letter for presentation: "2 Food"
      String capitalized =
          standardCategory[0].toUpperCase() + standardCategory.substring(1);
      formattedSegments.add('$quantity $capitalized');
    }

    // Fallback if no matching numeric pattern was found (e.g., user just typed "Groceries")
    if (formattedSegments.isEmpty) {
      String basicCategory = _standardizeCategory(input.trim());
      String capitalized =
          basicCategory[0].toUpperCase() + basicCategory.substring(1);
      return ParsedExpense(
        formattedBreakdown: input,
        primaryCategory: capitalized,
        itemCount: 1, // Fallback to 1 item if no quantity explicitly written
      );
    }

    // Find the category with the maximum item counts
    String dominantCategory = 'Food';
    int maxQuantity = -1;
    categoryWeights.forEach((category, count) {
      if (count > maxQuantity) {
        maxQuantity = count;
        dominantCategory = category;
      }
    });

    // Re-capitalize the dominant category string
    dominantCategory =
        dominantCategory[0].toUpperCase() + dominantCategory.substring(1);

    return ParsedExpense(
      formattedBreakdown: formattedSegments.join(' + '),
      primaryCategory: dominantCategory,
      itemCount: totalItemsCalculated, // Return the calculated total item sum
    );
  }

  static String _standardizeCategory(String text) {
    text = text.trim().toLowerCase();
    if (text.contains('food') ||
        text.contains('eat') ||
        text.contains('rice') ||
        text.contains('meal')) {
      return 'food';
    }
    if (text.contains('beverage') ||
        text.contains('drink') ||
        text.contains('coffee') ||
        text.contains('water')) {
      return 'food'; // Maps to food or change to 'beverage' if icon exists
    }
    if (text.contains('soap') ||
        text.contains('wash') ||
        text.contains('detergent') ||
        text.contains('laundry')) {
      return 'detergent';
    }
    if (text.contains('pen') ||
        text.contains('book') ||
        text.contains('paper') ||
        text.contains('stationery')) {
      return 'stationery';
    }
    if (text.contains('supply') ||
        text.contains('supplies') ||
        text.contains('grocery') ||
        text.contains('groceries')) {
      return 'supplies';
    }
    if (text.contains('car') ||
        text.contains('fuel') ||
        text.contains('bus') ||
        text.contains('transport')) {
      return 'transport';
    }
    if (text.contains('cloth') ||
        text.contains('buy') ||
        text.contains('shopping')) {
      return 'shopping';
    }
    if (text.contains('movie') ||
        text.contains('game') ||
        text.contains('entertainment')) {
      return 'entertainment';
    }
    return 'food'; // Default fallback safely
  }
}
