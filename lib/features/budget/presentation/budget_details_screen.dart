import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/budget_entity.dart';
import 'budget_controller.dart';

class BudgetDetailsScreen extends ConsumerStatefulWidget {
  const BudgetDetailsScreen({
    super.key,
    required this.budgetId,
    this.showBottomNavigation = true,
  });

  final String budgetId;
  final bool showBottomNavigation;

  @override
  ConsumerState<BudgetDetailsScreen> createState() =>
      _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends ConsumerState<BudgetDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetControllerProvider);
    final budget = state.selectedBudget;
    return AppScaffold(
      title: 'Budget Details',
      showBottomNavigation: widget.showBottomNavigation,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            if (state.isLoading && budget == null)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null && budget == null)
              AppEmptyCard(message: state.errorMessage!)
            else if (budget == null)
              const AppEmptyCard(message: 'Budget not found.')
            else ...[
              _Summary(budget: budget),
              const SizedBox(height: 16),
              _Actions(
                budget: budget,
                isMutating: state.isMutating,
                onActivate: () => _confirm(
                  title: 'Activate Budget?',
                  actionLabel: 'Activate',
                  action: () => ref
                      .read(budgetControllerProvider.notifier)
                      .activate(budget.localId),
                ),
                onClose: () => _confirm(
                  title: 'Close Budget?',
                  actionLabel: 'Close',
                  action: () => ref
                      .read(budgetControllerProvider.notifier)
                      .close(budget.localId),
                ),
                onAdjust: () => _showAdjustment(budget),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(budgetControllerProvider.notifier)
        .loadDetail(widget.budgetId);
  }

  Future<void> _confirm({
    required String title,
    required String actionLabel,
    required Future<Budget?> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final budget = await action();
    if (!mounted || budget == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Budget ${actionLabel.toLowerCase()}d.')),
    );
  }

  Future<void> _showAdjustment(Budget budget) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showModalBottomSheet<BudgetAdjustmentPayload>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Adjustment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('budgetAdjustmentAmountField'),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('budgetAdjustmentDescriptionField'),
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('saveBudgetAdjustmentButton'),
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount == 0 || descriptionController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  BudgetAdjustmentPayload(
                    amount: amount,
                    description: descriptionController.text,
                  ),
                );
              },
              child: const Text('Save Adjustment'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    descriptionController.dispose();
    if (result == null) return;
    final updated = await ref
        .read(budgetControllerProvider.notifier)
        .addAdjustment(budget.localId, result);
    if (!mounted || updated == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Budget adjustment saved.')));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final date = DateFormat.yMMMd();
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budget.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              StatusChip(status: budget.normalizedStatus),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoGrid(
            items: [
              AppInfoItem(label: 'Department', value: budget.departmentName),
              AppInfoItem(label: 'Period', value: budget.periodType),
              AppInfoItem(
                label: 'Start',
                value: date.format(budget.periodStartDate),
              ),
              AppInfoItem(
                label: 'End',
                value: date.format(budget.periodEndDate),
              ),
              AppInfoItem(
                label: 'Allocated',
                value: currency.format(budget.allocatedAmount),
              ),
              AppInfoItem(
                label: 'Spent',
                value: currency.format(budget.spentAmount),
              ),
              AppInfoItem(
                label: 'Available',
                value: currency.format(budget.availableAmount),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            budget.notes?.trim().isNotEmpty == true
                ? budget.notes!
                : 'No notes.',
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.budget,
    required this.isMutating,
    required this.onActivate,
    required this.onClose,
    required this.onAdjust,
  });

  final Budget budget;
  final bool isMutating;
  final VoidCallback onActivate;
  final VoidCallback onClose;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (budget.isDraft)
            OutlinedButton.icon(
              key: const Key('editBudgetButton'),
              onPressed: isMutating
                  ? null
                  : () => context.push('/budgets/${budget.localId}/edit'),
              icon: const Icon(AppIcons.description),
              label: const Text('Edit'),
            ),
          if (budget.isDraft)
            FilledButton.icon(
              key: const Key('activateBudgetButton'),
              onPressed: isMutating ? null : onActivate,
              icon: const Icon(AppIcons.check),
              label: const Text('Activate'),
            ),
          if (budget.isActive)
            FilledButton.icon(
              key: const Key('adjustBudgetButton'),
              onPressed: isMutating ? null : onAdjust,
              icon: const Icon(AppIcons.plus),
              label: const Text('Add Adjustment'),
            ),
          if (budget.isActive)
            OutlinedButton.icon(
              key: const Key('closeBudgetButton'),
              onPressed: isMutating ? null : onClose,
              icon: const Icon(AppIcons.x),
              label: const Text('Close'),
            ),
          OutlinedButton.icon(
            key: const Key('budgetTransactionsButton'),
            onPressed: () =>
                context.push('/budgets/${budget.localId}/transactions'),
            icon: const Icon(AppIcons.history),
            label: const Text('Transactions'),
          ),
        ],
      ),
    );
  }
}
