import 'package:geolocator/geolocator.dart';
import 'dart:developer';

class LocationService {
  static Future<void> captureLocation() async {
    try {
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

      // 5️⃣ UTC timestamp (IMPORTANT)
      final recordedAtUtc = DateTime.now().toUtc();

      // 6️⃣ TEMP: Log it (replace with DB/server in next steps)
      log(
        '📍 LOCATION | lat=$latitude, lng=$longitude, '
            'accuracy=${accuracy.toStringAsFixed(1)}m, '
            'time=$recordedAtUtc',
      );

      // NEXT STEP (not yet):
      // - if online -> send to Supabase
      // - else -> save locally

    } catch (e) {
      log('⚠️ Location error: $e');
    }
  }
}
