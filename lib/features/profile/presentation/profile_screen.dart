import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final name = session?.userName ?? 'User';
    final department = session?.departmentName;

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
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
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
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(session?.email ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Column(
              children: [
                AppInfoRow(
                  icon: AppIcons.profile,
                  label: 'Role',
                  value: session?.primaryRole ?? 'employee',
                ),
                AppInfoRow(
                  icon: AppIcons.store,
                  label: 'Company',
                  value: session?.companyName ?? 'Company',
                ),
                AppInfoRow(
                  icon: AppIcons.department,
                  label: 'Department',
                  value: (department == null || department.isEmpty)
                      ? 'General'
                      : department,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppActionTile(
            icon: AppIcons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            route: '/change-password',
            margin: const EdgeInsets.only(bottom: 10),
          ),
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
