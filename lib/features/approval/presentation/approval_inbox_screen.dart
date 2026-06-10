import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import '../domain/approval_repository.dart';
import 'approval_controller.dart';
import 'approval_state.dart';

class ApprovalInboxScreen extends ConsumerStatefulWidget {
  const ApprovalInboxScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<ApprovalInboxScreen> createState() =>
      _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends ConsumerState<ApprovalInboxScreen> {
  final _searchController = TextEditingController();
  final _departmentController = TextEditingController();
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
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.session != next.session) {
        _load();
      }
    });

    final state = ref.watch(approvalControllerProvider);

    return AppScaffold(
      title: 'Approval Inbox',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _ApprovalFiltersCard(
              searchController: _searchController,
              departmentController: _departmentController,
              priority: _priority,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              onPriorityChanged: (value) => setState(() => _priority = value),
              onPickDateFrom: () => _selectDate(isFrom: true),
              onPickDateTo: () => _selectDate(isFrom: false),
              onClear: _clearFilters,
              onApply: _applyFilters,
            ),
            const SizedBox(height: 14),
            _ApprovalList(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    final session = ref.read(authControllerProvider).session;
    return ref.read(approvalControllerProvider.notifier).load(session);
  }

  Future<void> _applyFilters() {
    final session = ref.read(authControllerProvider).session;
    return ref
        .read(approvalControllerProvider.notifier)
        .load(session, _filters());
  }

  Future<void> _clearFilters() {
    setState(() {
      _searchController.clear();
      _departmentController.clear();
      _priority = null;
      _dateFrom = null;
      _dateTo = null;
    });
    final session = ref.read(authControllerProvider).session;
    return ref
        .read(approvalControllerProvider.notifier)
        .load(session, const ApprovalInboxFilters());
  }

  ApprovalInboxFilters _filters() {
    return ApprovalInboxFilters(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      priority: _priority,
      departmentId: _departmentController.text.trim().isEmpty
          ? null
          : _departmentController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
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

class _ApprovalFiltersCard extends StatelessWidget {
  const _ApprovalFiltersCard({
    required this.searchController,
    required this.departmentController,
    required this.priority,
    required this.dateFrom,
    required this.dateTo,
    required this.onPriorityChanged,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    required this.onClear,
    required this.onApply,
  });

  final TextEditingController searchController;
  final TextEditingController departmentController;
  final String? priority;
  final DateTime? dateFrom;
  final DateTime? dateTo;
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
            key: const Key('approvalSearchField'),
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
                  key: ValueKey('approvalPriorityFilter-$priority'),
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
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('approvalDepartmentField'),
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department ID',
                    prefixIcon: Icon(AppIcons.department),
                  ),
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
                key: const Key('approvalFilterApplyButton'),
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

class _ApprovalList extends StatelessWidget {
  const _ApprovalList({required this.state});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
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

    if (state.items.isEmpty) {
      return const AppEmptyCard(message: 'No requests awaiting approval.');
    }

    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMd();
    return Column(
      children: [
        for (final item in state.items)
          AppSectionCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => context.push('/approvals/${item.requestId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(status: item.priority),
                  ],
                ),
                const SizedBox(height: 10),
                AppInfoRow(
                  icon: AppIcons.user,
                  label: 'Requester',
                  value: item.requesterName.isEmpty
                      ? 'Requester'
                      : item.requesterName,
                ),
                AppInfoRow(
                  icon: AppIcons.department,
                  label: 'Department',
                  value: item.departmentName.isEmpty
                      ? item.departmentId ?? 'Not assigned'
                      : item.departmentName,
                ),
                AppInfoRow(
                  icon: AppIcons.calendar,
                  label: 'Needed Date',
                  value: item.neededDate == null
                      ? 'Not set'
                      : dateFormat.format(item.neededDate!),
                ),
                AppInfoRow(
                  icon: AppIcons.money,
                  label: 'Estimated Total',
                  value: currency.format(item.estimatedTotal),
                ),
                AppInfoRow(
                  icon: AppIcons.approval,
                  label: 'Current Step',
                  value: item.currentApprovalStep.isEmpty
                      ? 'Pending approval'
                      : item.currentApprovalStep,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
