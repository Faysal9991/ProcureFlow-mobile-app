import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../approval/domain/approval_repository.dart';
import '../../approval/presentation/approval_controller.dart';
import '../../attachments/domain/attachment_entity.dart';
import '../../attachments/presentation/attachment_section.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../domain/purchase_request_entity.dart';
import 'purchase_request_controller.dart';
import 'purchase_request_state.dart';

class PurchaseRequestDetailsScreen extends ConsumerStatefulWidget {
  const PurchaseRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.showBottomNavigation = true,
    this.approvalMode = false,
  });

  final String requestId;
  final bool showBottomNavigation;
  final bool approvalMode;

  @override
  ConsumerState<PurchaseRequestDetailsScreen> createState() {
    return _PurchaseRequestDetailsScreenState();
  }
}

class _PurchaseRequestDetailsScreenState
    extends ConsumerState<PurchaseRequestDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRequestControllerProvider);
    final request = state.selectedRequest;

    return AppScaffold(
      title: widget.approvalMode ? 'Approval Details' : 'Request Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && request == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && request == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (request == null)
              const AppEmptyCard(message: 'Purchase request not found.')
            else ...[
              _RequestSummary(request: request),
              const SizedBox(height: 16),
              _ItemsSection(request: request),
              const SizedBox(height: 16),
              _ApprovalSection(request: request),
              const SizedBox(height: 16),
              _Actions(
                state: state,
                request: request,
                approvalMode: widget.approvalMode,
                onSubmit: () => _submit(request),
                onCancel: () => _cancel(request),
                onApprove: () => _approvalDecision(request, approve: true),
                onReject: () => _approvalDecision(request, approve: false),
              ),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.purchaseRequest,
                entityId: request.localId,
                canUpload: !widget.approvalMode,
                canDelete: !widget.approvalMode,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(purchaseRequestControllerProvider.notifier)
        .loadDetail(widget.requestId);
  }

  Future<void> _submit(PurchaseRequestEntity request) async {
    final updated = await ref
        .read(purchaseRequestControllerProvider.notifier)
        .submit(request.localId);
    if (!mounted || updated == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request submitted.')));
  }

  Future<void> _cancel(PurchaseRequestEntity request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text(
          'This request will no longer continue for approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final updated = await ref
        .read(purchaseRequestControllerProvider.notifier)
        .cancel(request.localId);
    if (!mounted || updated == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request cancelled.')));
  }

  Future<void> _approvalDecision(
    PurchaseRequestEntity request, {
    required bool approve,
  }) async {
    final payload = await _showApprovalDecisionSheet(context, approve: approve);
    if (payload == null) return;

    final session = ref.read(authControllerProvider).session;
    final controller = ref.read(approvalControllerProvider.notifier);
    final success = approve
        ? await controller.approve(session, request.localId, payload)
        : await controller.reject(session, request.localId, payload);
    if (!mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Request approved.' : 'Request rejected.'),
      ),
    );
    await _load();
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(notificationControllerProvider);
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.request});

  final PurchaseRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    return AppSectionCard(
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
              const SizedBox(width: 8),
              StatusChip(status: request.normalizedStatus),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (request.requestNumber.isNotEmpty)
                StatusChip(status: request.requestNumber),
              StatusChip(status: request.normalizedPriority),
            ],
          ),
          if (request.description != null &&
              request.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(request.description!),
          ],
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Requester',
                value: request.requesterName?.isNotEmpty == true
                    ? request.requesterName!
                    : request.requesterId,
              ),
              AppInfoItem(
                label: 'Department',
                value:
                    request.departmentName ??
                    request.departmentId ??
                    'Not assigned',
              ),
              AppInfoItem(
                label: 'Needed Date',
                value: request.neededDate == null
                    ? 'Not set'
                    : dateFormat.format(request.neededDate!),
              ),
              AppInfoItem(
                label: 'Estimated Total',
                value: currency.format(request.totalAmount),
              ),
            ],
          ),
          if (request.budgetCheck != null) ...[
            const SizedBox(height: 14),
            AppListTileCard(
              leading: const Icon(AppIcons.money),
              title: Text('Budget ${request.budgetCheck!.status}'),
              subtitle: Text(request.budgetCheck!.message),
              trailing: Text(
                currency.format(request.budgetCheck!.availableAmount),
              ),
            ),
          ],
          if (request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppEmptyCard(message: request.rejectionReason!),
          ],
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.request});

  final PurchaseRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (request.items.isEmpty)
          const AppEmptyCard(message: 'No items found.')
        else
          for (final item in request.items)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 10),
              leading: const Icon(AppIcons.item),
              title: Text(item.name),
              subtitle: Text(
                '${_quantity(item.quantity)} ${item.unit} x ${currency.format(item.unitPrice)}',
              ),
              trailing: Text(
                currency.format(item.lineTotal),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
      ],
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _ApprovalSection extends StatelessWidget {
  const _ApprovalSection({required this.request});

  final PurchaseRequestEntity request;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          StatusChip(
            status: request.approvalStatus ?? request.normalizedStatus,
          ),
          const SizedBox(height: 12),
          Text(_message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  String get _message {
    return switch (request.normalizedStatus) {
      PurchaseRequestStatus.draft => 'Saved as draft. Submit when ready.',
      PurchaseRequestStatus.submitted => 'Submitted and waiting for approval.',
      PurchaseRequestStatus.approved => 'Approved and ready for next steps.',
      PurchaseRequestStatus.rejected =>
        'Rejected. Review the approval history.',
      PurchaseRequestStatus.cancelled => 'Cancelled by requester.',
      PurchaseRequestStatus.poCreated => 'Purchase order has been created.',
      _ => 'Status is available from the request workflow.',
    };
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.request,
    required this.approvalMode,
    required this.onSubmit,
    required this.onCancel,
    required this.onApprove,
    required this.onReject,
  });

  final PurchaseRequestState state;
  final PurchaseRequestEntity request;
  final bool approvalMode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (approvalMode) {
      if (request.isSubmitted) {
        actions.add(
          FilledButton.icon(
            key: const Key('approveRequestButton'),
            onPressed: state.isMutating ? null : onApprove,
            icon: const Icon(AppIcons.check),
            label: const Text('Approve'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            key: const Key('rejectRequestButton'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: state.isMutating ? null : onReject,
            icon: const Icon(AppIcons.x),
            label: const Text('Reject'),
          ),
        );
      }
      actions.add(
        OutlinedButton.icon(
          key: const Key('approvalHistoryButton'),
          onPressed: () =>
              context.push('/requests/${request.localId}/approval-history'),
          icon: const Icon(AppIcons.history),
          label: const Text('Approval History'),
        ),
      );

      return Wrap(spacing: 10, runSpacing: 10, children: actions);
    }

    if (request.canEdit) {
      actions.add(
        OutlinedButton.icon(
          key: const Key('editRequestButton'),
          onPressed: state.isMutating
              ? null
              : () => context.push('/requests/${request.localId}/edit'),
          icon: const Icon(AppIcons.description),
          label: const Text('Edit'),
        ),
      );
    }
    if (request.canSubmit) {
      actions.add(
        FilledButton.icon(
          key: const Key('submitDraftButton'),
          onPressed: state.isMutating ? null : onSubmit,
          icon: const Icon(AppIcons.send),
          label: const Text('Submit'),
        ),
      );
    }
    if (request.canCancel) {
      actions.add(
        OutlinedButton.icon(
          key: const Key('cancelRequestButton'),
          onPressed: state.isMutating ? null : onCancel,
          icon: const Icon(AppIcons.x),
          label: const Text('Cancel'),
        ),
      );
    }
    if (request.canViewApprovalHistory) {
      actions.add(
        OutlinedButton.icon(
          key: const Key('approvalHistoryButton'),
          onPressed: () =>
              context.push('/requests/${request.localId}/approval-history'),
          icon: const Icon(AppIcons.history),
          label: const Text('Approval History'),
        ),
      );
    }

    if (actions.isEmpty) {
      return const AppEmptyCard(
        message: 'No actions available for this status.',
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }
}

Future<ApprovalDecisionPayload?> _showApprovalDecisionSheet(
  BuildContext context, {
  required bool approve,
}) {
  return showModalBottomSheet<ApprovalDecisionPayload>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ApprovalDecisionSheet(approve: approve),
  );
}

class _ApprovalDecisionSheet extends StatefulWidget {
  const _ApprovalDecisionSheet({required this.approve});

  final bool approve;

  @override
  State<_ApprovalDecisionSheet> createState() => _ApprovalDecisionSheetState();
}

class _ApprovalDecisionSheetState extends State<_ApprovalDecisionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.approve;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        top: 4,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approve ? 'Approve Request' : 'Reject Request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: Key(approve ? 'approveCommentField' : 'rejectReasonField'),
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: approve ? 'Comment (Optional)' : 'Reason',
                helperText: approve
                    ? 'Optional, maximum 1000 characters.'
                    : 'Required, 10-1000 characters.',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (approve) {
                  return trimmed.length > 1000
                      ? 'Comment cannot exceed 1000 characters'
                      : null;
                }
                if (trimmed.length < 10) {
                  return 'Reason must be at least 10 characters';
                }
                if (trimmed.length > 1000) {
                  return 'Reason cannot exceed 1000 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: Key(
                      approve ? 'confirmApproveButton' : 'confirmRejectButton',
                    ),
                    style: approve
                        ? null
                        : FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.of(
                        context,
                      ).pop(ApprovalDecisionPayload(comment: _controller.text));
                    },
                    icon: Icon(approve ? AppIcons.check : AppIcons.x),
                    label: Text(approve ? 'Approve' : 'Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
