import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'auth/screens/login_screen.dart'; // Employee setup screen
import 'employee/tracking/screens/employee_tracking_screen.dart';
import 'auth/screens/admin_password_screen.dart';

class MyApp extends StatelessWidget {
  final bool isEmployeeRegistered;

  const MyApp({
    super.key,
    required this.isEmployeeRegistered,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      // 👇 FIX: Correct routing
      home: isEmployeeRegistered
          ? const EmployeeTrackingScreen()  // ✅ If registered → tracking
          : const LoginScreen(),            // ✅ If NOT registered → login/setup

      // Named routes
      routes: {
        ...AppRoutes.routes,
        '/admin-password': (_) => const AdminPasswordScreen(),
      },
    );
  }
}
