import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/rfq_repository_impl.dart';
import '../domain/rfq_repository.dart';

final rfqRepositoryProvider = Provider<RfqRepository>((ref) {
  return RfqRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});
