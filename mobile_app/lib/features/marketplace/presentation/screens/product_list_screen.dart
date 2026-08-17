import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Back to Login (temp)',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(child: Text('Product List Screen')),
    );
  }
}
