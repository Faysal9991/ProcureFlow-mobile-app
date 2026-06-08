import 'package:equatable/equatable.dart';

import '../../../core/domain/use_case.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import 'purchase_order_repository.dart';

class CreatePurchaseOrderInput extends Equatable {
  const CreatePurchaseOrderInput({
    required this.request,
    required this.createdById,
  });

  final PurchaseRequestEntity request;
  final String createdById;

  @override
  List<Object?> get props => [request, createdById];
}

class CreatePurchaseOrderUseCase
    implements UseCase<CreatePurchaseOrderInput, void> {
  const CreatePurchaseOrderUseCase(this._repository);

  final PurchaseOrderRepository _repository;

  @override
  Future<void> call(CreatePurchaseOrderInput input) {
    return _repository.createFromRequest(
      request: input.request,
      createdById: input.createdById,
    );
  }
}
