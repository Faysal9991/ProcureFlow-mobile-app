import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/report_repository_impl.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    api: ref.watch(procurementApiProvider),
    dio: ref.watch(dioProvider),
    dao: ref.watch(procurementDaoProvider),
    config: ref.watch(appConfigProvider),
  );
});
