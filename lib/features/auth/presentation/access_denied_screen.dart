import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({
    super.key,
    required this.path,
    this.showBottomNavigation = true,
  });

  final String path;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Access Denied',
      showBottomNavigation: showBottomNavigation,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  AppIcons.lock,
                  color: Theme.of(context).colorScheme.error,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  'You do not have permission to open this page.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(path),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('accessDeniedDashboardButton'),
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(AppIcons.dashboard),
                  label: const Text('Dashboard'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
