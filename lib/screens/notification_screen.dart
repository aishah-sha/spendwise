import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color accentGreen = Color(0xFF32BA32);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProfileCubit()..loadProfile()),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          bool isDarkMode = (profileState is ProfileLoaded)
              ? profileState.user.isDarkMode
              : false;

          return Theme(
            data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
            child: Scaffold(
              backgroundColor: isDarkMode ? Colors.black : Colors.white,
              appBar: _buildAppBar(context, isDarkMode),
              body: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state.notifications.isEmpty) {
                    return _buildEmptyState(isDarkMode);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        index,
                        isDarkMode,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      title: Text(
        'Notifications',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final hasUnread = state.notifications.any((n) => !n.isRead);
            return TextButton(
              onPressed: hasUnread
                  ? () async {
                      final cubit = context.read<NotificationCubit>();
                      await cubit.markAllAsRead();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications marked as read'),
                            backgroundColor: accentGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null, // Disable button when no unread notifications
              child: Text(
                'Mark all as read',
                style: TextStyle(color: hasUnread ? accentGreen : Colors.grey),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            _showClearAllDialog(context, isDarkMode);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDarkMode ? Colors.white60 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          'Clear All Notifications',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final cubit = context.read<NotificationCubit>();
              final notifications = cubit.state.notifications
                  .toList(); // Save for undo
              await cubit.clearNotifications();

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications cleared'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () async {
                        // Restore all notifications
                        for (var notification in notifications) {
                          await context
                              .read<NotificationCubit>()
                              .addNotification(notification);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Restored all notifications'),
                              backgroundColor: accentGreen,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSingleDialog(
    BuildContext context,
    String notificationId,
    bool isDarkMode,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          'Delete Notification',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final cubit = context.read<NotificationCubit>();
              await cubit.deleteNotification(notificationId);

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notification deleted'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () async {
                        // Restore the notification
                        await context.read<NotificationCubit>().addNotification(
                          notification,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification restored'),
                              backgroundColor: accentGreen,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
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
    bool isDarkMode,
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
      onDismissed: (direction) async {
        // Save notification for potential undo
        final deletedNotification = notification;

        // Delete the notification
        await context.read<NotificationCubit>().deleteNotification(
          notification.id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () async {
                  // Restore the notification
                  await context.read<NotificationCubit>().addNotification(
                    deletedNotification,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification restored'),
                        backgroundColor: accentGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () async {
          // Mark as read when tapped (if not already read)
          if (!notification.isRead) {
            await context.read<NotificationCubit>().markAsRead(notification.id);
          }

          // Optional: Navigate to detail screen based on notification type
          _handleNotificationTap(context, notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDarkMode ? Colors.grey[850] : Colors.white)
                : (isDarkMode
                      ? accentGreen.withOpacity(0.15)
                      : Colors.green.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? (isDarkMode ? Colors.grey[700]! : Colors.grey.shade200)
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
                            ? (isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700)
                            : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white60
                            : Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white60
                            : Colors.grey.shade500,
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
                  _showDeleteSingleDialog(
                    context,
                    notification.id,
                    isDarkMode,
                    notification,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.1),
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

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.monthlyBudgetExceeded:
      case NotificationType.monthlyBudgetNearLimit:
        // Navigate to monthly budget screen
        _showNotificationDetails(context, notification);
        break;
      case NotificationType.categoryBudgetExceeded:
      case NotificationType.categoryBudgetNearLimit:
        // Navigate to category budget screen
        _showNotificationDetails(context, notification);
        break;
      default:
        _showNotificationDetails(context, notification);
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(notification.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'Received: ${_formatDetailedTime(notification.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Additional Details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...notification.data!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accentGreen),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Add action based on notification type
                      _handleNotificationAction(context, notification);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Take Action'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationAction(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Implement action based on notification type
    switch (notification.type) {
      case NotificationType.monthlyBudgetExceeded:
      case NotificationType.monthlyBudgetNearLimit:
        // Navigate to budget adjustment screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to budget settings'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      case NotificationType.categoryBudgetExceeded:
      case NotificationType.categoryBudgetNearLimit:
        // Navigate to category budget screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to category budget'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action triggered'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }

  String _formatDetailedTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

// Add this method to your NotificationCubit if not already present
extension NotificationCubitExtension on NotificationCubit {
  Future<void> addNotification(NotificationModel notification) async {
    // Implement this method to add a notification back to the list
    // This should emit a new state with the notification added
    final currentState = state;
    final updatedNotifications = List<NotificationModel>.from(
      currentState.notifications,
    )..insert(0, notification);
    emit(currentState.copyWith(notifications: updatedNotifications));
  }
}
