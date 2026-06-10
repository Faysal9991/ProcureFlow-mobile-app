import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../attachments/domain/attachment_entity.dart';
import '../../attachments/presentation/attachment_section.dart';
import '../domain/payment_entity.dart';
import 'payment_controller.dart';

class PaymentDetailsScreen extends ConsumerStatefulWidget {
  const PaymentDetailsScreen({
    super.key,
    required this.paymentId,
    this.showBottomNavigation = true,
  });

  final String paymentId;
  final bool showBottomNavigation;

  @override
  ConsumerState<PaymentDetailsScreen> createState() =>
      _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends ConsumerState<PaymentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentControllerProvider);
    final payment = state.selectedPayment;
    return AppScaffold(
      title: 'Payment Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && payment == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && payment == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (payment == null)
              const AppEmptyCard(message: 'Payment not found.')
            else ...[
              _PaymentSummary(payment: payment),
              const SizedBox(height: 16),
              AttachmentSection(
                entityType: AttachmentEntityType.payment,
                entityId: payment.localId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(paymentControllerProvider.notifier)
        .loadDetail(widget.paymentId);
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat.yMMMd();
    final dateFormat = DateFormat.yMMMd().add_jm();
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency.format(payment.amount),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Invoice',
                value: _fallback(payment.invoiceNumber),
              ),
              AppInfoItem(
                label: 'Vendor',
                value: _fallback(payment.vendorName),
              ),
              AppInfoItem(
                label: 'Payment Date',
                value: payment.paymentDate == null
                    ? 'Not provided'
                    : dayFormat.format(payment.paymentDate!),
              ),
              AppInfoItem(
                label: 'Method',
                value: payment.normalizedPaymentMethod.replaceAll('_', ' '),
              ),
              AppInfoItem(
                label: 'Reference',
                value: _fallback(payment.referenceNumber),
              ),
              AppInfoItem(
                label: 'Created By',
                value: _fallback(payment.createdByName),
              ),
              AppInfoItem(
                label: 'Created',
                value: dateFormat.format(payment.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(_fallback(payment.notes)),
        ],
      ),
    );
  }

  String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}
