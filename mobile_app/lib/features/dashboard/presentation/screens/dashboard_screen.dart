import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Login (temp)',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(child: Text('Dashboard Screen')),
    );
  }
}
