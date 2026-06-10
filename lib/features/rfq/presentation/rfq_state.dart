import 'package:equatable/equatable.dart';

import '../domain/rfq_entity.dart';

class RfqState extends Equatable {
  const RfqState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const RfqFilters(),
    this.rfqs = const [],
    this.selectedRfq,
    this.comparison,
    this.eligiblePurchaseRequests = const [],
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final RfqFilters filters;
  final List<Rfq> rfqs;
  final Rfq? selectedRfq;
  final RfqComparison? comparison;
  final List<EligiblePurchaseRequest> eligiblePurchaseRequests;
  final int total;

  RfqState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    RfqFilters? filters,
    List<Rfq>? rfqs,
    Rfq? selectedRfq,
    bool clearSelectedRfq = false,
    RfqComparison? comparison,
    bool clearComparison = false,
    List<EligiblePurchaseRequest>? eligiblePurchaseRequests,
    int? total,
  }) {
    return RfqState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      rfqs: rfqs ?? this.rfqs,
      selectedRfq: clearSelectedRfq ? null : selectedRfq ?? this.selectedRfq,
      comparison: clearComparison ? null : comparison ?? this.comparison,
      eligiblePurchaseRequests:
          eligiblePurchaseRequests ?? this.eligiblePurchaseRequests,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    rfqs,
    selectedRfq,
    comparison,
    eligiblePurchaseRequests,
    total,
  ];
}
