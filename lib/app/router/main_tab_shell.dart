import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../features/approval/presentation/approval_inbox_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/purchase_request/presentation/my_requests_screen.dart';

class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = initialIndex
        .clamp(0, appBottomTabs.length - 1)
        .toInt();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: AppSmoothScreenSwitcher(
          transitionKey: appBottomTabs[selectedIndex].route,
          child: _tabScreens[selectedIndex],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _goToTab(context, index),
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    if (index < 0 || index >= appBottomTabs.length) return;

    final route = appBottomTabs[index].route;
    final currentPath = GoRouter.maybeOf(
      context,
    )?.routerDelegate.currentConfiguration.uri.path;
    if (currentPath != route) {
      context.go(route);
    }
  }
}

const _tabScreens = [
  DashboardScreen(showBottomNavigation: false),
  MyRequestsScreen(showBottomNavigation: false),
  ApprovalInboxScreen(showBottomNavigation: false),
  NotificationsScreen(showBottomNavigation: false),
  ProfileScreen(showBottomNavigation: false),
];
