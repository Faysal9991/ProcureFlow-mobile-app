import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/notification_repository.dart';
import 'notification_controller.dart';
import 'notification_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.session != next.session) {
        _load();
      }
    });
    ref.listen<NotificationState>(notificationControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final session = ref.watch(authControllerProvider).session;
    final state = ref.watch(notificationControllerProvider);

    return AppScaffold(
      title: 'Notifications',
      showBottomNavigation: widget.showBottomNavigation,
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          onPressed: state.unreadCount == 0 || state.isMutating
              ? null
              : () => ref
                    .read(notificationControllerProvider.notifier)
                    .markAllRead(session),
          icon: const Icon(AppIcons.checkAll),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _UnreadSummary(unreadCount: state.unreadCount),
            const SizedBox(height: 16),
            if (state.isLoading && state.items.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.items.isEmpty)
              const AppEmptyState(message: 'No notifications yet.')
            else
              for (final notification in state.items)
                _NotificationTile(
                  notification: notification,
                  onTap: notification.isRead
                      ? null
                      : () => ref
                            .read(notificationControllerProvider.notifier)
                            .markRead(session, notification.id),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    final session = ref.read(authControllerProvider).session;
    return ref.read(notificationControllerProvider.notifier).load(session);
  }
}

class _UnreadSummary extends StatelessWidget {
  const _UnreadSummary({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Row(
        children: [
          const Icon(AppIcons.bellActive),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unreadCount == 1
                  ? '1 unread notification'
                  : '$unreadCount unread notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: Icon(
        notification.isRead ? AppIcons.bell : AppIcons.bellActive,
        color: notification.isRead
            ? theme.colorScheme.onSurface.withValues(alpha: 0.56)
            : theme.colorScheme.primary,
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w900,
        ),
      ),
      subtitle: Text(
        '${notification.message}\n${dateFormat.format(notification.createdAt)}',
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
    );
  }
}
