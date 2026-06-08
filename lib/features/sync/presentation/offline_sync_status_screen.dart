import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import 'sync_providers.dart';

class OfflineSyncStatusScreen extends ConsumerWidget {
  const OfflineSyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    final syncState = ref.watch(syncControllerProvider);
    final isOnline = ref.watch(onlineStatusProvider).valueOrNull;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return AppScaffold(
      title: 'Offline Sync Status',
      child: AppScreenListView(
        padding: AppInsets.compactScreen,
        children: [
          AppSectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isOnline == false
                          ? AppIcons.cloudOff
                          : AppIcons.cloudCheck,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOnline == false ? 'Offline' : 'Online',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusChip(status: '$pendingCount pending sync'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: syncState.isLoading
                        ? null
                        : () => ref
                              .read(syncControllerProvider.notifier)
                              .syncNow(),
                    icon: syncState.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(AppIcons.sync),
                    label: const Text('Sync now'),
                  ),
                ),
              ],
            ),
          ),
          if (syncState.valueOrNull != null) ...[
            const SizedBox(height: 12),
            AppListTileCard(
              title: const Text('Last sync run'),
              subtitle: Text(
                'Attempted ${syncState.value!.attempted}, '
                'synced ${syncState.value!.succeeded}, '
                'failed ${syncState.value!.failed}',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Sync logs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: ref.watch(syncLogsProvider),
            empty: const AppEmptyCard(message: 'No sync attempts recorded.'),
            data: (logs) {
              return Column(
                children: [
                  for (final log in logs)
                    AppListTileCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      leading: const Icon(AppIcons.history),
                      title: Text('${log.entityType} • ${log.status}'),
                      subtitle: Text(
                        '${log.action} • ${dateFormat.format(log.createdAt)}'
                        '${log.message == null ? '' : '\n${log.message}'}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
