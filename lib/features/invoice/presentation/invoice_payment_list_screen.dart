import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/payment_entity.dart';
import 'payment_controller.dart';
import 'payment_state.dart';

class InvoicePaymentListScreen extends ConsumerStatefulWidget {
  const InvoicePaymentListScreen({
    super.key,
    required this.invoiceId,
    this.showBottomNavigation = true,
  });

  final String invoiceId;
  final bool showBottomNavigation;

  @override
  ConsumerState<InvoicePaymentListScreen> createState() =>
      _InvoicePaymentListScreenState();
}

class _InvoicePaymentListScreenState
    extends ConsumerState<InvoicePaymentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentControllerProvider);
    return AppScaffold(
      title: 'Payment History',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(children: [_PaymentList(state: state)]),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(paymentControllerProvider.notifier)
        .loadList(PaymentFilters(invoiceId: widget.invoiceId));
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
          _label(payment.normalizedPaymentMethod),
          if (payment.referenceNumber?.trim().isNotEmpty == true)
            'Reference: ${payment.referenceNumber}',
          if (payment.paymentDate != null)
            'Payment Date: ${dayFormat.format(payment.paymentDate!)}',
          if (payment.notes?.trim().isNotEmpty == true) payment.notes!,
          'Created: ${dayFormat.format(payment.createdAt)}',
        ].join('\n'),
      ),
      trailing: const Icon(AppIcons.chevronRight),
      onTap: () => context.push('/payments/${payment.localId}'),
    );
  }

  String _label(String value) => value.replaceAll('_', ' ');
}
