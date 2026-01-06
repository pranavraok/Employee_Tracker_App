import 'package:employee_tracker/admin/employee/screens/employee_detail_screen.dart';
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

      // 👇 Decide first screen
      home: isEmployeeRegistered
          ? const EmployeeTrackingScreen()
          : const EmployeeDetailScreen(),

      // Named routes
      routes: {
        ...AppRoutes.routes,

        // Admin entry (Option B)
        '/admin-password': (_) => const AdminPasswordScreen(),
      },
    );
  }
}
