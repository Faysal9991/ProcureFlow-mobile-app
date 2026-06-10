import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/budget_entity.dart';
import 'budget_controller.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departmentController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _periodType = BudgetPeriodType.monthly;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _seeded = false;

  bool get _isEdit => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      Future.microtask(
        () => ref
            .read(budgetControllerProvider.notifier)
            .loadDetail(widget.budgetId!),
      );
    }
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetControllerProvider);
    final budget = state.selectedBudget;
    if (_isEdit && !_seeded && budget != null) {
      _seeded = true;
      _departmentController.text = budget.departmentId;
      _nameController.text = budget.name;
      _amountController.text = budget.allocatedAmount.toStringAsFixed(0);
      _notesController.text = budget.notes ?? '';
      _periodType = budget.periodType;
      _startDate = budget.periodStartDate;
      _endDate = budget.periodEndDate;
    }

    return AppScaffold(
      title: _isEdit ? 'Edit Budget' : 'New Budget',
      child: AppScreenListView(
        children: [
          if (_isEdit && state.isLoading && budget == null)
            const AppSectionCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_isEdit && budget != null && !budget.isDraft)
            const AppEmptyCard(message: 'Only draft budgets can be edited.')
          else
            AppSectionCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('budgetDepartmentField'),
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department ID',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('budgetNameField'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Name',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('budgetPeriodTypeField'),
                      initialValue: _periodType,
                      decoration: const InputDecoration(
                        labelText: 'Period Type',
                      ),
                      items: [
                        for (final type in BudgetPeriodType.values)
                          DropdownMenuItem(value: type, child: Text(type)),
                      ],
                      onChanged: (value) =>
                          setState(() => _periodType = value ?? _periodType),
                    ),
                    const SizedBox(height: 12),
                    _DateButton(
                      key: const Key('budgetStartDateButton'),
                      label: 'Period Start',
                      value: _startDate,
                      onPressed: () => _pickDate(isStart: true),
                    ),
                    const SizedBox(height: 10),
                    _DateButton(
                      key: const Key('budgetEndDateButton'),
                      label: 'Period End',
                      value: _endDate,
                      onPressed: () => _pickDate(isStart: false),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('budgetAllocatedAmountField'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Allocated Amount',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter an amount greater than zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isMutating
                                ? null
                                : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('saveBudgetButton'),
                            onPressed: state.isMutating ? null : _save,
                            child: Text(_isEdit ? 'Save' : 'Create'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            AppEmptyCard(message: state.errorMessage!),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period start and end are required.')),
      );
      return;
    }
    final payload = BudgetPayload(
      departmentId: _departmentController.text,
      name: _nameController.text,
      periodType: _periodType,
      periodStartDate: _startDate,
      periodEndDate: _endDate,
      allocatedAmount: double.tryParse(_amountController.text) ?? 0,
      notes: _notesController.text,
    );
    final result = _isEdit
        ? await ref
              .read(budgetControllerProvider.notifier)
              .update(widget.budgetId!, payload)
        : await ref.read(budgetControllerProvider.notifier).create(payload);
    if (!mounted || result == null) return;
    ref.invalidate(dashboardControllerProvider);
    context.go('/budgets/${result.localId}');
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required.';
    return null;
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.calendar),
      label: Text(
        value == null ? label : '$label: ${DateFormat.yMMMd().format(value!)}',
      ),
    );
  }
}
