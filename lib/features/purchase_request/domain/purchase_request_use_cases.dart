import 'package:equatable/equatable.dart';

import '../../../core/domain/use_case.dart';
import 'purchase_request_entity.dart';
import 'purchase_request_repository.dart';

class CreatePurchaseRequestUseCase
    implements UseCase<CreatePurchaseRequestInput, PurchaseRequestEntity> {
  const CreatePurchaseRequestUseCase(this._repository);

  final PurchaseRequestRepository _repository;

  @override
  Future<PurchaseRequestEntity> call(CreatePurchaseRequestInput input) {
    return _repository.create(input);
  }
}

class ApprovalActionInput extends Equatable {
  const ApprovalActionInput({
    required this.companyId,
    required this.requestLocalId,
    required this.actorId,
    required this.comment,
  });

  final String companyId;
  final String requestLocalId;
  final String actorId;
  final String comment;

  @override
  List<Object?> get props => [companyId, requestLocalId, actorId, comment];
}

class ApprovePurchaseRequestUseCase
    implements UseCase<ApprovalActionInput, void> {
  const ApprovePurchaseRequestUseCase(this._repository);

  final PurchaseRequestRepository _repository;

  @override
  Future<void> call(ApprovalActionInput input) {
    return _repository.approve(
      companyId: input.companyId,
      requestLocalId: input.requestLocalId,
      actorId: input.actorId,
      comment: input.comment,
    );
  }
}

class RejectPurchaseRequestUseCase
    implements UseCase<ApprovalActionInput, void> {
  const RejectPurchaseRequestUseCase(this._repository);

  final PurchaseRequestRepository _repository;

  @override
  Future<void> call(ApprovalActionInput input) {
    return _repository.reject(
      companyId: input.companyId,
      requestLocalId: input.requestLocalId,
      actorId: input.actorId,
      comment: input.comment,
    );
  }
}
