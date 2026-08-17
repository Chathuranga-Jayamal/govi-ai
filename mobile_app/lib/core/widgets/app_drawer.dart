import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Govi-AI')),
          _drawerItem(context, 'Login', '/login'),
          _drawerItem(context, 'Register', '/register'),
          _drawerItem(context, 'Dashboard', '/dashboard'),
          _drawerItem(context, 'Capture', '/capture'),
          _drawerItem(context, 'Advisory', '/advisory'),
          _drawerItem(context, 'Marketplace', '/marketplace'),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String label, String route) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
