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
              firstName: firstName.isEmpty ? 'User' : firstName,
              unreadCount: state.unreadCount,
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              AppEmptyCard(message: state.errorMessage!)
            else if (state.isLoading && state.cards.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else
              _SummaryCards(cards: state.cards),
            const SizedBox(height: 16),
            _QuickMenu(state: state, onComingSoon: _showComingSoon),
            const SizedBox(height: 16),
            _RecentActivity(
              activities: state.activities,
              onComingSoon: _showComingSoon,
            ),
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
  const _DashboardHeader({required this.firstName, required this.unreadCount});

  final String firstName;
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
                  '${_greeting()}, $firstName',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'ProcureFlow',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
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
                child: AppSectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconBadge(icon: _cardIcon(card.key)),
                      const Spacer(),
                      Text(
                        card.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
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
        Text('Quick Menu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.menuItems.isEmpty)
          const AppEmptyCard(message: 'No menu items available.')
        else
          for (final item in state.menuItems)
            _MenuTile(item: item, onComingSoon: onComingSoon),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.onComingSoon});

  final AppMenuItem item;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    final tile = AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: _IconBadge(icon: _menuIcon(item.title)),
      title: Text(item.title),
      subtitle: item.isImplemented ? null : const Text('Coming Soon'),
      trailing: item.isImplemented
          ? const Icon(AppIcons.chevronRight)
          : const _ComingSoonChip(),
      onTap: item.isImplemented
          ? () => context.go(item.route)
          : () => onComingSoon(item.title),
    );

    return item.isImplemented ? tile : Opacity(opacity: 0.72, child: tile);
  }

  IconData _menuIcon(String title) {
    return switch (title) {
      'Approvals' => AppIcons.approval,
      'Vendors' => AppIcons.vendors,
      'RFQ' => AppIcons.compare,
      'Purchase Orders' => AppIcons.order,
      'Invoices' || 'Budgets' => AppIcons.money,
      'Reports' => AppIcons.history,
      _ => AppIcons.list,
    };
  }
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

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.controlBorder,
      ),
      child: Text(
        'Coming Soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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
