import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/purchase_request_entity.dart';
import 'purchase_request_controller.dart';
import 'purchase_request_state.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  final _searchController = TextEditingController();
  String? _status;
  String? _priority;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRequestControllerProvider);

    return AppScaffold(
      title: 'My Requests',
      showBottomNavigation: widget.showBottomNavigation,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createRequestButton'),
        onPressed: () => context.push('/requests/new'),
        icon: const Icon(AppIcons.add),
        label: const Text('Create'),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _FiltersCard(
              searchController: _searchController,
              status: _status,
              priority: _priority,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              onStatusChanged: (value) => setState(() => _status = value),
              onPriorityChanged: (value) => setState(() => _priority = value),
              onPickDateFrom: () => _selectDate(isFrom: true),
              onPickDateTo: () => _selectDate(isFrom: false),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _RequestList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(purchaseRequestControllerProvider.notifier).loadList();
  }

  Future<void> _applyFilters() {
    return ref
        .read(purchaseRequestControllerProvider.notifier)
        .loadList(
          PurchaseRequestFilters(
            search: _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
            status: _status,
            priority: _priority,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          ),
        );
  }

  Future<void> _clearFilters() {
    setState(() {
      _searchController.clear();
      _status = null;
      _priority = null;
      _dateFrom = null;
      _dateTo = null;
    });
    return ref
        .read(purchaseRequestControllerProvider.notifier)
        .loadList(const PurchaseRequestFilters());
  }

  Future<void> _selectDate({required bool isFrom}) async {
    final now = DateTime.now();
    final current = isFrom ? _dateFrom : _dateTo;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;

    setState(() {
      if (isFrom) {
        _dateFrom = selected;
      } else {
        _dateTo = selected;
      }
    });
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.searchController,
    required this.status,
    required this.priority,
    required this.dateFrom,
    required this.dateTo,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final String? status;
  final String? priority;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('requestSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.list),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('requestStatusFilter-$status'),
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(
                      value: PurchaseRequestStatus.draft,
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestStatus.submitted,
                      child: Text('Submitted'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestStatus.approved,
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestStatus.rejected,
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestStatus.cancelled,
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('requestPriorityFilter-$priority'),
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    DropdownMenuItem(
                      value: PurchaseRequestPriority.low,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestPriority.normal,
                      child: Text('Normal'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestPriority.high,
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: PurchaseRequestPriority.urgent,
                      child: Text('Urgent'),
                    ),
                  ],
                  onChanged: onPriorityChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateFilterButton(
                  label: 'Date From',
                  value: dateFrom == null
                      ? 'Any'
                      : dateFormat.format(dateFrom!),
                  onTap: onPickDateFrom,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateFilterButton(
                  label: 'Date To',
                  value: dateTo == null ? 'Any' : dateFormat.format(dateTo!),
                  onTap: onPickDateTo,
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
                key: const Key('requestFilterApplyButton'),
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

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(AppIcons.calendar),
        ),
        child: Text(value, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.state});

  final PurchaseRequestState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.requests.isEmpty) {
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

    if (state.requests.isEmpty) {
      return const AppEmptyCard(message: 'No purchase requests found.');
    }

    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    return Column(
      children: [
        for (final request in state.requests)
          AppSectionCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => context.push('/requests/${request.localId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        request.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: request.normalizedStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(status: request.normalizedPriority),
                    if (request.neededDate != null)
                      StatusChip(
                        status:
                            'Needed ${dateFormat.format(request.neededDate!)}',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.requestNumber.isEmpty
                            ? 'Created ${dateFormat.format(request.createdAt)}'
                            : request.requestNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      currency.format(request.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${dateFormat.format(request.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
