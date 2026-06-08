import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Notifications',
      showBottomNavigation: showBottomNavigation,
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          onPressed: () => ref.read(markNotificationsReadProvider)(),
          icon: const Icon(AppIcons.checkAll),
        ),
      ],
      child: AsyncValueView(
        value: ref.watch(notificationsProvider),
        empty: const AppEmptyState(message: 'No notifications yet.'),
        data: (notifications) {
          return AppSeparatedListView(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return AppListTileCard(
                leading: Icon(
                  notification.isRead ? AppIcons.bell : AppIcons.bellActive,
                ),
                title: Text(notification.title),
                subtitle: Text(notification.body),
              );
            },
          );
        },
      ),
    );
  }
}
