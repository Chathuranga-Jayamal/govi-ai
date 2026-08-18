import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/advisory_chat_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _advisoryBranchIndex = 2;

  final AdvisoryChatController _advisoryChatController =
      AdvisoryChatController();

  @override
  void dispose() {
    _advisoryChatController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _advisoryBranchIndex) {
      // Every bottom-nav arrival at Advisory starts a fresh conversation —
      // whatever was live gets archived into history first (if it had at
      // least one exchange), then the tab reopens empty.
      _advisoryChatController.startConversation();
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdvisoryChatScope(
      controller: _advisoryChatController,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt),
              label: 'Capture',
            ),
            NavigationDestination(icon: Icon(Icons.chat), label: 'Advisory'),
            NavigationDestination(
              icon: Icon(Icons.storefront),
              label: 'Marketplace',
            ),
          ],
        ),
      ),
    );
  }
}
