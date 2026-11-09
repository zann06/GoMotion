import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';

/// The persistent shell for the four primary destinations.
///
/// Uses a [StatefulNavigationShell] so each tab keeps its own navigation stack
/// and scroll position, while the bottom bar stays fixed.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onSelected(int index) {
    // Tapping the active tab pops back to its root, matching platform norms.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: shell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: shell.currentIndex,
        onSelected: _onSelected,
      ),
    );
  }
}
