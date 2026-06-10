import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  VendorRepositoryImpl({
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
  Future<VendorPage> getVendors(VendorFilters filters) async {
    if (_config.useMockApi) {
      final rows = await _dao.getVendors('company-demo');
      final filtered = rows.map(_toEntity).where((vendor) {
        final search = filters.search?.trim().toLowerCase();
        if (search != null &&
            search.isNotEmpty &&
            !vendor.name.toLowerCase().contains(search) &&
            !(vendor.contactPerson?.toLowerCase().contains(search) ?? false) &&
            !(vendor.phone?.toLowerCase().contains(search) ?? false) &&
            !(vendor.email?.toLowerCase().contains(search) ?? false)) {
          return false;
        }
        if (filters.status != null &&
            vendor.normalizedStatus != normalizeVendorStatus(filters.status!)) {
          return false;
        }
        return true;
      }).toList();
      final start = (filters.page - 1) * filters.limit;
      final pageItems = start >= filtered.length
          ? <VendorEntity>[]
          : filtered.skip(start).take(filters.limit).toList();
      return VendorPage(
        items: pageItems,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final response = await _api.getVendors(
      _stringQuery(filters.search),
      filters.status == null ? null : normalizeVendorStatus(filters.status!),
      filters.page,
      filters.limit,
    );
    return VendorPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<VendorEntity?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getVendor(id);
      if (row == null) return null;
      return _toEntity(row);
    }
    return _fromDto(await _api.getVendor(id));
  }

  @override
  Future<VendorEntity> create(VendorPayload payload) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      final now = DateTime.now();
      final localId = _uuid.v4();
      await _dao.insertVendor(
        VendorsCompanion.insert(
          localId: localId,
          serverId: Value('mock-$localId'),
          companyId: 'company-demo',
          name: payload.name.trim(),
          contactPerson: Value(_blankToNull(payload.contactPerson)),
          phone: Value(payload.phone.trim()),
          email: Value(_blankToNull(payload.email)),
          address: Value(_blankToNull(payload.address)),
          isActive: Value(
            normalizeVendorStatus(payload.status) == VendorStatus.active,
          ),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
      );
      return (await getById(localId))!;
    }

    return _fromDto(await _api.createVendor(_payloadDto(payload)));
  }

  @override
  Future<VendorEntity> update(String id, VendorPayload payload) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      final existing = await _dao.getVendor(id);
      if (existing == null) {
        throw StateError('Vendor not found.');
      }
      final now = DateTime.now();
      await _dao.updateVendor(
        id,
        VendorsCompanion(
          name: Value(payload.name.trim()),
          contactPerson: Value(_blankToNull(payload.contactPerson)),
          phone: Value(payload.phone.trim()),
          email: Value(_blankToNull(payload.email)),
          address: Value(_blankToNull(payload.address)),
          isActive: Value(
            normalizeVendorStatus(payload.status) == VendorStatus.active,
          ),
          updatedAt: Value(now),
        ),
      );
      return (await getById(id))!;
    }

    return _fromDto(await _api.updateVendor(id, _payloadDto(payload)));
  }

  @override
  Future<void> delete(String id) {
    if (_config.useMockApi) {
      return _dao.softDeleteVendor(id);
    }
    return _api.deleteVendor(id);
  }

  @override
  Future<List<VendorEntity>> getByCompany(String companyId) async {
    final rows = await _dao.getVendors(companyId);
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<VendorEntity>> watchByCompany(String companyId) {
    return _dao
        .watchVendors(companyId)
        .map((rows) => rows.map(_toEntity).toList());
  }

  VendorEntity _toEntity(Vendor row) {
    return VendorEntity(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      name: row.name,
      contactPerson: row.contactPerson,
      email: row.email,
      phone: row.phone,
      address: row.address,
      status: row.isActive ? VendorStatus.active : VendorStatus.inactive,
    );
  }

  VendorEntity _fromDto(VendorDto dto) {
    return VendorEntity(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      name: dto.name,
      contactPerson: dto.contactPerson,
      email: dto.email,
      phone: dto.phone,
      address: dto.address,
      status: dto.status,
    );
  }

  VendorPayloadDto _payloadDto(VendorPayload payload) {
    return VendorPayloadDto(
      name: payload.name.trim(),
      contactPerson: _blankToNull(payload.contactPerson),
      phone: payload.phone.trim(),
      email: _blankToNull(payload.email),
      address: _blankToNull(payload.address),
      status: normalizeVendorStatus(payload.status),
    );
  }

  void _validatePayload(VendorPayload payload) {
    if (payload.name.trim().isEmpty) {
      throw ArgumentError('Name is required.');
    }
    if (payload.phone.trim().isEmpty) {
      throw ArgumentError('Phone is required.');
    }
    if (payload.email != null &&
        payload.email!.trim().isNotEmpty &&
        !_emailPattern.hasMatch(payload.email!.trim())) {
      throw ArgumentError('Enter a valid email address.');
    }
    if (payload.status.trim().isEmpty) {
      throw ArgumentError('Status is required.');
    }
    normalizeVendorStatus(payload.status);
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _stringQuery(String? value) => _blankToNull(value);

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
