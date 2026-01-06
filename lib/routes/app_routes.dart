import 'package:flutter/material.dart';
import '../admin/dashboard/admin_dashboard_screen.dart';
import '../admin/employee/screens/employee_detail_screen.dart';
import '../employee/tracking/screens/employee_tracking_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/employee-tracking': (_) => const EmployeeTrackingScreen(),
    '/admin-dashboard': (_) => const AdminDashboardScreen(),
    '/employee-detail': (_) => const EmployeeDetailScreen(),
  };
}
