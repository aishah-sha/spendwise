class ReceiptModel {
  final String id;
  final DateTime date;
  final double amount;
  final String? imagePath;
  final String? receiptType; // 'scan', 'upload', or 'manual'
  final String? merchantName;
  final List<ReceiptItem>? items;

  ReceiptModel({
    required this.id,
    required this.date,
    required this.amount,
    this.imagePath,
    this.receiptType,
    this.merchantName,
    this.items,
  });
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}
