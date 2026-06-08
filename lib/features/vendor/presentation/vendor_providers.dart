import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/vendor_repository_impl.dart';
import '../domain/vendor_entity.dart';
import '../domain/vendor_repository.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(ref.watch(procurementDaoProvider));
});

final vendorsProvider = StreamProvider.autoDispose<List<VendorEntity>>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) {
    return const Stream.empty();
  }
  return ref.watch(vendorRepositoryProvider).watchByCompany(session.companyId);
});
