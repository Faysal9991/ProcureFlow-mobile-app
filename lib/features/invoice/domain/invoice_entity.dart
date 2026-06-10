import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';

abstract final class InvoiceStatus {
  static const pending = 'PENDING';
  static const partiallyPaid = 'PARTIALLY_PAID';
  static const paid = 'PAID';
  static const cancelled = 'CANCELLED';

  static const values = [pending, partiallyPaid, paid, cancelled];
}

String normalizeInvoiceStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    InvoiceStatus.partiallyPaid || 'PARTIAL' => InvoiceStatus.partiallyPaid,
    InvoiceStatus.paid => InvoiceStatus.paid,
    'CANCELLED' || 'CANCELED' => InvoiceStatus.cancelled,
    _ => InvoiceStatus.pending,
  };
}

class Invoice extends SyncableEntity {
  const Invoice({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.status,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.notes,
  });

  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final String status;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double invoiceAmount;
  final double paidAmount;
  final double dueAmount;
  final String? notes;

  String get normalizedStatus => normalizeInvoiceStatus(status);

  bool get isPending => normalizedStatus == InvoiceStatus.pending;

  bool get isPartiallyPaid => normalizedStatus == InvoiceStatus.partiallyPaid;

  bool get isPaid => normalizedStatus == InvoiceStatus.paid;

  bool get isCancelled => normalizedStatus == InvoiceStatus.cancelled;

  bool get canEdit => isPending;

  bool get canCancel => isPending;

  bool get canRecordPayment => (isPending || isPartiallyPaid) && dueAmount > 0;

  @override
  List<Object?> get props => [
    ...super.props,
    invoiceNumber,
    vendorId,
    vendorName,
    purchaseOrderId,
    purchaseOrderNumber,
    status,
    invoiceDate,
    dueDate,
    invoiceAmount,
    paidAmount,
    dueAmount,
    notes,
  ];
}

class InvoicePage extends Equatable {
  const InvoicePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Invoice> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class InvoiceFilters extends Equatable {
  const InvoiceFilters({
    this.search,
    this.status,
    this.vendorId,
    this.purchaseOrderId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final String? vendorId;
  final String? purchaseOrderId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  InvoiceFilters copyWith({
    String? search,
    bool clearSearch = false,
    String? status,
    bool clearStatus = false,
    String? vendorId,
    bool clearVendorId = false,
    String? purchaseOrderId,
    bool clearPurchaseOrderId = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    int? page,
    int? limit,
  }) {
    return InvoiceFilters(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      vendorId: clearVendorId ? null : vendorId ?? this.vendorId,
      purchaseOrderId: clearPurchaseOrderId
          ? null
          : purchaseOrderId ?? this.purchaseOrderId,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    search,
    status,
    vendorId,
    purchaseOrderId,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}

class CreateInvoicePayload extends Equatable {
  const CreateInvoicePayload({
    required this.purchaseOrderId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.notes,
  });

  final String purchaseOrderId;
  final String invoiceNumber;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double invoiceAmount;
  final String? notes;

  @override
  List<Object?> get props => [
    purchaseOrderId,
    invoiceNumber,
    invoiceDate,
    dueDate,
    invoiceAmount,
    notes,
  ];
}

class UpdateInvoicePayload extends Equatable {
  const UpdateInvoicePayload({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.notes,
  });

  final String invoiceNumber;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double invoiceAmount;
  final String? notes;

  @override
  List<Object?> get props => [
    invoiceNumber,
    invoiceDate,
    dueDate,
    invoiceAmount,
    notes,
  ];
}
