import 'package:flutter/material.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Rahul Kumar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Phone: 9876543210'),
            Text('Tags: Delivery, Bike'),

            SizedBox(height: 20),

            Text(
              'Map will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Icon(Icons.map, size: 100, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
