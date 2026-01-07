import 'package:flutter/material.dart';
import '../../../core/services/work_hours_service.dart';
import '../../../core/services/foreground_tracking_service.dart';
import 'dart:async';
import '../../local_storage/repositories/location_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sync_service.dart';

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
  Timer? _autoSyncTimer;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _updateStatus();

    // Update status every 10 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _updateStatus();
        _checkServiceStatus();
      }
    });

    // Auto-sync every 30 seconds
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _autoSync();
      }
    });
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await ForegroundTrackingService.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  Future<void> _updateStatus() async {
    final count = await LocationRepository.getUnsyncedCount();
    setState(() {
      statusMessage = WorkHoursService.getWorkStatusMessage();
      unsyncedCount = count;
    });
  }

  Future<void> _autoSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await SyncService.syncLocations();
      setState(() => _lastSyncTime = DateTime.now());
      await _updateStatus();
    } catch (e) {
      print('Auto-sync error: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  String _formatLastSync() {
    if (_lastSyncTime == null) return 'Not synced yet';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = WorkHoursService.isWithinWorkHours();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (WITHOUT logout button)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Tracking Active' : 'Tracking Paused',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isServiceRunning
                                    ? Colors.greenAccent
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isServiceRunning
                                  ? 'Service Running'
                                  : 'Service Stopped',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Status Icon
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 80,
                            color: isActive ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Status Message
                        Text(
                          statusMessage,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isActive
                              ? 'Your location is being recorded every 30 seconds.'
                              : 'Tracking is paused. It will resume during work hours.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Sync Status Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.cyan.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.shade100,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_upload,
                                        color: Colors.blue.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Auto-Sync',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _isSyncing
                                                ? 'Syncing...'
                                                : _formatLastSync(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (_isSyncing)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              if (unsyncedCount > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pending,
                                        size: 16,
                                        color: Colors.orange.shade900,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$unsyncedCount pending locations',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Info Cards
                        _buildInfoCard(
                          Icons.timer,
                          'Work Hours',
                          '9:00 AM - 6:00 PM',
                          Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          Icons.update,
                          'Update Interval',
                          'Every 30 seconds',
                          Colors.teal,
                        ),
                        const SizedBox(height: 30),

                        // Important Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'App runs in background. Do not force stop or clear from recent apps.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // NO FLOATING ACTION BUTTON - Admin FAB removed
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



