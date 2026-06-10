import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';

abstract final class PurchaseOrderStatus {
  static const draft = 'DRAFT';
  static const issued = 'ISSUED';
  static const received = 'RECEIVED';
  static const closed = 'CLOSED';
  static const cancelled = 'CANCELLED';

  static const values = [draft, issued, received, closed, cancelled];
}

String normalizePurchaseOrderStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    PurchaseOrderStatus.issued => PurchaseOrderStatus.issued,
    PurchaseOrderStatus.received => PurchaseOrderStatus.received,
    PurchaseOrderStatus.closed => PurchaseOrderStatus.closed,
    'CANCELLED' || 'CANCELED' => PurchaseOrderStatus.cancelled,
    _ => PurchaseOrderStatus.draft,
  };
}

class PurchaseOrder extends SyncableEntity {
  const PurchaseOrder({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.poNumber,
    required this.vendorId,
    required this.vendorName,
    required this.rfqId,
    required this.rfqNumber,
    required this.quotationId,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.createdById,
    required this.createdByName,
    required this.status,
    required this.totalAmount,
    required this.notes,
    required this.issueDate,
    required this.receivedDate,
    required this.closedDate,
    required this.cancelledDate,
    required this.items,
  });

  final String poNumber;
  final String vendorId;
  final String vendorName;
  final String rfqId;
  final String rfqNumber;
  final String quotationId;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final String createdById;
  final String createdByName;
  final String status;
  final double totalAmount;
  final String? notes;
  final DateTime? issueDate;
  final DateTime? receivedDate;
  final DateTime? closedDate;
  final DateTime? cancelledDate;
  final List<PurchaseOrderItem> items;

  String get normalizedStatus => normalizePurchaseOrderStatus(status);

  bool get isDraft => normalizedStatus == PurchaseOrderStatus.draft;

  bool get isIssued => normalizedStatus == PurchaseOrderStatus.issued;

  bool get isReceived => normalizedStatus == PurchaseOrderStatus.received;

  bool get isClosed => normalizedStatus == PurchaseOrderStatus.closed;

  bool get isCancelled => normalizedStatus == PurchaseOrderStatus.cancelled;

  bool get canEdit => isDraft;

  bool get canIssue => isDraft;

  bool get canCancel => isDraft;

  bool get canReceive => isIssued;

  bool get canClose => isReceived;

  @override
  List<Object?> get props => [
    ...super.props,
    poNumber,
    vendorId,
    vendorName,
    rfqId,
    rfqNumber,
    quotationId,
    purchaseRequestId,
    purchaseRequestNumber,
    purchaseRequestTitle,
    createdById,
    createdByName,
    status,
    totalAmount,
    notes,
    issueDate,
    receivedDate,
    closedDate,
    cancelledDate,
    items,
  ];
}

class PurchaseOrderItem extends Equatable {
  const PurchaseOrderItem({
    required this.id,
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String id;
  final String rfqItemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [
    id,
    rfqItemId,
    itemName,
    quantity,
    unit,
    unitPrice,
    lineTotal,
  ];
}

class PurchaseOrderPage extends Equatable {
  const PurchaseOrderPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PurchaseOrder> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class PurchaseOrderFilters extends Equatable {
  const PurchaseOrderFilters({
    this.search,
    this.status,
    this.vendorId,
    this.purchaseRequestId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final String? vendorId;
  final String? purchaseRequestId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [
    search,
    status,
    vendorId,
    purchaseRequestId,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}

class CreatePurchaseOrderPayload extends Equatable {
  const CreatePurchaseOrderPayload({
    required this.quotationId,
    required this.notes,
  });

  final String quotationId;
  final String? notes;

  @override
  List<Object?> get props => [quotationId, notes];
}

class UpdatePurchaseOrderPayload extends Equatable {
  const UpdatePurchaseOrderPayload({required this.notes});

  final String? notes;

  @override
  List<Object?> get props => [notes];
}
