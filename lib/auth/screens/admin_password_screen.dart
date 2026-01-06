import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class AdminPasswordScreen extends StatefulWidget {
  const AdminPasswordScreen({super.key});

  @override
  State<AdminPasswordScreen> createState() => _AdminPasswordScreenState();
}

class _AdminPasswordScreenState extends State<AdminPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  String? error;

  void verifyPassword() {
    if (_passwordCtrl.text == AppConstants.adminPassword) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      setState(() => error = "Wrong password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Access")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Admin Password",
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyPassword,
              child: const Text("Enter"),
            ),
          ],
        ),
      ),
    );
  }
}
