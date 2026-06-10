import 'purchase_order_entity.dart';

abstract interface class PurchaseOrderRepository {
  Future<PurchaseOrderPage> getPurchaseOrders(PurchaseOrderFilters filters);

  Future<PurchaseOrder> create(CreatePurchaseOrderPayload payload);

  Future<PurchaseOrder?> getById(String id);

  Future<PurchaseOrder> update(String id, UpdatePurchaseOrderPayload payload);

  Future<PurchaseOrder> issue(String id);

  Future<PurchaseOrder> receive(String id);

  Future<PurchaseOrder> cancel(String id);

  Future<PurchaseOrder> close(String id);
}
