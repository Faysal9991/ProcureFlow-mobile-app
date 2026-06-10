import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import '../domain/rfq_entity.dart';
import '../domain/rfq_repository.dart';

class RfqRepositoryImpl implements RfqRepository {
  RfqRepositoryImpl({
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
  Future<RfqPage> getRfqs(RfqFilters filters) async {
    if (_config.useMockApi) {
      final rows = await _dao.getRfqs('company-demo');
      final all = await Future.wait(rows.map(_toEntity));
      final filtered = all.where((rfq) => _matches(rfq, filters)).toList();
      final start = (filters.page - 1) * filters.limit;
      final items = start >= filtered.length
          ? <Rfq>[]
          : filtered.skip(start).take(filters.limit).toList();
      return RfqPage(
        items: items,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final response = await _api.getRfqs(
      _stringQuery(filters.search),
      filters.status == null ? null : normalizeRfqStatus(filters.status!),
      _stringQuery(filters.purchaseRequestId),
      filters.page,
      filters.limit,
    );
    return RfqPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<Rfq> createRfq(CreateRfqPayload payload) async {
    _validateCreate(payload);
    if (_config.useMockApi) {
      final request = await _dao.getPurchaseRequest(payload.purchaseRequestId);
      if (request == null ||
          normalizePurchaseRequestStatus(request.status) !=
              PurchaseRequestStatus.approved) {
        throw StateError('Select an approved purchase request.');
      }
      final requestItems = await _dao.getPurchaseRequestItems(request.localId);
      final now = DateTime.now();
      final rfqLocalId = _uuid.v4();
      await _dao.insertRfqWithItems(
        rfq: db.RfqsCompanion.insert(
          localId: rfqLocalId,
          serverId: Value('mock-$rfqLocalId'),
          companyId: request.companyId,
          rfqNumber: _dao.nextRfqNumber(),
          purchaseRequestId: request.localId,
          purchaseRequestNumber: request.requestNumber,
          purchaseRequestTitle: request.title,
          dueDate: Value(payload.dueDate),
          notes: Value(_blankToNull(payload.notes)),
          status: const Value(RfqStatus.draft),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
        items: [
          for (final item in requestItems)
            db.RfqItemsCompanion.insert(
              localId: _uuid.v4(),
              serverId: Value('mock-${_uuid.v4()}'),
              companyId: request.companyId,
              rfqLocalId: rfqLocalId,
              itemName: item.name,
              description: Value(item.description),
              quantity: item.quantity.toDouble(),
              unit: const Value('pcs'),
              estimatedUnitPrice: Value(item.unitPrice),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
        ],
      );
      return (await getById(rfqLocalId))!;
    }

    return _fromDto(
      await _api.createRfq(
        CreateRfqPayloadDto(
          purchaseRequestId: payload.purchaseRequestId.trim(),
          dueDate: payload.dueDate!,
          notes: _blankToNull(payload.notes),
        ),
      ),
    );
  }

  @override
  Future<Rfq?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getRfq(id);
      if (row == null) return null;
      return _toEntity(row);
    }
    return _fromDto(await _api.getRfq(id));
  }

  @override
  Future<Rfq> assignVendors(String id, AssignRfqVendorsPayload payload) async {
    _validateVendorAssignment(payload);
    if (_config.useMockApi) {
      final rfq = await _dao.getRfq(id);
      if (rfq == null) throw StateError('RFQ not found.');
      final allVendors = await _dao.getVendors(rfq.companyId);
      final selected = [
        for (final vendor in allVendors)
          if (payload.vendorIds.contains(vendor.localId) ||
              (vendor.serverId != null &&
                  payload.vendorIds.contains(vendor.serverId)))
            vendor,
      ];
      if (selected.isEmpty) {
        throw ArgumentError('Select at least one vendor.');
      }
      final now = DateTime.now();
      await _dao.assignRfqVendors(
        rfqLocalId: id,
        vendors: [
          for (final vendor in selected)
            db.RfqVendorsCompanion.insert(
              localId: _uuid.v4(),
              serverId: Value('mock-${_uuid.v4()}'),
              companyId: rfq.companyId,
              rfqLocalId: id,
              vendorId: vendor.localId,
              vendorName: vendor.name,
              contactPerson: Value(vendor.contactPerson),
              email: Value(vendor.email),
              phone: Value(vendor.phone),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
        ],
      );
      return (await getById(id))!;
    }

    return _fromDto(
      await _api.assignRfqVendors(
        id,
        AssignRfqVendorsPayloadDto(vendorIds: payload.vendorIds),
      ),
    );
  }

  @override
  Future<Rfq> openRfq(String id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('RFQ not found.');
    }
    if (existing.vendorCount <= 0) {
      throw ArgumentError(
        'Please assign at least one vendor before opening this RFQ.',
      );
    }
    if (_config.useMockApi) {
      await _dao.openRfq(id);
      return (await getById(id))!;
    }

    return _fromDto(await _api.openRfq(id));
  }

  @override
  Future<Quotation> createQuotation(
    String id,
    CreateQuotationPayload payload,
  ) async {
    _validateQuotation(payload);
    final rfq = await getById(id);
    if (rfq == null) throw StateError('RFQ not found.');
    RfqVendor? vendor;
    for (final item in rfq.vendors) {
      if (item.vendorId == payload.vendorId) {
        vendor = item;
        break;
      }
    }
    if (vendor == null) {
      throw ArgumentError('Select an assigned vendor.');
    }

    if (_config.useMockApi) {
      final now = DateTime.now();
      final quotationLocalId = _uuid.v4();
      await _dao.insertQuotationWithItems(
        quotation: db.QuotationsCompanion.insert(
          localId: quotationLocalId,
          serverId: Value('mock-$quotationLocalId'),
          companyId: rfq.companyId,
          rfqLocalId: id,
          vendorId: vendor.vendorId,
          vendorName: vendor.vendorName,
          quotationNumber: payload.quotationNumber.trim(),
          quotationDate: Value(payload.quotationDate),
          validUntil: Value(payload.validUntil),
          notes: Value(_blankToNull(payload.notes)),
          status: const Value('SUBMITTED'),
          totalAmount: Value(payload.totalAmount),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
        items: [
          for (final item in payload.items)
            db.QuotationItemsCompanion.insert(
              localId: _uuid.v4(),
              serverId: Value('mock-${_uuid.v4()}'),
              companyId: rfq.companyId,
              quotationLocalId: quotationLocalId,
              rfqItemId: item.rfqItemId,
              itemName: item.itemName,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.totalPrice,
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
        ],
      );
      final row = (await _dao.getRfqQuotations(
        id,
      )).firstWhere((quotation) => quotation.localId == quotationLocalId);
      return _quotationToEntity(row, rfq.companyId);
    }

    return _quotationFromDto(
      await _api.createRfqQuotation(id, _quotationPayloadDto(payload)),
      companyId: rfq.companyId,
    );
  }

  @override
  Future<RfqComparison> getComparison(String id) async {
    if (_config.useMockApi) {
      final rfq = await getById(id);
      if (rfq == null) throw StateError('RFQ not found.');
      return _comparisonFromRfq(rfq);
    }

    return _comparisonFromDto(await _api.getRfqComparison(id));
  }

  @override
  Future<Rfq> selectQuotation(
    String id,
    SelectedQuotationPayload payload,
  ) async {
    _validateSelectedQuotation(payload);
    if (_config.useMockApi) {
      final comparison = await getComparison(id);
      if (!comparison.canSelectWinner) {
        throw StateError('Winner selection is not available for this RFQ.');
      }
      final found = comparison.quotations.any(
        (quotation) => quotation.quotationId == payload.quotationId,
      );
      if (!found) {
        throw StateError('Quotation not found.');
      }
      await _dao.selectWinningRfqQuotation(
        rfqLocalId: id,
        quotationId: payload.quotationId,
      );
      return (await getById(id))!;
    }

    return _fromDto(
      await _api.selectRfqQuotation(
        id,
        SelectedQuotationPayloadDto(quotationId: payload.quotationId.trim()),
      ),
    );
  }

  @override
  Future<List<EligiblePurchaseRequest>> getEligiblePurchaseRequests({
    int page = 1,
    int limit = 20,
  }) async {
    if (_config.useMockApi) {
      final rows = await _dao.getEligiblePurchaseRequestsForRfq('company-demo');
      final start = (page - 1) * limit;
      final pageRows = start >= rows.length
          ? <db.PurchaseRequest>[]
          : rows.skip(start).take(limit).toList();
      return pageRows.map(_eligibleFromRow).toList();
    }

    final response = await _api.getEligiblePurchaseRequestsForRfq(page, limit);
    return response.items.map(_eligibleFromDto).toList();
  }

  bool _matches(Rfq rfq, RfqFilters filters) {
    final search = filters.search?.trim().toLowerCase();
    if (search != null &&
        search.isNotEmpty &&
        !rfq.rfqNumber.toLowerCase().contains(search) &&
        !rfq.purchaseRequestNumber.toLowerCase().contains(search) &&
        !rfq.purchaseRequestTitle.toLowerCase().contains(search)) {
      return false;
    }
    if (filters.status != null &&
        rfq.normalizedStatus != normalizeRfqStatus(filters.status!)) {
      return false;
    }
    if (filters.purchaseRequestId != null &&
        filters.purchaseRequestId!.trim().isNotEmpty &&
        rfq.purchaseRequestId != filters.purchaseRequestId!.trim()) {
      return false;
    }
    return true;
  }

  void _validateCreate(CreateRfqPayload payload) {
    if (payload.purchaseRequestId.trim().isEmpty) {
      throw ArgumentError('Purchase request is required.');
    }
    if (payload.dueDate == null) {
      throw ArgumentError('Due date is required.');
    }
  }

  void _validateVendorAssignment(AssignRfqVendorsPayload payload) {
    if (payload.vendorIds.isEmpty) {
      throw ArgumentError('Select at least one vendor.');
    }
  }

  void _validateQuotation(CreateQuotationPayload payload) {
    if (payload.vendorId.trim().isEmpty) {
      throw ArgumentError('Vendor is required.');
    }
    if (payload.quotationNumber.trim().isEmpty) {
      throw ArgumentError('Quotation number is required.');
    }
    if (payload.quotationDate == null) {
      throw ArgumentError('Quotation date is required.');
    }
    if (payload.items.isEmpty) {
      throw ArgumentError('Quotation items are required.');
    }
    for (final item in payload.items) {
      if (item.rfqItemId.trim().isEmpty || item.unitPrice <= 0) {
        throw ArgumentError('Enter a valid unit price for every item.');
      }
    }
  }

  void _validateSelectedQuotation(SelectedQuotationPayload payload) {
    if (payload.quotationId.trim().isEmpty) {
      throw ArgumentError('Quotation is required.');
    }
  }

  CreateQuotationPayloadDto _quotationPayloadDto(
    CreateQuotationPayload payload,
  ) {
    return CreateQuotationPayloadDto(
      vendorId: payload.vendorId.trim(),
      quotationNumber: payload.quotationNumber.trim(),
      quotationDate: payload.quotationDate!,
      validUntil: payload.validUntil,
      notes: _blankToNull(payload.notes),
      items: [
        for (final item in payload.items)
          CreateQuotationItemPayloadDto(
            rfqItemId: item.rfqItemId,
            unitPrice: item.unitPrice,
          ),
      ],
    );
  }

  Rfq _fromDto(RfqDto dto) {
    return Rfq(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      rfqNumber: dto.rfqNumber,
      purchaseRequestId: dto.purchaseRequestId,
      purchaseRequestNumber: dto.purchaseRequestNumber,
      purchaseRequestTitle: dto.purchaseRequestTitle,
      dueDate: dto.dueDate,
      status: dto.status,
      notes: dto.notes,
      vendorCount: dto.vendorCount,
      quotationCount: dto.quotationCount,
      selectedQuotationId: dto.selectedQuotationId,
      items: dto.items.map(_itemFromDto).toList(),
      vendors: dto.vendors.map(_vendorFromDto).toList(),
      quotations: [
        for (final quotation in dto.quotations)
          _quotationFromDto(quotation, companyId: dto.companyId),
      ],
    );
  }

  RfqItem _itemFromDto(RfqItemDto dto) {
    return RfqItem(
      id: dto.id,
      itemName: dto.itemName,
      description: dto.description,
      quantity: dto.quantity,
      unit: dto.unit,
      estimatedUnitPrice: dto.estimatedUnitPrice,
    );
  }

  RfqVendor _vendorFromDto(RfqVendorDto dto) {
    return RfqVendor(
      id: dto.id,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      contactPerson: dto.contactPerson,
      email: dto.email,
      phone: dto.phone,
    );
  }

  Quotation _quotationFromDto(QuotationDto dto, {required String companyId}) {
    return Quotation(
      localId: dto.id,
      serverId: dto.id,
      companyId: companyId.isEmpty ? 'remote' : companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      rfqId: dto.rfqId,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      quotationNumber: dto.quotationNumber,
      quotationDate: dto.quotationDate,
      validUntil: dto.validUntil,
      status: dto.status,
      totalAmount: dto.totalAmount,
      notes: dto.notes,
      items: dto.items.map(_quotationItemFromDto).toList(),
    );
  }

  QuotationItem _quotationItemFromDto(QuotationItemDto dto) {
    return QuotationItem(
      id: dto.id,
      rfqItemId: dto.rfqItemId,
      itemName: dto.itemName,
      quantity: dto.quantity,
      unitPrice: dto.unitPrice,
      totalPrice: dto.totalPrice,
    );
  }

  Future<Rfq> _toEntity(db.Rfq row) async {
    final items = await _dao.getRfqItems(row.localId);
    final vendors = await _dao.getRfqVendors(row.localId);
    final quotations = await _dao.getRfqQuotations(row.localId);
    return Rfq(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      rfqNumber: row.rfqNumber,
      purchaseRequestId: row.purchaseRequestId,
      purchaseRequestNumber: row.purchaseRequestNumber,
      purchaseRequestTitle: row.purchaseRequestTitle,
      dueDate: row.dueDate,
      status: normalizeRfqStatus(row.status),
      notes: row.notes,
      vendorCount: row.vendorCount,
      quotationCount: row.quotationCount,
      selectedQuotationId: row.selectedQuotationId,
      items: items.map(_itemToEntity).toList(),
      vendors: vendors.map(_vendorToEntity).toList(),
      quotations: [
        for (final quotation in quotations)
          await _quotationToEntity(quotation, row.companyId),
      ],
    );
  }

  RfqItem _itemToEntity(db.RfqItem row) {
    return RfqItem(
      id: row.localId,
      itemName: row.itemName,
      description: row.description,
      quantity: row.quantity,
      unit: row.unit,
      estimatedUnitPrice: row.estimatedUnitPrice,
    );
  }

  RfqVendor _vendorToEntity(db.RfqVendor row) {
    return RfqVendor(
      id: row.localId,
      vendorId: row.vendorId,
      vendorName: row.vendorName,
      contactPerson: row.contactPerson,
      email: row.email,
      phone: row.phone,
    );
  }

  Future<Quotation> _quotationToEntity(
    db.Quotation row,
    String companyId,
  ) async {
    final items = await _dao.getQuotationItems(row.localId);
    return Quotation(
      localId: row.localId,
      serverId: row.serverId,
      companyId: companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      rfqId: row.rfqLocalId,
      vendorId: row.vendorId,
      vendorName: row.vendorName,
      quotationNumber: row.quotationNumber,
      quotationDate: row.quotationDate,
      validUntil: row.validUntil,
      status: row.status,
      totalAmount: row.totalAmount,
      notes: row.notes,
      items: items.map(_quotationItemToEntity).toList(),
    );
  }

  QuotationItem _quotationItemToEntity(db.QuotationItem row) {
    return QuotationItem(
      id: row.localId,
      rfqItemId: row.rfqItemId,
      itemName: row.itemName,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      totalPrice: row.totalPrice,
    );
  }

  EligiblePurchaseRequest _eligibleFromRow(db.PurchaseRequest row) {
    return EligiblePurchaseRequest(
      id: row.localId,
      requestNumber: row.requestNumber,
      title: row.title,
      departmentName: row.departmentId ?? 'Not assigned',
      estimatedTotal: row.totalAmount,
      status: normalizePurchaseRequestStatus(row.status),
    );
  }

  EligiblePurchaseRequest _eligibleFromDto(EligiblePurchaseRequestDto dto) {
    return EligiblePurchaseRequest(
      id: dto.id,
      requestNumber: dto.requestNumber,
      title: dto.title,
      departmentName: dto.departmentName,
      estimatedTotal: dto.estimatedTotal,
      status: dto.status,
    );
  }

  RfqComparison _comparisonFromDto(RfqComparisonDto dto) {
    final ranked = _rankComparisonQuotations(
      dto.quotations.map(_comparisonQuotationFromDto).toList(),
    );
    return RfqComparison(
      rfqId: dto.rfqId,
      rfqNumber: dto.rfqNumber,
      status: dto.status,
      purchaseRequestId: dto.purchaseRequestId,
      purchaseRequestNumber: dto.purchaseRequestNumber,
      purchaseRequestTitle: dto.purchaseRequestTitle,
      quotations: ranked,
      lowestQuotationId:
          dto.lowestQuotationId ??
          (ranked.isEmpty ? null : ranked.first.quotationId),
      selectedQuotationId: dto.selectedQuotationId,
      purchaseOrderId: dto.purchaseOrderId,
    );
  }

  RfqComparisonQuotation _comparisonQuotationFromDto(
    RfqComparisonQuotationDto dto,
  ) {
    return RfqComparisonQuotation(
      quotationId: dto.quotationId,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      quotationNumber: dto.quotationNumber,
      quotationDate: dto.quotationDate,
      validUntil: dto.validUntil,
      totalAmount: dto.totalAmount,
      rank: dto.rank,
      items: dto.items.map(_comparisonItemFromDto).toList(),
    );
  }

  RfqComparisonItem _comparisonItemFromDto(RfqComparisonItemDto dto) {
    return RfqComparisonItem(
      rfqItemId: dto.rfqItemId,
      itemName: dto.itemName,
      quantity: dto.quantity,
      unit: dto.unit,
      unitPrice: dto.unitPrice,
      lineTotal: dto.lineTotal,
    );
  }

  Future<RfqComparison> _comparisonFromRfq(Rfq rfq) async {
    final quotations = [
      for (final quotation in rfq.quotations)
        RfqComparisonQuotation(
          quotationId: quotation.localId,
          vendorId: quotation.vendorId,
          vendorName: quotation.vendorName,
          quotationNumber: quotation.quotationNumber,
          quotationDate: quotation.quotationDate,
          validUntil: quotation.validUntil,
          totalAmount: quotation.totalAmount,
          rank: 0,
          items: [
            for (final item in quotation.items)
              _comparisonItemFromQuotationItem(item, rfq.items),
          ],
        ),
    ];
    final ranked = _rankComparisonQuotations(quotations);
    final purchaseOrder = rfq.selectedQuotationId == null
        ? null
        : await _dao.getPurchaseOrderByQuotationId(rfq.selectedQuotationId!);
    return RfqComparison(
      rfqId: rfq.localId,
      rfqNumber: rfq.rfqNumber,
      status: rfq.normalizedStatus,
      purchaseRequestId: rfq.purchaseRequestId,
      purchaseRequestNumber: rfq.purchaseRequestNumber,
      purchaseRequestTitle: rfq.purchaseRequestTitle,
      quotations: ranked,
      lowestQuotationId: ranked.isEmpty ? null : ranked.first.quotationId,
      selectedQuotationId: rfq.selectedQuotationId,
      purchaseOrderId: purchaseOrder?.localId,
    );
  }

  RfqComparisonItem _comparisonItemFromQuotationItem(
    QuotationItem item,
    List<RfqItem> rfqItems,
  ) {
    RfqItem? rfqItem;
    for (final candidate in rfqItems) {
      if (candidate.id == item.rfqItemId) {
        rfqItem = candidate;
        break;
      }
    }
    return RfqComparisonItem(
      rfqItemId: item.rfqItemId,
      itemName: item.itemName,
      quantity: item.quantity,
      unit: rfqItem?.unit ?? 'pcs',
      unitPrice: item.unitPrice,
      lineTotal: item.totalPrice,
    );
  }

  List<RfqComparisonQuotation> _rankComparisonQuotations(
    List<RfqComparisonQuotation> quotations,
  ) {
    final sorted = [...quotations]
      ..sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
    return [
      for (var index = 0; index < sorted.length; index++)
        RfqComparisonQuotation(
          quotationId: sorted[index].quotationId,
          vendorId: sorted[index].vendorId,
          vendorName: sorted[index].vendorName,
          quotationNumber: sorted[index].quotationNumber,
          quotationDate: sorted[index].quotationDate,
          validUntil: sorted[index].validUntil,
          totalAmount: sorted[index].totalAmount,
          rank: index + 1,
          items: sorted[index].items,
        ),
    ];
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _stringQuery(String? value) => _blankToNull(value);
}
