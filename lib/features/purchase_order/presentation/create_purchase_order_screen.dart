import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../rfq/domain/rfq_entity.dart';
import '../../rfq/presentation/rfq_controller.dart';
import '../domain/purchase_order_entity.dart';
import 'purchase_order_controller.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({
    super.key,
    required this.rfqId,
    required this.quotationId,
    this.showBottomNavigation = true,
  });

  final String? rfqId;
  final String? quotationId;
  final bool showBottomNavigation;

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  final _notesController = TextEditingController();

  bool get _hasSource =>
      widget.rfqId?.trim().isNotEmpty == true &&
      widget.quotationId?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasSource) {
      Future.microtask(
        () => ref
            .read(rfqControllerProvider.notifier)
            .loadComparison(widget.rfqId!.trim()),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rfqState = ref.watch(rfqControllerProvider);
    final poState = ref.watch(purchaseOrderControllerProvider);
    final comparison = rfqState.comparison;
    final quotation = _quotationFrom(comparison);

    return AppScaffold(
      title: 'Create Purchase Order',
      showBottomNavigation: widget.showBottomNavigation,
      child: AppScreenListView(
        children: [
          if (!_hasSource)
            const AppEmptyCard(
              message:
                  'Open a completed RFQ comparison to create a purchase order.',
            )
          else if (rfqState.isLoading && comparison == null)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (rfqState.errorMessage != null && comparison == null)
            AppEmptyCard(message: rfqState.errorMessage!)
          else if (comparison == null || quotation == null)
            const AppEmptyCard(message: 'Selected quotation source not found.')
          else ...[
            _SourceSummary(comparison: comparison, quotation: quotation),
            const SizedBox(height: 16),
            _CreatePurchaseOrderForm(
              notesController: _notesController,
              isMutating: poState.isMutating,
              errorMessage: poState.errorMessage,
              onCreate: () => _create(quotation),
            ),
          ],
        ],
      ),
    );
  }

  RfqComparisonQuotation? _quotationFrom(RfqComparison? comparison) {
    if (comparison == null || widget.quotationId == null) return null;
    for (final quotation in comparison.quotations) {
      if (quotation.quotationId == widget.quotationId) {
        return quotation;
      }
    }
    return null;
  }

  Future<void> _create(RfqComparisonQuotation quotation) async {
    final order = await ref
        .read(purchaseOrderControllerProvider.notifier)
        .create(
          CreatePurchaseOrderPayload(
            quotationId: quotation.quotationId,
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || order == null) return;

    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(rfqControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchase order created.')));
    context.replace('/purchase-orders/${order.localId}');
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _SourceSummary extends StatelessWidget {
  const _SourceSummary({required this.comparison, required this.quotation});

  final RfqComparison comparison;
  final RfqComparisonQuotation quotation;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return AppSectionCard(
      padding: AppInsets.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Quotation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          AppInfoGrid(
            items: [
              AppInfoItem(label: 'Vendor', value: quotation.vendorName),
              AppInfoItem(label: 'RFQ', value: comparison.rfqNumber),
              AppInfoItem(
                label: 'Purchase Request',
                value: comparison.purchaseRequestNumber,
              ),
              AppInfoItem(
                label: 'Grand Total',
                value: currency.format(quotation.totalAmount),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Items', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in quotation.items)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 8),
              title: Text(item.itemName),
              subtitle: Text('${_quantity(item.quantity)} ${item.unit}'),
              trailing: Text(currency.format(item.lineTotal)),
            ),
        ],
      ),
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _CreatePurchaseOrderForm extends StatelessWidget {
  const _CreatePurchaseOrderForm({
    required this.notesController,
    required this.isMutating,
    required this.errorMessage,
    required this.onCreate,
  });

  final TextEditingController notesController;
  final bool isMutating;
  final String? errorMessage;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
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
            key: const Key('purchaseOrderNotesField'),
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
              prefixIcon: Icon(AppIcons.description),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('createPurchaseOrderButton'),
            onPressed: isMutating ? null : onCreate,
            icon: const Icon(AppIcons.order),
            label: Text(isMutating ? 'Creating...' : 'Create PO'),
          ),
        ],
      ),
    );
  }
}
