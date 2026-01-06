import 'package:supabase_flutter/supabase_flutter.dart';
import '../../employee/local_storage/repositories/location_repository.dart';
import '../constants/app_constants.dart';
import 'connectivity_service.dart';
import 'dart:developer';

class SyncService {
  static bool _isSyncing = false;

  // Start sync process
  static Future<void> syncLocations() async {
    if (_isSyncing) {
      log('⏳ Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;

    try {
      // 1️⃣ Check internet
      final isOnline = await ConnectivityService.isConnected();
      if (!isOnline) {
        log('📵 No internet. Sync skipped.');
        _isSyncing = false;
        return;
      }

      // 2️⃣ Get unsynced count
      final unsyncedCount = await LocationRepository.getUnsyncedCount();
      if (unsyncedCount == 0) {
        log('✅ No locations to sync');
        _isSyncing = false;
        return;
      }

      log('🔄 Starting sync: $unsyncedCount unsynced locations');

      // 3️⃣ Fetch batch
      final locations = await LocationRepository.getUnsyncedLocations(
        limit: AppConstants.syncBatchSize,
      );

      if (locations.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 4️⃣ Prepare data for Supabase
      final dataToUpload = locations.map((loc) {
        return {
          'employee_id': loc['employee_id'],
          'latitude': loc['latitude'],
          'longitude': loc['longitude'],
          'accuracy': loc['accuracy'],
          'recorded_at': loc['recorded_at'],
        };
      }).toList();

      // 5️⃣ Upload to Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('locations').insert(dataToUpload);

      // 6️⃣ Mark as synced
      final ids = locations.map((loc) => loc['id'] as int).toList();
      await LocationRepository.markAsSynced(ids);

      log('✅ Successfully synced ${locations.length} locations');

      // 7️⃣ If more exist, sync again
      if (unsyncedCount > AppConstants.syncBatchSize) {
        log('🔄 More locations pending. Syncing next batch...');
        await Future.delayed(const Duration(seconds: 2));
        await syncLocations(); // Recursive call
      }
    } catch (e) {
      log('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
