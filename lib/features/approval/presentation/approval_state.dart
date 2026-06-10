import 'package:equatable/equatable.dart';

import '../domain/approval_repository.dart';

class ApprovalState extends Equatable {
  const ApprovalState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const ApprovalInboxFilters(),
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final ApprovalInboxFilters filters;
  final List<ApprovalInboxItem> items;
  final int page;
  final int limit;
  final int total;

  ApprovalState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    ApprovalInboxFilters? filters,
    List<ApprovalInboxItem>? items,
    int? page,
    int? limit,
    int? total,
  }) {
    return ApprovalState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    items,
    page,
    limit,
    total,
  ];
}
