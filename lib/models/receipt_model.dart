import 'dart:convert';
import 'package:equatable/equatable.dart';

class ReceiptItem extends Equatable {
  final String name;
  final double price;
  final int quantity;
  final String category;
  final double? unitPrice;

  const ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.category = 'Groceries',
    this.unitPrice,
  });

  // Helper getter for total amount (price * quantity)
  double get totalAmount => price * quantity;

  double get effectiveUnitPrice =>
      unitPrice ?? (quantity > 0 ? price / quantity : price);

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String? ?? 'Unknown Item',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      category: json['category'] as String? ?? 'Groceries',
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }

  ReceiptItem copyWith({
    String? name,
    double? price,
    int? quantity,
    String? category,
    double? unitPrice,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [name, price, quantity, category, unitPrice];
}

class ReceiptModel extends Equatable {
  final String id;
  final DateTime date;
  final double rawAmount; // <-- 1. Rename the field to avoid conflict
  final double? tax;
  final double? subtotal;
  final double? serviceCharge;
  final String? imagePath;
  final String? receiptType;
  final String? merchantName;
  final String category;
  final String? currency;
  final String? ocrStatus;
  final List<ReceiptItem>? items;
  final String? userId;
  final bool processed;
  final String? expenseId;
  final String establishmentType;

  const ReceiptModel({
    required this.id,
    required this.date,
    double amount =
        0.0, // <-- 2. Keep 'amount' as the constructor argument name for compatibility
    this.tax,
    this.subtotal,
    this.serviceCharge,
    this.imagePath,
    this.receiptType,
    this.merchantName,
    this.category = 'Groceries',
    this.currency,
    this.ocrStatus,
    this.items,
    this.userId,
    this.processed = false,
    this.expenseId,
    this.establishmentType = 'General Retail',
  }) : rawAmount = amount; // <-- 3. Initialize the internal field here

  // <-- 4. Now this getter works perfectly without any name conflicts!
  double get amount {
    if (rawAmount > 0.0) return rawAmount;
    if (items != null && items!.isNotEmpty) {
      return items!.fold(0.0, (sum, item) => sum + item.totalAmount) +
          (tax ?? 0.0) +
          (serviceCharge ?? 0.0);
    }
    return 0.0;
  }

  // ... rest of your model methods (Update toDatabaseJson and copyWith below)

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

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
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  int get totalItemCount {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalItemsPrice {
    if (items == null) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.price);
  }

  String get categorySummary {
    if (items == null || items!.isEmpty) return category;
    final categoryCounts = <String, int>{};

    for (var item in items!) {
      final cat = item.category;
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return category;

    if (sorted.length == 1) {
      return '${sorted.first.value} ${sorted.first.key}';
    } else {
      return '${sorted.first.value} ${sorted.first.key} +${sorted.length - 1} other';
    }
  }

  factory ReceiptModel.fromDatabaseJson(Map<String, dynamic> json) {
    List<ReceiptItem>? parsedItems;
    if (json['items'] != null) {
      try {
        final rawItems = json['items'];
        final List listData = rawItems is String
            ? jsonDecode(rawItems)
            : rawItems;
        parsedItems = listData
            .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        parsedItems = null;
      }
    }

    return ReceiptModel(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      serviceCharge: (json['service_charge'] as num?)?.toDouble(),
      imagePath: json['image_path'] as String?,
      receiptType: json['receipt_type'] as String?,
      merchantName: json['merchant_name'] as String?,
      category: json['category'] as String? ?? 'Groceries',
      currency: json['currency'] as String?,
      ocrStatus: json['ocr_status'] as String?,
      userId: json['user_id'] as String?,
      processed: json['processed'] == 1 || json['processed'] == true,
      expenseId: json['expense_id'] as String?,
      items: parsedItems,
      establishmentType:
          json['establishment_type'] as String? ??
          'General Retail', // <--- PARSE FIELD
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'tax': tax,
      'subtotal': subtotal,
      'service_charge': serviceCharge,
      'image_path': imagePath,
      'receipt_type': receiptType,
      'merchant_name': merchantName,
      'category': category,
      'currency': currency,
      'ocr_status': ocrStatus,
      'user_id': userId,
      'processed': processed ? 1 : 0,
      'expense_id': expenseId,
      'items': items != null
          ? jsonEncode(items!.map((item) => item.toJson()).toList())
          : null,
      'establishment_type': establishmentType, // <--- WRITE FIELD
    };
  }

  ReceiptModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    double? tax,
    double? subtotal,
    double? serviceCharge,
    String? imagePath,
    String? receiptType,
    String? merchantName,
    String? category,
    String? currency,
    String? ocrStatus,
    List<ReceiptItem>? items,
    String? userId,
    bool? processed,
    String? expenseId,
    String? establishmentType, // <--- ARGUMENT
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      tax: tax ?? this.tax,
      subtotal: subtotal ?? this.subtotal,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      imagePath: imagePath ?? this.imagePath,
      receiptType: receiptType ?? this.receiptType,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      items: items ?? this.items,
      userId: userId ?? this.userId,
      processed: processed ?? this.processed,
      expenseId: expenseId ?? this.expenseId,
      establishmentType:
          establishmentType ?? this.establishmentType, // <--- RE-MAP
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    amount,
    tax,
    subtotal,
    serviceCharge,
    imagePath,
    receiptType,
    merchantName,
    category,
    currency,
    ocrStatus,
    items,
    userId,
    processed,
    expenseId,
    establishmentType, // <--- EQUATABLE TRACKING
  ];
}
