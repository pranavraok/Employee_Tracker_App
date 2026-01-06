import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart'; // ✅ ADD THIS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Notification Service
  await NotificationService.init();

  // Check if employee is already registered
  final prefs = await SharedPreferences.getInstance();
  final bool isEmployeeRegistered = prefs.getString('employee_id') != null;

  // 🔥 START BACKGROUND SERVICE IF EMPLOYEE IS REGISTERED
  if (isEmployeeRegistered) {
    print('🚀 Starting background service...');
    await BackgroundService.start();
    print('✅ Background service started successfully');
  }

  runApp(
    MyApp(
      isEmployeeRegistered: isEmployeeRegistered,
    ),
  );
}
