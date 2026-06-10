import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/purchase_order_entity.dart';
import 'purchase_order_controller.dart';
import 'purchase_order_state.dart';

class PurchaseOrderListScreen extends ConsumerStatefulWidget {
  const PurchaseOrderListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends ConsumerState<PurchaseOrderListScreen> {
  final _searchController = TextEditingController();
  final _vendorController = TextEditingController();
  final _requestController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vendorController.dispose();
    _requestController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderControllerProvider);
    return AppScaffold(
      title: 'Purchase Orders',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _PurchaseOrderFiltersCard(
              searchController: _searchController,
              vendorController: _vendorController,
              requestController: _requestController,
              dateFromController: _dateFromController,
              dateToController: _dateToController,
              status: _status,
              onStatusChanged: (value) => setState(() => _status = value),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _PurchaseOrderList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(purchaseOrderControllerProvider.notifier).loadList();
  }

  Future<void> _applyFilters() {
    return ref
        .read(purchaseOrderControllerProvider.notifier)
        .loadList(
          PurchaseOrderFilters(
            search: _blankToNull(_searchController.text),
            status: _status,
            vendorId: _blankToNull(_vendorController.text),
            purchaseRequestId: _blankToNull(_requestController.text),
            dateFrom: _parseDate(_dateFromController.text),
            dateTo: _parseDate(_dateToController.text),
          ),
        );
  }

  Future<void> _clearFilters() {
    setState(() {
      _searchController.clear();
      _vendorController.clear();
      _requestController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _status = null;
    });
    return ref
        .read(purchaseOrderControllerProvider.notifier)
        .loadList(const PurchaseOrderFilters());
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
}

class _PurchaseOrderFiltersCard extends StatelessWidget {
  const _PurchaseOrderFiltersCard({
    required this.searchController,
    required this.vendorController,
    required this.requestController,
    required this.dateFromController,
    required this.dateToController,
    required this.status,
    required this.onStatusChanged,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final TextEditingController vendorController;
  final TextEditingController requestController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('purchaseOrderSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.list),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey('purchaseOrderStatusFilter-$status'),
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(AppIcons.circleCheck),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(
                value: PurchaseOrderStatus.draft,
                child: Text('Draft'),
              ),
              DropdownMenuItem(
                value: PurchaseOrderStatus.issued,
                child: Text('Issued'),
              ),
              DropdownMenuItem(
                value: PurchaseOrderStatus.received,
                child: Text('Received'),
              ),
              DropdownMenuItem(
                value: PurchaseOrderStatus.closed,
                child: Text('Closed'),
              ),
              DropdownMenuItem(
                value: PurchaseOrderStatus.cancelled,
                child: Text('Cancelled'),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('purchaseOrderVendorFilterField'),
            controller: vendorController,
            decoration: const InputDecoration(
              labelText: 'Vendor ID',
              prefixIcon: Icon(AppIcons.vendors),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('purchaseOrderRequestFilterField'),
            controller: requestController,
            decoration: const InputDecoration(
              labelText: 'Purchase Request ID',
              prefixIcon: Icon(AppIcons.description),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('purchaseOrderDateFromFilterField'),
                  controller: dateFromController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Date From',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('purchaseOrderDateToFilterField'),
                  controller: dateToController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Date To',
                    hintText: 'YYYY-MM-DD',
                  ),
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
                key: const Key('purchaseOrderFilterApplyButton'),
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

class _PurchaseOrderList extends StatelessWidget {
  const _PurchaseOrderList({required this.state});

  final PurchaseOrderState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.orders.isEmpty) {
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
    if (state.orders.isEmpty) {
      return const AppEmptyCard(message: 'No purchase orders found.');
    }
    return Column(
      children: [
        for (final order in state.orders) _PurchaseOrderCard(order: order),
      ],
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    final issueDate = order.issueDate == null
        ? 'Not issued'
        : dateFormat.format(order.issueDate!);
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.order),
      title: Text(
        order.poNumber.isEmpty ? 'Purchase Order' : order.poNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          order.vendorName,
          currency.format(order.totalAmount),
          'Issue: $issueDate',
          'Created: ${dateFormat.format(order.createdAt)}',
        ].where((value) => value.trim().isNotEmpty).join('\n'),
      ),
      trailing: StatusChip(status: order.normalizedStatus),
      onTap: () => context.push('/purchase-orders/${order.localId}'),
    );
  }
}
