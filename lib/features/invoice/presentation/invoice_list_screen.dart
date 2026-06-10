import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/invoice_entity.dart';
import 'invoice_controller.dart';
import 'invoice_state.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _searchController = TextEditingController();
  final _vendorController = TextEditingController();
  final _purchaseOrderController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  Timer? _searchDebounce;
  String? _status;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _vendorController.dispose();
    _purchaseOrderController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceControllerProvider);
    return AppScaffold(
      title: 'Invoices',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _InvoiceFiltersCard(
              searchController: _searchController,
              vendorController: _vendorController,
              purchaseOrderController: _purchaseOrderController,
              dateFromController: _dateFromController,
              dateToController: _dateToController,
              status: _status,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: (value) => setState(() => _status = value),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _InvoiceList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(invoiceControllerProvider.notifier).loadList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed.length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 400), _applyFilters);
  }

  Future<void> _applyFilters() {
    final search = _searchController.text.trim();
    return ref
        .read(invoiceControllerProvider.notifier)
        .loadList(
          InvoiceFilters(
            search: search.length < 2 ? null : search,
            status: _status,
            vendorId: _blankToNull(_vendorController.text),
            purchaseOrderId: _blankToNull(_purchaseOrderController.text),
            dateFrom: _parseDate(_dateFromController.text),
            dateTo: _parseDate(_dateToController.text),
            page: 1,
          ),
        );
  }

  Future<void> _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _vendorController.clear();
      _purchaseOrderController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _status = null;
    });
    return ref
        .read(invoiceControllerProvider.notifier)
        .loadList(const InvoiceFilters());
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

class _InvoiceFiltersCard extends StatelessWidget {
  const _InvoiceFiltersCard({
    required this.searchController,
    required this.vendorController,
    required this.purchaseOrderController,
    required this.dateFromController,
    required this.dateToController,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final TextEditingController vendorController;
  final TextEditingController purchaseOrderController;
  final TextEditingController dateFromController;
  final TextEditingController dateToController;
  final String? status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('invoiceSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.list),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey('invoiceStatusFilter-$status'),
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              prefixIcon: Icon(AppIcons.circleCheck),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(
                value: InvoiceStatus.pending,
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: InvoiceStatus.partiallyPaid,
                child: Text('Partially Paid'),
              ),
              DropdownMenuItem(value: InvoiceStatus.paid, child: Text('Paid')),
              DropdownMenuItem(
                value: InvoiceStatus.cancelled,
                child: Text('Cancelled'),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoiceVendorFilterField'),
            controller: vendorController,
            decoration: const InputDecoration(
              labelText: 'Vendor ID',
              prefixIcon: Icon(AppIcons.vendors),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('invoicePurchaseOrderFilterField'),
            controller: purchaseOrderController,
            decoration: const InputDecoration(
              labelText: 'Purchase Order ID',
              prefixIcon: Icon(AppIcons.order),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('invoiceDateFromFilterField'),
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
                  key: const Key('invoiceDateToFilterField'),
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
                key: const Key('invoiceFilterApplyButton'),
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

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({required this.state});

  final InvoiceState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.invoices.isEmpty) {
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
    if (state.invoices.isEmpty) {
      return const AppEmptyCard(message: 'No invoices found.');
    }
    return Column(
      children: [
        for (final invoice in state.invoices) _InvoiceCard(invoice: invoice),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.money),
      title: Text(
        invoice.invoiceNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          invoice.vendorName,
          'PO: ${invoice.purchaseOrderNumber}',
          'Amount: ${currency.format(invoice.invoiceAmount)}',
          'Paid: ${currency.format(invoice.paidAmount)}',
          'Due: ${currency.format(invoice.dueAmount)}',
          if (invoice.dueDate != null)
            'Due Date: ${dateFormat.format(invoice.dueDate!)}',
        ].join('\n'),
      ),
      trailing: StatusChip(status: invoice.normalizedStatus),
      onTap: () => context.push('/invoices/${invoice.localId}'),
    );
  }
}
