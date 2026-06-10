import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/purchase_order_entity.dart';
import '../domain/purchase_order_repository.dart';
import 'purchase_order_providers.dart';
import 'purchase_order_state.dart';

final purchaseOrderControllerProvider =
    StateNotifierProvider.autoDispose<
      PurchaseOrderController,
      PurchaseOrderState
    >((ref) {
      return PurchaseOrderController(
        ref.watch(purchaseOrderRepositoryProvider),
      );
    });

class PurchaseOrderController extends StateNotifier<PurchaseOrderState> {
  PurchaseOrderController(this._repository) : super(const PurchaseOrderState());

  final PurchaseOrderRepository _repository;

  Future<void> loadList([PurchaseOrderFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getPurchaseOrders(nextFilters);
      state = state.copyWith(
        isLoading: false,
        orders: page.items,
        total: page.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadDetail(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelectedOrder: true,
    );
    try {
      final order = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedOrder: order);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<PurchaseOrder?> create(CreatePurchaseOrderPayload payload) {
    return _mutate(() => _repository.create(payload));
  }

  Future<PurchaseOrder?> update(String id, UpdatePurchaseOrderPayload payload) {
    return _mutate(() => _repository.update(id, payload));
  }

  Future<PurchaseOrder?> issue(String id) {
    return _mutate(() => _repository.issue(id));
  }

  Future<PurchaseOrder?> receive(String id) {
    return _mutate(() => _repository.receive(id));
  }

  Future<PurchaseOrder?> cancel(String id) {
    return _mutate(() => _repository.cancel(id));
  }

  Future<PurchaseOrder?> close(String id) {
    return _mutate(() => _repository.close(id));
  }

  Future<PurchaseOrder?> _mutate(
    Future<PurchaseOrder> Function() action,
  ) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final order = await action();
      final updatedOrders = [
        for (final item in state.orders)
          if (item.localId == order.localId || item.serverId == order.serverId)
            order
          else
            item,
      ];
      if (!updatedOrders.any(
        (item) =>
            item.localId == order.localId || item.serverId == order.serverId,
      )) {
        updatedOrders.insert(0, order);
      }
      state = state.copyWith(
        isMutating: false,
        selectedOrder: order,
        orders: updatedOrders,
      );
      return order;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('Invalid argument(s): ')) {
      return message.substring('Invalid argument(s): '.length);
    }
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    return message;
  }
}
