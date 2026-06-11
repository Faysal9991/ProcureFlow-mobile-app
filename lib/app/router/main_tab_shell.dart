import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = initialIndex
        .clamp(0, appBottomTabs.length - 1)
        .toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail =
            constraints.maxWidth >= AppBreakpoints.navigationRail;
        final body = ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: AppSmoothScreenSwitcher(
            transitionKey: appBottomTabs[selectedIndex].route,
            child: _tabScreens[selectedIndex],
          ),
        );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: useNavigationRail
              ? Row(
                  children: [
                    AppNavigationRail(
                      selectedIndex: selectedIndex,
                      extended:
                          constraints.maxWidth >=
                          AppBreakpoints.extendedNavigationRail,
                      onDestinationSelected: (index) =>
                          _goToTab(context, index),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    ),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useNavigationRail
              ? null
              : AppBottomNavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _goToTab(context, index),
                ),
        );
      },
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
  NotificationsScreen(showBottomNavigation: false),
  ProfileScreen(showBottomNavigation: false),
];
