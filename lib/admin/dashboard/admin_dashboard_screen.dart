import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String? selectedFirm;
  final List<String> firms = [
    'All Firms',
    'ElectroHeat Systems',
    'ElectroTech Services',
    'SolarTech Industries',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Fetch all employees with firm info
      final employeeData = await supabase
          .from('employees')
          .select('id, name, phone, tags, firm')
          .order('name', ascending: true);

      // For each employee, get their last location timestamp
      final employeesWithLastSeen = <Map<String, dynamic>>[];
      for (final emp in employeeData) {
        final lastLocation = await supabase
            .from('locations')
            .select('recorded_at')
            .eq('employee_id', emp['id'])
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();

        employeesWithLastSeen.add({
          'id': emp['id'],
          'name': emp['name'],
          'phone': emp['phone'],
          'tags': emp['tags'] ?? '',
          'firm': emp['firm'] ?? 'Not Assigned',
          'last_seen': lastLocation?['recorded_at'],
        });
      }

      setState(() {
        employees = employeesWithLastSeen;
        filteredEmployees = employeesWithLastSeen;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load employees: $e';
        isLoading = false;
      });
    }
  }

  void _filterEmployees() {
    setState(() {
      filteredEmployees = employees.where((emp) {
        final matchesSearch = emp['name']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()) ||
            emp['phone'].contains(searchQuery);

        final matchesFirm = selectedFirm == null ||
            selectedFirm == 'All Firms' ||
            emp['firm'] == selectedFirm;

        return matchesSearch && matchesFirm;
      }).toList();
    });
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to permanently delete "${employee['name']}"?\n\n'
              'This will remove:\n'
              '• Employee profile\n'
              '• All location history\n'
              '• All tracking data\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final employeeId = employee['id'];

      // Delete locations first
      await supabase.from('locations').delete().eq('employee_id', employeeId);

      // Delete employee
      await supabase.from('employees').delete().eq('id', employeeId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${employee['name']} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload employee list
      await _loadEmployees();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete employee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatLastSeen(String? timestamp) {
    if (timestamp == null) return 'Never tracked';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return DateFormat('MMM d, HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  bool _isActive(String? timestamp) {
    if (timestamp == null) return false;
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      return difference.inMinutes < 30; // Active if tracked within 30 min
    } catch (e) {
      return false;
    }
  }

  int get activeCount => employees.where((e) => _isActive(e['last_seen'])).length;
  int get totalCount => employees.length;

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Employee Management',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadEmployees,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Cards
              if (!isLoading && error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          totalCount.toString(),
                          Icons.people,
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Active Now',
                          activeCount.toString(),
                          Icons.circle,
                          Colors.greenAccent,
                        ),
                      ),
                    ],
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

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or phone...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          onChanged: (value) {
                            searchQuery = value;
                            _filterEmployees();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Firm Filter
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: selectedFirm ?? 'All Firms',
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.filter_list),
                            items: firms.map((firm) {
                              return DropdownMenuItem(
                                value: firm,
                                child: Text(firm),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedFirm = value;
                                _filterEmployees();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Employee List
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : error != null
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32),
                                child: Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEmployees,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                            : filteredEmployees.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No employees registered yet'
                                    : 'No employees found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee =
                            filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final lastSeen = _formatLastSeen(employee['last_seen']);
    final isActive = _isActive(employee['last_seen']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isActive
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              child: Text(
                employee['name'][0].toUpperCase(),
                style: TextStyle(
                  color: isActive ? Colors.green.shade900 : Colors.grey.shade700,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isActive)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          employee['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  employee['firm'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  employee['phone'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lastSeen,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              onPressed: () => _deleteEmployee(employee),
              tooltip: 'Delete Employee',
            ),
            // Arrow Button
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/employee-detail',
            arguments: employee,
          );
        },
      ),
    );
  }
}
