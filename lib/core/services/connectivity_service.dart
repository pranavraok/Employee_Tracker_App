import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has any active internet connection
  static Future<bool> isConnected() async {
    try {
      // In v6.1.2, checkConnectivity() returns ConnectivityResult (not List)
      final ConnectivityResult result = await _connectivity.checkConnectivity();

      final bool hasConnection = result != ConnectivityResult.none;

      log(hasConnection ? '🌐 Internet: ONLINE' : '📵 Internet: OFFLINE');
      return hasConnection;
    } catch (e) {
      log('❌ Connectivity check error: $e');
      return false;
    }
  }

  /// Stream that emits connectivity status changes
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((ConnectivityResult result) {
      return result != ConnectivityResult.none;
    });
  }
}
