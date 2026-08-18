import 'package:flutter/material.dart';

import 'core/state/cart_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

class GoviApp extends StatefulWidget {
  const GoviApp({super.key});

  @override
  State<GoviApp> createState() => _GoviAppState();
}

class _GoviAppState extends State<GoviApp> {
  final CartController _cartController = CartController();

  @override
  void dispose() {
    _cartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartScope(
      controller: _cartController,
      child: MaterialApp.router(
        title: 'Govi-AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
