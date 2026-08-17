import 'package:flutter/material.dart';

import '../../../../core/widgets/app_drawer.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product List Screen')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Product List Screen')),
    );
  }
}
