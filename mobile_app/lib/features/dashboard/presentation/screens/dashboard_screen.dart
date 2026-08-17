import 'package:flutter/material.dart';

import '../../../../core/widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Screen')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Dashboard Screen')),
    );
  }
}
