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
  bool isLoading = true;
  String? error;

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

      // Fetch all employees
      final employeeData = await supabase
          .from('employees')
          .select('id, name, phone, tags')
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
          'last_seen': lastLocation?['recorded_at'],
        });
      }

      setState(() {
        employees = employeesWithLastSeen;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load employees: $e';
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployees,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : employees.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No employees registered yet'),
          ],
        ),
      )
          : ListView.separated(
        itemCount: employees.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final employee = employees[index];
          final lastSeen = _formatLastSeen(employee['last_seen']);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                employee['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              employee['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📱 ${employee['phone']}'),
                if (employee['tags'].isNotEmpty)
                  Text(
                    '🏷️ ${employee['tags']}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                Text(
                  '🕒 $lastSeen',
                  style: TextStyle(
                    fontSize: 12,
                    color: lastSeen.contains('ago')
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/employee-detail',
                arguments: employee,
              );
            },
          );
        },
      ),
    );
  }
}
