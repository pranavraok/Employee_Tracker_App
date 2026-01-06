import 'package:shared_preferences/shared_preferences.dart';
import '../database/location_database.dart';
import 'dart:developer';

class LocationRepository {
  // Save location to SQLite
  static Future<bool> saveLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime recordedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employee_id');

      if (employeeId == null) {
        log('❌ No employee_id found. Cannot save location.');
        return false;
      }

      final locationData = {
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
        'synced': 0,
      };

      final id = await LocationDatabase.insertLocation(locationData);
      log('✅ Location saved to SQLite (ID: $id)');
      return true;
    } catch (e) {
      log('❌ Error saving location: $e');
      return false;
    }
  }

  // Get unsynced locations
  static Future<List<Map<String, dynamic>>> getUnsyncedLocations({
    int limit = 50,
  }) async {
    return await LocationDatabase.getUnsyncedLocations(limit: limit);
  }

  // Mark as synced
  static Future<bool> markAsSynced(List<int> ids) async {
    try {
      await LocationDatabase.markAsSynced(ids);
      log('✅ Marked ${ids.length} locations as synced');
      return true;
    } catch (e) {
      log('❌ Error marking as synced: $e');
      return false;
    }
  }

  // Get unsynced count
  static Future<int> getUnsyncedCount() async {
    return await LocationDatabase.getUnsyncedCount();
  }
}
