import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/invoice_entity.dart';
import 'invoice_controller.dart';
import 'invoice_providers.dart';

class InvoiceEditScreen extends ConsumerStatefulWidget {
  const InvoiceEditScreen({
    super.key,
    required this.invoiceId,
    this.showBottomNavigation = true,
  });

  final String invoiceId;
  final bool showBottomNavigation;

  @override
  ConsumerState<InvoiceEditScreen> createState() => _InvoiceEditScreenState();
}

class _InvoiceEditScreenState extends ConsumerState<InvoiceEditScreen> {
  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _hydratedInvoiceId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
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
    final state = ref.watch(invoiceControllerProvider);
    final invoice = state.selectedInvoice;
    final session = ref.watch(authControllerProvider).session;
    final canManage = PermissionPolicy.canManageInvoices(session);
    if (invoice != null) {
      _hydrate(invoice);
    }

    return AppScaffold(
      title: 'Edit Invoice',
      showBottomNavigation: widget.showBottomNavigation,
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
          else if (!canManage)
            const AppEmptyCard(
              message: 'Invoice manage permission is required.',
            )
          else if (!invoice.isPending)
            const AppEmptyCard(message: 'Only pending invoices can be edited.')
          else
            _InvoiceEditFormCard(
              invoiceNumberController: _invoiceNumberController,
              invoiceDateController: _invoiceDateController,
              dueDateController: _dueDateController,
              amountController: _amountController,
              notesController: _notesController,
              showValidation: _submitted,
              isMutating: state.isMutating,
              errorMessage: state.errorMessage,
              onCancel: _cancel,
              onSubmit: () => _save(invoice),
            ),
        ],
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(invoiceControllerProvider.notifier)
        .loadDetail(widget.invoiceId);
  }

  void _hydrate(Invoice invoice) {
    if (_hydratedInvoiceId == invoice.localId) return;
    _hydratedInvoiceId = invoice.localId;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _invoiceDateController.text = _dateOnly(invoice.invoiceDate);
    _dueDateController.text = _dateOnly(invoice.dueDate);
    _amountController.text = invoice.invoiceAmount.toStringAsFixed(2);
    _notesController.text = invoice.notes ?? '';
  }

  Future<void> _save(Invoice invoice) async {
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
    setState(() => _submitted = true);
    final invoiceDate = _parseDate(_invoiceDateController.text);
    final dueDate = _parseDate(_dueDateController.text);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (!_isValid(invoiceDate, dueDate, amount)) return;
    final updated = await ref
        .read(invoiceControllerProvider.notifier)
        .update(
          invoice.localId,
          UpdateInvoicePayload(
            invoiceNumber: _invoiceNumberController.text,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            invoiceAmount: amount,
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || updated == null) return;
    ref.invalidate(invoiceForPurchaseOrderProvider(updated.purchaseOrderId));
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoice updated.')));
    context.replace('/invoices/${updated.localId}');
  }

  void _cancel() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/invoices/${widget.invoiceId}');
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

  String _dateOnly(DateTime? value) {
    if (value == null) return '';
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _InvoiceEditFormCard extends StatelessWidget {
  const _InvoiceEditFormCard({
    required this.invoiceNumberController,
    required this.invoiceDateController,
    required this.dueDateController,
    required this.amountController,
    required this.notesController,
    required this.showValidation,
    required this.isMutating,
    required this.errorMessage,
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
            key: const Key('invoiceEditNumberField'),
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
            key: const Key('invoiceEditDateField'),
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
            key: const Key('invoiceEditDueDateField'),
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
            key: const Key('invoiceEditAmountField'),
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
            key: const Key('invoiceEditNotesField'),
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
                key: const Key('saveInvoiceEditButton'),
                onPressed: isMutating ? null : onSubmit,
                icon: const Icon(AppIcons.check),
                label: Text(isMutating ? 'Saving...' : 'Save Invoice'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
