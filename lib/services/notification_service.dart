import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles system-level push banners (lock screen, notification tray).
/// Call [NotificationService.instance.init()] once in main.dart before runApp().
/// Compatible with flutter_local_notifications ^22.0.0-dev.3
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── Initialise once at app startup ──────────────────────────────────────

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // FIXED: Added the required 'settings:' named parameter
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap here if needed
      },
    );
  }

  // ─── Show a system banner ─────────────────────────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'spendwise_budget_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when you approach or exceed your budget',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // FIXED: Added named arguments for id, title, and body
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
