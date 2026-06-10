import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/purchase_request_repository_impl.dart';
import '../domain/purchase_request_entity.dart';
import '../domain/purchase_request_repository.dart';
import '../domain/purchase_request_use_cases.dart';
import '../../auth/presentation/auth_controller.dart';

final purchaseRequestRepositoryProvider = Provider<PurchaseRequestRepository>((
  ref,
) {
  return PurchaseRequestRepositoryImpl(
    dao: ref.watch(procurementDaoProvider),
    api: ref.watch(procurementApiProvider),
    config: ref.watch(appConfigProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

final createPurchaseRequestUseCaseProvider =
    Provider<CreatePurchaseRequestUseCase>((ref) {
      return CreatePurchaseRequestUseCase(
        ref.watch(purchaseRequestRepositoryProvider),
      );
    });

final approvePurchaseRequestUseCaseProvider =
    Provider<ApprovePurchaseRequestUseCase>((ref) {
      return ApprovePurchaseRequestUseCase(
        ref.watch(purchaseRequestRepositoryProvider),
      );
    });

final rejectPurchaseRequestUseCaseProvider =
    Provider<RejectPurchaseRequestUseCase>((ref) {
      return RejectPurchaseRequestUseCase(
        ref.watch(purchaseRequestRepositoryProvider),
      );
    });

final purchaseRequestsProvider =
    StreamProvider.autoDispose<List<PurchaseRequestEntity>>((ref) {
      final session = ref.watch(authControllerProvider).session;
      if (session == null) {
        return const Stream.empty();
      }
      return ref
          .watch(purchaseRequestRepositoryProvider)
          .watchByCompany(session.companyId);
    });

final approvalInboxProvider =
    StreamProvider.autoDispose<List<PurchaseRequestEntity>>((ref) {
      final session = ref.watch(authControllerProvider).session;
      if (session == null) {
        return const Stream.empty();
      }
      return ref
          .watch(purchaseRequestRepositoryProvider)
          .watchApprovalInbox(session.companyId);
    });

final purchaseRequestDetailProvider = FutureProvider.autoDispose
    .family<PurchaseRequestEntity?, String>((ref, localId) {
      return ref.watch(purchaseRequestRepositoryProvider).getById(localId);
    });

final createPurchaseRequestControllerProvider =
    StateNotifierProvider.autoDispose<
      CreatePurchaseRequestController,
      AsyncValue<PurchaseRequestEntity?>
    >((ref) {
      return CreatePurchaseRequestController(
        ref.watch(createPurchaseRequestUseCaseProvider),
      );
    });

class CreatePurchaseRequestController
    extends StateNotifier<AsyncValue<PurchaseRequestEntity?>> {
  CreatePurchaseRequestController(this._useCase) : super(const AsyncData(null));

  final CreatePurchaseRequestUseCase _useCase;

  Future<PurchaseRequestEntity?> create(
    CreatePurchaseRequestInput input,
  ) async {
    state = const AsyncLoading();
    try {
      final request = await _useCase(input);
      state = AsyncData(request);
      return request;
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final approvalActionControllerProvider =
    StateNotifierProvider.autoDispose<
      ApprovalActionController,
      AsyncValue<void>
    >((ref) {
      return ApprovalActionController(
        approveUseCase: ref.watch(approvePurchaseRequestUseCaseProvider),
        rejectUseCase: ref.watch(rejectPurchaseRequestUseCaseProvider),
      );
    });

class ApprovalActionController extends StateNotifier<AsyncValue<void>> {
  ApprovalActionController({
    required ApprovePurchaseRequestUseCase approveUseCase,
    required RejectPurchaseRequestUseCase rejectUseCase,
  }) : _approveUseCase = approveUseCase,
       _rejectUseCase = rejectUseCase,
       super(const AsyncData(null));

  final ApprovePurchaseRequestUseCase _approveUseCase;
  final RejectPurchaseRequestUseCase _rejectUseCase;

  Future<void> approve(ApprovalActionInput input) async {
    await _run(() => _approveUseCase(input));
  }

  Future<void> reject(ApprovalActionInput input) async {
    await _run(() => _rejectUseCase(input));
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
