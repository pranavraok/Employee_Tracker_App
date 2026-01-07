import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'auth/screens/login_screen.dart';
import 'employee/tracking/screens/employee_tracking_screen.dart';
import 'auth/screens/admin_password_screen.dart';
import 'shared/screens/splash_screen.dart';  // ✅ ADD THIS

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

      // ✅ Always show splash screen first
      home: const SplashScreen(),

      // Named routes
      routes: {
        ...AppRoutes.routes,
        '/admin-password': (_) => const AdminPasswordScreen(),
        '/login': (_) => const LoginScreen(),  // ✅ ADD THIS
        '/tracking': (_) => const EmployeeTrackingScreen(),  // ✅ ADD THIS
      },
    );
  }
}
