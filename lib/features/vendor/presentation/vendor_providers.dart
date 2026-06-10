import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/vendor_repository_impl.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});

final vendorsProvider = FutureProvider.autoDispose<List<VendorEntity>>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) {
    return const [];
  }
  return ref.watch(vendorRepositoryProvider).getByCompany(session.companyId);
});
