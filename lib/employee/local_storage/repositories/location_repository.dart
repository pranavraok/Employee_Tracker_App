import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import 'dart:developer' as dev;

class LocationRepository {
  // Insert a new location record
  static Future<int> insertLocation({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      final db = await DatabaseHelper.database;

      final id = await db.insert(
        'locations',
        {
          'employee_id': employeeId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
          'is_synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      dev.log('✅ Location saved: $id (employee: $employeeId)');

      // Immediately check unsynced count
      final unsyncedCount = await getUnsyncedCount();
      dev.log('📊 Total unsynced: $unsyncedCount');

      return id;
    } catch (e) {
      dev.log('❌ Insert location error: $e');
      rethrow;
    }
  }

  // Get count of unsynced locations
  static Future<int> getUnsyncedCount() async {
    try {
      final db = await DatabaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM locations WHERE is_synced = 0',
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      dev.log('📈 Unsynced count: $count');
      return count;
    } catch (e) {
      dev.log('❌ getUnsyncedCount error: $e');
      return 0;
    }
  }

  // Get all unsynced locations
  static Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    try {
      final db = await DatabaseHelper.database;

      // First check if table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='locations'"
      );

      if (tables.isEmpty) {
        dev.log('❌ Table locations does not exist!');
        return [];
      }

      final locations = await db.query(
        'locations',
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'recorded_at ASC',
      );

      dev.log('📍 Found ${locations.length} unsynced locations');

      // Print first location for debugging
      if (locations.isNotEmpty) {
        dev.log('📌 Sample location: ${locations.first}');
      }

      return locations;
    } catch (e) {
      dev.log('❌ getUnsyncedLocations error: $e');
      return [];
    }
  }

  // Mark locations as synced
  static Future<int> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return 0;

    try {
      final db = await DatabaseHelper.database;
      final count = await db.update(
        'locations',
        {'is_synced': 1},
        where: 'id IN (${ids.join(',')})',
      );

      dev.log('✅ Marked $count locations as synced');
      return count;
    } catch (e) {
      dev.log('❌ markAsSynced error: $e');
      return 0;
    }
  }

  // Get all locations (for debugging) - THIS WAS MISSING!
  static Future<List<Map<String, dynamic>>> getAllLocations() async {
    try {
      final db = await DatabaseHelper.database;
      final locations = await db.query('locations');
      dev.log('📊 Total locations in DB: ${locations.length}');
      return locations;
    } catch (e) {
      dev.log('❌ getAllLocations error: $e');
      return [];
    }
  }

  // Delete old synced locations (cleanup)
  static Future<int> deleteOldSyncedLocations({int daysOld = 30}) async {
    try {
      final db = await DatabaseHelper.database;
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysOld))
          .toUtc()
          .toIso8601String();

      return await db.delete(
        'locations',
        where: 'is_synced = ? AND recorded_at < ?',
        whereArgs: [1, cutoffDate],
      );
    } catch (e) {
      dev.log('❌ deleteOldSyncedLocations error: $e');
      return 0;
    }
  }
}
