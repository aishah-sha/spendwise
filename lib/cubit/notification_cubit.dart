import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

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
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  NotificationCubit() : super(NotificationState.initial()) {
    _loadNotifications();
  }

  // ─── Load from Supabase ───────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((item) => NotificationModel.fromDatabaseJson(item))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      emit(state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // ─── Save one notification to Supabase ───────────────────────────────────
  // user_id is added here so the model itself stays clean

  Future<void> _saveToSupabase(NotificationModel notification) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = notification.toDatabaseJson();
      data['user_id'] = userId;

      await _supabase.from('notifications').insert(data);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // ─── Add notification + fire system banner ────────────────────────────────

  Future<void> addNotification(NotificationModel notification) async {
    final exists = state.notifications.any((n) => n.id == notification.id);
    if (exists) return;

    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));

    // 1. Persist to Supabase notifications table
    await _saveToSupabase(notification);

    // 2. Show system banner on the device
    await NotificationService.instance.showNotification(
      // UUID hashCode gives a stable int id for the plugin
      id: notification.id.hashCode.abs() % 100000,
      title: notification.title,
      body: notification.message,
    );
  }

  // ─── Mark single notification as read ────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // ─── Mark all as read ─────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    final updatedNotifications =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    emit(state.copyWith(notifications: updatedNotifications, unreadCount: 0));

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // ─── Delete a single notification ─────────────────────────────────────────

  Future<void> deleteNotification(String notificationId) async {
    final updatedNotifications =
        state.notifications.where((n) => n.id != notificationId).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // ─── Delete multiple notifications ────────────────────────────────────────

  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    final updatedNotifications = state.notifications
        .where((n) => !notificationIds.contains(n.id))
        .toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));

    try {
      await _supabase
          .from('notifications')
          .delete()
          .inFilter('id', notificationIds);
    } catch (e) {
      print('Error deleting multiple notifications: $e');
    }
  }

  // ─── Clear all notifications for this user ────────────────────────────────

  Future<void> clearNotifications() async {
    emit(NotificationState.initial());

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // ─── Budget threshold check ───────────────────────────────────────────────
  // Logic unchanged — only id generation updated to UUID

  Future<void> checkBudgetAndNotify({
    required double monthlyBudget,
    required double totalSpent,
    required Map<String, double> categoryBudgets,
    required Map<String, double> categorySpent,
  }) async {
    final now = DateTime.now();

    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (monthlyBudget > 0) {
        final spentPercentage = (totalSpent / monthlyBudget) * 100;

        if (spentPercentage >= 80 && spentPercentage < 100) {
          final existingNear = state.notifications.any(
            (n) =>
                n.type == NotificationType.monthlyBudgetNearLimit &&
                n.timestamp.day == now.day &&
                n.timestamp.month == now.month &&
                n.timestamp.year == now.year,
          );

          if (!existingNear) {
            await addNotification(NotificationModel(
              // No id passed — auto-generates UUID
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
            ));
          }
        } else if (spentPercentage >= 100) {
          final existingExceeded = state.notifications.any(
            (n) =>
                n.type == NotificationType.monthlyBudgetExceeded &&
                n.timestamp.day == now.day &&
                n.timestamp.month == now.month &&
                n.timestamp.year == now.year,
          );

          if (!existingExceeded) {
            final overAmount = totalSpent - monthlyBudget;
            await addNotification(NotificationModel(
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
            ));
          }
        }
      }

      for (final entry in categoryBudgets.entries) {
        final category = entry.key;
        final budget = entry.value;

        if (budget > 0) {
          final spent = categorySpent[category] ?? 0;
          final spentPercentage = (spent / budget) * 100;

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
              await addNotification(NotificationModel(
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
              ));
            }
          } else if (spentPercentage >= 100) {
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
              await addNotification(NotificationModel(
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
              ));
            }
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
