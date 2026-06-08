import '../../purchase_request/domain/purchase_request_entity.dart';
import 'purchase_order_entity.dart';

abstract interface class PurchaseOrderRepository {
  Stream<List<PurchaseOrderEntity>> watchByCompany(String companyId);

  Future<List<PurchaseOrderEntity>> getByCompany(String companyId);

  Future<void> createFromRequest({
    required PurchaseRequestEntity request,
    required String createdById,
  });
}
