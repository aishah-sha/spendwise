class ReceiptModel {
  final String id;
  final DateTime date;
  final double amount;
  final double? tax;
  final double? subtotal;
  final double? serviceCharge;
  final String? imagePath;
  final String? receiptType; // 'scan', 'upload', or 'manual'
  final String? merchantName;
  final String? category;
  final String? currency;
  final String? ocrStatus;
  final List<ReceiptItem>? items;

  ReceiptModel({
    required this.id,
    required this.date,
    required this.amount,
    this.tax,
    this.subtotal,
    this.serviceCharge,
    this.imagePath,
    this.receiptType,
    this.merchantName,
    this.category,
    this.currency,
    this.ocrStatus,
    this.items,
  });

  // Helper method to get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Calculate subtotal from items if not provided
  double get calculatedSubtotal {
    if (subtotal != null) return subtotal!;
    if (items == null) return amount;

    return items!.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Calculate tax if not provided (assuming 7.5% as in the image)
  double get calculatedTax {
    if (tax != null) return tax!;
    return calculatedSubtotal * 0.075; // 7.5% tax rate
  }
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
  final String? category;
  final double? discount;
  final String? notes;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.category,
    this.discount,
    this.notes,
  });

  // Calculate total price for this item
  double get totalPrice {
    double itemTotal = price * quantity;
    if (discount != null) {
      itemTotal -= discount!;
    }
    return itemTotal;
  }

  // Factory method to create from OCR data
  factory ReceiptItem.fromOcr(Map<String, dynamic> data) {
    return ReceiptItem(
      name: data['name'] ?? 'Unknown Item',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] as int? ?? 1,
      category: data['category'],
      discount: (data['discount'] as num?)?.toDouble(),
      notes: data['notes'],
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'discount': discount,
      'notes': notes,
    };
  }
}

// Extension for creating sample data (useful for testing)
extension ReceiptModelSample on ReceiptModel {
  static ReceiptModel createSample() {
    return ReceiptModel(
      id: 'sample_001',
      date: DateTime.now(),
      amount: 19000.0,
      tax: 1353.75,
      subtotal: 16000.0,
      serviceCharge: 0.0,
      imagePath: null,
      receiptType: 'scan',
      merchantName: '100plus',
      category: 'Food & Beverage',
      currency: 'RM',
      ocrStatus: 'SUCCESS',
      items: [
        ReceiptItem(
          name: 'Imperial Roll Shrimp Springroll',
          price: 7000.0,
          quantity: 1,
          category: 'Appetizer',
        ),
        ReceiptItem(
          name: 'Sweet and Sour Chicken Nasi Goreng',
          price: 3500.0,
          quantity: 1,
          category: 'Main Course',
        ),
        ReceiptItem(
          name: 'Fresh Fruit Punch Stamp Duty',
          price: 2500.0,
          quantity: 1,
          category: 'Beverage',
        ),
        ReceiptItem(
          name: 'NA Beverage Total Stamp Duty',
          price: 16000.0,
          quantity: 1,
          category: 'Beverage',
        ),
      ],
    );
  }
}
