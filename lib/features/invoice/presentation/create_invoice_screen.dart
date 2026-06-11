import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../purchase_order/domain/purchase_order_entity.dart';
import '../../purchase_order/presentation/purchase_order_controller.dart';
import '../domain/invoice_entity.dart';
import 'invoice_controller.dart';
import 'invoice_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    required this.purchaseOrderId,
    this.showBottomNavigation = true,
  });

  final String? purchaseOrderId;
  final bool showBottomNavigation;

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitted = false;

  bool get _hasSource => widget.purchaseOrderId?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasSource) {
      Future.microtask(
        () => ref
            .read(purchaseOrderControllerProvider.notifier)
            .loadDetail(widget.purchaseOrderId!.trim()),
      );
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poState = ref.watch(purchaseOrderControllerProvider);
    final invoiceState = ref.watch(invoiceControllerProvider);
    final session = ref.watch(authControllerProvider).session;
    final canCreate = PermissionPolicy.canCreateInvoice(session);
    final order = poState.selectedOrder;
    final existingInvoice = _hasSource
        ? ref.watch(
            invoiceForPurchaseOrderProvider(widget.purchaseOrderId!.trim()),
          )
        : null;

    return AppScaffold(
      title: 'Create Invoice',
      showBottomNavigation: widget.showBottomNavigation,
      child: AppScreenListView(
        children: [
          if (!_hasSource)
            const AppEmptyCard(
              message: 'Open a received purchase order to create an invoice.',
            )
          else if (poState.isLoading && order == null)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (poState.errorMessage != null && order == null)
            AppEmptyCard(message: poState.errorMessage!)
          else if (order == null)
            const AppEmptyCard(message: 'Purchase order not found.')
          else if (!canCreate)
            const AppEmptyCard(
              message: 'Invoice create permission is required.',
            )
          else if (!order.isReceived)
            const AppEmptyCard(
              message: 'Invoice can only be created from a received PO.',
            )
          else if (existingInvoice == null)
            const AppEmptyCard(message: 'Checking existing invoice...')
          else
            existingInvoice.when(
              loading: () =>
                  const AppEmptyCard(message: 'Checking existing invoice...'),
              error: (error, stackTrace) =>
                  AppEmptyCard(message: error.toString()),
              data: (invoice) {
                if (invoice != null) {
                  return AppActionTile(
                    icon: AppIcons.money,
                    title: 'View Invoice',
                    subtitle: 'An invoice already exists for this PO.',
                    route: '/invoices/${invoice.localId}',
                  );
                }
                return Column(
                  children: [
                    _PurchaseOrderInvoiceSource(order: order),
                    const SizedBox(height: 16),
                    _InvoiceFormCard(
                      invoiceNumberController: _invoiceNumberController,
                      invoiceDateController: _invoiceDateController,
                      dueDateController: _dueDateController,
                      amountController: _amountController,
                      notesController: _notesController,
                      showValidation: _submitted,
                      isMutating: invoiceState.isMutating,
                      errorMessage: invoiceState.errorMessage,
                      submitLabel: 'Create Invoice',
                      onCancel: _cancel,
                      onSubmit: () => _create(order),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _create(PurchaseOrder order) async {
    if (!PermissionPolicy.canCreateInvoice(
      ref.read(authControllerProvider).session,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission for this action.'),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
    final invoiceDate = _parseDate(_invoiceDateController.text);
    final dueDate = _parseDate(_dueDateController.text);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (!_isValid(invoiceDate, dueDate, amount)) return;
    final invoice = await ref
        .read(invoiceControllerProvider.notifier)
        .create(
          CreateInvoicePayload(
            purchaseOrderId: order.localId,
            invoiceNumber: _invoiceNumberController.text,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            invoiceAmount: amount,
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || invoice == null) return;
    ref.invalidate(invoiceForPurchaseOrderProvider(order.localId));
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice created.')));
    context.replace('/invoices/${invoice.localId}');
  }

  void _cancel() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else if (_hasSource) {
      context.go('/purchase-orders/${widget.purchaseOrderId}');
    } else {
      context.go('/invoices');
    }
  }

  bool _isValid(DateTime? invoiceDate, DateTime? dueDate, double amount) {
    if (_invoiceNumberController.text.trim().isEmpty) return false;
    if (invoiceDate == null || dueDate == null) return false;
    if (amount <= 0) return false;
    if (dueDate.isBefore(invoiceDate)) return false;
    return true;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PurchaseOrderInvoiceSource extends StatelessWidget {
  const _PurchaseOrderInvoiceSource({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          AppInfoGrid(
            items: [
              AppInfoItem(label: 'PO', value: order.poNumber),
              AppInfoItem(label: 'Vendor', value: order.vendorName),
              AppInfoItem(
                label: 'PO Total',
                value: currency.format(order.totalAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceFormCard extends StatelessWidget {
  const _InvoiceFormCard({
    required this.invoiceNumberController,
    required this.invoiceDateController,
    required this.dueDateController,
    required this.amountController,
    required this.notesController,
    required this.showValidation,
    required this.isMutating,
    required this.errorMessage,
    required this.submitLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  final TextEditingController invoiceNumberController;
  final TextEditingController invoiceDateController;
  final TextEditingController dueDateController;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final bool showValidation;
  final bool isMutating;
  final String? errorMessage;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final invoiceDate = DateTime.tryParse(invoiceDateController.text.trim());
    final dueDate = DateTime.tryParse(dueDateController.text.trim());
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('invoiceNumberField'),
            controller: invoiceNumberController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Invoice Number',
              prefixIcon: const Icon(AppIcons.title),
              errorText:
                  showValidation && invoiceNumberController.text.trim().isEmpty
                  ? 'Invoice number is required'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoiceDateField'),
            controller: invoiceDateController,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Invoice Date',
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(AppIcons.calendar),
              errorText: showValidation && invoiceDate == null
                  ? 'Invoice date is required'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoiceDueDateField'),
            controller: dueDateController,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Due Date',
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(AppIcons.calendar),
              errorText: showValidation && dueDate == null
                  ? 'Due date is required'
                  : showValidation &&
                        dueDate != null &&
                        invoiceDate != null &&
                        dueDate.isBefore(invoiceDate)
                  ? 'Due date must be on or after invoice date'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoiceAmountField'),
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Invoice Amount',
              prefixIcon: const Icon(AppIcons.money),
              errorText: showValidation && amount <= 0
                  ? 'Invoice amount must be greater than zero'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoiceNotesField'),
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
              prefixIcon: Icon(AppIcons.description),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              const Spacer(),
              FilledButton.icon(
                key: const Key('submitInvoiceButton'),
                onPressed: isMutating ? null : onSubmit,
                icon: const Icon(AppIcons.check),
                label: Text(isMutating ? 'Saving...' : submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
