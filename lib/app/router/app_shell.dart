import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../features/inbox/application/inbox_controller.dart';

/// The persistent shell for the five primary destinations.
///
/// Uses a [StatefulNavigationShell] so each tab keeps its own navigation stack
/// and scroll position, while the bottom bar stays fixed. The tab set mirrors
/// the reference board: Home, Food, Orders, Inbox, Profile.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _onSelected(int index) {
    // Tapping the active tab pops back to its root, matching platform norms.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: shell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: shell.currentIndex,
        onSelected: _onSelected,
        badges: {ShellTab.inbox: unread},
      ),
    );
  }
}
