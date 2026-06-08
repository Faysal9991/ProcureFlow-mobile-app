import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/purchase_order_repository_impl.dart';
import '../domain/purchase_order_entity.dart';
import '../domain/purchase_order_repository.dart';
import '../domain/purchase_order_use_cases.dart';

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((
  ref,
) {
  return PurchaseOrderRepositoryImpl(ref.watch(procurementDaoProvider));
});

final purchaseOrdersProvider =
    StreamProvider.autoDispose<List<PurchaseOrderEntity>>((ref) {
      final session = ref.watch(authControllerProvider).session;
      if (session == null) {
        return const Stream.empty();
      }
      return ref
          .watch(purchaseOrderRepositoryProvider)
          .watchByCompany(session.companyId);
    });

final createPurchaseOrderUseCaseProvider = Provider<CreatePurchaseOrderUseCase>(
  (ref) {
    return CreatePurchaseOrderUseCase(
      ref.watch(purchaseOrderRepositoryProvider),
    );
  },
);

final createPurchaseOrderControllerProvider =
    StateNotifierProvider.autoDispose<
      CreatePurchaseOrderController,
      AsyncValue<void>
    >(
      (ref) => CreatePurchaseOrderController(
        ref.watch(createPurchaseOrderUseCaseProvider),
      ),
    );

class CreatePurchaseOrderController extends StateNotifier<AsyncValue<void>> {
  CreatePurchaseOrderController(this._useCase) : super(const AsyncData(null));

  final CreatePurchaseOrderUseCase _useCase;

  Future<void> create(CreatePurchaseOrderInput input) async {
    state = const AsyncLoading();
    try {
      await _useCase(input);
      state = const AsyncData(null);
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
