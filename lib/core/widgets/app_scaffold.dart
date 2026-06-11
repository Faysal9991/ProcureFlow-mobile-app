import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import 'app_icons.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBottomNavigation = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNavigation;

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = _currentPath(context);
    final selectedIndex = appBottomNavSelectedIndex(path);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail =
            widget.showBottomNavigation &&
            constraints.maxWidth >= AppBreakpoints.navigationRail;
        final body = ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: AppSmoothScreenSwitcher(
            transitionKey: path,
            child: SafeArea(top: false, child: widget.child),
          ),
        );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(title: Text(widget.title), actions: widget.actions),
          body: useNavigationRail
              ? Row(
                  children: [
                    AppNavigationRail(
                      selectedIndex: selectedIndex,
                      extended:
                          constraints.maxWidth >=
                          AppBreakpoints.extendedNavigationRail,
                      topSafeArea: false,
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
          bottomNavigationBar: widget.showBottomNavigation && !useNavigationRail
              ? AppBottomNavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _goToTab(context, index),
                )
              : null,
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }

  String _currentPath(BuildContext context) {
    final router = GoRouter.maybeOf(context);

    if (router == null) {
      return '/dashboard';
    }

    return router.routerDelegate.currentConfiguration.uri.path;
  }

  void _goToTab(BuildContext context, int index) {
    if (index < 0 || index >= appBottomTabs.length) return;

    final route = appBottomTabs[index].route;

    if (_currentPath(context) != route) {
      context.go(route);
    }
  }
}

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
    this.topSafeArea = true,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool extended;
  final bool topSafeArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.58);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: AppNeumorphic.softShadow(
          theme.brightness,
          depth: theme.brightness == Brightness.dark ? 0.20 : 0.10,
          distance: 7,
          blur: 16,
        ),
      ),
      child: SafeArea(
        top: topSafeArea,
        bottom: true,
        child: NavigationRail(
          extended: extended,
          minWidth: 72,
          minExtendedWidth: 196,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Colors.transparent,
          indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          selectedIconTheme: IconThemeData(color: colorScheme.primary),
          unselectedIconTheme: IconThemeData(color: inactiveColor),
          selectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          unselectedLabelTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: inactiveColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          destinations: [
            for (final tab in appBottomTabs)
              NavigationRailDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: Text(tab.label),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.56);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.18)),
        ),
        boxShadow: AppNeumorphic.softShadow(
          theme.brightness,
          depth: theme.brightness == Brightness.dark ? 0.24 : 0.14,
          distance: 8,
          blur: 18,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: NavigationBarTheme(
            data: theme.navigationBarTheme.copyWith(
              backgroundColor: Colors.transparent,
              indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? colorScheme.primary
                      : inactiveColor,
                  size: 24,
                ),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => theme.textTheme.labelSmall?.copyWith(
                  color: states.contains(WidgetState.selected)
                      ? colorScheme.primary
                      : inactiveColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            child: NavigationBar(
              height: 60,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final tab in appBottomTabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSmoothScreenSwitcher extends StatelessWidget {
  const AppSmoothScreenSwitcher({
    super.key,
    required this.transitionKey,
    required this.child,
  });

  final String transitionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.018, 0.01),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(key: ValueKey(transitionKey), child: child),
      ),
    );
  }
}

int appBottomNavSelectedIndex(String path) {
  if (path.startsWith('/notifications')) return 1;
  if (path.startsWith('/profile')) return 2;

  return 0;
}

const appBottomTabs = [
  AppBottomTab(
    icon: AppIcons.dashboard,
    selectedIcon: AppIcons.dashboard,
    label: 'Home',
    route: '/dashboard',
  ),
  AppBottomTab(
    icon: AppIcons.bell,
    selectedIcon: AppIcons.bellActive,
    label: 'Notifications',
    route: '/notifications',
  ),
  AppBottomTab(
    icon: AppIcons.profile,
    selectedIcon: AppIcons.profile,
    label: 'Profile',
    route: '/profile',
  ),
];

class AppBottomTab {
  const AppBottomTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
}
