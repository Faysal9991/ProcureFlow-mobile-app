import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/purchase_order_entity.dart';
import 'purchase_order_controller.dart';

class PurchaseOrderEditScreen extends ConsumerStatefulWidget {
  const PurchaseOrderEditScreen({
    super.key,
    required this.orderId,
    this.showBottomNavigation = true,
  });

  final String orderId;
  final bool showBottomNavigation;

  @override
  ConsumerState<PurchaseOrderEditScreen> createState() =>
      _PurchaseOrderEditScreenState();
}

class _PurchaseOrderEditScreenState
    extends ConsumerState<PurchaseOrderEditScreen> {
  final _notesController = TextEditingController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(purchaseOrderControllerProvider.notifier)
          .loadDetail(widget.orderId),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderControllerProvider);
    final order = state.selectedOrder;
    if (!_hydrated && order != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hydrated) _hydrate(order);
      });
    }

    return AppScaffold(
      title: 'Edit Purchase Order',
      showBottomNavigation: widget.showBottomNavigation,
      child: Builder(
        builder: (context) {
          if (state.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && order == null) {
            return AppScreenListView(
              children: [AppEmptyCard(message: state.errorMessage!)],
            );
          }
          if (order == null) {
            return const AppScreenListView(
              children: [AppEmptyCard(message: 'Purchase order not found.')],
            );
          }
          if (!order.canEdit) {
            return const AppScreenListView(
              children: [
                AppEmptyCard(
                  message: 'Only draft purchase orders can be edited.',
                ),
              ],
            );
          }
          return _PurchaseOrderEditForm(
            order: order,
            notesController: _notesController,
            isMutating: state.isMutating,
            errorMessage: state.errorMessage,
            onCancel: _cancel,
            onSave: () => _save(order),
          );
        },
      ),
    );
  }

  void _hydrate(PurchaseOrder order) {
    _notesController.text = order.notes ?? '';
    _hydrated = true;
  }

  Future<void> _save(PurchaseOrder order) async {
    final updated = await ref
        .read(purchaseOrderControllerProvider.notifier)
        .update(
          order.localId,
          UpdatePurchaseOrderPayload(
            notes: _blankToNull(_notesController.text),
          ),
        );
    if (!mounted || updated == null) return;
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Purchase order updated.')));
    context.replace('/purchase-orders/${updated.localId}');
  }

  void _cancel() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/purchase-orders/${widget.orderId}');
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _PurchaseOrderEditForm extends StatelessWidget {
  const _PurchaseOrderEditForm({
    required this.order,
    required this.notesController,
    required this.isMutating,
    required this.errorMessage,
    required this.onCancel,
    required this.onSave,
  });

  final PurchaseOrder order;
  final TextEditingController notesController;
  final bool isMutating;
  final String? errorMessage;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppScreenListView(
      children: [
        AppSectionCard(
          padding: AppInsets.cardLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                order.poNumber.isEmpty ? 'Purchase Order' : order.poNumber,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                key: const Key('editPurchaseOrderNotesField'),
                controller: notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(AppIcons.description),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(onPressed: onCancel, child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(
                    key: const Key('savePurchaseOrderNotesButton'),
                    onPressed: isMutating ? null : onSave,
                    icon: const Icon(AppIcons.check),
                    label: Text(isMutating ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
