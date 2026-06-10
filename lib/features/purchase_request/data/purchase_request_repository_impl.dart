import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
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
    required SyncService syncService,
  }) : _dao = dao,
       _api = api,
       _config = config,
       _syncService = syncService;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  @override
  Future<PurchaseRequestPage> getMyRequests(
    PurchaseRequestFilters filters,
  ) async {
    if (_config.useMockApi) {
      final rows = await _dao.getPurchaseRequests('company-demo');
      final all = await Future.wait(rows.map(_toEntity));
      final filtered = _filterLocalRequests(all, filters);
      final start = (filters.page - 1) * filters.limit;
      final pageItems = start >= filtered.length
          ? <PurchaseRequestEntity>[]
          : filtered.skip(start).take(filters.limit).toList();
      return PurchaseRequestPage(
        items: pageItems,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final response = await _api.getMyPurchaseRequests(
      filters.search?.trim().isEmpty == true ? null : filters.search?.trim(),
      filters.status == null
          ? null
          : normalizePurchaseRequestStatus(filters.status!),
      filters.priority == null
          ? null
          : normalizePurchaseRequestPriority(filters.priority!),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );
    return PurchaseRequestPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<PurchaseRequestEntity> saveDraft(
    PurchaseRequestPayload payload,
  ) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      return _createLocalDraft(payload);
    }
    return _fromDto(await _api.createPurchaseRequest(_payloadDto(payload)));
  }

  @override
  Future<PurchaseRequestEntity> updateDraft(
    String id,
    PurchaseRequestPayload payload,
  ) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      return _updateLocalDraft(id, payload);
    }
    return _fromDto(await _api.updatePurchaseRequest(id, _payloadDto(payload)));
  }

  @override
  Future<PurchaseRequestEntity> submit(String id) async {
    if (_config.useMockApi) {
      await _dao.updatePurchaseRequestLifecycleStatus(
        localId: id,
        status: PurchaseRequestStatus.submitted,
        actorId: 'current-user',
        comment: 'Submitted for approval.',
      );
      return (await getById(id))!;
    }
    return _fromDto(await _api.submitPurchaseRequest(id));
  }

  @override
  Future<PurchaseRequestEntity> cancel(String id) async {
    if (_config.useMockApi) {
      await _dao.updatePurchaseRequestLifecycleStatus(
        localId: id,
        status: PurchaseRequestStatus.cancelled,
        actorId: 'current-user',
        comment: 'Cancelled by requester.',
      );
      return (await getById(id))!;
    }
    return _fromDto(await _api.cancelPurchaseRequest(id));
  }

  @override
  Future<List<ApprovalHistoryEntry>> getApprovalHistory(String id) async {
    if (_config.useMockApi) {
      final rows = await _dao.getApprovalHistory(id);
      return rows
          .map(
            (row) => ApprovalHistoryEntry(
              id: row.localId,
              approverName: row.actorId,
              action: row.action,
              status: normalizePurchaseRequestStatus(row.action),
              comment: row.comment,
              createdAt: row.createdAt,
            ),
          )
          .toList();
    }
    final response = await _api.getPurchaseRequestApprovalHistory(id);
    return response.items.map(_historyFromDto).toList();
  }

  @override
  Future<PurchaseRequestEntity> create(CreatePurchaseRequestInput input) {
    return saveDraft(input);
  }

  @override
  Future<List<PurchaseRequestEntity>> getAll() async {
    return (await getMyRequests(const PurchaseRequestFilters())).items;
  }

  @override
  Future<PurchaseRequestEntity?> getById(String localId) async {
    if (_config.useMockApi) {
      final row = await _dao.getPurchaseRequest(localId);
      if (row == null) return null;
      return _toEntity(row);
    }
    return _fromDto(await _api.getPurchaseRequest(localId));
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

  Future<PurchaseRequestEntity> _createLocalDraft(
    PurchaseRequestPayload payload,
  ) async {
    final now = DateTime.now();
    final requestLocalId = _uuid.v4();
    await _dao.insertPurchaseRequestWithItems(
      request: PurchaseRequestsCompanion.insert(
        localId: requestLocalId,
        serverId: Value('mock-$requestLocalId'),
        companyId: 'company-demo',
        requestNumber: _dao.nextPurchaseRequestNumber(),
        title: payload.title.trim(),
        description: Value(payload.description),
        requesterId: 'current-user',
        departmentId: const Value('General'),
        priority: Value(normalizePurchaseRequestPriority(payload.priority)),
        neededDate: Value(payload.neededDate),
        status: const Value(PurchaseRequestStatus.draft),
        totalAmount: Value(payload.totalAmount),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      items: _itemCompanions(
        requestLocalId: requestLocalId,
        companyId: 'company-demo',
        items: payload.items,
        now: now,
      ),
    );
    return (await getById(requestLocalId))!;
  }

  Future<PurchaseRequestEntity> _updateLocalDraft(
    String id,
    PurchaseRequestPayload payload,
  ) async {
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('Purchase request not found.');
    }
    if (!existing.isDraft) {
      throw StateError('Only draft requests can be edited.');
    }

    final now = DateTime.now();
    await _dao.updatePurchaseRequestWithItems(
      requestLocalId: id,
      request: PurchaseRequestsCompanion(
        title: Value(payload.title.trim()),
        description: Value(payload.description),
        priority: Value(normalizePurchaseRequestPriority(payload.priority)),
        neededDate: Value(payload.neededDate),
        totalAmount: Value(payload.totalAmount),
        updatedAt: Value(now),
      ),
      items: _itemCompanions(
        requestLocalId: id,
        companyId: existing.companyId,
        items: payload.items,
        now: now,
      ),
    );
    return (await getById(id))!;
  }

  List<PurchaseRequestItemsCompanion> _itemCompanions({
    required String requestLocalId,
    required String companyId,
    required List<PurchaseRequestItemInput> items,
    required DateTime now,
  }) {
    return [
      for (final item in items)
        PurchaseRequestItemsCompanion.insert(
          localId: _uuid.v4(),
          serverId: Value('mock-${_uuid.v4()}'),
          companyId: companyId,
          requestLocalId: requestLocalId,
          name: item.name.trim(),
          description: Value(item.description),
          quantity: item.quantity.round(),
          unitPrice: item.estimatedUnitPrice,
          lineTotal: item.lineTotal,
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
    ];
  }

  List<PurchaseRequestEntity> _filterLocalRequests(
    List<PurchaseRequestEntity> requests,
    PurchaseRequestFilters filters,
  ) {
    final search = filters.search?.trim().toLowerCase();
    return requests.where((request) {
      if (search != null &&
          search.isNotEmpty &&
          !request.title.toLowerCase().contains(search) &&
          !request.requestNumber.toLowerCase().contains(search)) {
        return false;
      }
      if (filters.status != null &&
          request.normalizedStatus !=
              normalizePurchaseRequestStatus(filters.status!)) {
        return false;
      }
      if (filters.priority != null &&
          request.normalizedPriority !=
              normalizePurchaseRequestPriority(filters.priority!)) {
        return false;
      }
      if (filters.dateFrom != null &&
          request.createdAt.isBefore(filters.dateFrom!)) {
        return false;
      }
      if (filters.dateTo != null &&
          request.createdAt.isAfter(
            filters.dateTo!.add(const Duration(days: 1)),
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  PurchaseRequestPayloadDto _payloadDto(PurchaseRequestPayload payload) {
    return PurchaseRequestPayloadDto(
      title: payload.title.trim(),
      description: payload.description?.trim().isEmpty == true
          ? null
          : payload.description?.trim(),
      priority: normalizePurchaseRequestPriority(payload.priority),
      neededDate: payload.neededDate,
      items: [
        for (final item in payload.items)
          PurchaseRequestItemPayloadDto(
            name: item.name.trim(),
            description: item.description?.trim().isEmpty == true
                ? null
                : item.description?.trim(),
            quantity: item.quantity,
            unit: item.unit.trim().isEmpty ? 'pcs' : item.unit.trim(),
            estimatedUnitPrice: item.estimatedUnitPrice,
          ),
      ],
    );
  }

  void _validatePayload(PurchaseRequestPayload payload) {
    if (payload.title.trim().isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (payload.items.isEmpty) {
      throw ArgumentError('At least one item is required.');
    }
    for (final item in payload.items) {
      if (item.name.trim().isEmpty) {
        throw ArgumentError('Item name is required.');
      }
      if (item.quantity <= 0) {
        throw ArgumentError('Item quantity must be greater than zero.');
      }
      if (item.estimatedUnitPrice < 0) {
        throw ArgumentError('Item price cannot be negative.');
      }
    }
  }

  PurchaseRequestEntity _fromDto(PurchaseRequestDto dto) {
    return PurchaseRequestEntity(
      localId: dto.id,
      serverId: dto.id,
      companyId: 'remote',
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      requestNumber: dto.requestNumber,
      title: dto.title,
      description: dto.description,
      requesterId: dto.requesterId,
      requesterName: dto.requesterName,
      departmentId: null,
      departmentName: dto.departmentName,
      priority: dto.priority,
      neededDate: dto.neededDate,
      status: dto.status,
      totalAmount: dto.estimatedTotal,
      rejectionReason: dto.rejectionReason,
      budgetCheck: dto.budgetCheck == null
          ? null
          : BudgetCheck(
              status: dto.budgetCheck!.status,
              message: dto.budgetCheck!.message,
              availableAmount: dto.budgetCheck!.availableAmount,
            ),
      approvalStatus: dto.approvalStatus,
      items: [
        for (final item in dto.items)
          PurchaseRequestItemEntity(
            localId: item.id,
            serverId: item.id,
            companyId: 'remote',
            syncStatus: SyncStatus.synced,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            lastSyncedAt: dto.updatedAt,
            isDeleted: false,
            requestLocalId: dto.id,
            name: item.name,
            description: item.description,
            quantity: item.quantity,
            unit: item.unit,
            unitPrice: item.estimatedUnitPrice,
            lineTotal: item.totalPrice,
          ),
      ],
    );
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
      requesterName: row.requesterId,
      departmentId: row.departmentId,
      departmentName: row.departmentId,
      priority: normalizePurchaseRequestPriority(row.priority),
      neededDate: row.neededDate,
      status: normalizePurchaseRequestStatus(row.status),
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
      quantity: row.quantity.toDouble(),
      unit: 'pcs',
      unitPrice: row.unitPrice,
      lineTotal: row.lineTotal,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
    );
  }

  ApprovalHistoryEntry _historyFromDto(ApprovalHistoryEntryDto dto) {
    return ApprovalHistoryEntry(
      id: dto.id,
      approverName: dto.approverName,
      action: dto.action,
      status: dto.status,
      comment: dto.comment,
      createdAt: dto.createdAt,
    );
  }

  String? _dateQuery(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }
}
