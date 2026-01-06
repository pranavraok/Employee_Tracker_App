import 'package:flutter/material.dart';

class EmployeeTrackingScreen extends StatelessWidget {
  const EmployeeTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Active'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.location_on, size: 60, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Location tracking is running',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Your location is being recorded during work hours only.',
            ),
            SizedBox(height: 20),
            Text(
              'You can keep the app minimized.\nDo not force stop.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
