import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  static Future<void> showTrackingNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Employee Tracking',
      channelDescription: 'Location tracking is active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );

    await _notifications.show(
      1,
      'Tracking enabled',
      'Work-hours location tracking is active',
      const NotificationDetails(android: androidDetails),
    );
  }
}
