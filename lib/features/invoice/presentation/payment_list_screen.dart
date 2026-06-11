import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/payment_entity.dart';
import 'payment_controller.dart';
import 'payment_state.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  final _vendorController = TextEditingController();
  final _methodController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _methodController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentControllerProvider);
    return AppScaffold(
      title: 'Payments',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _PaymentFilters(
              vendorController: _vendorController,
              methodController: _methodController,
              dateFromController: _dateFromController,
              dateToController: _dateToController,
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _PaymentList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(paymentControllerProvider.notifier).loadList();
  }

  Future<void> _applyFilters() {
    return ref
        .read(paymentControllerProvider.notifier)
        .loadList(
          PaymentFilters(
            vendorId: _blankToNull(_vendorController.text),
            paymentMethod: _blankToNull(_methodController.text),
            dateFrom: _parseDate(_dateFromController.text),
            dateTo: _parseDate(_dateToController.text),
          ),
        );
  }

  Future<void> _clearFilters() {
    _vendorController.clear();
    _methodController.clear();
    _dateFromController.clear();
    _dateToController.clear();
    return ref
        .read(paymentControllerProvider.notifier)
        .loadList(const PaymentFilters());
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : DateTime.tryParse(trimmed);
  }
}

class _PaymentFilters extends StatelessWidget {
  const _PaymentFilters({
    required this.vendorController,
    required this.methodController,
    required this.dateFromController,
    required this.dateToController,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController vendorController;
  final TextEditingController methodController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('paymentVendorFilterField'),
            controller: vendorController,
            decoration: const InputDecoration(
              labelText: 'Vendor ID',
              prefixIcon: Icon(AppIcons.vendors),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('paymentMethodFilterField'),
            controller: methodController,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(AppIcons.money),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('paymentDateFromFilterField'),
                  controller: dateFromController,
                  decoration: const InputDecoration(labelText: 'Date from'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('paymentDateToFilterField'),
                  controller: dateToController,
                  decoration: const InputDecoration(labelText: 'Date to'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              const Spacer(),
              FilledButton.icon(
                key: const Key('paymentFilterApplyButton'),
                onPressed: onApply,
                icon: const Icon(AppIcons.check),
                label: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.state});

  final PaymentState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.payments.isEmpty) {
      return const AppSectionCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (state.errorMessage != null) {
      return AppEmptyCard(message: state.errorMessage!);
    }
    if (state.payments.isEmpty) {
      return const AppEmptyCard(message: 'No payments recorded yet.');
    }
    return Column(
      children: [
        for (final payment in state.payments) _PaymentCard(payment: payment),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dayFormat = DateFormat.yMMMd();
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.money),
      title: Text(currency.format(payment.amount)),
      subtitle: Text(
        [
          payment.normalizedPaymentMethod.replaceAll('_', ' '),
          if (payment.invoiceNumber.trim().isNotEmpty)
            'Invoice: ${payment.invoiceNumber}',
          if (payment.vendorName.trim().isNotEmpty)
            'Vendor: ${payment.vendorName}',
          if (payment.referenceNumber?.trim().isNotEmpty == true)
            'Reference: ${payment.referenceNumber}',
          if (payment.paymentDate != null)
            'Payment Date: ${dayFormat.format(payment.paymentDate!)}',
        ].join('\n'),
      ),
      trailing: const Icon(AppIcons.chevronRight),
      onTap: () => context.push('/payments/${payment.localId}'),
    );
  }
}
