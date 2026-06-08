import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import '../../purchase_request/domain/purchase_request_use_cases.dart';
import '../../purchase_request/presentation/purchase_request_providers.dart';

class ApprovalInboxScreen extends ConsumerWidget {
  const ApprovalInboxScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppScaffold(
      title: 'Approval Inbox',
      showBottomNavigation: showBottomNavigation,
      child: AsyncValueView(
        value: ref.watch(approvalInboxProvider),
        empty: const AppEmptyState(message: 'No requests awaiting approval.'),
        data: (requests) {
          return AppSeparatedListView(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(status: request.priority),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppInfoRow(
                      icon: AppIcons.user,
                      label: 'Requested By',
                      value: request.requesterId,
                    ),
                    AppInfoRow(
                      icon: AppIcons.department,
                      label: 'Department',
                      value: request.departmentId ?? 'General',
                    ),
                    AppInfoRow(
                      icon: AppIcons.item,
                      label: 'Items',
                      value: request.items.length.toString(),
                    ),
                    AppInfoRow(
                      icon: AppIcons.money,
                      label: 'Estimated Cost',
                      value: currency.format(request.totalAmount),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                _action(context, ref, request, approve: true),
                            icon: const Icon(AppIcons.check),
                            label: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            onPressed: () =>
                                _action(context, ref, request, approve: false),
                            icon: const Icon(AppIcons.x),
                            label: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/requests/${request.localId}'),
                      icon: const Icon(AppIcons.externalLink),
                      label: const Text('Open details'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    PurchaseRequestEntity request, {
    required bool approve,
  }) async {
    final comment = await _commentDialog(context, approve: approve);
    if (comment == null) {
      return;
    }
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      return;
    }
    final input = ApprovalActionInput(
      companyId: session.companyId,
      requestLocalId: request.localId,
      actorId: session.userId,
      comment: comment,
    );
    if (approve) {
      await ref.read(approvalActionControllerProvider.notifier).approve(input);
    } else {
      await ref.read(approvalActionControllerProvider.notifier).reject(input);
    }
  }

  Future<String?> _commentDialog(
    BuildContext context, {
    required bool approve,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve request' : 'Reject request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Comment'),
          minLines: 3,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
