import '../../../core/domain/base_entity.dart';

class PurchaseRequestItemEntity extends SyncableEntity {
  const PurchaseRequestItemEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.requestLocalId,
    required this.name,
    required this.description,
    required this.quantity,
    this.unit = 'pcs',
    required this.unitPrice,
    required this.lineTotal,
  });

  final String requestLocalId;
  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [
    ...super.props,
    requestLocalId,
    name,
    description,
    quantity,
    unit,
    unitPrice,
    lineTotal,
  ];
}

class PurchaseRequestEntity extends SyncableEntity {
  const PurchaseRequestEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.requestNumber,
    required this.title,
    required this.description,
    required this.requesterId,
    this.requesterName,
    required this.departmentId,
    this.departmentName,
    required this.priority,
    required this.neededDate,
    required this.status,
    required this.totalAmount,
    required this.items,
    this.rejectionReason,
    this.budgetCheck,
    this.approvalStatus,
  });

  final String requestNumber;
  final String title;
  final String? description;
  final String requesterId;
  final String? requesterName;
  final String? departmentId;
  final String? departmentName;
  final String priority;
  final DateTime? neededDate;
  final String status;
  final double totalAmount;
  final List<PurchaseRequestItemEntity> items;
  final String? rejectionReason;
  final BudgetCheck? budgetCheck;
  final String? approvalStatus;

  String get normalizedStatus => normalizePurchaseRequestStatus(status);

  String get normalizedPriority => normalizePurchaseRequestPriority(priority);

  bool get isDraft => normalizedStatus == PurchaseRequestStatus.draft;

  bool get isSubmitted => normalizedStatus == PurchaseRequestStatus.submitted;

  bool get isApproved => normalizedStatus == PurchaseRequestStatus.approved;

  bool get isRejected => normalizedStatus == PurchaseRequestStatus.rejected;

  bool get isCancelled => normalizedStatus == PurchaseRequestStatus.cancelled;

  bool get hasPurchaseOrder =>
      normalizedStatus == PurchaseRequestStatus.poCreated;

  bool get canEdit => isDraft;

  bool get canSubmit => isDraft;

  bool get canCancel => isDraft || isSubmitted;

  bool get canViewApprovalHistory => isSubmitted || isRejected;

  @override
  List<Object?> get props => [
    ...super.props,
    requestNumber,
    title,
    description,
    requesterId,
    requesterName,
    departmentId,
    departmentName,
    priority,
    neededDate,
    status,
    totalAmount,
    items,
    rejectionReason,
    budgetCheck,
    approvalStatus,
  ];
}

class PurchaseRequestItemInput {
  const PurchaseRequestItemInput({
    required this.name,
    required this.description,
    required this.quantity,
    this.unit = 'pcs',
    required this.estimatedUnitPrice,
  });

  final String name;
  final String? description;
  final double quantity;
  final String unit;
  final double estimatedUnitPrice;

  double get unitPrice => estimatedUnitPrice;

  double get lineTotal => quantity * estimatedUnitPrice;
}

class PurchaseRequestPayload {
  const PurchaseRequestPayload({
    required this.title,
    required this.description,
    required this.priority,
    required this.neededDate,
    required this.items,
  });

  final String title;
  final String? description;
  final String priority;
  final DateTime? neededDate;
  final List<PurchaseRequestItemInput> items;

  double get totalAmount {
    return items.fold(0, (total, item) => total + item.lineTotal);
  }
}

class CreatePurchaseRequestInput extends PurchaseRequestPayload {
  const CreatePurchaseRequestInput({
    required this.companyId,
    required this.requesterId,
    required super.title,
    required super.description,
    required super.priority,
    required super.neededDate,
    required super.items,
    this.forceOffline = false,
  });

  final String companyId;
  final String requesterId;
  final bool forceOffline;
}

class PurchaseRequestFilters {
  const PurchaseRequestFilters({
    this.search,
    this.status,
    this.priority,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final String? priority;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  PurchaseRequestFilters copyWith({
    String? search,
    String? status,
    String? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return PurchaseRequestFilters(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      priority: clearPriority ? null : priority ?? this.priority,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class PurchaseRequestPage {
  const PurchaseRequestPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PurchaseRequestEntity> items;
  final int page;
  final int limit;
  final int total;
}

class BudgetCheck {
  const BudgetCheck({
    required this.status,
    required this.message,
    required this.availableAmount,
  });

  final String status;
  final String message;
  final double availableAmount;
}

class ApprovalHistoryEntry {
  const ApprovalHistoryEntry({
    required this.id,
    required this.approverName,
    required this.action,
    required this.status,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String approverName;
  final String action;
  final String status;
  final String? comment;
  final DateTime createdAt;
}

abstract final class PurchaseRequestStatus {
  static const draft = 'DRAFT';
  static const submitted = 'SUBMITTED';
  static const approved = 'APPROVED';
  static const rejected = 'REJECTED';
  static const cancelled = 'CANCELLED';
  static const poCreated = 'PO_CREATED';
}

abstract final class PurchaseRequestPriority {
  static const low = 'LOW';
  static const normal = 'NORMAL';
  static const high = 'HIGH';
  static const urgent = 'URGENT';
}

String normalizePurchaseRequestStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    PurchaseRequestStatus.submitted => PurchaseRequestStatus.submitted,
    PurchaseRequestStatus.approved => PurchaseRequestStatus.approved,
    PurchaseRequestStatus.rejected => PurchaseRequestStatus.rejected,
    'CANCELED' ||
    PurchaseRequestStatus.cancelled => PurchaseRequestStatus.cancelled,
    PurchaseRequestStatus.poCreated => PurchaseRequestStatus.poCreated,
    _ => PurchaseRequestStatus.draft,
  };
}

String normalizePurchaseRequestPriority(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    PurchaseRequestPriority.low => PurchaseRequestPriority.low,
    PurchaseRequestPriority.high => PurchaseRequestPriority.high,
    PurchaseRequestPriority.urgent => PurchaseRequestPriority.urgent,
    _ => PurchaseRequestPriority.normal,
  };
}
