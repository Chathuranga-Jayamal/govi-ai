import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Login (temp)',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(child: Text('Capture Screen')),
    );
  }
}
