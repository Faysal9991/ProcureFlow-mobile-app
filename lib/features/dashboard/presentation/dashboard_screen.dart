import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/app_menu_item.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_controller.dart';
import 'dashboard_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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

    final session = ref.watch(authControllerProvider).session;
    final state = ref.watch(dashboardControllerProvider);
    final firstName = (session?.userName.split(' ').first ?? 'User').trim();

    return AppScaffold(
      title: 'Home',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: () => _load(),
        child: AppScreenListView(
          children: [
            _DashboardHeader(
              name: firstName.isEmpty ? 'User' : firstName,
              companyName: session?.companyName ?? 'Company',
              accessProfile: state.accessProfile,
              unreadCount: state.unreadCount,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              AppErrorCard(message: state.errorMessage!, onRetry: _load)
            else if (state.isLoading && state.cards.isEmpty)
              const AppLoadingCard(message: 'Loading dashboard...')
            else
              _SummaryCards(cards: state.cards),
            const SizedBox(height: 16),
            _QuickMenu(state: state, onComingSoon: _showComingSoon),
            const SizedBox(height: 16),
            _RecentActivity(
              activities: state.activities,
              onComingSoon: _showComingSoon,
            ),
            if (_pendingSyncValue(state.cards) != null &&
                _pendingSyncValue(state.cards)! > 0) ...[
              const SizedBox(height: 16),
              _SyncStatusCard(pendingCount: _pendingSyncValue(state.cards)!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    final session = ref.read(authControllerProvider).session;
    return ref.read(dashboardControllerProvider.notifier).load(session);
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title is coming soon.')));
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.companyName,
    required this.accessProfile,
    required this.unreadCount,
  });

  final String name;
  final String companyName;
  final DashboardAccessProfile accessProfile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $name',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'ProcureFlow',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${accessProfile.primaryLabel} / $companyName',
                  style: theme.textTheme.bodySmall,
                ),
                if (accessProfile.additionalAccessLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Additional access: ${accessProfile.additionalAccessLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
              child: const Icon(AppIcons.bellActive),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.cards});

  final List<DashboardSummaryCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const AppEmptyCard(message: 'No dashboard summary available.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth > 700 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: tileWidth,
                height: 132,
                child: AppSummaryCard(
                  icon: _cardIcon(card.key),
                  label: card.label,
                  value: card.value,
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _cardIcon(String key) {
    return switch (key) {
      'pending_approvals' || 'pendingApprovals' => AppIcons.approval,
      'purchase_orders' || 'purchaseOrders' => AppIcons.order,
      'invoices' || 'due_amount' || 'dueAmount' => AppIcons.money,
      'total_spend' || 'totalSpend' => AppIcons.money,
      _ => AppIcons.list,
    };
  }
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({required this.state, required this.onComingSoon});

  final DashboardState state;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.modules.isEmpty && state.quickActions.isEmpty)
          const AppEmptyCard(message: 'No menu items available.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth >= 840
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in _tiles())
                    SizedBox(
                      width: tileWidth,
                      height: 138,
                      child: AppModuleCard(
                        icon: item.icon,
                        title: item.title,
                        subtitle: item.subtitle,
                        badge: item.badge,
                        enabled: item.isImplemented,
                        onTap: () => item.isImplemented
                            ? context.go(item.route)
                            : onComingSoon(item.title),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<_DashboardTileData> _tiles() {
    return [
      for (final action in state.quickActions)
        _DashboardTileData(
          title: action.title,
          subtitle: action.subtitle,
          route: action.route,
          icon: action.icon,
          badge: _badgeFor(action.countKeys),
          isImplemented: action.isImplemented,
        ),
      for (final module in state.modules)
        _DashboardTileData(
          title: module.title,
          subtitle: module.subtitle,
          route: module.route,
          icon: module.icon,
          badge: _badgeFor(module.countKeys),
          isImplemented: module.isImplemented,
        ),
    ];
  }

  String? _badgeFor(List<String> keys) {
    if (keys.isEmpty) return null;
    for (final key in keys) {
      for (final card in state.cards) {
        if (card.key == key && card.value.trim().isNotEmpty) {
          return card.value;
        }
      }
    }
    return null;
  }
}

class _DashboardTileData {
  const _DashboardTileData({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.isImplemented,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool isImplemented;
  final String? badge;
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.activities, required this.onComingSoon});

  final List<DashboardActivity> activities;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          const AppEmptyCard(message: 'No recent activity yet.')
        else
          for (final activity in activities.take(5))
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 10),
              leading: const _IconBadge(icon: AppIcons.history),
              title: Text(activity.title),
              subtitle: Text(
                '${activity.message}\n${dateFormat.format(activity.createdAt)}',
              ),
              onTap: _isActiveRoute(activity.route)
                  ? () => context.go(activity.route!)
                  : activity.route == null
                  ? null
                  : () => onComingSoon(activity.title),
            ),
      ],
    );
  }

  bool _isActiveRoute(String? route) {
    return route == '/dashboard' ||
        route == '/notifications' ||
        route == '/profile' ||
        route == '/approvals' ||
        (route?.startsWith('/approvals/') ?? false) ||
        route == '/vendors' ||
        route == '/vendors/new' ||
        (route?.startsWith('/vendors/') ?? false) ||
        route == '/rfqs' ||
        route == '/rfqs/new' ||
        (route?.startsWith('/rfqs/') ?? false) ||
        route == '/purchase-orders' ||
        route == '/purchase-orders/new' ||
        (route?.startsWith('/purchase-orders/') ?? false) ||
        route == '/invoices' ||
        route == '/invoices/new' ||
        (route?.startsWith('/invoices/') ?? false) ||
        route == '/payments' ||
        (route?.startsWith('/payments/') ?? false) ||
        route == '/requests' ||
        route == '/requests/new' ||
        (route?.startsWith('/requests/') ?? false);
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: () => context.go('/sync-status'),
      child: Row(
        children: [
          const _IconBadge(icon: AppIcons.sync),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text('$pendingCount item(s) waiting to sync'),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight),
        ],
      ),
    );
  }
}

int? _pendingSyncValue(List<DashboardSummaryCard> cards) {
  for (final card in cards) {
    if (card.key == 'pending_sync' || card.key == 'pendingSync') {
      return int.tryParse(card.value.replaceAll(RegExp(r'[^0-9]'), ''));
    }
  }
  return null;
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.iconBorder,
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 20),
    );
  }
}
