import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/purchase_request_entity.dart';
import 'purchase_request_controller.dart';

class ApprovalHistoryScreen extends ConsumerStatefulWidget {
  const ApprovalHistoryScreen({
    super.key,
    required this.requestId,
    this.showBottomNavigation = true,
  });

  final String requestId;
  final bool showBottomNavigation;

  @override
  ConsumerState<ApprovalHistoryScreen> createState() {
    return _ApprovalHistoryScreenState();
  }
}

class _ApprovalHistoryScreenState extends ConsumerState<ApprovalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRequestControllerProvider);

    return AppScaffold(
      title: 'Approval History',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && state.approvalHistory.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null)
              AppEmptyCard(message: state.errorMessage!)
            else if (state.approvalHistory.isEmpty)
              const AppEmptyCard(message: 'No approval history found.')
            else
              _HistoryTimeline(entries: state.approvalHistory),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(purchaseRequestControllerProvider.notifier)
        .loadApprovalHistory(widget.requestId);
  }
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<ApprovalHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y, h:mm a');
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            _HistoryRow(
              entry: entries[index],
              timestamp: dateFormat.format(entries[index].createdAt),
              isLast: index == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.timestamp,
    required this.isLast,
  });

  final ApprovalHistoryEntry entry;
  final String timestamp;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(AppIcons.history, size: 16),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 56,
                color: colorScheme.outline.withValues(alpha: 0.28),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.approverName.isEmpty
                            ? 'Approver'
                            : entry.approverName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusChip(status: entry.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.action.isEmpty ? entry.status : entry.action,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(entry.comment!),
                ],
                const SizedBox(height: 4),
                Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
