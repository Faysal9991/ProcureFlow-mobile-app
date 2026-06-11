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
import '../domain/invoice_entity.dart';
import '../domain/payment_entity.dart';
import 'invoice_controller.dart';
import 'invoice_providers.dart';
import 'payment_controller.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.invoiceId,
    this.showBottomNavigation = true,
  });

  final String invoiceId;
  final bool showBottomNavigation;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _paymentDateController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = PaymentMethod.bankTransfer;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _paymentDateController.text = _dateOnly(today);
    Future.microtask(_loadInvoice);
  }

  @override
  void dispose() {
    _paymentDateController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceControllerProvider);
    final paymentState = ref.watch(paymentControllerProvider);
    final invoice = invoiceState.selectedInvoice;
    final session = ref.watch(authControllerProvider).session;
    final canRecord = PermissionPolicy.canCreatePayment(session);

    return AppScaffold(
      title: 'Record Payment',
      showBottomNavigation: widget.showBottomNavigation,
      child: AppScreenListView(
        children: [
          if (invoiceState.isLoading && invoice == null)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (invoiceState.errorMessage != null && invoice == null)
            AppEmptyCard(message: invoiceState.errorMessage!)
          else if (invoice == null)
            const AppEmptyCard(message: 'Invoice not found.')
          else if (!canRecord)
            const AppEmptyCard(
              message: 'Payment create permission is required.',
            )
          else if (!_isPayable(invoice))
            const AppEmptyCard(message: 'This invoice is not payable.')
          else ...[
            _InvoicePaymentSource(invoice: invoice),
            const SizedBox(height: 16),
            _RecordPaymentForm(
              paymentDateController: _paymentDateController,
              amountController: _amountController,
              referenceController: _referenceController,
              notesController: _notesController,
              paymentMethod: _paymentMethod,
              dueAmount: invoice.dueAmount,
              showValidation: _submitted,
              isMutating: paymentState.isMutating,
              errorMessage: paymentState.errorMessage,
              onMethodChanged: (value) => setState(() {
                _paymentMethod = value ?? PaymentMethod.bankTransfer;
              }),
              onCancel: _cancel,
              onSubmit: () => _record(invoice),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadInvoice() {
    return ref
        .read(invoiceControllerProvider.notifier)
        .loadDetail(widget.invoiceId);
  }

  Future<void> _record(Invoice invoice) async {
    if (!PermissionPolicy.canCreatePayment(
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
    final paymentDate = DateTime.tryParse(_paymentDateController.text.trim());
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (!_isValid(paymentDate, amount, invoice.dueAmount)) return;
    final payment = await ref
        .read(paymentControllerProvider.notifier)
        .recordInvoicePayment(
          invoice.localId,
          CreatePaymentPayload(
            paymentDate: paymentDate,
            amount: amount,
            paymentMethod: _paymentMethod,
            referenceNumber: _blankToNull(_referenceController.text),
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || payment == null) return;
    ref.invalidate(invoiceForPurchaseOrderProvider(invoice.purchaseOrderId));
    ref.invalidate(dashboardControllerProvider);
    await ref
        .read(invoiceControllerProvider.notifier)
        .loadDetail(invoice.localId);
    await ref
        .read(paymentControllerProvider.notifier)
        .loadList(PaymentFilters(invoiceId: invoice.localId));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment recorded.')));
    context.replace('/payments/${payment.localId}');
  }

  bool _isPayable(Invoice invoice) {
    return (invoice.isPending || invoice.isPartiallyPaid) &&
        invoice.dueAmount > 0;
  }

  bool _isValid(DateTime? paymentDate, double amount, double dueAmount) {
    if (paymentDate == null) return false;
    if (amount <= 0) return false;
    if (amount > dueAmount) return false;
    if (_paymentMethod.trim().isEmpty) return false;
    if (normalizePaymentMethod(_paymentMethod) != PaymentMethod.cash &&
        _blankToNull(_referenceController.text) == null) {
      return false;
    }
    return true;
  }

  void _cancel() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/invoices/${widget.invoiceId}');
    }
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _InvoicePaymentSource extends StatelessWidget {
  const _InvoicePaymentSource({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: AppInfoGrid(
        items: [
          AppInfoItem(label: 'Invoice', value: invoice.invoiceNumber),
          AppInfoItem(label: 'Vendor', value: invoice.vendorName),
          AppInfoItem(
            label: 'Paid',
            value: currency.format(invoice.paidAmount),
          ),
          AppInfoItem(label: 'Due', value: currency.format(invoice.dueAmount)),
        ],
      ),
    );
  }
}

class _RecordPaymentForm extends StatelessWidget {
  const _RecordPaymentForm({
    required this.paymentDateController,
    required this.amountController,
    required this.referenceController,
    required this.notesController,
    required this.paymentMethod,
    required this.dueAmount,
    required this.showValidation,
    required this.isMutating,
    required this.errorMessage,
    required this.onMethodChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  final TextEditingController paymentDateController;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final TextEditingController notesController;
  final String paymentMethod;
  final double dueAmount;
  final bool showValidation;
  final bool isMutating;
  final String? errorMessage;
  final ValueChanged<String?> onMethodChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final paymentDate = DateTime.tryParse(paymentDateController.text.trim());
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final method = normalizePaymentMethod(paymentMethod);
    final referenceRequired = method != PaymentMethod.cash;
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
            key: const Key('paymentDateField'),
            controller: paymentDateController,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: 'Payment Date',
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(AppIcons.calendar),
              errorText: showValidation && paymentDate == null
                  ? 'Payment date is required'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('paymentAmountField'),
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: const Icon(AppIcons.money),
              errorText: showValidation && amount <= 0
                  ? 'Amount must be greater than zero'
                  : showValidation && amount > dueAmount
                  ? 'Amount cannot exceed due amount'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('paymentMethodField-$paymentMethod'),
            initialValue: paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(AppIcons.circleCheck),
            ),
            items: [
              for (final value in PaymentMethod.values)
                DropdownMenuItem(value: value, child: Text(_label(value))),
            ],
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('paymentReferenceField'),
            controller: referenceController,
            decoration: InputDecoration(
              labelText: 'Reference Number',
              prefixIcon: const Icon(AppIcons.description),
              errorText:
                  showValidation &&
                      referenceRequired &&
                      referenceController.text.trim().isEmpty
                  ? 'Reference number is required for non-cash payments'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('paymentNotesField'),
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
                key: const Key('submitPaymentButton'),
                onPressed: isMutating ? null : onSubmit,
                icon: const Icon(AppIcons.check),
                label: Text(isMutating ? 'Saving...' : 'Record Payment'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(String value) => value.replaceAll('_', ' ');
}
