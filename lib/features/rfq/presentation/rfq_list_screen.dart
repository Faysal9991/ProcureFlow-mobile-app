import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/rfq_entity.dart';
import 'rfq_controller.dart';
import 'rfq_state.dart';

class RfqListScreen extends ConsumerStatefulWidget {
  const RfqListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends ConsumerState<RfqListScreen> {
  final _searchController = TextEditingController();
  final _purchaseRequestController = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _purchaseRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfqControllerProvider);
    final session = ref.watch(authControllerProvider).session;

    return AppScaffold(
      title: 'RFQs',
      showBottomNavigation: widget.showBottomNavigation,
      floatingActionButton: PermissionPolicy.canManageRfq(session)
          ? FloatingActionButton.extended(
              key: const Key('createRfqButton'),
              onPressed: () => context.push('/rfqs/new'),
              icon: const Icon(AppIcons.add),
              label: const Text('New RFQ'),
            )
          : null,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _RfqFiltersCard(
              searchController: _searchController,
              purchaseRequestController: _purchaseRequestController,
              status: _status,
              onStatusChanged: (value) => setState(() => _status = value),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _RfqList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(rfqControllerProvider.notifier).loadList();
  }

  Future<void> _applyFilters() {
    return ref
        .read(rfqControllerProvider.notifier)
        .loadList(
          RfqFilters(
            search: _blankToNull(_searchController.text),
            status: _status,
            purchaseRequestId: _blankToNull(_purchaseRequestController.text),
          ),
        );
  }

  Future<void> _clearFilters() {
    setState(() {
      _searchController.clear();
      _purchaseRequestController.clear();
      _status = null;
    });
    return ref
        .read(rfqControllerProvider.notifier)
        .loadList(const RfqFilters());
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _RfqFiltersCard extends StatelessWidget {
  static const _anyStatus = 'ANY';

  const _RfqFiltersCard({
    required this.searchController,
    required this.purchaseRequestController,
    required this.status,
    required this.onStatusChanged,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final TextEditingController purchaseRequestController;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('rfqSearchField'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.list),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                _StatusDropdown(
                  status: status,
                  onStatusChanged: onStatusChanged,
                ),
                TextField(
                  key: const Key('rfqPurchaseRequestFilterField'),
                  controller: purchaseRequestController,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Request',
                    prefixIcon: Icon(AppIcons.list),
                  ),
                ),
              ];

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [fields[0], const SizedBox(height: 12), fields[1]],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: onClear, child: const Text('Clear')),
              const Spacer(),
              FilledButton.icon(
                key: const Key('rfqFilterApplyButton'),
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

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.status, required this.onStatusChanged});

  final String? status;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('rfqStatusFilter-${status ?? _RfqFiltersCard._anyStatus}'),
      initialValue: status ?? _RfqFiltersCard._anyStatus,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Status'),
      items: const [
        DropdownMenuItem(value: _RfqFiltersCard._anyStatus, child: Text('Any')),
        DropdownMenuItem(value: RfqStatus.draft, child: Text('Draft')),
        DropdownMenuItem(value: RfqStatus.open, child: Text('Open')),
        DropdownMenuItem(
          value: RfqStatus.quotationReceived,
          child: Text('Quotation Received'),
        ),
        DropdownMenuItem(value: RfqStatus.completed, child: Text('Completed')),
        DropdownMenuItem(value: RfqStatus.cancelled, child: Text('Cancelled')),
      ],
      onChanged: (value) {
        onStatusChanged(value == _RfqFiltersCard._anyStatus ? null : value);
      },
    );
  }
}

class _RfqList extends StatelessWidget {
  const _RfqList({required this.state});

  final RfqState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.rfqs.isEmpty) {
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
    if (state.rfqs.isEmpty) {
      return const AppEmptyCard(message: 'No RFQs found.');
    }

    return Column(children: [for (final rfq in state.rfqs) _RfqCard(rfq: rfq)]);
  }
}

class _RfqCard extends StatelessWidget {
  const _RfqCard({required this.rfq});

  final Rfq rfq;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push('/rfqs/${rfq.localId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rfq.rfqNumber.isEmpty ? 'RFQ' : rfq.rfqNumber,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(status: rfq.normalizedStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${rfq.purchaseRequestNumber} • ${rfq.purchaseRequestTitle}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                status: rfq.dueDate == null
                    ? 'No Due Date'
                    : 'Due ${dateFormat.format(rfq.dueDate!)}',
              ),
              StatusChip(status: '${rfq.vendorCount} Vendors'),
              StatusChip(status: 'Created ${dateFormat.format(rfq.createdAt)}'),
            ],
          ),
        ],
      ),
    );
  }
}
