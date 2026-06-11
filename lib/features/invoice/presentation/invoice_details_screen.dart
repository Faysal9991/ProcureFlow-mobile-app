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
import '../domain/invoice_entity.dart';
import 'invoice_controller.dart';
import 'invoice_providers.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
    this.showBottomNavigation = true,
  });

  final String invoiceId;
  final bool showBottomNavigation;

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceControllerProvider);
    final invoice = state.selectedInvoice;
    final session = ref.watch(authControllerProvider).session;
    final canManage = PermissionPolicy.canManageInvoices(session);
    final canRecordPayment = PermissionPolicy.canCreatePayment(session);
    final canViewPayments = PermissionPolicy.canViewPayments(session);

    return AppScaffold(
      title: 'Invoice Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && invoice == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && invoice == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (invoice == null)
              const AppEmptyCard(message: 'Invoice not found.')
            else ...[
              _InvoiceSummary(invoice: invoice),
              const SizedBox(height: 16),
              _InvoiceActions(
                invoice: invoice,
                canManage: canManage,
                canRecordPayment: canRecordPayment,
                canViewPayments: canViewPayments,
                isMutating: state.isMutating,
                onCancel: () => _confirmCancel(invoice),
              ),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.invoice,
                entityId: invoice.localId,
                canView: PermissionPolicy.canViewAttachments(session: session),
                canUpload:
                    !invoice.isPaid &&
                    !invoice.isCancelled &&
                    PermissionPolicy.canUploadAttachments(session: session),
                canDelete:
                    !invoice.isPaid &&
                    !invoice.isCancelled &&
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
        .read(invoiceControllerProvider.notifier)
        .loadDetail(widget.invoiceId);
  }

  Future<void> _confirmCancel(Invoice invoice) async {
    if (!PermissionPolicy.canManageInvoices(
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
        title: const Text('Cancel Invoice?'),
        content: const Text('This invoice will no longer be payable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmCancelInvoiceButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final cancelled = await ref
        .read(invoiceControllerProvider.notifier)
        .cancel(invoice.localId);
    if (!mounted || cancelled == null) return;
    ref.invalidate(invoiceForPurchaseOrderProvider(invoice.purchaseOrderId));
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice cancelled.')));
  }
}

class _InvoiceSummary extends StatelessWidget {
  const _InvoiceSummary({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final dayFormat = DateFormat.yMMMd();
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
                  invoice.invoiceNumber,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: invoice.normalizedStatus),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Vendor',
                value: _fallback(invoice.vendorName),
              ),
              AppInfoItem(
                label: 'Purchase Order',
                value: _fallback(invoice.purchaseOrderNumber),
              ),
              AppInfoItem(
                label: 'Invoice Date',
                value: _formatDay(invoice.invoiceDate, dayFormat),
              ),
              AppInfoItem(
                label: 'Due Date',
                value: _formatDay(invoice.dueDate, dayFormat),
              ),
              AppInfoItem(
                label: 'Invoice Amount',
                value: currency.format(invoice.invoiceAmount),
              ),
              AppInfoItem(
                label: 'Paid Amount',
                value: currency.format(invoice.paidAmount),
              ),
              AppInfoItem(
                label: 'Due Amount',
                value: currency.format(invoice.dueAmount),
              ),
              AppInfoItem(
                label: 'Created',
                value: dateFormat.format(invoice.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(_fallback(invoice.notes)),
        ],
      ),
    );
  }

  String _formatDay(DateTime? value, DateFormat format) {
    return value == null ? 'Not provided' : format.format(value);
  }

  String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}

class _InvoiceActions extends StatelessWidget {
  const _InvoiceActions({
    required this.invoice,
    required this.canManage,
    required this.canRecordPayment,
    required this.canViewPayments,
    required this.isMutating,
    required this.onCancel,
  });

  final Invoice invoice;
  final bool canManage;
  final bool canRecordPayment;
  final bool canViewPayments;
  final bool isMutating;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (invoice.canEdit && canManage)
        FilledButton.icon(
          key: const Key('editInvoiceButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/invoices/${invoice.localId}/edit'),
          icon: const Icon(AppIcons.description),
          label: const Text('Edit'),
        ),
      if (invoice.canCancel && canManage)
        OutlinedButton.icon(
          key: const Key('cancelInvoiceButton'),
          onPressed: isMutating ? null : onCancel,
          icon: const Icon(AppIcons.x),
          label: const Text('Cancel'),
        ),
      if (canViewPayments)
        OutlinedButton.icon(
          key: const Key('viewInvoicePaymentsButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/invoices/${invoice.localId}/payments'),
          icon: const Icon(AppIcons.history),
          label: const Text('View Payments'),
        ),
      if (invoice.canRecordPayment && canRecordPayment)
        FilledButton.icon(
          key: const Key('recordInvoicePaymentButton'),
          onPressed: isMutating
              ? null
              : () => context.push('/invoices/${invoice.localId}/payments/new'),
          icon: const Icon(AppIcons.money),
          label: const Text('Record Payment'),
        ),
    ];

    if (actions.isEmpty) {
      return const AppEmptyCard(message: 'This invoice is view only.');
    }
    return Wrap(spacing: 10, runSpacing: 10, children: actions);
  }
}
