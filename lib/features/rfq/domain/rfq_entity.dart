import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';
import '../../../core/sync/sync_status.dart';

class Rfq extends SyncableEntity {
  const Rfq({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.rfqNumber,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.vendorCount,
    required this.quotationCount,
    required this.selectedQuotationId,
    required this.items,
    required this.vendors,
    required this.quotations,
  });

  final String rfqNumber;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final DateTime? dueDate;
  final String status;
  final String? notes;
  final int vendorCount;
  final int quotationCount;
  final String? selectedQuotationId;
  final List<RfqItem> items;
  final List<RfqVendor> vendors;
  final List<Quotation> quotations;

  String get normalizedStatus => normalizeRfqStatus(status);

  bool get isDraft => normalizedStatus == RfqStatus.draft;

  bool get isOpen => normalizedStatus == RfqStatus.open;

  bool get hasQuotationReceived =>
      normalizedStatus == RfqStatus.quotationReceived;

  bool get canAddVendors => isDraft || isOpen || hasQuotationReceived;

  bool get canOpen => isDraft;

  bool get canAddQuotations => isOpen || hasQuotationReceived;

  bool get canCompareQuotations =>
      quotationCount > 0 &&
      (isOpen ||
          hasQuotationReceived ||
          normalizedStatus == RfqStatus.completed);

  @override
  List<Object?> get props => [
    ...super.props,
    rfqNumber,
    purchaseRequestId,
    purchaseRequestNumber,
    purchaseRequestTitle,
    dueDate,
    status,
    notes,
    vendorCount,
    quotationCount,
    selectedQuotationId,
    items,
    vendors,
    quotations,
  ];
}

class RfqItem extends Equatable {
  const RfqItem({
    required this.id,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.estimatedUnitPrice,
  });

  final String id;
  final String itemName;
  final String? description;
  final double quantity;
  final String unit;
  final double estimatedUnitPrice;

  @override
  List<Object?> get props => [
    id,
    itemName,
    description,
    quantity,
    unit,
    estimatedUnitPrice,
  ];
}

class RfqVendor extends Equatable {
  const RfqVendor({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.contactPerson,
    required this.email,
    required this.phone,
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final String? contactPerson;
  final String? email;
  final String? phone;

  @override
  List<Object?> get props => [
    id,
    vendorId,
    vendorName,
    contactPerson,
    email,
    phone,
  ];
}

class Quotation extends SyncableEntity {
  const Quotation({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.rfqId,
    required this.vendorId,
    required this.vendorName,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.status,
    required this.totalAmount,
    required this.notes,
    required this.items,
  });

  final String rfqId;
  final String vendorId;
  final String vendorName;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final String status;
  final double totalAmount;
  final String? notes;
  final List<QuotationItem> items;

  @override
  List<Object?> get props => [
    ...super.props,
    rfqId,
    vendorId,
    vendorName,
    quotationNumber,
    quotationDate,
    validUntil,
    status,
    totalAmount,
    notes,
    items,
  ];
}

class QuotationItem extends Equatable {
  const QuotationItem({
    required this.id,
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String id;
  final String rfqItemId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  @override
  List<Object?> get props => [
    id,
    rfqItemId,
    itemName,
    quantity,
    unitPrice,
    totalPrice,
  ];
}

class CreateRfqPayload extends Equatable {
  const CreateRfqPayload({
    required this.purchaseRequestId,
    required this.dueDate,
    required this.notes,
  });

  final String purchaseRequestId;
  final DateTime? dueDate;
  final String? notes;

  @override
  List<Object?> get props => [purchaseRequestId, dueDate, notes];
}

class AssignRfqVendorsPayload extends Equatable {
  const AssignRfqVendorsPayload({required this.vendorIds});

  final List<String> vendorIds;

  @override
  List<Object?> get props => [vendorIds];
}

class CreateQuotationPayload extends Equatable {
  const CreateQuotationPayload({
    required this.vendorId,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.notes,
    required this.items,
  });

  final String vendorId;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final String? notes;
  final List<CreateQuotationItemInput> items;

  double get totalAmount {
    return items.fold(0, (total, item) => total + item.totalPrice);
  }

  @override
  List<Object?> get props => [
    vendorId,
    quotationNumber,
    quotationDate,
    validUntil,
    notes,
    items,
  ];
}

class CreateQuotationItemInput extends Equatable {
  const CreateQuotationItemInput({
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  final String rfqItemId;
  final String itemName;
  final double quantity;
  final double unitPrice;

  double get totalPrice => quantity * unitPrice;

  @override
  List<Object?> get props => [rfqItemId, itemName, quantity, unitPrice];
}

class SelectedQuotationPayload extends Equatable {
  const SelectedQuotationPayload({required this.quotationId});

  final String quotationId;

  @override
  List<Object?> get props => [quotationId];
}

class RfqComparison extends Equatable {
  const RfqComparison({
    required this.rfqId,
    required this.rfqNumber,
    required this.status,
    required this.purchaseRequestId,
    required this.purchaseRequestNumber,
    required this.purchaseRequestTitle,
    required this.quotations,
    required this.lowestQuotationId,
    required this.selectedQuotationId,
    this.purchaseOrderId,
  });

  final String rfqId;
  final String rfqNumber;
  final String status;
  final String purchaseRequestId;
  final String purchaseRequestNumber;
  final String purchaseRequestTitle;
  final List<RfqComparisonQuotation> quotations;
  final String? lowestQuotationId;
  final String? selectedQuotationId;
  final String? purchaseOrderId;

  String get normalizedStatus => normalizeRfqStatus(status);

  bool get hasQuotations => quotations.isNotEmpty;

  bool get canSelectWinner {
    return hasQuotations &&
        (normalizedStatus == RfqStatus.open ||
            normalizedStatus == RfqStatus.quotationReceived);
  }

  @override
  List<Object?> get props => [
    rfqId,
    rfqNumber,
    status,
    purchaseRequestId,
    purchaseRequestNumber,
    purchaseRequestTitle,
    quotations,
    lowestQuotationId,
    selectedQuotationId,
    purchaseOrderId,
  ];
}

class RfqComparisonQuotation extends Equatable {
  const RfqComparisonQuotation({
    required this.quotationId,
    required this.vendorId,
    required this.vendorName,
    required this.quotationNumber,
    required this.quotationDate,
    required this.validUntil,
    required this.totalAmount,
    required this.rank,
    required this.items,
  });

  final String quotationId;
  final String vendorId;
  final String vendorName;
  final String quotationNumber;
  final DateTime? quotationDate;
  final DateTime? validUntil;
  final double totalAmount;
  final int rank;
  final List<RfqComparisonItem> items;

  @override
  List<Object?> get props => [
    quotationId,
    vendorId,
    vendorName,
    quotationNumber,
    quotationDate,
    validUntil,
    totalAmount,
    rank,
    items,
  ];
}

class RfqComparisonItem extends Equatable {
  const RfqComparisonItem({
    required this.rfqItemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String rfqItemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [
    rfqItemId,
    itemName,
    quantity,
    unit,
    unitPrice,
    lineTotal,
  ];
}

class RfqFilters extends Equatable {
  const RfqFilters({
    this.search,
    this.status,
    this.purchaseRequestId,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final String? purchaseRequestId;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [search, status, purchaseRequestId, page, limit];
}

class RfqPage extends Equatable {
  const RfqPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Rfq> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class EligiblePurchaseRequest extends Equatable {
  const EligiblePurchaseRequest({
    required this.id,
    required this.requestNumber,
    required this.title,
    required this.departmentName,
    required this.estimatedTotal,
    required this.status,
  });

  final String id;
  final String requestNumber;
  final String title;
  final String departmentName;
  final double estimatedTotal;
  final String status;

  @override
  List<Object?> get props => [
    id,
    requestNumber,
    title,
    departmentName,
    estimatedTotal,
    status,
  ];
}

abstract final class RfqStatus {
  static const draft = 'DRAFT';
  static const open = 'OPEN';
  static const quotationReceived = 'QUOTATION_RECEIVED';
  static const completed = 'COMPLETED';
  static const cancelled = 'CANCELLED';
}

String normalizeRfqStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    RfqStatus.open => RfqStatus.open,
    RfqStatus.quotationReceived => RfqStatus.quotationReceived,
    RfqStatus.completed => RfqStatus.completed,
    'CANCELED' || RfqStatus.cancelled => RfqStatus.cancelled,
    _ => RfqStatus.draft,
  };
}

Rfq emptyRfq(String id) {
  final now = DateTime.now();
  return Rfq(
    localId: id,
    serverId: id,
    companyId: '',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    rfqNumber: '',
    purchaseRequestId: '',
    purchaseRequestNumber: '',
    purchaseRequestTitle: '',
    dueDate: null,
    status: RfqStatus.draft,
    notes: null,
    vendorCount: 0,
    quotationCount: 0,
    selectedQuotationId: null,
    items: const [],
    vendors: const [],
    quotations: const [],
  );
}
