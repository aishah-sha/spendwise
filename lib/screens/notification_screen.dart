import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notification_cubit.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color accentGreen = Color(0xFF32BA32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationCubit>().markAllAsRead();
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: accentGreen),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearAllDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return _buildNotificationItem(context, notification, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationCubit>().clearNotifications();
              Navigator.pop(context);

              // Show snackbar confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSingleDialog(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationCubit>().deleteNotification(
                notificationId,
              );
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    int index,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Delete the notification when swiped
        context.read<NotificationCubit>().deleteNotification(notification.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // Optional: Add undo functionality
                // context.read<NotificationCubit>().undoDelete();
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          // Mark as read when tapped (if not already read)
          if (!notification.isRead) {
            context.read<NotificationCubit>().markAsRead(notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : accentGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on notification type
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: notification.isRead
                            ? Colors.grey.shade700
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),

              // Delete button (optional - as an alternative to swipe)
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _showDeleteSingleDialog(context, notification.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.monthlyBudgetExceeded:
      case NotificationType.categoryBudgetExceeded:
      case NotificationType.budgetExceeded:
        return Icons.warning_amber_rounded;
      case NotificationType.monthlyBudgetNearLimit:
      case NotificationType.categoryBudgetNearLimit:
      case NotificationType.budgetNearLimit:
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.monthlyBudgetExceeded:
      case NotificationType.categoryBudgetExceeded:
      case NotificationType.budgetExceeded:
        return Colors.red;
      case NotificationType.monthlyBudgetNearLimit:
      case NotificationType.categoryBudgetNearLimit:
      case NotificationType.budgetNearLimit:
        return Colors.orange;
      default:
        return accentGreen;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
