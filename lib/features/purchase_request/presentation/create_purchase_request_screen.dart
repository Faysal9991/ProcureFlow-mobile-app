import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/purchase_request_entity.dart';
import 'purchase_request_providers.dart';

class CreatePurchaseRequestScreen extends ConsumerStatefulWidget {
  const CreatePurchaseRequestScreen({super.key});

  @override
  ConsumerState<CreatePurchaseRequestScreen> createState() {
    return _CreatePurchaseRequestScreenState();
  }
}

class _CreatePurchaseRequestScreenState
    extends ConsumerState<CreatePurchaseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_ItemDraft> _items = [];
  DateTime? _neededDate;
  String _priority = 'medium';
  var _forceOffline = false;
  var _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPurchaseRequestControllerProvider);
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final total = _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return AppScaffold(
      title: 'Create Purchase Request',
      child: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          type: StepperType.vertical,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: isLast
                          ? const Key('createRequestSubmitButton')
                          : const Key('createRequestNextButton'),
                      onPressed: state.isLoading
                          ? null
                          : isLast
                          ? _submit
                          : () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _currentStep = 1);
                              }
                            },
                      icon: state.isLoading && isLast
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isLast ? AppIcons.send : AppIcons.arrowForward,
                            ),
                      label: Text(
                        isLast ? 'Submit request' : 'Continue to items',
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Request details'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    key: const Key('requestTitleField'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(AppIcons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(AppIcons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(AppIcons.flag),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: AppRadius.controlBorder,
                    onTap: _selectNeededDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Needed date',
                        prefixIcon: Icon(AppIcons.calendar),
                      ),
                      child: Text(
                        _neededDate == null
                            ? 'Select date'
                            : DateFormat.yMMMd().format(_neededDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Queue as offline request'),
                    subtitle: const Text(
                      'Saves locally with pending_create status.',
                    ),
                    value: _forceOffline,
                    onChanged: (value) => setState(() => _forceOffline = value),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Items and estimate'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Items',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Add item',
                        onPressed: _addItem,
                        icon: const Icon(AppIcons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < _items.length; index++)
                    _ItemEditor(
                      item: _items[index],
                      index: index,
                      onChanged: () => setState(() {}),
                      onRemove: _items.length == 1
                          ? null
                          : () => setState(
                              () => _items.removeAt(index).dispose(),
                            ),
                    ),
                  const SizedBox(height: 12),
                  AppListTileCard(
                    title: const Text('Total estimate'),
                    trailing: Text(
                      currency.format(total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectNeededDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _neededDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _neededDate = selected);
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemDraft()));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      return;
    }
    final request = await ref
        .read(createPurchaseRequestControllerProvider.notifier)
        .create(
          CreatePurchaseRequestInput(
            companyId: session.companyId,
            requesterId: session.userId,
            title: _titleController.text,
            priority: _priority,
            neededDate: _neededDate,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            forceOffline: _forceOffline,
            items: _items
                .map(
                  (item) => PurchaseRequestItemInput(
                    name: item.nameController.text,
                    description: item.descriptionController.text.trim().isEmpty
                        ? null
                        : item.descriptionController.text.trim(),
                    quantity: int.parse(item.quantityController.text),
                    unitPrice: double.parse(item.unitPriceController.text),
                  ),
                )
                .toList(),
          ),
        );
    if (mounted && request != null) {
      context.replace('/requests/${request.localId}');
    }
  }
}

class _ItemEditor extends StatelessWidget {
  const _ItemEditor({
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final _ItemDraft item;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(AppIcons.item),
        title: Text(
          item.nameController.text.trim().isEmpty
              ? 'Item ${index + 1}'
              : item.nameController.text.trim(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          'Estimated ${NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0).format(item.lineTotal)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove item',
              onPressed: onRemove,
              icon: const Icon(AppIcons.trash),
            ),
            const Icon(AppIcons.chevronDown),
          ],
        ),
        children: [
          TextFormField(
            controller: item.nameController,
            decoration: const InputDecoration(labelText: 'Item name'),
            onChanged: (_) => onChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Item name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.quantityController,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity <= 0) {
                      return 'Invalid qty';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: item.unitPriceController,
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => onChanged(),
                  validator: (value) {
                    final price = double.tryParse(value ?? '');
                    if (price == null || price < 0) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final unitPriceController = TextEditingController(text: '0');

  double get lineTotal {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0;
    return quantity * unitPrice;
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
