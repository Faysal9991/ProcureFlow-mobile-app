import 'package:equatable/equatable.dart';

import '../domain/purchase_order_entity.dart';

class PurchaseOrderState extends Equatable {
  const PurchaseOrderState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const PurchaseOrderFilters(),
    this.orders = const [],
    this.selectedOrder,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final PurchaseOrderFilters filters;
  final List<PurchaseOrder> orders;
  final PurchaseOrder? selectedOrder;
  final int total;

  PurchaseOrderState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    PurchaseOrderFilters? filters,
    List<PurchaseOrder>? orders,
    PurchaseOrder? selectedOrder,
    bool clearSelectedOrder = false,
    int? total,
  }) {
    return PurchaseOrderState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      orders: orders ?? this.orders,
      selectedOrder: clearSelectedOrder
          ? null
          : selectedOrder ?? this.selectedOrder,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    orders,
    selectedOrder,
    total,
  ];
}
