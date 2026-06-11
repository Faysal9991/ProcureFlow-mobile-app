import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/budget_entity.dart';
import 'budget_controller.dart';

class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key, this.showBottomNavigation = true});

  final bool showBottomNavigation;

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetControllerProvider);
    final session = ref.watch(authControllerProvider).session;
    return AppScaffold(
      title: 'Budgets',
      showBottomNavigation: widget.showBottomNavigation,
      floatingActionButton: PermissionPolicy.canCreateBudget(session)
          ? FloatingActionButton.extended(
              key: const Key('createBudgetButton'),
              onPressed: () => context.push('/budgets/new'),
              icon: const Icon(AppIcons.plus),
              label: const Text('New Budget'),
            )
          : null,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _Filters(
              searchController: _searchController,
              selectedStatus: state.filters.status,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusChanged,
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.budgets.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null)
              AppEmptyCard(message: state.errorMessage!)
            else if (state.budgets.isEmpty)
              const AppEmptyCard(message: 'No budgets found.')
            else
              for (final budget in state.budgets) _BudgetCard(budget: budget),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(budgetControllerProvider.notifier).loadList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final current = ref.read(budgetControllerProvider).filters;
      final trimmed = value.trim();
      ref
          .read(budgetControllerProvider.notifier)
          .loadList(
            current.copyWith(
              search: trimmed.length >= 2 ? trimmed : null,
              clearSearch: trimmed.isEmpty || trimmed.length < 2,
              page: 1,
            ),
          );
    });
  }

  void _onStatusChanged(String? value) {
    final current = ref.read(budgetControllerProvider).filters;
    ref
        .read(budgetControllerProvider.notifier)
        .loadList(
          current.copyWith(status: value, clearStatus: value == null, page: 1),
        );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('budgetSearchField'),
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.search),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const Key('budgetStatusFilter'),
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final status in BudgetStatus.values)
                DropdownMenuItem<String?>(value: status, child: Text(status)),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final dates = DateFormat.yMMMd();
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.money),
      title: Text(budget.name),
      subtitle: Text(
        '${budget.departmentName} • ${dates.format(budget.periodStartDate)} - '
        '${dates.format(budget.periodEndDate)}\n'
        'Available ${currency.format(budget.availableAmount)} of '
        '${currency.format(budget.allocatedAmount)}',
      ),
      trailing: StatusChip(status: budget.normalizedStatus),
      onTap: () => context.push('/budgets/${budget.localId}'),
    );
  }
}
