import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../../purchase_order/domain/purchase_order_entity.dart';
import '../domain/invoice_entity.dart';
import '../domain/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
  }) : _dao = dao,
       _api = api,
       _config = config;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;
  final Uuid _uuid = const Uuid();

  @override
  Future<InvoicePage> getInvoices(InvoiceFilters filters) async {
    if (_config.useMockApi) {
      final rows = await _dao.getInvoices('company-demo');
      final all = rows.map(_toEntity).toList();
      final filtered = all
          .where((invoice) => _matches(invoice, filters))
          .toList();
      final start = (filters.page - 1) * filters.limit;
      final items = start >= filtered.length
          ? <Invoice>[]
          : filtered.skip(start).take(filters.limit).toList();
      return InvoicePage(
        items: items,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final status = _stringQuery(filters.status);
    final response = await _api.getInvoices(
      _searchQuery(filters.search),
      status == null ? null : normalizeInvoiceStatus(status),
      _stringQuery(filters.vendorId),
      _stringQuery(filters.purchaseOrderId),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );
    return InvoicePage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<Invoice> create(CreateInvoicePayload payload) async {
    _validateCreate(payload);
    if (_config.useMockApi) {
      final order = await _dao.getPurchaseOrder(payload.purchaseOrderId.trim());
      if (order == null) throw StateError('Purchase order not found.');
      if (normalizePurchaseOrderStatus(order.status) !=
          PurchaseOrderStatus.received) {
        throw StateError('Invoice can only be created from a received PO.');
      }
      final existing = await _dao.getInvoiceByPurchaseOrderId(order.localId);
      if (existing != null) {
        throw StateError('Invoice already exists for this purchase order.');
      }
      final now = DateTime.now();
      final localId = _uuid.v4();
      await _dao.insertInvoice(
        db.InvoicesCompanion.insert(
          localId: localId,
          serverId: Value('mock-invoice-$localId'),
          companyId: order.companyId,
          invoiceNumber: payload.invoiceNumber.trim(),
          purchaseOrderId: order.localId,
          purchaseOrderNumber: order.poNumber,
          vendorId: Value(order.vendorId),
          vendorName: Value(order.vendorName),
          status: const Value(InvoiceStatus.pending),
          invoiceDate: payload.invoiceDate!,
          dueDate: payload.dueDate!,
          invoiceAmount: payload.invoiceAmount,
          paidAmount: const Value(0),
          dueAmount: payload.invoiceAmount,
          notes: Value(_blankToNull(payload.notes)),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
      );
      return (await getById(localId))!;
    }

    return _fromDto(
      await _api.createInvoice(
        CreateInvoicePayloadDto(
          purchaseOrderId: payload.purchaseOrderId.trim(),
          invoiceNumber: payload.invoiceNumber.trim(),
          invoiceDate: payload.invoiceDate!,
          dueDate: payload.dueDate!,
          invoiceAmount: payload.invoiceAmount,
          notes: _blankToNull(payload.notes),
        ),
      ),
    );
  }

  @override
  Future<Invoice?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getInvoice(id);
      if (row == null) return null;
      return _toEntity(row);
    }
    return _fromDto(await _api.getInvoice(id));
  }

  @override
  Future<Invoice> update(String id, UpdateInvoicePayload payload) async {
    _validateUpdate(payload);
    if (_config.useMockApi) {
      final existing = await _dao.getInvoice(id);
      if (existing == null) throw StateError('Invoice not found.');
      await _dao.updateInvoice(
        id,
        db.InvoicesCompanion(
          invoiceNumber: Value(payload.invoiceNumber.trim()),
          invoiceDate: Value(payload.invoiceDate!),
          dueDate: Value(payload.dueDate!),
          invoiceAmount: Value(payload.invoiceAmount),
          dueAmount: Value(payload.invoiceAmount - existing.paidAmount),
          notes: Value(_blankToNull(payload.notes)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(id))!;
    }

    return _fromDto(
      await _api.updateInvoice(
        id,
        UpdateInvoicePayloadDto(
          invoiceNumber: payload.invoiceNumber.trim(),
          invoiceDate: payload.invoiceDate!,
          dueDate: payload.dueDate!,
          invoiceAmount: payload.invoiceAmount,
          notes: _blankToNull(payload.notes),
        ),
      ),
    );
  }

  @override
  Future<Invoice> cancel(String id) async {
    if (_config.useMockApi) {
      await _dao.cancelInvoice(id);
      return (await getById(id))!;
    }
    return _fromDto(await _api.cancelInvoice(id));
  }

  @override
  Future<Invoice?> getByPurchaseOrderId(String purchaseOrderId) async {
    if (_config.useMockApi) {
      final row = await _dao.getInvoiceByPurchaseOrderId(purchaseOrderId);
      if (row == null) return null;
      return _toEntity(row);
    }
    final page = await getInvoices(
      InvoiceFilters(purchaseOrderId: purchaseOrderId, limit: 1),
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  bool _matches(Invoice invoice, InvoiceFilters filters) {
    final search = _searchQuery(filters.search)?.toLowerCase();
    if (search != null &&
        !invoice.invoiceNumber.toLowerCase().contains(search) &&
        !invoice.vendorName.toLowerCase().contains(search) &&
        !invoice.purchaseOrderNumber.toLowerCase().contains(search) &&
        !(invoice.notes ?? '').toLowerCase().contains(search)) {
      return false;
    }
    if (filters.status != null &&
        filters.status!.trim().isNotEmpty &&
        invoice.normalizedStatus != normalizeInvoiceStatus(filters.status!)) {
      return false;
    }
    if (filters.vendorId != null &&
        filters.vendorId!.trim().isNotEmpty &&
        invoice.vendorId != filters.vendorId!.trim()) {
      return false;
    }
    if (filters.purchaseOrderId != null &&
        filters.purchaseOrderId!.trim().isNotEmpty &&
        invoice.purchaseOrderId != filters.purchaseOrderId!.trim()) {
      return false;
    }
    final invoiceDate = invoice.invoiceDate;
    if (invoiceDate != null &&
        filters.dateFrom != null &&
        invoiceDate.isBefore(filters.dateFrom!)) {
      return false;
    }
    if (invoiceDate != null &&
        filters.dateTo != null &&
        invoiceDate.isAfter(filters.dateTo!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  void _validateCreate(CreateInvoicePayload payload) {
    if (payload.purchaseOrderId.trim().isEmpty) {
      throw ArgumentError('Purchase order is required.');
    }
    _validateInvoiceFields(
      invoiceNumber: payload.invoiceNumber,
      invoiceDate: payload.invoiceDate,
      dueDate: payload.dueDate,
      invoiceAmount: payload.invoiceAmount,
    );
  }

  void _validateUpdate(UpdateInvoicePayload payload) {
    _validateInvoiceFields(
      invoiceNumber: payload.invoiceNumber,
      invoiceDate: payload.invoiceDate,
      dueDate: payload.dueDate,
      invoiceAmount: payload.invoiceAmount,
    );
  }

  void _validateInvoiceFields({
    required String invoiceNumber,
    required DateTime? invoiceDate,
    required DateTime? dueDate,
    required double invoiceAmount,
  }) {
    if (invoiceNumber.trim().isEmpty) {
      throw ArgumentError('Invoice number is required.');
    }
    if (invoiceDate == null) {
      throw ArgumentError('Invoice date is required.');
    }
    if (dueDate == null) {
      throw ArgumentError('Due date is required.');
    }
    if (invoiceAmount <= 0) {
      throw ArgumentError('Invoice amount must be greater than zero.');
    }
    if (dueDate.isBefore(invoiceDate)) {
      throw ArgumentError('Due date must be on or after invoice date.');
    }
  }

  Invoice _fromDto(InvoiceDto dto) {
    return Invoice(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      invoiceNumber: dto.invoiceNumber,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      purchaseOrderId: dto.purchaseOrderId,
      purchaseOrderNumber: dto.purchaseOrderNumber,
      status: dto.status,
      invoiceDate: dto.invoiceDate,
      dueDate: dto.dueDate,
      invoiceAmount: dto.invoiceAmount,
      paidAmount: dto.paidAmount,
      dueAmount: dto.dueAmount,
      notes: dto.notes,
    );
  }

  Invoice _toEntity(db.Invoice row) {
    return Invoice(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      invoiceNumber: row.invoiceNumber,
      vendorId: row.vendorId ?? '',
      vendorName: row.vendorName ?? 'Not assigned',
      purchaseOrderId: row.purchaseOrderId,
      purchaseOrderNumber: row.purchaseOrderNumber,
      status: normalizeInvoiceStatus(row.status),
      invoiceDate: row.invoiceDate,
      dueDate: row.dueDate,
      invoiceAmount: row.invoiceAmount,
      paidAmount: row.paidAmount,
      dueAmount: row.dueAmount,
      notes: row.notes,
    );
  }

  String? _dateQuery(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  String? _searchQuery(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.length < 2) return null;
    return trimmed;
  }

  String? _stringQuery(String? value) => _blankToNull(value);

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
