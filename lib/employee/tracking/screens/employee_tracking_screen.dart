import 'package:flutter/material.dart';
import '../../../core/services/work_hours_service.dart';
import '../../../core/services/background_service.dart';
import 'dart:async';
import '../../local_storage/repositories/location_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sync_service.dart'; // ✅ ADD THIS IMPORT


class EmployeeTrackingScreen extends StatefulWidget {
  const EmployeeTrackingScreen({super.key});

  @override
  State<EmployeeTrackingScreen> createState() =>
      _EmployeeTrackingScreenState();
}

class _EmployeeTrackingScreenState extends State<EmployeeTrackingScreen> {
  String statusMessage = '';
  int unsyncedCount = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateStatus();

    // Update status every 10 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _updateStatus();
      }
    });
  }

  Future<void> _updateStatus() async {
    final count = await LocationRepository.getUnsyncedCount();
    setState(() {
      statusMessage = WorkHoursService.getWorkStatusMessage();
      unsyncedCount = count;
    });
  }

  // 🆕 LOGOUT FUNCTION
  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'This will stop tracking and clear your registration. '
              'You will need to register again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Stop background service
    BackgroundService.stop();

    // Clear employee_id from local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('employee_id');

    // Navigate to login screen
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = WorkHoursService.isWithinWorkHours();

    return Scaffold(
      appBar: AppBar(
        title: Text(isActive ? 'Tracking Active' : 'Tracking Paused'),
        backgroundColor: isActive ? Colors.green : Colors.orange,
        actions: [
          // 🆕 LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              size: 60,
              color: isActive ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isActive
                  ? 'Your location is being recorded every 30 seconds.'
                  : 'Tracking is paused. It will resume during work hours.',
            ),
            const SizedBox(height: 20),

            // DEBUG INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Debug Info',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('🔢 Unsynced locations: $unsyncedCount'),
                  const SizedBox(height: 4),
                  Text('🕐 Last checked: ${DateTime.now().toString().substring(11, 19)}'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ),
                ],
              ),
            ),
            // In the debug info section, add a new button:

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await SyncService.syncLocations();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync triggered - check logs')),
                  );
                  await Future.delayed(const Duration(seconds: 2));
                  _updateStatus();
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'You can keep the app minimized.\nDo not force stop the app.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),

      // Admin access button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin-password');
        },
        child: const Icon(Icons.admin_panel_settings),
        tooltip: 'Admin Access',
      ),
    );
  }
}


