import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/purchase_order_entity.dart';
import '../domain/purchase_order_repository.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  PurchaseOrderRepositoryImpl({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
  }) : _dao = dao,
       _api = api,
       _config = config;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;

  @override
  Future<PurchaseOrderPage> getPurchaseOrders(
    PurchaseOrderFilters filters,
  ) async {
    if (_config.useMockApi) {
      final rows = await _dao.getPurchaseOrders('company-demo');
      final all = await Future.wait(rows.map(_toEntity));
      final filtered = all.where((order) => _matches(order, filters)).toList();
      final start = (filters.page - 1) * filters.limit;
      final items = start >= filtered.length
          ? <PurchaseOrder>[]
          : filtered.skip(start).take(filters.limit).toList();
      return PurchaseOrderPage(
        items: items,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final response = await _api.getPurchaseOrders(
      _stringQuery(filters.search),
      filters.status == null
          ? null
          : normalizePurchaseOrderStatus(filters.status!),
      _stringQuery(filters.vendorId),
      _stringQuery(filters.purchaseRequestId),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );
    return PurchaseOrderPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<PurchaseOrder> create(CreatePurchaseOrderPayload payload) async {
    _validateCreate(payload);
    if (_config.useMockApi) {
      final quotation = await _dao.getQuotationById(payload.quotationId.trim());
      if (quotation == null) {
        throw StateError('Selected quotation not found.');
      }
      final rfq = await _dao.getRfq(quotation.rfqLocalId);
      if (rfq == null) {
        throw StateError('RFQ not found.');
      }
      final items = await _dao.getQuotationItems(quotation.localId);
      await _dao.createPurchaseOrderFromSelectedQuotation(
        rfq: rfq,
        quotation: quotation,
        items: items,
        createdById: 'user-demo',
        createdByName: 'Demo User',
        notes: _blankToNull(payload.notes),
      );
      final order = await _dao.getPurchaseOrderByQuotationId(quotation.localId);
      return _toEntity(order!);
    }

    return _fromDto(
      await _api.createPurchaseOrder(
        CreatePurchaseOrderPayloadDto(
          quotationId: payload.quotationId.trim(),
          notes: _blankToNull(payload.notes),
        ),
      ),
    );
  }

  @override
  Future<PurchaseOrder?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getPurchaseOrder(id);
      if (row == null) return null;
      return _toEntity(row);
    }
    return _fromDto(await _api.getPurchaseOrder(id));
  }

  @override
  Future<PurchaseOrder> update(
    String id,
    UpdatePurchaseOrderPayload payload,
  ) async {
    if (_config.useMockApi) {
      await _dao.updatePurchaseOrderNotes(id, _blankToNull(payload.notes));
      return (await getById(id))!;
    }
    return _fromDto(
      await _api.updatePurchaseOrder(
        id,
        UpdatePurchaseOrderPayloadDto(notes: _blankToNull(payload.notes)),
      ),
    );
  }

  @override
  Future<PurchaseOrder> issue(String id) {
    return _lifecycle(
      id,
      mockAction: () => _dao.issuePurchaseOrder(id),
      remoteAction: () => _api.issuePurchaseOrder(id),
    );
  }

  @override
  Future<PurchaseOrder> receive(String id) {
    return _lifecycle(
      id,
      mockAction: () => _dao.receivePurchaseOrder(id),
      remoteAction: () => _api.receivePurchaseOrder(id),
    );
  }

  @override
  Future<PurchaseOrder> cancel(String id) {
    return _lifecycle(
      id,
      mockAction: () => _dao.cancelPurchaseOrder(id),
      remoteAction: () => _api.cancelPurchaseOrder(id),
    );
  }

  @override
  Future<PurchaseOrder> close(String id) {
    return _lifecycle(
      id,
      mockAction: () => _dao.closePurchaseOrder(id),
      remoteAction: () => _api.closePurchaseOrder(id),
    );
  }

  Future<PurchaseOrder> _lifecycle(
    String id, {
    required Future<void> Function() mockAction,
    required Future<PurchaseOrderDto> Function() remoteAction,
  }) async {
    if (_config.useMockApi) {
      await mockAction();
      return (await getById(id))!;
    }
    return _fromDto(await remoteAction());
  }

  bool _matches(PurchaseOrder order, PurchaseOrderFilters filters) {
    final search = filters.search?.trim().toLowerCase();
    if (search != null &&
        search.isNotEmpty &&
        !order.poNumber.toLowerCase().contains(search) &&
        !order.vendorName.toLowerCase().contains(search) &&
        !order.rfqNumber.toLowerCase().contains(search) &&
        !order.purchaseRequestNumber.toLowerCase().contains(search)) {
      return false;
    }
    if (filters.status != null &&
        filters.status!.trim().isNotEmpty &&
        order.normalizedStatus !=
            normalizePurchaseOrderStatus(filters.status!)) {
      return false;
    }
    if (filters.vendorId != null &&
        filters.vendorId!.trim().isNotEmpty &&
        order.vendorId != filters.vendorId!.trim()) {
      return false;
    }
    if (filters.purchaseRequestId != null &&
        filters.purchaseRequestId!.trim().isNotEmpty &&
        order.purchaseRequestId != filters.purchaseRequestId!.trim()) {
      return false;
    }
    if (filters.dateFrom != null &&
        order.createdAt.isBefore(filters.dateFrom!)) {
      return false;
    }
    if (filters.dateTo != null &&
        order.createdAt.isAfter(filters.dateTo!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  void _validateCreate(CreatePurchaseOrderPayload payload) {
    if (payload.quotationId.trim().isEmpty) {
      throw ArgumentError('Quotation is required.');
    }
  }

  PurchaseOrder _fromDto(PurchaseOrderDto dto) {
    return PurchaseOrder(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      poNumber: dto.poNumber,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      rfqId: dto.rfqId,
      rfqNumber: dto.rfqNumber,
      quotationId: dto.quotationId,
      purchaseRequestId: dto.purchaseRequestId,
      purchaseRequestNumber: dto.purchaseRequestNumber,
      purchaseRequestTitle: dto.purchaseRequestTitle,
      createdById: dto.createdById,
      createdByName: dto.createdByName,
      status: dto.status,
      totalAmount: dto.totalAmount,
      notes: dto.notes,
      issueDate: dto.issueDate,
      receivedDate: dto.receivedDate,
      closedDate: dto.closedDate,
      cancelledDate: dto.cancelledDate,
      items: dto.items.map(_itemFromDto).toList(),
    );
  }

  PurchaseOrderItem _itemFromDto(PurchaseOrderItemDto dto) {
    return PurchaseOrderItem(
      id: dto.id,
      rfqItemId: dto.rfqItemId,
      itemName: dto.itemName,
      quantity: dto.quantity,
      unit: dto.unit,
      unitPrice: dto.unitPrice,
      lineTotal: dto.lineTotal,
    );
  }

  Future<PurchaseOrder> _toEntity(db.PurchaseOrder row) async {
    final items = await _dao.getPurchaseOrderItems(row.localId);
    return PurchaseOrder(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      poNumber: row.poNumber,
      vendorId: row.vendorId ?? '',
      vendorName: row.vendorName ?? 'Not assigned',
      rfqId: row.rfqId ?? '',
      rfqNumber: row.rfqNumber ?? '',
      quotationId: row.quotationId ?? '',
      purchaseRequestId: row.requestLocalId ?? '',
      purchaseRequestNumber: row.purchaseRequestNumber ?? '',
      purchaseRequestTitle: row.purchaseRequestTitle ?? '',
      createdById: row.createdById,
      createdByName: row.createdByName ?? '',
      status: normalizePurchaseOrderStatus(row.status),
      totalAmount: row.totalAmount,
      notes: row.notes,
      issueDate: row.issueDate,
      receivedDate: row.receivedDate,
      closedDate: row.closedDate,
      cancelledDate: row.cancelledDate,
      items: items.map(_itemToEntity).toList(),
    );
  }

  PurchaseOrderItem _itemToEntity(db.PurchaseOrderItem row) {
    return PurchaseOrderItem(
      id: row.localId,
      rfqItemId: row.rfqItemId ?? '',
      itemName: row.itemName,
      quantity: row.quantity.toDouble(),
      unit: row.unit,
      unitPrice: row.unitPrice,
      lineTotal: row.lineTotal,
    );
  }

  String? _dateQuery(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  String? _stringQuery(String? value) => _blankToNull(value);

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
