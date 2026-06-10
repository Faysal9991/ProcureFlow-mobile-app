import 'package:equatable/equatable.dart';

import '../domain/purchase_request_entity.dart';

class PurchaseRequestState extends Equatable {
  const PurchaseRequestState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const PurchaseRequestFilters(),
    this.requests = const [],
    this.selectedRequest,
    this.approvalHistory = const [],
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final PurchaseRequestFilters filters;
  final List<PurchaseRequestEntity> requests;
  final PurchaseRequestEntity? selectedRequest;
  final List<ApprovalHistoryEntry> approvalHistory;
  final int total;

  PurchaseRequestState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    PurchaseRequestFilters? filters,
    List<PurchaseRequestEntity>? requests,
    PurchaseRequestEntity? selectedRequest,
    bool clearSelectedRequest = false,
    List<ApprovalHistoryEntry>? approvalHistory,
    int? total,
  }) {
    return PurchaseRequestState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      requests: requests ?? this.requests,
      selectedRequest: clearSelectedRequest
          ? null
          : selectedRequest ?? this.selectedRequest,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    requests,
    selectedRequest,
    approvalHistory,
    total,
  ];
}
