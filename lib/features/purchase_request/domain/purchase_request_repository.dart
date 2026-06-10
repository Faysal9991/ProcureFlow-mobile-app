import '../../../core/domain/repository.dart';
import '../domain/purchase_request_entity.dart';

abstract interface class PurchaseRequestRepository
    implements SyncableRepository<PurchaseRequestEntity> {
  Future<PurchaseRequestPage> getMyRequests(PurchaseRequestFilters filters);

  Stream<List<PurchaseRequestEntity>> watchByCompany(String companyId);

  Stream<List<PurchaseRequestEntity>> watchApprovalInbox(String companyId);

  Future<PurchaseRequestEntity> create(CreatePurchaseRequestInput input);

  Future<PurchaseRequestEntity> saveDraft(PurchaseRequestPayload payload);

  Future<PurchaseRequestEntity> updateDraft(
    String id,
    PurchaseRequestPayload payload,
  );

  Future<PurchaseRequestEntity> submit(String id);

  Future<PurchaseRequestEntity> cancel(String id);

  Future<List<ApprovalHistoryEntry>> getApprovalHistory(String id);

  Future<void> approve({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  });

  Future<void> reject({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  });
}
