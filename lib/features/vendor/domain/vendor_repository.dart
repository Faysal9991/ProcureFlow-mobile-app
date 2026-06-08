import 'vendor_entity.dart';

abstract interface class VendorRepository {
  Stream<List<VendorEntity>> watchByCompany(String companyId);

  Future<List<VendorEntity>> getByCompany(String companyId);
}
