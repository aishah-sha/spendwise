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
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  // Convert to Supabase notification format
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': _typeToString(type),
      'is_read': isRead,
      'created_at': timestamp.toIso8601String(),
    };
  }

  // Create from Supabase notification response
  factory NotificationModel.fromDatabaseJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      type: _stringToType(json['type'] as String),
      isRead: json['is_read'] as bool? ?? false,
      data: null,
    );
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.budgetExceeded:
        return 'budget_exceeded';
      case NotificationType.budgetNearLimit:
        return 'budget_near_limit';
      case NotificationType.monthlyBudgetExceeded:
        return 'monthly_budget_exceeded';
      case NotificationType.monthlyBudgetNearLimit:
        return 'monthly_budget_near_limit';
      case NotificationType.categoryBudgetExceeded:
        return 'category_budget_exceeded';
      case NotificationType.categoryBudgetNearLimit:
        return 'category_budget_near_limit';
    }
  }

  static NotificationType _stringToType(String type) {
    switch (type) {
      case 'budget_exceeded':
        return NotificationType.budgetExceeded;
      case 'budget_near_limit':
        return NotificationType.budgetNearLimit;
      case 'monthly_budget_exceeded':
        return NotificationType.monthlyBudgetExceeded;
      case 'monthly_budget_near_limit':
        return NotificationType.monthlyBudgetNearLimit;
      case 'category_budget_exceeded':
        return NotificationType.categoryBudgetExceeded;
      case 'category_budget_near_limit':
        return NotificationType.categoryBudgetNearLimit;
      default:
        return NotificationType.budgetExceeded;
    }
  }

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
