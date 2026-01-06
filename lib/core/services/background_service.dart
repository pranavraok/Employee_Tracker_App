import 'dart:async';
import 'notification_service.dart';
import 'location_service.dart';
import 'sync_service.dart';
import 'work_hours_service.dart';

class BackgroundService {
  static Timer? _locationTimer;
  static Timer? _syncTimer;
  static Timer? _statusCheckTimer;

  static Future<void> start() async {
    await NotificationService.showTrackingNotification();

    // 🔄 Location capture every 30 seconds (with work hours check inside)
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => LocationService.captureLocation(),
    );

    // 🌐 Sync every 5 minutes
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
          (_) => SyncService.syncLocations(),
    );

    // 🆕 Update notification every minute
    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _updateNotificationStatus(),
    );

    // Immediate first sync on start
    SyncService.syncLocations();
  }

  static Future<void> _updateNotificationStatus() async {
    final status = WorkHoursService.getWorkStatusMessage();
    await NotificationService.updateNotification(status);
  }

  static void stop() {
    _locationTimer?.cancel();
    _syncTimer?.cancel();
    _statusCheckTimer?.cancel();
    _locationTimer = null;
    _syncTimer = null;
    _statusCheckTimer = null;
  }
}

