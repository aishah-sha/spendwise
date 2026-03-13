enum NotificationType {
  budgetExceeded,
  budgetNearLimit,
  monthlyBudgetExceeded,
  monthlyBudgetNearLimit,
  categoryBudgetExceeded,
  categoryBudgetNearLimit,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>?
  data; // Additional data like category name, amount, etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  // For JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
    'isRead': isRead,
    'data': data,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values[json['type']],
      isRead: json['isRead'],
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
