import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import '../domain/purchase_order_entity.dart';
import '../domain/purchase_order_repository.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  PurchaseOrderRepositoryImpl(this._dao);

  final ProcurementDao _dao;

  @override
  Future<void> createFromRequest({
    required PurchaseRequestEntity request,
    required String createdById,
  }) async {
    final storedRequest = await _dao.getPurchaseRequest(request.localId);
    if (storedRequest == null) {
      throw StateError('Purchase request not found.');
    }
    final items = await _dao.getPurchaseRequestItems(request.localId);
    await _dao.createPurchaseOrderFromRequest(
      request: storedRequest,
      items: items,
      createdById: createdById,
    );
  }

  @override
  Future<List<PurchaseOrderEntity>> getByCompany(String companyId) async {
    final rows = await _dao.getPurchaseOrders(companyId);
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<PurchaseOrderEntity>> watchByCompany(String companyId) {
    return _dao
        .watchPurchaseOrders(companyId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  PurchaseOrderEntity _toEntity(PurchaseOrder row) {
    return PurchaseOrderEntity(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      poNumber: row.poNumber,
      requestLocalId: row.requestLocalId,
      vendorId: row.vendorId,
      createdById: row.createdById,
      status: row.status,
      totalAmount: row.totalAmount,
    );
  }
}
