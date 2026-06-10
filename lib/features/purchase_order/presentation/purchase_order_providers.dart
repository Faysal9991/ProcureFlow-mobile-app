import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/purchase_order_repository_impl.dart';
import '../domain/purchase_order_repository.dart';

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((
  ref,
) {
  return PurchaseOrderRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
  );
});
