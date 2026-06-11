import 'package:drift/drift.dart';

import '../api/api_dtos.dart';
import '../api/procurement_api.dart';
import '../config/app_config.dart';
import '../database/app_database.dart' as db;
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

    if (pending.isNotEmpty && !_config.useMockApi) {
      try {
        final pushSummary = await _pushPendingPurchaseRequests(
          companyId,
          pending,
        );
        await _pullLatest(companyId);
        return pushSummary;
      } catch (_) {
        // Older backends/tests may only expose the original create endpoint.
        // Fall through to the legacy one-by-one create sync path.
      }
    }

    for (final request in pending) {
      try {
        final items = await _dao.getPurchaseRequestItems(request.localId);
        final response = _config.useMockApi
            ? PurchaseRequestSyncResponseDto(
                serverId: 'srv-${request.localId}',
                requestNumber: request.requestNumber,
                syncedAt: DateTime.now(),
              )
            : await _api.syncCreatePurchaseRequest(
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

    await _pullLatest(companyId);
    return SyncSummary(
      attempted: pending.length,
      succeeded: succeeded,
      failed: failed,
    );
  }

  Future<SyncSummary> _pushPendingPurchaseRequests(
    String companyId,
    List<dynamic> pending,
  ) async {
    final changes = <SyncChangeDto>[];
    for (final request in pending) {
      final items = await _dao.getPurchaseRequestItems(request.localId);
      changes.add(
        SyncChangeDto(
          entityType: 'purchase_request',
          operation: 'create',
          localId: request.localId,
          data: {
            'localId': request.localId,
            'serverId': request.serverId,
            'companyId': request.companyId,
            'title': request.title,
            'description': request.description,
            'priority': request.priority,
            'neededDate': request.neededDate
                ?.toIso8601String()
                .split('T')
                .first,
            'totalAmount': request.totalAmount,
            'items': [
              for (final item in items)
                {
                  'localId': item.localId,
                  'name': item.name,
                  'description': item.description,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'lineTotal': item.lineTotal,
                },
            ],
          },
        ),
      );
    }

    final response = await _api.pushSync(SyncPushRequestDto(changes: changes));
    var succeeded = 0;
    var failed = 0;
    for (final result in response.results) {
      final normalizedStatus = result.status.trim().toLowerCase();
      if (normalizedStatus == 'synced' || normalizedStatus == 'success') {
        await _dao.markPurchaseRequestSynced(
          localId: result.localId,
          serverId: result.serverId,
          requestNumber: result.serverId.isEmpty
              ? result.localId
              : result.serverId,
          syncedAt: response.syncedAt,
          serverUpdatedAt: result.serverUpdatedAt,
        );
        await _dao.addSyncLog(
          companyId: companyId,
          entityType: 'purchase_request',
          entityLocalId: result.localId,
          action: 'sync_push',
          status: SyncStatus.synced.storageValue,
          message: 'Purchase request synced.',
        );
        succeeded++;
      } else {
        if (normalizedStatus == 'conflict') {
          await _dao.markPurchaseRequestConflict(
            localId: result.localId,
            message:
                result.message ?? 'Server data changed. Pull latest and retry.',
          );
        } else {
          await _dao.markPurchaseRequestSyncFailed(
            localId: result.localId,
            message: result.message ?? 'Sync failed.',
          );
        }
        failed++;
      }
    }

    return SyncSummary(
      attempted: pending.length,
      succeeded: succeeded,
      failed: failed + (pending.length - response.results.length),
    );
  }

  Future<void> _pullLatest(String companyId) async {
    if (_config.useMockApi) return;
    try {
      final lastSyncedAt = await _dao.getLastSyncAt(
        companyId: companyId,
        scope: 'purchase_requests',
      );
      final response = await _api.pullSync(_rfc3339(lastSyncedAt));
      for (final request in response.purchaseRequests) {
        await _upsertPulledPurchaseRequest(
          companyId,
          request,
          response.syncedAt,
        );
      }
      await _dao.setLastSyncAt(
        companyId: companyId,
        scope: 'purchase_requests',
        syncedAt: response.syncedAt,
      );
    } catch (_) {
      // Pull refresh is best-effort; push results already updated local state.
    }
  }

  String? _rfc3339(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }

  Future<void> _upsertPulledPurchaseRequest(
    String companyId,
    PurchaseRequestDto request,
    DateTime syncedAt,
  ) async {
    if (request.id.isEmpty) return;
    final existing = await _dao.getPurchaseRequestByServerId(request.id);
    if (existing != null &&
        existing.syncStatus != SyncStatus.synced.storageValue &&
        existing.updatedAt.isAfter(request.updatedAt)) {
      await _dao.markPurchaseRequestConflict(
        localId: existing.localId,
        message: 'Server data changed after local edit.',
      );
      return;
    }

    final localId = existing?.localId ?? request.id;
    final requestCompanion = db.PurchaseRequestsCompanion.insert(
      localId: localId,
      serverId: Value(request.id),
      companyId: companyId,
      requestNumber: request.requestNumber.isEmpty
          ? 'PR-${request.id}'
          : request.requestNumber,
      title: request.title,
      description: Value(request.description),
      requesterId: request.requesterId,
      departmentId: Value(request.departmentName),
      priority: Value(request.priority),
      neededDate: Value(request.neededDate),
      status: Value(request.status),
      totalAmount: Value(request.estimatedTotal),
      syncStatus: Value(SyncStatus.synced.storageValue),
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      lastSyncedAt: Value(syncedAt),
      lastKnownServerUpdatedAt: Value(request.updatedAt),
      lastSyncError: const Value(null),
      isDirty: const Value(false),
    );
    final itemCompanions = [
      for (final item in request.items)
        db.PurchaseRequestItemsCompanion.insert(
          localId: item.id.isEmpty ? '$localId-${item.name}' : item.id,
          serverId: item.id.isEmpty ? const Value.absent() : Value(item.id),
          companyId: companyId,
          requestLocalId: localId,
          name: item.name,
          description: Value(item.description),
          quantity: item.quantity.round() <= 0 ? 1 : item.quantity.round(),
          unitPrice: item.estimatedUnitPrice,
          lineTotal: item.totalPrice,
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: request.createdAt,
          updatedAt: request.updatedAt,
          lastSyncedAt: Value(syncedAt),
          lastKnownServerUpdatedAt: Value(request.updatedAt),
          lastSyncError: const Value(null),
          isDirty: const Value(false),
        ),
    ];

    if (existing == null) {
      await _dao.insertPurchaseRequestWithItems(
        request: requestCompanion,
        items: itemCompanions,
      );
    } else {
      await _dao.updatePurchaseRequestWithItems(
        requestLocalId: existing.localId,
        request: requestCompanion,
        items: itemCompanions,
      );
    }
  }
}
