import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  VendorRepositoryImpl(this._dao);

  final ProcurementDao _dao;

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
      email: row.email,
      phone: row.phone,
      address: row.address,
      isActive: row.isActive,
    );
  }
}
