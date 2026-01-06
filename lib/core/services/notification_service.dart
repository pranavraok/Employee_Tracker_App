import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'work_hours_service.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);
  }

  static Future<void> showTrackingNotification() async {
    final status = WorkHoursService.getWorkStatusMessage();

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
      'Employee Tracker',
      status,
      const NotificationDetails(android: androidDetails),
    );
  }

  // 🆕 Update notification dynamically
  static Future<void> updateNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Employee Tracking',
      channelDescription: 'Location tracking status',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
    );

    await _notifications.show(
      1,
      'Employee Tracker',
      message,
      const NotificationDetails(android: androidDetails),
    );
  }
}
