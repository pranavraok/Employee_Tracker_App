import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  MapController? _mapController;
  Map<String, dynamic>? employee;
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  double totalDistance = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    employee = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (employee != null) {
      _loadLocationData();
    }
  }

  Future<void> _loadLocationData() async {
    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Get locations for selected date
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final locations = await supabase
          .from('locations')
          .select('latitude, longitude, recorded_at, accuracy')
          .eq('employee_id', employee!['id'])
          .gte('recorded_at', startOfDay.toIso8601String())
          .lt('recorded_at', endOfDay.toIso8601String())
          .order('recorded_at', ascending: true);

      if (locations.isEmpty) {
        setState(() {
          routePoints = [];
          markers = [];
          totalDistance = 0;
          isLoading = false;
        });
        return;
      }

      // Convert to LatLng
      final points = locations
          .map((loc) => LatLng(loc['latitude'], loc['longitude']))
          .toList();

      // Create markers
      final newMarkers = <Marker>[];

      // Start marker (Green)
      newMarkers.add(
        Marker(
          point: points.first,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              _showMarkerInfo(
                'Start Point',
                _formatTime(locations.first['recorded_at']),
              );
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.green,
              size: 40,
            ),
          ),
        ),
      );

      // End marker (Red)
      if (points.length > 1) {
        newMarkers.add(
          Marker(
            point: points.last,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                _showMarkerInfo(
                  'End Point',
                  _formatTime(locations.last['recorded_at']),
                );
              },
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        );
      }

      // Calculate total distance
      final distance = _calculateTotalDistance(points);

      setState(() {
        routePoints = points;
        markers = newMarkers;
        totalDistance = distance;
        isLoading = false;
      });

      // Fit bounds to show all points
      if (points.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _fitBounds(points);
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showMarkerInfo(String title, String time) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title at $time'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    try {
      _mapController?.move(LatLng(centerLat, centerLng), 15);
    } catch (e) {
      debugPrint('Map move error: $e');
    }
  }

  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0;

    final Distance distance = const Distance();
    double total = 0;

    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }

    return total;
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadLocationData();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (employee == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employee Details')),
        body: const Center(child: Text('No employee data')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(employee!['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Employee Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee!['name'],
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('📱 ${employee!['phone']}'),
                if (employee!['tags'].toString().isNotEmpty)
                  Text('🏷️ ${employee!['tags']}'),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(selectedDate),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (!isLoading && routePoints.isNotEmpty)
                  Text(
                    '📍 ${routePoints.length} points • ${(totalDistance / 1000).toStringAsFixed(2)} km',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : routePoints.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tracking data for this date'),
                ],
              ),
            )
                : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: routePoints.first,
                initialZoom: 14,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.employee_tracker',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
