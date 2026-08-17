import 'package:flutter/material.dart';

import '../../../../core/widgets/app_drawer.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Screen')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Capture Screen')),
    );
  }
}
