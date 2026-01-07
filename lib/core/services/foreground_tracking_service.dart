import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../employee/local_storage/repositories/location_repository.dart';
import 'work_hours_service.dart';
import 'sync_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class ForegroundTrackingService {
  static void initializeService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_tracking_channel',
        channelName: 'Location Tracking',
        channelDescription: 'Tracks employee location during work hours',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      print('✅ Service already running');
      return;
    }

    // Request battery optimization permission
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // ✅ FIX: Don't check result.success, just call the service
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Location Tracking Active',
      notificationText: 'Tracking your location',
      callback: startCallback,
    );

    print('🚀 Foreground service started');
  }

  static Future<void> stopService() async {
    // ✅ FIX: Don't check result.success, just call the service
    await FlutterForegroundTask.stopService();
    print('🛑 Foreground service stopped');
  }

  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}

class LocationTaskHandler extends TaskHandler {
  int _locationCount = 0;
  int _syncCycle = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🚀 Location tracking started');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      // Check work hours
      if (!WorkHoursService.isWithinWorkHours()) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Tracking Paused',
          notificationText: 'Outside work hours',
        );
        return;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 15));

      // Get employee ID
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_id');

      if (employeeId == null) {
        print('❌ No employee ID');
        return;
      }

      // Save location
      await LocationRepository.insertLocation(
        employeeId: employeeId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      _locationCount++;
      print('✅ Location saved: $_locationCount');

      // Update notification
      FlutterForegroundTask.updateService(
        notificationTitle: 'Location Tracking Active',
        notificationText: 'Recorded $_locationCount locations',
      );

      // Sync every 10 cycles (5 minutes)
      _syncCycle++;
      if (_syncCycle >= 10) {
        await SyncService.syncLocations();
        _syncCycle = 0;
        print('✅ Synced locations');
      }
    } catch (e) {
      print('❌ Error: $e');
      FlutterForegroundTask.updateService(
        notificationTitle: 'Tracking Error',
        notificationText: 'Retrying...',
      );
    }

    FlutterForegroundTask.sendDataToMain({'locationCount': _locationCount});
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🛑 Tracking stopped');
  }

  @override
  void onRepeatEventError(Object error, StackTrace stackTrace) {
    print('❌ Repeat error: $error');
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('🔔 Button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    print('🔔 Notification tapped');
    FlutterForegroundTask.launchApp('/tracking');
  }

  @override
  void onNotificationDismissed() {
    print('🔔 Notification dismissed');
  }
}
