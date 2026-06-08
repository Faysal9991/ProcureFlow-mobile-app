import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import 'auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    return AppScaffold(
      title: 'Profile',
      showBottomNavigation: showBottomNavigation,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            padding: AppInsets.cardLarge,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    (session?.userName.isNotEmpty ?? false)
                        ? session!.userName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.userName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(session?.email ?? ''),
                      Text(session?.companyName ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppActionTile(
            icon: AppIcons.vendors,
            title: 'Vendor List',
            subtitle: 'Supplier records and contacts',
            route: '/vendors',
            margin: EdgeInsets.only(bottom: 10),
          ),
          const AppActionTile(
            icon: AppIcons.compare,
            title: 'Quotation Compare',
            subtitle: 'Compare vendor proposals',
            route: '/quotations',
            margin: EdgeInsets.only(bottom: 10),
          ),
          const AppActionTile(
            icon: AppIcons.order,
            title: 'Purchase Orders',
            subtitle: 'Issued procurement orders',
            route: '/purchase-orders',
            margin: EdgeInsets.only(bottom: 10),
          ),
          const AppActionTile(
            icon: AppIcons.sync,
            title: 'Offline Sync',
            subtitle: 'Pending sync and retry logs',
            route: '/sync',
            margin: EdgeInsets.only(bottom: 10),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(AppIcons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
