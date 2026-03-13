import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationState({required this.notifications, required this.unreadCount});

  factory NotificationState.initial() {
    return NotificationState(notifications: [], unreadCount: 0);
  }

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationCubit extends Cubit<NotificationState> {
  static const String _storageKey = 'notifications';

  NotificationCubit() : super(NotificationState.initial()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_storageKey);

      if (saved != null) {
        final List<dynamic> decoded = json.decode(saved);
        final notifications =
            decoded.map((item) => NotificationModel.fromJson(item)).toList()
              ..sort(
                (a, b) => b.timestamp.compareTo(a.timestamp),
              ); // Sort by date desc

        final unreadCount = notifications.where((n) => !n.isRead).length;

        emit(
          state.copyWith(
            notifications: notifications,
            unreadCount: unreadCount,
          ),
        );
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = state.notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(encoded));
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  void addNotification(NotificationModel notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(
      state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ),
    );

    _saveNotifications();
  }

  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(
      state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ),
    );

    _saveNotifications();
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    emit(state.copyWith(notifications: updatedNotifications, unreadCount: 0));

    _saveNotifications();
  }

  void clearNotifications() {
    emit(NotificationState.initial());
    _saveNotifications();
  }

  // Check budget and create notifications
  void checkBudgetAndNotify({
    required double monthlyBudget,
    required double totalSpent,
    required Map<String, double> categoryBudgets,
    required Map<String, double> categorySpent,
  }) {
    final now = DateTime.now();

    // Check monthly budget
    if (monthlyBudget > 0) {
      final spentPercentage = (totalSpent / monthlyBudget) * 100;

      // Near limit (80%)
      if (spentPercentage >= 80 && spentPercentage < 100) {
        final existingNear = state.notifications.any(
          (n) =>
              n.type == NotificationType.monthlyBudgetNearLimit &&
              n.timestamp.day == now.day &&
              n.timestamp.month == now.month &&
              n.timestamp.year == now.year,
        );

        if (!existingNear) {
          addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: '⚠️ Monthly Budget Near Limit',
              message:
                  'You have spent ${spentPercentage.toStringAsFixed(1)}% of your monthly budget. Only RM ${(monthlyBudget - totalSpent).toStringAsFixed(2)} remaining.',
              timestamp: now,
              type: NotificationType.monthlyBudgetNearLimit,
              data: {
                'percentage': spentPercentage,
                'remaining': monthlyBudget - totalSpent,
                'totalSpent': totalSpent,
                'budget': monthlyBudget,
              },
            ),
          );
        }
      }
      // Exceeded limit
      else if (spentPercentage >= 100) {
        final existingExceeded = state.notifications.any(
          (n) =>
              n.type == NotificationType.monthlyBudgetExceeded &&
              n.timestamp.day == now.day &&
              n.timestamp.month == now.month &&
              n.timestamp.year == now.year,
        );

        if (!existingExceeded) {
          final overAmount = totalSpent - monthlyBudget;
          addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: '🚨 Monthly Budget Exceeded!',
              message:
                  'You have exceeded your monthly budget by RM ${overAmount.toStringAsFixed(2)}. Consider adjusting your spending.',
              timestamp: now,
              type: NotificationType.monthlyBudgetExceeded,
              data: {
                'overAmount': overAmount,
                'totalSpent': totalSpent,
                'budget': monthlyBudget,
              },
            ),
          );
        }
      }
    }

    // Check category budgets
    categoryBudgets.forEach((category, budget) {
      if (budget > 0) {
        final spent = categorySpent[category] ?? 0;
        final spentPercentage = (spent / budget) * 100;

        // Category near limit (80%)
        if (spentPercentage >= 80 && spentPercentage < 100) {
          final existingNear = state.notifications.any(
            (n) =>
                n.type == NotificationType.categoryBudgetNearLimit &&
                n.data?['category'] == category &&
                n.timestamp.day == now.day &&
                n.timestamp.month == now.month &&
                n.timestamp.year == now.year,
          );

          if (!existingNear) {
            addNotification(
              NotificationModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: '⚠️ $category Budget Near Limit',
                message:
                    'You have spent ${spentPercentage.toStringAsFixed(1)}% of your $category budget. Only RM ${(budget - spent).toStringAsFixed(2)} remaining.',
                timestamp: now,
                type: NotificationType.categoryBudgetNearLimit,
                data: {
                  'category': category,
                  'percentage': spentPercentage,
                  'remaining': budget - spent,
                  'spent': spent,
                  'budget': budget,
                },
              ),
            );
          }
        }
        // Category exceeded
        else if (spentPercentage >= 100) {
          final existingExceeded = state.notifications.any(
            (n) =>
                n.type == NotificationType.categoryBudgetExceeded &&
                n.data?['category'] == category &&
                n.timestamp.day == now.day &&
                n.timestamp.month == now.month &&
                n.timestamp.year == now.year,
          );

          if (!existingExceeded) {
            final overAmount = spent - budget;
            addNotification(
              NotificationModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: '🚨 $category Budget Exceeded!',
                message:
                    'You have exceeded your $category budget by RM ${overAmount.toStringAsFixed(2)}.',
                timestamp: now,
                type: NotificationType.categoryBudgetExceeded,
                data: {
                  'category': category,
                  'overAmount': overAmount,
                  'spent': spent,
                  'budget': budget,
                },
              ),
            );
          }
        }
      }
    });
  }
}
