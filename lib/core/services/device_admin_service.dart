import 'package:flutter/services.dart';

class DeviceAdminService {
  static const platform = MethodChannel('device_admin_channel');

  static Future<bool> requestDeviceAdmin() async {
    try {
      final bool result = await platform.invokeMethod('requestDeviceAdmin');
      return result;
    } catch (e) {
      print('Error requesting device admin: $e');
      return false;
    }
  }

  static Future<bool> isDeviceAdminActive() async {
    try {
      final bool result = await platform.invokeMethod('isDeviceAdminActive');
      return result;
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  static Future<void> removeDeviceAdmin() async {
    try {
      await platform.invokeMethod('removeDeviceAdmin');
    } catch (e) {
      print('Error removing device admin: $e');
    }
  }
}

