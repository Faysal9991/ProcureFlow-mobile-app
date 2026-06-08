import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/sync/sync_summary.dart';
import '../domain/purchase_request_entity.dart';
import '../domain/purchase_request_repository.dart';

class PurchaseRequestRepositoryImpl implements PurchaseRequestRepository {
  PurchaseRequestRepositoryImpl({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
    required ConnectivityService connectivity,
    required SyncService syncService,
  }) : _dao = dao,
       _api = api,
       _config = config,
       _connectivity = connectivity,
       _syncService = syncService;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  @override
  Future<PurchaseRequestEntity> create(CreatePurchaseRequestInput input) async {
    if (input.title.trim().isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (input.items.isEmpty) {
      throw ArgumentError('At least one item is required.');
    }

    final now = DateTime.now();
    final requestLocalId = _uuid.v4();
    final itemLocalIds = input.items.map((_) => _uuid.v4()).toList();
    final isOnline = !input.forceOffline && await _connectivity.isOnline;
    var syncStatus = isOnline ? SyncStatus.synced : SyncStatus.pendingCreate;
    var serverId = isOnline && _config.useMockApi
        ? 'mock-$requestLocalId'
        : null;
    var lastSyncedAt = isOnline && _config.useMockApi ? now : null;
    var requestNumber = _dao.nextPurchaseRequestNumber();

    if (isOnline && !_config.useMockApi) {
      try {
        final response = await _api.createPurchaseRequest(
          PurchaseRequestSyncRequestDto(
            localId: requestLocalId,
            companyId: input.companyId,
            title: input.title.trim(),
            description: input.description,
            priority: input.priority,
            neededDate: input.neededDate,
            totalAmount: input.totalAmount,
            items: [
              for (var index = 0; index < input.items.length; index++)
                PurchaseRequestItemSyncDto(
                  localId: itemLocalIds[index],
                  name: input.items[index].name.trim(),
                  description: input.items[index].description,
                  quantity: input.items[index].quantity,
                  unitPrice: input.items[index].unitPrice,
                  lineTotal: input.items[index].lineTotal,
                ),
            ],
          ),
        );
        serverId = response.serverId;
        requestNumber = response.requestNumber;
        lastSyncedAt = response.syncedAt;
      } on Exception {
        syncStatus = SyncStatus.pendingCreate;
        serverId = null;
        lastSyncedAt = null;
      }
    }

    final request = PurchaseRequestsCompanion.insert(
      localId: requestLocalId,
      serverId: Value(serverId),
      companyId: input.companyId,
      requestNumber: requestNumber,
      title: input.title.trim(),
      description: Value(input.description),
      requesterId: input.requesterId,
      departmentId: const Value.absent(),
      priority: Value(input.priority),
      neededDate: Value(input.neededDate),
      status: const Value('submitted'),
      totalAmount: Value(input.totalAmount),
      syncStatus: Value(syncStatus.storageValue),
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: Value(lastSyncedAt),
    );
    final items = [
      for (var index = 0; index < input.items.length; index++)
        PurchaseRequestItemsCompanion.insert(
          localId: itemLocalIds[index],
          serverId: Value(
            syncStatus == SyncStatus.synced
                ? 'mock-${itemLocalIds[index]}'
                : null,
          ),
          companyId: input.companyId,
          requestLocalId: requestLocalId,
          name: input.items[index].name.trim(),
          description: Value(input.items[index].description),
          quantity: input.items[index].quantity,
          unitPrice: input.items[index].unitPrice,
          lineTotal: input.items[index].lineTotal,
          syncStatus: Value(syncStatus.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(lastSyncedAt),
        ),
    ];
    await _dao.insertPurchaseRequestWithItems(request: request, items: items);
    final entity = await getById(requestLocalId);
    return entity!;
  }

  @override
  Future<List<PurchaseRequestEntity>> getAll() {
    return _getForCompany('company-demo');
  }

  Future<List<PurchaseRequestEntity>> _getForCompany(String companyId) async {
    final rows = await _dao.getPurchaseRequests(companyId);
    return Future.wait(rows.map(_toEntity));
  }

  @override
  Future<PurchaseRequestEntity?> getById(String localId) async {
    final row = await _dao.getPurchaseRequest(localId);
    if (row == null) {
      return null;
    }
    return _toEntity(row);
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchByCompany(String companyId) {
    return _dao
        .watchPurchaseRequests(companyId)
        .asyncMap((rows) => Future.wait(rows.map(_toEntity)));
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchApprovalInbox(String companyId) {
    return _dao
        .watchApprovalInbox(companyId)
        .asyncMap((rows) => Future.wait(rows.map(_toEntity)));
  }

  @override
  Future<void> approve({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) {
    return _dao.updatePurchaseRequestStatus(
      requestLocalId: requestLocalId,
      actorId: actorId,
      companyId: companyId,
      action: 'approved',
      comment: comment,
    );
  }

  @override
  Future<void> reject({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) {
    return _dao.updatePurchaseRequestStatus(
      requestLocalId: requestLocalId,
      actorId: actorId,
      companyId: companyId,
      action: 'rejected',
      comment: comment,
    );
  }

  @override
  Future<SyncSummary> syncPending() {
    return _syncService.syncPendingPurchaseRequests('company-demo');
  }

  Future<PurchaseRequestEntity> _toEntity(PurchaseRequest row) async {
    final items = await _dao.getPurchaseRequestItems(row.localId);
    return PurchaseRequestEntity(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      requestNumber: row.requestNumber,
      title: row.title,
      description: row.description,
      requesterId: row.requesterId,
      departmentId: row.departmentId,
      priority: row.priority,
      neededDate: row.neededDate,
      status: row.status,
      totalAmount: row.totalAmount,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      items: items.map(_itemToEntity).toList(),
    );
  }

  PurchaseRequestItemEntity _itemToEntity(PurchaseRequestItem row) {
    return PurchaseRequestItemEntity(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      requestLocalId: row.requestLocalId,
      name: row.name,
      description: row.description,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      lineTotal: row.lineTotal,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
    );
  }
}
