import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/purchase_request_entity.dart';
import 'purchase_request_controller.dart';

class PurchaseRequestFormScreen extends ConsumerStatefulWidget {
  const PurchaseRequestFormScreen({
    super.key,
    this.requestId,
    this.showBottomNavigation = true,
  });

  final String? requestId;
  final bool showBottomNavigation;

  bool get isEditMode => requestId != null;

  @override
  ConsumerState<PurchaseRequestFormScreen> createState() {
    return _PurchaseRequestFormScreenState();
  }
}

class _PurchaseRequestFormScreenState
    extends ConsumerState<PurchaseRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_ItemDraft> _items = [];

  DateTime? _neededDate;
  String _priority = PurchaseRequestPriority.normal;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      Future.microtask(
        () => ref
            .read(purchaseRequestControllerProvider.notifier)
            .loadDetail(widget.requestId!),
      );
    } else {
      _addItem();
    }
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
    ref.listen(purchaseRequestControllerProvider, (previous, next) {
      final request = next.selectedRequest;
      if (widget.isEditMode && !_hydrated && request != null) {
        _hydrate(request);
      }
    });

    final state = ref.watch(purchaseRequestControllerProvider);
    final request = state.selectedRequest;
    final session = ref.watch(authControllerProvider).session;
    final isEdit = widget.isEditMode;
    final canCreate = PermissionPolicy.canCreatePurchaseRequest(session);
    final canEdit = !isEdit
        ? canCreate
        : request != null &&
              PermissionPolicy.canEditPurchaseRequest(
                session: session,
                requesterId: request.requesterId,
                status: request.normalizedStatus,
              );

    if (isEdit && !_hydrated && request != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hydrated) {
          _hydrate(request);
        }
      });
    }

    return AppScaffold(
      title: isEdit ? 'Edit Request' : 'New Request',
      showBottomNavigation: widget.showBottomNavigation,
      child: Builder(
        builder: (context) {
          if (state.isLoading && isEdit && request == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (isEdit && request == null && state.errorMessage != null) {
            return AppScreenListView(
              children: [AppEmptyCard(message: state.errorMessage!)],
            );
          }
          if (!canEdit) {
            return AppScreenListView(
              children: [
                AppEmptyCard(
                  message: isEdit
                      ? 'You can only edit your own draft requests.'
                      : 'You do not have permission to create purchase requests.',
                ),
              ],
            );
          }
          return _FormBody(
            formKey: _formKey,
            titleController: _titleController,
            descriptionController: _descriptionController,
            items: _items,
            priority: _priority,
            neededDate: _neededDate,
            isEdit: isEdit,
            isMutating: state.isMutating,
            errorMessage: state.errorMessage,
            onPriorityChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
            onPickNeededDate: _selectNeededDate,
            onAddItem: _addItem,
            onRemoveItem: (index) {
              setState(() => _items.removeAt(index).dispose());
            },
            onItemChanged: () => setState(() {}),
            onSaveDraft: _saveDraft,
            onSubmit: _submit,
          );
        },
      ),
    );
  }

  void _hydrate(PurchaseRequestEntity request) {
    _titleController.text = request.title;
    _descriptionController.text = request.description ?? '';
    _priority = request.normalizedPriority;
    _neededDate = request.neededDate;
    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(request.items.map(_ItemDraft.fromEntity));
    if (_items.isEmpty) {
      _items.add(_ItemDraft());
    }
    _hydrated = true;
    if (mounted) setState(() {});
  }

  Future<void> _selectNeededDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _neededDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() => _neededDate = selected);
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemDraft()));
  }

  PurchaseRequestPayload _payload() {
    return PurchaseRequestPayload(
      title: _titleController.text,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      neededDate: _neededDate,
      items: [
        for (final item in _items)
          PurchaseRequestItemInput(
            name: item.nameController.text,
            description: item.descriptionController.text.trim().isEmpty
                ? null
                : item.descriptionController.text.trim(),
            quantity: double.tryParse(item.quantityController.text) ?? 0,
            unit: item.unitController.text.trim().isEmpty
                ? 'pcs'
                : item.unitController.text.trim(),
            estimatedUnitPrice:
                double.tryParse(item.unitPriceController.text) ?? 0,
          ),
      ],
    );
  }

  Future<void> _saveDraft() async {
    if (!_hasFormPermission) {
      _showDeniedSnackBar();
      return;
    }
    if (!_validate()) return;
    final request = await ref
        .read(purchaseRequestControllerProvider.notifier)
        .saveDraft(payload: _payload(), id: widget.requestId);
    if (!mounted || request == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
    context.replace('/requests/${request.localId}');
  }

  Future<void> _submit() async {
    if (!_hasFormPermission) {
      _showDeniedSnackBar();
      return;
    }
    if (!_validate()) return;
    final controller = ref.read(purchaseRequestControllerProvider.notifier);
    final request = widget.requestId == null
        ? await controller.createAndSubmit(_payload())
        : await controller.submit(widget.requestId!);
    if (!mounted || request == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request submitted.')));
    context.replace('/requests/${request.localId}');
  }

  bool _validate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item.')));
      return false;
    }
    return true;
  }

  bool get _hasFormPermission {
    final session = ref.read(authControllerProvider).session;
    if (!widget.isEditMode) {
      return PermissionPolicy.canCreatePurchaseRequest(session);
    }
    final request = ref.read(purchaseRequestControllerProvider).selectedRequest;
    if (request == null) return false;
    return PermissionPolicy.canEditPurchaseRequest(
      session: session,
      requesterId: request.requesterId,
      status: request.normalizedStatus,
    );
  }

  void _showDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission for this action.'),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.items,
    required this.priority,
    required this.neededDate,
    required this.isEdit,
    required this.isMutating,
    required this.errorMessage,
    required this.onPriorityChanged,
    required this.onPickNeededDate,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onItemChanged,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<_ItemDraft> items;
  final String priority;
  final DateTime? neededDate;
  final bool isEdit;
  final bool isMutating;
  final String? errorMessage;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onPickNeededDate;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onItemChanged;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
    final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final dateFormat = DateFormat.yMMMd();

    return Form(
      key: formKey,
      child: AppScreenListView(
        children: [
          AppSectionCard(
            padding: AppInsets.cardLarge,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('requestTitleField'),
                  controller: titleController,
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
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(AppIcons.description),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(AppIcons.flag),
                  ),
                  items: const [
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
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: AppRadius.controlBorder,
                  onTap: onPickNeededDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Needed date',
                      prefixIcon: Icon(AppIcons.calendar),
                    ),
                    child: Text(
                      neededDate == null
                          ? 'Select date'
                          : dateFormat.format(neededDate!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                onPressed: onAddItem,
                icon: const Icon(AppIcons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < items.length; index++)
            _ItemEditor(
              item: items[index],
              index: index,
              onChanged: onItemChanged,
              onRemove: items.length == 1 ? null : () => onRemoveItem(index),
            ),
          AppListTileCard(
            title: const Text('Estimated Total'),
            trailing: Text(
              currency.format(total),
              key: const Key('requestTotalText'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            AppEmptyCard(message: errorMessage!),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('saveDraftButton'),
                  onPressed: isMutating ? null : onSaveDraft,
                  icon: const Icon(AppIcons.check),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('submitRequestButton'),
                  onPressed: isMutating ? null : onSubmit,
                  icon: isMutating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.send),
                  label: const Text('Submit'),
                ),
              ),
            ],
          ),
          if (isEdit) ...[
            const SizedBox(height: 10),
            const StatusChip(status: PurchaseRequestStatus.draft),
          ],
        ],
      ),
    );
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
    final currency = NumberFormat.currency(symbol: 'BDT ', decimalDigits: 0);
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Total ${currency.format(item.lineTotal)}'),
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
            key: Key('itemNameField-$index'),
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
                  key: Key('itemQuantityField-$index'),
                  controller: item.quantityController,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => onChanged(),
                  validator: (value) {
                    final quantity = double.tryParse(value ?? '');
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
                  key: Key('itemUnitField-$index'),
                  controller: item.unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: Key('itemUnitPriceField-$index'),
            controller: item.unitPriceController,
            decoration: const InputDecoration(
              labelText: 'Estimated unit price',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onChanged(),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              if (price == null || price < 0) {
                return 'Invalid price';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  _ItemDraft();

  _ItemDraft.fromEntity(PurchaseRequestItemEntity item) {
    nameController.text = item.name;
    descriptionController.text = item.description ?? '';
    quantityController.text = _compactNumber(item.quantity);
    unitController.text = item.unit;
    unitPriceController.text = _compactNumber(item.unitPrice);
  }

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final unitController = TextEditingController(text: 'pcs');
  final unitPriceController = TextEditingController(text: '0');

  double get lineTotal {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0;
    return quantity * unitPrice;
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitController.dispose();
    unitPriceController.dispose();
  }

  String _compactNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
