import 'package:uuid/uuid.dart';

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
    String? id, // optional — auto-generates a UUID if not provided
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  }) : id = id ?? const Uuid().v4(); // generates UUID matching your table's UUID column

  // ─── Supabase (matches your exact table schema) ──────────────────────────
  // Fields: id, user_id, title, message, type, is_read, created_at
  // Note: user_id is added by the cubit (not stored in the model)

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

  // ─── Type helpers (match your table's CHECK constraint exactly) ──────────

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
}
