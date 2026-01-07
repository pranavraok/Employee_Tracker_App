import 'package:geolocator/geolocator.dart';
import '../../employee/local_storage/repositories/location_repository.dart';
import 'work_hours_service.dart';
import 'dart:developer';

class LocationService {
  static Future<void> captureLocation(String employeeId) async {
    try {
      // 🆕 CHECK WORK HOURS FIRST
      if (!WorkHoursService.isWithinWorkHours()) {
        log('⏸️ Skipping GPS capture - Outside work hours');
        return;
      }

      // 1️⃣ Ensure location service is ON
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ Location service disabled');
        return;
      }

      // 2️⃣ Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log('❌ Location permission denied');
        return;
      }

      // 3️⃣ Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4️⃣ Extract data
      final latitude = position.latitude;
      final longitude = position.longitude;
      final accuracy = position.accuracy;

      // 5️⃣ Save to SQLite using insertLocation
      final savedId = await LocationRepository.insertLocation(
        employeeId: employeeId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

      if (savedId > 0) {
        log(
          '📍 Location saved | ID=$savedId | lat=$latitude, lng=$longitude, '
              'accuracy=${accuracy.toStringAsFixed(1)}m',
        );
      }
    } catch (e) {
      log('⚠️ Location error: $e');
    }
  }
}

