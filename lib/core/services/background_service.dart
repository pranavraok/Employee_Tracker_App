import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'location_service.dart';
import 'sync_service.dart';
import 'work_hours_service.dart';
import 'dart:developer';

class BackgroundService {
  static Timer? _locationTimer;
  static Timer? _syncTimer;
  static Timer? _statusCheckTimer;

  static Future<void> start() async {
    try {
      // Get employee_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_id');

      if (employeeId == null) {
        log('❌ No employee_id found, cannot start tracking');
        return;
      }

      log('✅ Starting background service for employee: $employeeId');

      NotificationService.showTrackingNotification('Tracking active');

      // 🔄 Location capture every 30 seconds (with work hours check inside)
      _locationTimer = Timer.periodic(
        const Duration(seconds: 30),
            (_) => LocationService.captureLocation(employeeId),
      );

      // 🌐 Sync every 2 minutes
      _syncTimer = Timer.periodic(
        const Duration(minutes: 2),
            (_) => SyncService.syncLocations(),
      );

      // 🆕 Update notification every minute
      _statusCheckTimer = Timer.periodic(
        const Duration(minutes: 1),
            (_) => _updateNotificationStatus(),
      );

      // Immediate first capture and sync
      await LocationService.captureLocation(employeeId);
      await SyncService.syncLocations();
    } catch (e) {
      log('❌ Error starting background service: $e');
    }
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

    log('🛑 Background service stopped');
  }
}
