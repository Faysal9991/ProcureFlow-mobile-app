import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import 'app_settings_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final settings = ref.watch(appSettingsControllerProvider);
    final name = session?.userName ?? 'User';
    final department = session?.departmentName;
    final roles = [
      for (final role in session?.roles ?? const <String>[]) _roleLabel(role),
    ];

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
                      if (roles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final role in roles) Chip(label: Text(role)),
                          ],
                        ),
                      ],
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
                  label: 'Primary Role',
                  value: roles.isEmpty ? 'Employee' : roles.first,
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
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThemeMode>(
                  key: const Key('profileThemeModeField'),
                  initialValue: settings.themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Theme',
                    prefixIcon: Icon(AppIcons.circle),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System default'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appSettingsControllerProvider.notifier)
                          .setThemeMode(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('profileLanguageField'),
                  initialValue: settings.languageCode,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    prefixIcon: Icon(AppIcons.info),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(appSettingsControllerProvider.notifier)
                          .setLanguageCode(value);
                    }
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(AppIcons.bell),
                  title: const Text('Notifications'),
                  subtitle: const Text('Allow procurement alerts'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => ref
                      .read(appSettingsControllerProvider.notifier)
                      .setNotificationsEnabled(value),
                ),
                const Divider(),
                AppInfoRow(
                  icon: AppIcons.info,
                  label: 'App Version',
                  value: '1.0.0+1',
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(appSettingsControllerProvider.notifier)
                        .clearLocalPreferences();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Local settings cleared.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(AppIcons.trash),
                  label: const Text('Clear Cache'),
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
          if (PermissionPolicy.canUseOfflineSync(session))
            AppActionTile(
              icon: AppIcons.sync,
              title: 'Offline Sync',
              subtitle: 'Review pending drafts and sync history',
              route: '/sync-status',
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

  String _roleLabel(String value) {
    final normalized = RoleType.normalize(value);
    return switch (normalized) {
      'COMPANY_ADMIN' => 'Company Admin',
      'SUPER_ADMIN' => 'Super Admin',
      'PROCUREMENT' => 'Procurement Officer',
      'FINANCE' => 'Finance Executive',
      'MANAGER' => 'Manager',
      _ => 'Employee',
    };
  }
}
