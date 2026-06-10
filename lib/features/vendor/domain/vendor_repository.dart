import 'vendor_entity.dart';

abstract interface class VendorRepository {
  Future<VendorPage> getVendors(VendorFilters filters);

  Future<VendorEntity?> getById(String id);

  Future<VendorEntity> create(VendorPayload payload);

  Future<VendorEntity> update(String id, VendorPayload payload);

  Future<void> delete(String id);

  Stream<List<VendorEntity>> watchByCompany(String companyId);

  Future<List<VendorEntity>> getByCompany(String companyId);
}
