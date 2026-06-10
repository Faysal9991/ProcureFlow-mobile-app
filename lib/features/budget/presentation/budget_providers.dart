import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/budget_repository_impl.dart';
import '../domain/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});
