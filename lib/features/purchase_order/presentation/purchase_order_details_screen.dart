import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../attachments/domain/attachment_entity.dart';
import '../../attachments/presentation/attachment_section.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../invoice/domain/invoice_entity.dart';
import '../../invoice/presentation/invoice_providers.dart';
import '../domain/purchase_order_entity.dart';
import 'purchase_order_controller.dart';

class PurchaseOrderDetailsScreen extends ConsumerStatefulWidget {
  const PurchaseOrderDetailsScreen({
    super.key,
    required this.orderId,
    this.showBottomNavigation = true,
  });

  final String orderId;
  final bool showBottomNavigation;

  @override
  ConsumerState<PurchaseOrderDetailsScreen> createState() =>
      _PurchaseOrderDetailsScreenState();
}

class _PurchaseOrderDetailsScreenState
    extends ConsumerState<PurchaseOrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderControllerProvider);
    final order = state.selectedOrder;
    final session = ref.watch(authControllerProvider).session;
    final canCreateInvoice = PermissionPolicy.canCreateInvoice(session);
    final canViewInvoice = PermissionPolicy.canViewInvoices(session);
    final canManagePurchaseOrders = PermissionPolicy.canManagePurchaseOrders(
      session,
    );
    final invoiceForOrder = order == null
        ? null
        : ref.watch(invoiceForPurchaseOrderProvider(order.localId));
    return AppScaffold(
      title: 'PO Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && order == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && order == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (order == null)
              const AppEmptyCard(message: 'Purchase order not found.')
            else ...[
              _PurchaseOrderSummary(order: order),
              const SizedBox(height: 16),
              _PurchaseOrderItems(order: order),
              const SizedBox(height: 16),
              _PurchaseOrderActions(
                order: order,
                isMutating: state.isMutating,
                invoiceForOrder: invoiceForOrder,
                canManagePurchaseOrders: canManagePurchaseOrders,
                canCreateInvoice: canCreateInvoice,
                canViewInvoice: canViewInvoice,
                onIssue: () => _confirmLifecycle(
                  title: 'Issue Purchase Order?',
                  message: 'The vendor will be considered officially selected.',
                  actionLabel: 'Issue',
                  action: () => ref
                      .read(purchaseOrderControllerProvider.notifier)
                      .issue(order.localId),
                  successMessage: 'Purchase order issued.',
                ),
                onReceive: () => _confirmLifecycle(
                  title: 'Mark this PO as received?',
                  message: null,
                  actionLabel: 'Receive',
                  action: () => ref
                      .read(purchaseOrderControllerProvider.notifier)
                      .receive(order.localId),
                  successMessage: 'Purchase order received.',
                ),
                onClose: () => _confirmLifecycle(
                  title: 'Close this PO?',
                  message:
                      'This action indicates the procurement process is completed.',
                  actionLabel: 'Close',
                  action: () => ref
                      .read(purchaseOrderControllerProvider.notifier)
                      .close(order.localId),
                  successMessage: 'Purchase order closed.',
                ),
                onCancel: () => _confirmLifecycle(
                  title: 'Cancel this PO?',
                  message: null,
                  actionLabel: 'Cancel',
                  action: () => ref
                      .read(purchaseOrderControllerProvider.notifier)
                      .cancel(order.localId),
                  successMessage: 'Purchase order cancelled.',
                ),
              ),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.purchaseOrder,
                entityId: order.localId,
                canView: PermissionPolicy.canViewAttachments(session: session),
                canUpload:
                    !order.isClosed &&
                    !order.isCancelled &&
                    PermissionPolicy.canUploadAttachments(session: session),
                canDelete:
                    !order.isClosed &&
                    !order.isCancelled &&
                    PermissionPolicy.canDeleteAttachments(session: session),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(purchaseOrderControllerProvider.notifier)
        .loadDetail(widget.orderId);
  }

  Future<void> _confirmLifecycle({
    required String title,
    required String? message,
    required String actionLabel,
    required Future<PurchaseOrder?> Function() action,
    required String successMessage,
  }) async {
    if (!PermissionPolicy.canManagePurchaseOrders(
      ref.read(authControllerProvider).session,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission for this action.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Key('confirm${actionLabel}PurchaseOrderButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final order = await action();
    if (!mounted || order == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }
}

class _PurchaseOrderSummary extends StatelessWidget {
  const _PurchaseOrderSummary({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
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
                  order.poNumber.isEmpty ? 'Purchase Order' : order.poNumber,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: order.normalizedStatus),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(label: 'Vendor', value: _fallback(order.vendorName)),
              AppInfoItem(label: 'RFQ', value: _fallback(order.rfqNumber)),
              AppInfoItem(
                label: 'Purchase Request',
                value: _fallback(order.purchaseRequestNumber),
              ),
              AppInfoItem(
                label: 'Created By',
                value: _fallback(order.createdByName),
              ),
              AppInfoItem(
                label: 'Grand Total',
                value: currency.format(order.totalAmount),
              ),
              AppInfoItem(
                label: 'Created',
                value: dateFormat.format(order.createdAt),
              ),
              if (order.issueDate != null)
                AppInfoItem(
                  label: 'Issued',
                  value: dateFormat.format(order.issueDate!),
                ),
              if (order.receivedDate != null)
                AppInfoItem(
                  label: 'Received',
                  value: dateFormat.format(order.receivedDate!),
                ),
              if (order.closedDate != null)
                AppInfoItem(
                  label: 'Closed',
                  value: dateFormat.format(order.closedDate!),
                ),
              if (order.cancelledDate != null)
                AppInfoItem(
                  label: 'Cancelled',
                  value: dateFormat.format(order.cancelledDate!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(_fallback(order.notes)),
        ],
      ),
    );
  }

  String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}

class _PurchaseOrderItems extends StatelessWidget {
  const _PurchaseOrderItems({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          const AppEmptyCard(message: 'No PO items found.')
        else
          for (final item in order.items)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 8),
              title: Text(item.itemName),
              subtitle: Text('${_quantity(item.quantity)} ${item.unit}'),
              trailing: Text(currency.format(item.lineTotal)),
            ),
      ],
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _PurchaseOrderActions extends StatelessWidget {
  const _PurchaseOrderActions({
    required this.order,
    required this.isMutating,
    required this.invoiceForOrder,
    required this.canManagePurchaseOrders,
    required this.canCreateInvoice,
    required this.canViewInvoice,
    required this.onIssue,
    required this.onReceive,
    required this.onClose,
    required this.onCancel,
  });

  final PurchaseOrder order;
  final bool isMutating;
  final AsyncValue<Invoice?>? invoiceForOrder;
  final bool canManagePurchaseOrders;
  final bool canCreateInvoice;
  final bool canViewInvoice;
  final VoidCallback onIssue;
  final VoidCallback onReceive;
  final VoidCallback onClose;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (order.canEdit && canManagePurchaseOrders)
        FilledButton.icon(
          key: const Key('editPurchaseOrderButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/purchase-orders/${order.localId}/edit'),
          icon: const Icon(AppIcons.description),
          label: const Text('Edit'),
        ),
      if (order.canIssue && canManagePurchaseOrders)
        FilledButton.icon(
          key: const Key('issuePurchaseOrderButton'),
          onPressed: isMutating ? null : onIssue,
          icon: const Icon(AppIcons.send),
          label: const Text('Issue'),
        ),
      if (order.canReceive && canManagePurchaseOrders)
        FilledButton.icon(
          key: const Key('receivePurchaseOrderButton'),
          onPressed: isMutating ? null : onReceive,
          icon: const Icon(AppIcons.check),
          label: const Text('Receive'),
        ),
      if (order.canClose && canManagePurchaseOrders)
        FilledButton.icon(
          key: const Key('closePurchaseOrderButton'),
          onPressed: isMutating ? null : onClose,
          icon: const Icon(AppIcons.circleCheck),
          label: const Text('Close'),
        ),
      if (order.canCancel && canManagePurchaseOrders)
        OutlinedButton.icon(
          key: const Key('cancelPurchaseOrderButton'),
          onPressed: isMutating ? null : onCancel,
          icon: const Icon(AppIcons.x),
          label: const Text('Cancel'),
        ),
      ..._invoiceActions(context),
    ];

    if (actions.isEmpty) {
      return const AppEmptyCard(message: 'This purchase order is view only.');
    }
    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }

  List<Widget> _invoiceActions(BuildContext context) {
    final invoiceValue = invoiceForOrder;
    if (invoiceValue == null) return const [];
    if (invoiceValue.isLoading && order.isReceived && canCreateInvoice) {
      return [
        OutlinedButton.icon(
          key: const Key('checkingPurchaseOrderInvoiceButton'),
          onPressed: null,
          icon: const Icon(AppIcons.money),
          label: const Text('Checking Invoice'),
        ),
      ];
    }
    final invoice = invoiceValue.valueOrNull;
    if (invoice != null && canViewInvoice) {
      return [
        OutlinedButton.icon(
          key: const Key('viewPurchaseOrderInvoiceButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/invoices/${invoice.localId}'),
          icon: const Icon(AppIcons.money),
          label: const Text('View Invoice'),
        ),
      ];
    }
    if (order.isReceived && canCreateInvoice) {
      return [
        FilledButton.icon(
          key: const Key('createPurchaseOrderInvoiceButton'),
          onPressed: isMutating
              ? null
              : () => context.push(
                  '/invoices/new?purchaseOrderId=${order.localId}',
                ),
          icon: const Icon(AppIcons.money),
          label: const Text('Create Invoice'),
        ),
      ];
    }
    return const [];
  }
}
