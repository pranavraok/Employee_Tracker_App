import 'package:supabase_flutter/supabase_flutter.dart';
import '../../employee/local_storage/repositories/location_repository.dart';
import 'connectivity_service.dart';
import 'dart:developer' as dev;

class SyncService {
  static Future<void> syncLocations() async {
    try {
      dev.log('🔄 Starting sync process...');

      // Check internet connectivity
      final isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        dev.log('📵 No internet, skipping sync');
        return;
      }

      // Get unsynced locations
      final unsyncedLocations = await LocationRepository.getUnsyncedLocations();

      if (unsyncedLocations.isEmpty) {
        dev.log('✅ No locations to sync');

        // Debug: Check total locations
        final allLocations = await LocationRepository.getAllLocations();
        dev.log('📊 Total locations in DB: ${allLocations.length}');
        return;
      }

      dev.log('🔄 Syncing ${unsyncedLocations.length} locations...');

      final supabase = Supabase.instance.client;
      final List<int> syncedIds = [];

      // Upload each location
      for (final location in unsyncedLocations) {
        try {
          dev.log('📤 Uploading location: ${location['id']} for employee: ${location['employee_id']}');

          await supabase.from('locations').insert({
            'employee_id': location['employee_id'],
            'latitude': location['latitude'],
            'longitude': location['longitude'],
            'accuracy': location['accuracy'],
            'recorded_at': location['recorded_at'],
          });

          syncedIds.add(location['id'] as int);
          dev.log('✅ Synced location ${location['id']}');
        } catch (e) {
          dev.log('❌ Failed to sync location ${location['id']}: $e');
        }
      }

      // Mark as synced
      if (syncedIds.isNotEmpty) {
        await LocationRepository.markAsSynced(syncedIds);
        dev.log('✅ Marked ${syncedIds.length} locations as synced');
      }
    } catch (e) {
      dev.log('❌ Sync error: $e');
    }
  }
}

