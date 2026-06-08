import '../api/api_dtos.dart';
import '../api/procurement_api.dart';
import '../config/app_config.dart';
import '../database/daos/procurement_dao.dart';
import 'sync_status.dart';
import 'sync_summary.dart';

class SyncService {
  SyncService({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
  }) : _dao = dao,
       _api = api,
       _config = config;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;

  Future<SyncSummary> syncPendingPurchaseRequests(String companyId) async {
    final pending = await _dao.getPendingPurchaseRequestCreates(companyId);
    var succeeded = 0;
    var failed = 0;

    for (final request in pending) {
      try {
        final items = await _dao.getPurchaseRequestItems(request.localId);
        final response = _config.useMockApi
            ? PurchaseRequestSyncResponseDto(
                serverId: 'srv-${request.localId}',
                requestNumber: request.requestNumber,
                syncedAt: DateTime.now(),
              )
            : await _api.createPurchaseRequest(
                PurchaseRequestSyncRequestDto(
                  localId: request.localId,
                  companyId: request.companyId,
                  title: request.title,
                  description: request.description,
                  priority: request.priority,
                  neededDate: request.neededDate,
                  totalAmount: request.totalAmount,
                  items: items
                      .map(
                        (item) => PurchaseRequestItemSyncDto(
                          localId: item.localId,
                          name: item.name,
                          description: item.description,
                          quantity: item.quantity,
                          unitPrice: item.unitPrice,
                          lineTotal: item.lineTotal,
                        ),
                      )
                      .toList(),
                ),
              );
        await _dao.markPurchaseRequestSynced(
          localId: request.localId,
          serverId: response.serverId,
          requestNumber: response.requestNumber,
          syncedAt: response.syncedAt,
        );
        await _dao.addSyncLog(
          companyId: companyId,
          entityType: 'purchase_request',
          entityLocalId: request.localId,
          action: 'create',
          status: SyncStatus.synced.storageValue,
          message: 'Purchase request synced.',
        );
        succeeded++;
      } on Exception catch (error) {
        await _dao.markPurchaseRequestSyncFailed(
          localId: request.localId,
          message: error.toString(),
        );
        failed++;
      }
    }

    return SyncSummary(
      attempted: pending.length,
      succeeded: succeeded,
      failed: failed,
    );
  }
}
