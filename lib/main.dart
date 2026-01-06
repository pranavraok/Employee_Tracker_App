import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if employee is already registered
  final prefs = await SharedPreferences.getInstance();
  final bool isEmployeeRegistered =
      prefs.getString('employee_id') != null;

  runApp(
    MyApp(
      isEmployeeRegistered: isEmployeeRegistered,
    ),
  );
}
