import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../purchase_order/domain/purchase_order_use_cases.dart';
import '../../purchase_order/presentation/purchase_order_providers.dart';
import '../domain/purchase_request_entity.dart';
import '../domain/purchase_request_use_cases.dart';
import 'purchase_request_providers.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.localId});

  final String localId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(purchaseRequestDetailProvider(localId));
    final session = ref.watch(authControllerProvider).session;
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);

    return AppScaffold(
      title: 'Request Details',
      child: AsyncValueView(
        value: requestAsync,
        empty: const AppEmptyState(message: 'Purchase request not found.'),
        data: (request) {
          if (request == null) {
            return const AppEmptyState(message: 'Purchase request not found.');
          }

          return AppScreenListView(
            children: [
              AppSectionCard(
                padding: AppInsets.cardLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        StatusChip(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(status: request.requestNumber),
                        StatusChip(status: request.priority),
                        StatusChip(status: request.syncStatus.label),
                      ],
                    ),
                    if (request.description != null) ...[
                      const SizedBox(height: 14),
                      Text(request.description!),
                    ],
                    const SizedBox(height: 16),
                    AppInfoGrid(
                      items: [
                        AppInfoItem(
                          label: 'Requested By',
                          value: request.requesterId,
                        ),
                        AppInfoItem(
                          label: 'Department',
                          value: request.departmentId ?? 'General',
                        ),
                        AppInfoItem(
                          label: 'Needed Date',
                          value: request.neededDate == null
                              ? 'Not set'
                              : DateFormat.yMMMd().format(request.neededDate!),
                        ),
                        AppInfoItem(
                          label: 'Estimated Cost',
                          value: currency.format(request.totalAmount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                padding: AppInsets.cardLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Timeline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Timeline(
                      steps: [
                        TimelineStep(
                          title: 'Created',
                          subtitle: DateFormat.yMMMd().format(
                            request.createdAt,
                          ),
                          complete: true,
                        ),
                        const TimelineStep(
                          title: 'Submitted',
                          subtitle: 'Waiting for manager review',
                          complete: true,
                        ),
                        TimelineStep(
                          title: request.status == 'rejected'
                              ? 'Manager Rejected'
                              : 'Manager Approved',
                          subtitle: request.status == 'submitted'
                              ? 'Pending decision'
                              : 'Decision recorded',
                          complete: request.status != 'submitted',
                        ),
                        TimelineStep(
                          title: 'Procurement Review',
                          subtitle: request.hasPurchaseOrder
                              ? 'Purchase order created'
                              : 'Starts after approval',
                          complete: request.hasPurchaseOrder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final item in request.items)
                AppListTileCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  title: Text(item.name),
                  subtitle: Text(
                    'Qty ${item.quantity} x ${currency.format(item.unitPrice)}',
                  ),
                  trailing: Text(
                    currency.format(item.lineTotal),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              if (session?.canApprove == true &&
                  request.status == 'submitted') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _approvalAction(
                          context,
                          ref,
                          request,
                          approve: true,
                        ),
                        icon: const Icon(AppIcons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _approvalAction(
                          context,
                          ref,
                          request,
                          approve: false,
                        ),
                        icon: const Icon(AppIcons.x),
                        label: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
              if (session?.canCreatePurchaseOrder == true &&
                  request.isApproved) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(createPurchaseOrderControllerProvider.notifier)
                        .create(
                          CreatePurchaseOrderInput(
                            request: request,
                            createdById: session!.userId,
                          ),
                        );
                    ref.invalidate(purchaseRequestDetailProvider(localId));
                  },
                  icon: const Icon(AppIcons.order),
                  label: const Text('Create purchase order'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _approvalAction(
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
    ref.invalidate(purchaseRequestDetailProvider(localId));
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
