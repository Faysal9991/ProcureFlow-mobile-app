import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../purchase_order/presentation/purchase_order_providers.dart';
import '../../purchase_request/presentation/purchase_request_providers.dart';
import '../../sync/presentation/sync_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final requests = ref.watch(purchaseRequestsProvider).valueOrNull ?? [];
    final approvals = ref.watch(approvalInboxProvider).valueOrNull ?? [];
    final orders = ref.watch(purchaseOrdersProvider).valueOrNull ?? [];
    final pendingSync = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final isOnline = ref.watch(onlineStatusProvider).valueOrNull;
    final approved = requests.where((request) => request.isApproved).length;
    final rejected = requests
        .where((request) => request.status == 'rejected')
        .length;
    final firstName = (session?.userName.split(' ').first ?? 'User').trim();

    return AppScaffold(
      title: 'Dashboard',
      showBottomNavigation: showBottomNavigation,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            padding: AppInsets.cardLarge,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()}, $firstName',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${session?.companyName ?? 'Company'} • ${session?.primaryRole ?? 'employee'}',
                      ),
                    ],
                  ),
                ),
                StatusChip(status: isOnline == false ? 'offline' : 'online'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final columns = constraints.maxWidth > 700 ? 4 : 2;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: tileWidth,
                    height: 140,
                    child: AppMetricTile(
                      icon: AppIcons.approval,
                      label: 'Pending Approvals',
                      value: approvals.length.toString(),
                      route: '/approvals',
                      tone: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 140,
                    child: AppMetricTile(
                      icon: AppIcons.list,
                      label: 'My Requests',
                      value: requests.length.toString(),
                      route: '/requests',
                      tone: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 140,
                    child: AppMetricTile(
                      icon: AppIcons.circleCheck,
                      label: 'Approved',
                      value: approved.toString(),
                      route: '/requests',
                      tone: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    height: 140,
                    child: AppMetricTile(
                      icon: AppIcons.circleX,
                      label: 'Rejected',
                      value: rejected.toString(),
                      route: '/requests',
                      tone: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AppSectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isOnline == false
                          ? AppIcons.cloudOff
                          : AppIcons.cloudCheck,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline == false ? 'Offline mode' : 'Online mode',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Purchase requests created offline are queued.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/requests/new'),
                    icon: const Icon(AppIcons.add),
                    label: const Text('New request'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppActionTile(
                  icon: AppIcons.order,
                  title: '${orders.length} POs',
                  route: '/purchase-orders',
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppActionTile(
                  icon: AppIcons.sync,
                  title: '$pendingSync Sync',
                  route: '/sync',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            const AppEmptyCard(message: 'No purchase requests yet.')
          else
            for (final request in requests.take(5))
              AppListTileCard(
                title: Text(request.title),
                subtitle: Text(
                  '${request.requestNumber} • BDT ${request.totalAmount.toStringAsFixed(0)}',
                ),
                trailing: StatusChip(status: request.status),
                onTap: () => context.push('/requests/${request.localId}'),
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
