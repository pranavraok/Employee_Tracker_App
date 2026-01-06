import 'dart:async';
import 'notification_service.dart';
import 'location_service.dart';

class BackgroundService {
  static Timer? _timer;

  static Future<void> start() async {
    await NotificationService.showTrackingNotification();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => LocationService.captureLocation(),
    );
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
