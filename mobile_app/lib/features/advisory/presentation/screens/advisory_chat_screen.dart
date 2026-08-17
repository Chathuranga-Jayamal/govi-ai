import 'package:flutter/material.dart';

import '../../../../core/widgets/app_drawer.dart';

class AdvisoryChatScreen extends StatelessWidget {
  const AdvisoryChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advisory Chat Screen')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Advisory Chat Screen')),
    );
  }
}
