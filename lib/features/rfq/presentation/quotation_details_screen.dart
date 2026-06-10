import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class QuotationDetailsScreen extends ConsumerStatefulWidget {
  const QuotationDetailsScreen({
    super.key,
    required this.rfqId,
    required this.quotationId,
    this.showBottomNavigation = true,
  });

  final String rfqId;
  final String quotationId;
  final bool showBottomNavigation;

  @override
  ConsumerState<QuotationDetailsScreen> createState() =>
      _QuotationDetailsScreenState();
}

class _QuotationDetailsScreenState
    extends ConsumerState<QuotationDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final comparison = state.comparison;
    final quotation = _quotationFrom(comparison);

    return AppScaffold(
      title: 'Quotation Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && comparison == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && comparison == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (quotation == null)
              const AppEmptyCard(message: 'Quotation not found.')
            else ...[
              _QuotationSummary(comparison: comparison!, quotation: quotation),
              const SizedBox(height: 16),
              _QuotationItems(quotation: quotation),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(rfqControllerProvider.notifier)
        .loadComparison(widget.rfqId);
  }

  RfqComparisonQuotation? _quotationFrom(RfqComparison? comparison) {
    if (comparison == null) return null;
    for (final quotation in comparison.quotations) {
      if (quotation.quotationId == widget.quotationId) {
        return quotation;
      }
    }
    return null;
  }
}

class _QuotationSummary extends StatelessWidget {
  const _QuotationSummary({required this.comparison, required this.quotation});

  final RfqComparison comparison;
  final RfqComparisonQuotation quotation;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    final isLowest = comparison.lowestQuotationId == quotation.quotationId;
    final isSelected = comparison.selectedQuotationId == quotation.quotationId;

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
                  quotation.vendorName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: 'Rank ${quotation.rank}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quotation.quotationNumber,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isLowest) const StatusChip(status: 'Lowest Price'),
              if (isSelected) const StatusChip(status: 'Selected'),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Quotation Date',
                value: quotation.quotationDate == null
                    ? 'Not set'
                    : dateFormat.format(quotation.quotationDate!),
              ),
              AppInfoItem(
                label: 'Valid Until',
                value: quotation.validUntil == null
                    ? 'Not set'
                    : dateFormat.format(quotation.validUntil!),
              ),
              AppInfoItem(
                label: 'Total',
                value: currency.format(quotation.totalAmount),
              ),
              AppInfoItem(label: 'Vendor ID', value: quotation.vendorId),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotationItems extends StatelessWidget {
  const _QuotationItems({required this.quotation});

  final RfqComparisonQuotation quotation;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in quotation.items)
          AppListTileCard(
            margin: const EdgeInsets.only(bottom: 10),
            leading: const Icon(AppIcons.item),
            title: Text(item.itemName),
            subtitle: Text(
              '${_quantity(item.quantity)} ${item.unit} × ${currency.format(item.unitPrice)}',
            ),
            trailing: Text(currency.format(item.lineTotal)),
          ),
      ],
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
