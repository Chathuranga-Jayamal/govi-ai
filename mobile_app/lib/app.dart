import 'package:flutter/material.dart';

import 'core/state/cart_controller.dart';
import 'core/state/current_user_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

class GoviApp extends StatefulWidget {
  const GoviApp({super.key});

  @override
  State<GoviApp> createState() => _GoviAppState();
}

class _GoviAppState extends State<GoviApp> {
  final CartController _cartController = CartController();
  final CurrentUserController _currentUserController = CurrentUserController();

  @override
  void dispose() {
    _cartController.dispose();
    _currentUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartScope(
      controller: _cartController,
      child: CurrentUserScope(
        controller: _currentUserController,
        child: MaterialApp.router(
          title: 'Govi-AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
