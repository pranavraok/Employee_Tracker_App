import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Rahul Kumar'),
            subtitle: const Text('9876543210 • Delivery'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/employee-detail');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Ankit Singh'),
            subtitle: const Text('9123456789 • Sales'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.pushNamed(context, '/employee-detail');
            },
          ),
        ],
      ),
    );
  }
}
