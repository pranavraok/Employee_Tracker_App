import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  // Check if internet is available
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final connected = result.first != ConnectivityResult.none;
      log(connected ? '🌐 Internet: ONLINE' : '📵 Internet: OFFLINE');
      return connected;
    } catch (e) {
      log('❌ Connectivity check error: $e');
      return false;
    }
  }

  // Listen to connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((resultList) {
      return resultList.isNotEmpty && resultList.first != ConnectivityResult.none;
    });
  }
}
