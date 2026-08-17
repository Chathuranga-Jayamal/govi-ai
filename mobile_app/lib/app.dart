import 'package:flutter/material.dart';

import 'routes/app_router.dart';

class GoviApp extends StatelessWidget {
  const GoviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Govi-AI',
      routerConfig: appRouter,
    );
  }
}
