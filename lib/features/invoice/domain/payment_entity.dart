import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';

abstract final class PaymentMethod {
  static const cash = 'CASH';
  static const bankTransfer = 'BANK_TRANSFER';
  static const cheque = 'CHEQUE';
  static const mobileBanking = 'MOBILE_BANKING';
  static const card = 'CARD';
  static const online = 'ONLINE';
  static const other = 'OTHER';

  static const values = [
    cash,
    bankTransfer,
    cheque,
    mobileBanking,
    card,
    online,
    other,
  ];
}

String normalizePaymentMethod(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    PaymentMethod.cash => PaymentMethod.cash,
    PaymentMethod.bankTransfer ||
    'BANK' ||
    'TRANSFER' => PaymentMethod.bankTransfer,
    PaymentMethod.cheque || 'CHECK' => PaymentMethod.cheque,
    PaymentMethod.mobileBanking || 'MOBILE' => PaymentMethod.mobileBanking,
    PaymentMethod.card || 'CREDIT_CARD' || 'DEBIT_CARD' => PaymentMethod.card,
    PaymentMethod.online || 'ONLINE_PAYMENT' => PaymentMethod.online,
    _ => PaymentMethod.other,
  };
}

class Payment extends SyncableEntity {
  const Payment({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
    required this.createdById,
    required this.createdByName,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final DateTime? paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String createdById;
  final String createdByName;

  String get normalizedPaymentMethod => normalizePaymentMethod(paymentMethod);

  @override
  List<Object?> get props => [
    ...super.props,
    invoiceId,
    invoiceNumber,
    vendorId,
    vendorName,
    paymentDate,
    amount,
    paymentMethod,
    referenceNumber,
    notes,
    createdById,
    createdByName,
  ];
}

class PaymentPage extends Equatable {
  const PaymentPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Payment> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class PaymentFilters extends Equatable {
  const PaymentFilters({
    this.invoiceId,
    this.vendorId,
    this.paymentMethod,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? invoiceId;
  final String? vendorId;
  final String? paymentMethod;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  PaymentFilters copyWith({
    String? invoiceId,
    bool clearInvoiceId = false,
    String? vendorId,
    bool clearVendorId = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    int? page,
    int? limit,
  }) {
    return PaymentFilters(
      invoiceId: clearInvoiceId ? null : invoiceId ?? this.invoiceId,
      vendorId: clearVendorId ? null : vendorId ?? this.vendorId,
      paymentMethod: clearPaymentMethod
          ? null
          : paymentMethod ?? this.paymentMethod,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    invoiceId,
    vendorId,
    paymentMethod,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}

class CreatePaymentPayload extends Equatable {
  const CreatePaymentPayload({
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.notes,
  });

  final DateTime? paymentDate;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;

  @override
  List<Object?> get props => [
    paymentDate,
    amount,
    paymentMethod,
    referenceNumber,
    notes,
  ];
}
