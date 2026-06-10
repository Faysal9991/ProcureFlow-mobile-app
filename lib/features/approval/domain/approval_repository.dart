import 'package:equatable/equatable.dart';

import '../../auth/domain/auth_session.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';

abstract interface class ApprovalRepository {
  Future<ApprovalInboxPage> getInbox(
    AuthSession session,
    ApprovalInboxFilters filters,
  );

  Future<void> approve(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  );

  Future<void> reject(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  );
}

class ApprovalInboxFilters extends Equatable {
  const ApprovalInboxFilters({
    this.search,
    this.priority,
    this.departmentId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? priority;
  final String? departmentId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  ApprovalInboxFilters copyWith({
    String? search,
    String? priority,
    String? departmentId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearPriority = false,
    bool clearDepartmentId = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return ApprovalInboxFilters(
      search: clearSearch ? null : search ?? this.search,
      priority: clearPriority ? null : priority ?? this.priority,
      departmentId: clearDepartmentId
          ? null
          : departmentId ?? this.departmentId,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    search,
    priority,
    departmentId,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}

class ApprovalInboxPage extends Equatable {
  const ApprovalInboxPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<ApprovalInboxItem> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class ApprovalInboxItem extends Equatable {
  const ApprovalInboxItem({
    required this.requestId,
    required this.requestNumber,
    required this.title,
    required this.requesterName,
    required this.departmentId,
    required this.departmentName,
    required this.priority,
    required this.neededDate,
    required this.estimatedTotal,
    required this.currentApprovalStep,
    required this.createdAt,
  });

  final String requestId;
  final String requestNumber;
  final String title;
  final String requesterName;
  final String? departmentId;
  final String departmentName;
  final String priority;
  final DateTime? neededDate;
  final double estimatedTotal;
  final String currentApprovalStep;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    requestId,
    requestNumber,
    title,
    requesterName,
    departmentId,
    departmentName,
    priority,
    neededDate,
    estimatedTotal,
    currentApprovalStep,
    createdAt,
  ];
}

class ApprovalDecisionPayload extends Equatable {
  const ApprovalDecisionPayload({this.comment});

  final String? comment;

  String? get normalizedComment {
    final trimmed = comment?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void validateApprove() {
    final value = normalizedComment;
    if (value != null && value.length > 1000) {
      throw ArgumentError('Comment cannot exceed 1000 characters.');
    }
  }

  void validateReject() {
    final value = normalizedComment;
    if (value == null || value.length < 10) {
      throw ArgumentError('Reason must be at least 10 characters.');
    }
    if (value.length > 1000) {
      throw ArgumentError('Reason cannot exceed 1000 characters.');
    }
  }

  @override
  List<Object?> get props => [comment];
}

String normalizeApprovalPriority(String value) {
  return normalizePurchaseRequestPriority(value);
}
