import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? currentAddress;
  LatLng? currentLocation;

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
    setState(() {
      isLoading = true;
      currentAddress = 'Loading address...';
    });

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
          .select('latitude, longitude, recorded_at')
          .eq('employee_id', employee!['id'])
          .gte('recorded_at', startOfDay.toIso8601String())
          .lt('recorded_at', endOfDay.toIso8601String())
          .order('recorded_at', ascending: true);

      if (locations.isEmpty) {
        setState(() {
          routePoints = [];
          markers = [];
          totalDistance = 0;
          currentAddress = 'No tracking data';
          isLoading = false;
        });
        return;
      }

      // Convert to LatLng for route (all points)
      final points = locations
          .map((loc) => LatLng(loc['latitude'], loc['longitude']))
          .toList();

      // Find locations where employee stayed 30+ minutes
      final stayLocations = _findStayLocations(locations);

      // Get current (latest) location
      final lastLoc = locations.last;
      currentLocation = LatLng(lastLoc['latitude'], lastLoc['longitude']);

      // Create markers for stay locations
      final newMarkers = <Marker>[];

      for (var stayLoc in stayLocations) {
        final point = LatLng(stayLoc['latitude'], stayLoc['longitude']);
        final time = _formatTime(stayLoc['recorded_at']);
        final duration = stayLoc['duration'] as int;

        newMarkers.add(
          Marker(
            point: point,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showStayInfo(time, duration, point),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Add current location marker (blue)
      newMarkers.add(
        Marker(
          point: currentLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 40,
            ),
          ),
        ),
      );

      // Calculate total distance
      final distance = _calculateTotalDistance(points);

      // Get current address (with retries)
      _getCurrentAddressWithRetry(lastLoc['latitude'], lastLoc['longitude']);

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
      setState(() {
        isLoading = false;
        currentAddress = 'Error loading data';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentAddressWithRetry(double lat, double lng) async {
    // Try Method 1: Nominatim (OpenStreetMap) - Free and reliable
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EmployeeTrackerApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;

        if (address != null && address.isNotEmpty) {
          setState(() {
            currentAddress = address;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
    }

    // Try Method 2: Photon API (backup)
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/reverse?lon=$lng&lat=$lat',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;

        if (features != null && features.isNotEmpty) {
          final properties = features[0]['properties'];
          final address = [
            properties['name'],
            properties['street'],
            properties['city'],
            properties['state'],
            properties['country'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

          if (address.isNotEmpty) {
            setState(() {
              currentAddress = address;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Photon geocoding failed: $e');
    }

    // Fallback: Show coordinates in readable format
    setState(() {
      currentAddress = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
    });
  }

  Future<String> _getAddressForLocation(double lat, double lng) async {
    // Try Nominatim first
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EmployeeTrackerApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;

        if (address != null && address.isNotEmpty) {
          return address;
        }
      }
    } catch (e) {
      debugPrint('Address fetch error: $e');
    }

    // Fallback
    return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
  }

  List<Map<String, dynamic>> _findStayLocations(List<dynamic> locations) {
    final stayLocations = <Map<String, dynamic>>[];

    if (locations.isEmpty) return stayLocations;

    for (int i = 0; i < locations.length; i++) {
      final currentLoc = locations[i];
      final currentTime = DateTime.parse(currentLoc['recorded_at']);

      // Look ahead to find how long they stayed in this area
      int j = i + 1;
      DateTime? lastTime = currentTime;

      while (j < locations.length) {
        final nextLoc = locations[j];
        final nextTime = DateTime.parse(nextLoc['recorded_at']);

        // Check if location is within 50 meters (same place)
        final distance = _calculateDistance(
          LatLng(currentLoc['latitude'], currentLoc['longitude']),
          LatLng(nextLoc['latitude'], nextLoc['longitude']),
        );

        if (distance < 50) {
          lastTime = nextTime;
          j++;
        } else {
          break;
        }
      }

      // If stayed 30+ minutes, add as a stay location
      final stayDuration = lastTime!.difference(currentTime).inMinutes;
      if (stayDuration >= 30) {
        stayLocations.add({
          'latitude': currentLoc['latitude'],
          'longitude': currentLoc['longitude'],
          'recorded_at': currentLoc['recorded_at'],
          'duration': stayDuration,
        });

        // Skip processed locations
        i = j - 1;
      }
    }

    return stayLocations;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  void _showStayInfo(String time, int duration, LatLng location) async {
    // Show dialog immediately with loading state
    String address = 'Loading address...';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 12),
            Text('Stay Location'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            // Fetch address in background
            _getAddressForLocation(location.latitude, location.longitude).then((addr) {
              setDialogState(() {
                address = addr;
              });
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Stayed for $duration minutes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: address.contains('Loading')
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
      _mapController?.move(LatLng(centerLat, centerLng), 13);
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
      body: Container(
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee!['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            employee!['firm'] ?? 'Not Assigned',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Date Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Distance Card (Main Stat)
                      if (!isLoading && routePoints.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Distance Traveled',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(totalDistance / 1000).toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Current Location Card
                      if (!isLoading && currentLocation != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Location',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentAddress ?? 'Loading...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: currentAddress?.contains('Loading') == true
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Map Legend
                      if (!isLoading && routePoints.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(Icons.my_location, 'Current', Colors.blue),
                              const SizedBox(width: 20),
                              _buildLegendItem(Icons.location_on, 'Stayed 30+ min', Colors.red),
                              const SizedBox(width: 20),
                              Container(
                                width: 40,
                                height: 3,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              const Text('Travel Path', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Map
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : routePoints.isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tracking data for this date',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: routePoints.first,
                                initialZoom: 13,
                                minZoom: 5,
                                maxZoom: 18,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                  'com.example.employee_tracker',
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
