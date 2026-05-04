import 'package:flutter/foundation.dart';

class ReceiptItemOld {
  final String name;
  final double price;
  final String category;
  final int? quantity;
  final double? unitPrice;

  ReceiptItemOld({
    required this.name,
    required this.price,
    required this.category,
    this.quantity,
    this.unitPrice,
  });

  ReceiptItem toNewReceiptItem() {
    return ReceiptItem(
      name: name,
      price: price,
      quantity: quantity ?? 1,
      category: category,
      discount: null,
      notes: null,
    );
  }
}

class ReceiptData {
  final String merchant;
  final double total;
  final List<ReceiptItemOld> items;

  ReceiptData({
    required this.merchant,
    required this.total,
    required this.items,
  });

  ReceiptModel toReceiptModel({String? id}) {
    return ReceiptModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: total,
      merchantName: merchant,
      items: items.map((item) => item.toNewReceiptItem()).toList(),
      receiptType: 'scan',
      currency: 'RM',
      ocrStatus: 'SUCCESS',
    );
  }
}

class ReceiptModel {
  final String id;
  final DateTime date;
  final double amount;
  final double? tax;
  final double? subtotal;
  final double? serviceCharge;
  final String? imagePath;
  final String? receiptType;
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
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double get calculatedSubtotal {
    if (subtotal != null) return subtotal!;
    if (items == null) return amount;
    return items!.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get calculatedTax {
    if (tax != null) return tax!;
    return calculatedSubtotal * 0.075;
  }

  Set<String> get categories {
    if (items == null || items!.isEmpty) {
      return {category ?? 'Uncategorized'};
    }
    return items!.map((item) => item.category ?? 'Uncategorized').toSet();
  }

  String get categorySummary {
    if (items == null || items!.isEmpty) {
      return category ?? 'Uncategorized';
    }

    final categoryCounts = <String, int>{};
    for (var item in items!) {
      final cat = item.category ?? 'Uncategorized';
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.length == 1) {
      return '${sortedCategories.first.value} ${sortedCategories.first.key}';
    } else {
      final mainCategory = sortedCategories.first.key;
      final otherCount = sortedCategories.length - 1;
      return '${sortedCategories.first.value} $mainCategory +$otherCount other';
    }
  }

  Map<String, double> get categoryBreakdown {
    if (items == null || items!.isEmpty) {
      return {category ?? 'Uncategorized': amount};
    }

    final breakdown = <String, double>{};
    for (var item in items!) {
      final cat = item.category ?? 'Uncategorized';
      breakdown[cat] = (breakdown[cat] ?? 0) + (item.price * item.quantity);
    }
    return breakdown;
  }

  String get primaryCategory {
    if (items == null || items!.isEmpty) {
      return category ?? 'Uncategorized';
    }

    final breakdown = categoryBreakdown;
    if (breakdown.isEmpty) return 'Uncategorized';

    return breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int get totalItemCount {
    if (items == null) return 0;
    return items!.fold(0, (sum, item) => sum + item.quantity);
  }

  ReceiptData toReceiptData() {
    return ReceiptData(
      merchant: merchantName ?? 'Unknown Store',
      total: amount,
      items: items?.map((item) => item.toReceiptItemOld()).toList() ?? [],
    );
  }

  factory ReceiptModel.fromReceiptData(ReceiptData data, {String? id}) {
    return ReceiptModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      amount: data.total,
      merchantName: data.merchant,
      items: data.items.map((item) => item.toNewReceiptItem()).toList(),
      receiptType: 'scan',
      currency: 'RM',
      ocrStatus: 'SUCCESS',
    );
  }

  // Convert to Supabase receipt format
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'receipt_type': receiptType,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'items': items?.map((item) => item.toJson()).toList() ?? [],
      'tax': tax,
      'subtotal': subtotal,
      'service_charge': serviceCharge,
      'category': category,
      'currency': currency ?? 'RM',
      'ocr_status': ocrStatus,
    };
  }

  // Create from Supabase receipt response
  factory ReceiptModel.fromDatabaseJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      tax: (json['tax'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      serviceCharge: (json['service_charge'] as num?)?.toDouble(),
      imagePath: json['image_path'] as String?,
      receiptType: json['receipt_type'] as String?,
      merchantName: json['merchant_name'] as String?,
      category: json['category'] as String?,
      currency: json['currency'] as String?,
      ocrStatus: json['ocr_status'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => ReceiptItem.fromJson(item))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'tax': tax,
      'subtotal': subtotal,
      'serviceCharge': serviceCharge,
      'imagePath': imagePath,
      'receiptType': receiptType,
      'merchantName': merchantName,
      'category': category,
      'currency': currency,
      'ocrStatus': ocrStatus,
      'items': items?.map((item) => item.toJson()).toList(),
      'hasImage': hasImage,
    };
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      tax: json['tax']?.toDouble(),
      subtotal: json['subtotal']?.toDouble(),
      serviceCharge: json['serviceCharge']?.toDouble(),
      imagePath: json['imagePath'],
      receiptType: json['receiptType'],
      merchantName: json['merchantName'],
      category: json['category'],
      currency: json['currency'],
      ocrStatus: json['ocrStatus'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => ReceiptItem.fromJson(item))
                .toList()
          : null,
    );
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

  double get totalPrice {
    double itemTotal = price * quantity;
    if (discount != null) {
      itemTotal -= discount!;
    }
    return itemTotal;
  }

  ReceiptItemOld toReceiptItemOld() {
    return ReceiptItemOld(
      name: name,
      price: price,
      category: category ?? 'Others',
      quantity: quantity,
      unitPrice: price,
    );
  }

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

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      category: json['category'],
      discount: json['discount']?.toDouble(),
      notes: json['notes'],
    );
  }
}

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
          category: 'Food',
        ),
        ReceiptItem(
          name: 'Sweet and Sour Chicken Nasi Goreng',
          price: 3500.0,
          quantity: 1,
          category: 'Food',
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
