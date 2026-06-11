import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';

class RfqComparisonScreen extends ConsumerStatefulWidget {
  const RfqComparisonScreen({
    super.key,
    required this.rfqId,
    this.showBottomNavigation = true,
  });

  final String rfqId;
  final bool showBottomNavigation;

  @override
  ConsumerState<RfqComparisonScreen> createState() =>
      _RfqComparisonScreenState();
}

class _RfqComparisonScreenState extends ConsumerState<RfqComparisonScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final comparison = state.comparison;
    final session = ref.watch(authControllerProvider).session;
    final canManage = PermissionPolicy.canManageRfq(session);
    final canCreatePurchaseOrder = PermissionPolicy.canCreatePurchaseOrder(
      session,
    );

    return AppScaffold(
      title: 'Quotation Comparison',
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
            else if (comparison == null)
              const AppEmptyCard(message: 'RFQ comparison not found.')
            else ...[
              _ComparisonSummary(comparison: comparison),
              const SizedBox(height: 16),
              _PurchaseOrderComparisonAction(
                comparison: comparison,
                canCreatePurchaseOrder: canCreatePurchaseOrder,
              ),
              if (_showsPurchaseOrderAction(comparison, canCreatePurchaseOrder))
                const SizedBox(height: 16),
              if (!comparison.hasQuotations)
                const AppEmptyCard(message: 'No quotations submitted yet.')
              else ...[
                if (comparison.canSelectWinner && !canManage)
                  const AppEmptyCard(
                    message:
                        'You can view comparison, but rfq.manage is required to select a winner.',
                  ),
                for (final quotation in comparison.quotations)
                  _QuotationComparisonCard(
                    comparison: comparison,
                    quotation: quotation,
                    canSelect:
                        comparison.canSelectWinner &&
                        canManage &&
                        comparison.selectedQuotationId != quotation.quotationId,
                    isMutating: state.isMutating,
                    onOpenDetails: () => context.push(
                      '/rfqs/${widget.rfqId}/quotations/${quotation.quotationId}',
                    ),
                    onSelect: () => _confirmSelection(quotation),
                  ),
              ],
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

  Future<void> _confirmSelection(RfqComparisonQuotation quotation) async {
    if (!PermissionPolicy.canManageRfq(
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
        title: const Text('Select winning quotation?'),
        content: Text(
          'Select ${quotation.vendorName} as winning quotation? This will complete the RFQ and allow PO creation in the next phase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmSelectQuotationButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Select Winner'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final selected = await ref
        .read(rfqControllerProvider.notifier)
        .selectQuotation(
          widget.rfqId,
          SelectedQuotationPayload(quotationId: quotation.quotationId),
        );
    if (!mounted || selected == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Winning quotation selected.')),
    );
  }

  bool _showsPurchaseOrderAction(
    RfqComparison comparison,
    bool canCreatePurchaseOrder,
  ) {
    return comparison.purchaseOrderId != null ||
        (comparison.normalizedStatus == RfqStatus.completed &&
            comparison.selectedQuotationId != null &&
            canCreatePurchaseOrder);
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.comparison});

  final RfqComparison comparison;

  @override
  Widget build(BuildContext context) {
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
                  comparison.rfqNumber.isEmpty ? 'RFQ' : comparison.rfqNumber,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: comparison.normalizedStatus),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${comparison.purchaseRequestNumber} • ${comparison.purchaseRequestTitle}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(
                label: 'Quotations',
                value: '${comparison.quotations.length}',
              ),
              AppInfoItem(
                label: 'Lowest',
                value: _vendorNameFor(
                  comparison,
                  comparison.lowestQuotationId,
                  fallback: 'Not available',
                ),
              ),
              AppInfoItem(
                label: 'Selected',
                value: _vendorNameFor(
                  comparison,
                  comparison.selectedQuotationId,
                  fallback: 'Not selected',
                ),
              ),
              AppInfoItem(label: 'Status', value: comparison.normalizedStatus),
            ],
          ),
        ],
      ),
    );
  }

  String _vendorNameFor(
    RfqComparison comparison,
    String? quotationId, {
    required String fallback,
  }) {
    if (quotationId == null || comparison.quotations.isEmpty) return fallback;
    for (final quotation in comparison.quotations) {
      if (quotation.quotationId == quotationId) {
        return quotation.vendorName;
      }
    }
    return fallback;
  }
}

class _PurchaseOrderComparisonAction extends StatelessWidget {
  const _PurchaseOrderComparisonAction({
    required this.comparison,
    required this.canCreatePurchaseOrder,
  });

  final RfqComparison comparison;
  final bool canCreatePurchaseOrder;

  @override
  Widget build(BuildContext context) {
    if (comparison.purchaseOrderId != null) {
      return AppActionTile(
        key: const Key('viewPurchaseOrderFromComparisonButton'),
        icon: AppIcons.order,
        title: 'View Purchase Order',
        subtitle: 'A purchase order already exists for the selected quotation.',
        route: '/purchase-orders/${comparison.purchaseOrderId}',
      );
    }

    final canCreate =
        comparison.normalizedStatus == RfqStatus.completed &&
        comparison.selectedQuotationId != null &&
        canCreatePurchaseOrder;
    if (!canCreate) {
      return const SizedBox.shrink();
    }

    final location = Uri(
      path: '/purchase-orders/new',
      queryParameters: {
        'rfqId': comparison.rfqId,
        'quotationId': comparison.selectedQuotationId!,
      },
    ).toString();

    return AppActionTile(
      key: const Key('createPurchaseOrderFromComparisonButton'),
      icon: AppIcons.order,
      title: 'Create Purchase Order',
      subtitle: 'Create a draft PO from the selected quotation.',
      route: location,
    );
  }
}

class _QuotationComparisonCard extends StatelessWidget {
  const _QuotationComparisonCard({
    required this.comparison,
    required this.quotation,
    required this.canSelect,
    required this.isMutating,
    required this.onOpenDetails,
    required this.onSelect,
  });

  final RfqComparison comparison;
  final RfqComparisonQuotation quotation;
  final bool canSelect;
  final bool isMutating;
  final VoidCallback onOpenDetails;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    final isLowest = comparison.lowestQuotationId == quotation.quotationId;
    final isSelected = comparison.selectedQuotationId == quotation.quotationId;

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: CircleAvatar(child: Text('${quotation.rank}')),
        title: Text(quotation.vendorName),
        subtitle: Text(
          [
            quotation.quotationNumber,
            quotation.quotationDate == null
                ? null
                : dateFormat.format(quotation.quotationDate!),
          ].whereType<String>().join(' • '),
        ),
        trailing: Text(
          currency.format(quotation.totalAmount),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isLowest) const StatusChip(status: 'Lowest Price'),
              if (isSelected) const StatusChip(status: 'Selected'),
              if (quotation.validUntil != null)
                StatusChip(
                  status: 'Valid ${dateFormat.format(quotation.validUntil!)}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in quotation.items)
            AppListTileCard(
              margin: const EdgeInsets.only(bottom: 8),
              title: Text(item.itemName),
              subtitle: Text('${_quantity(item.quantity)} ${item.unit}'),
              trailing: Text(currency.format(item.lineTotal)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onOpenDetails,
                icon: const Icon(AppIcons.eye),
                label: const Text('Details'),
              ),
              const Spacer(),
              if (canSelect)
                FilledButton.icon(
                  key: Key('selectQuotationButton-${quotation.quotationId}'),
                  onPressed: isMutating ? null : onSelect,
                  icon: const Icon(AppIcons.check),
                  label: const Text('Select Winner'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _quantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
