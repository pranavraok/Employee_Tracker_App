import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // Initialize notification service
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
    print('✅ Notification service initialized');
  }

  // Show tracking notification
  static Future<void> showTrackingNotification(String message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'tracking_channel',
      'Employee Tracking',
      channelDescription: 'Location tracking is active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Employee Tracker',
      message,
      notificationDetails,
    );
  }

  // Update notification
  static Future<void> updateNotification(String message) async {
    await showTrackingNotification(message);
  }

  // Cancel notification
  static Future<void> cancelNotification() async {
    await _notifications.cancel(1);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

