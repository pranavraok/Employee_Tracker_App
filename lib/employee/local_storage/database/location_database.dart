import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'employee_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            recorded_at TEXT NOT NULL,
            synced INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  // Insert location
  static Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    return await db.insert('locations', location);
  }

  // Get unsynced locations
  static Future<List<Map<String, dynamic>>> getUnsyncedLocations({
    int limit = 50,
  }) async {
    final db = await database;
    return await db.query(
      'locations',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'recorded_at ASC',
      limit: limit,
    );
  }

  // Mark locations as synced
  static Future<int> markAsSynced(List<int> ids) async {
    final db = await database;
    return await db.update(
      'locations',
      {'synced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }

  // Get total unsynced count
  static Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM locations WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete old synced locations (cleanup)
  static Future<int> deleteOldSyncedLocations({int daysOld = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysOld))
        .toIso8601String();

    return await db.delete(
      'locations',
      where: 'synced = ? AND created_at < ?',
      whereArgs: [1, cutoffDate],
    );
  }
}

