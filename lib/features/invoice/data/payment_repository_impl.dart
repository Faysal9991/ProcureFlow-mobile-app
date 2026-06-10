import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/invoice_entity.dart';
import '../domain/payment_entity.dart';
import '../domain/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
  }) : _dao = dao,
       _api = api,
       _config = config;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;
  final Uuid _uuid = const Uuid();

  @override
  Future<PaymentPage> getPayments(PaymentFilters filters) async {
    if (_config.useMockApi) {
      final rows = await _dao.getPayments('company-demo');
      final all = rows.map(_toEntity).toList();
      final filtered = all
          .where((payment) => _matches(payment, filters))
          .toList();
      final start = (filters.page - 1) * filters.limit;
      final items = start >= filtered.length
          ? <Payment>[]
          : filtered.skip(start).take(filters.limit).toList();
      return PaymentPage(
        items: items,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final method = _stringQuery(filters.paymentMethod);
    final response = await _api.getPayments(
      _stringQuery(filters.invoiceId),
      _stringQuery(filters.vendorId),
      method == null ? null : normalizePaymentMethod(method),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );
    return PaymentPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<Payment?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getPayment(id);
      return row == null ? null : _toEntity(row);
    }
    final page = await getPayments(const PaymentFilters(limit: 100));
    for (final payment in page.items) {
      if (payment.localId == id || payment.serverId == id) return payment;
    }
    return null;
  }

  @override
  Future<Payment> recordInvoicePayment(
    String invoiceId,
    CreatePaymentPayload payload,
  ) async {
    _validatePayload(invoiceId, payload);
    if (_config.useMockApi) {
      final invoice = await _dao.getInvoice(invoiceId.trim());
      if (invoice == null) throw StateError('Invoice not found.');
      final status = normalizeInvoiceStatus(invoice.status);
      if (status == InvoiceStatus.paid || status == InvoiceStatus.cancelled) {
        throw StateError('This invoice is not payable.');
      }
      if (payload.amount > invoice.dueAmount + 0.0001) {
        throw ArgumentError('Payment amount cannot exceed due amount.');
      }

      final now = DateTime.now();
      final localId = _uuid.v4();
      await _dao.recordPayment(
        db.PaymentsCompanion.insert(
          localId: localId,
          serverId: Value('mock-payment-$localId'),
          companyId: invoice.companyId,
          invoiceId: invoice.localId,
          invoiceNumber: invoice.invoiceNumber,
          vendorId: Value(invoice.vendorId),
          vendorName: Value(invoice.vendorName),
          paymentDate: payload.paymentDate!,
          amount: payload.amount,
          paymentMethod: normalizePaymentMethod(payload.paymentMethod),
          referenceNumber: Value(_blankToNull(payload.referenceNumber)),
          notes: Value(_blankToNull(payload.notes)),
          createdById: const Value(''),
          createdByName: const Value(''),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
      );
      return (await getById(localId))!;
    }

    return _fromDto(
      await _api.createInvoicePayment(
        invoiceId.trim(),
        CreatePaymentPayloadDto(
          paymentDate: payload.paymentDate!,
          amount: payload.amount,
          paymentMethod: normalizePaymentMethod(payload.paymentMethod),
          referenceNumber: _blankToNull(payload.referenceNumber),
          notes: _blankToNull(payload.notes),
        ),
      ),
    );
  }

  bool _matches(Payment payment, PaymentFilters filters) {
    if (filters.invoiceId != null &&
        filters.invoiceId!.trim().isNotEmpty &&
        payment.invoiceId != filters.invoiceId!.trim()) {
      return false;
    }
    if (filters.vendorId != null &&
        filters.vendorId!.trim().isNotEmpty &&
        payment.vendorId != filters.vendorId!.trim()) {
      return false;
    }
    if (filters.paymentMethod != null &&
        filters.paymentMethod!.trim().isNotEmpty &&
        payment.normalizedPaymentMethod !=
            normalizePaymentMethod(filters.paymentMethod!)) {
      return false;
    }
    final paymentDate = payment.paymentDate;
    if (paymentDate != null &&
        filters.dateFrom != null &&
        paymentDate.isBefore(filters.dateFrom!)) {
      return false;
    }
    if (paymentDate != null &&
        filters.dateTo != null &&
        paymentDate.isAfter(filters.dateTo!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  void _validatePayload(String invoiceId, CreatePaymentPayload payload) {
    if (invoiceId.trim().isEmpty) {
      throw ArgumentError('Invoice is required.');
    }
    if (payload.paymentDate == null) {
      throw ArgumentError('Payment date is required.');
    }
    if (payload.amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    if (payload.paymentMethod.trim().isEmpty) {
      throw ArgumentError('Payment method is required.');
    }
    final method = normalizePaymentMethod(payload.paymentMethod);
    if (method != PaymentMethod.cash &&
        (_blankToNull(payload.referenceNumber) == null)) {
      throw ArgumentError(
        'Reference number is required for non-cash payments.',
      );
    }
  }

  Payment _fromDto(PaymentDto dto) {
    return Payment(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      invoiceId: dto.invoiceId,
      invoiceNumber: dto.invoiceNumber,
      vendorId: dto.vendorId,
      vendorName: dto.vendorName,
      paymentDate: dto.paymentDate,
      amount: dto.amount,
      paymentMethod: dto.paymentMethod,
      referenceNumber: dto.referenceNumber,
      notes: dto.notes,
      createdById: dto.createdById,
      createdByName: dto.createdByName,
    );
  }

  Payment _toEntity(db.Payment row) {
    return Payment(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      invoiceId: row.invoiceId,
      invoiceNumber: row.invoiceNumber,
      vendorId: row.vendorId ?? '',
      vendorName: row.vendorName ?? 'Not assigned',
      paymentDate: row.paymentDate,
      amount: row.amount,
      paymentMethod: normalizePaymentMethod(row.paymentMethod),
      referenceNumber: row.referenceNumber,
      notes: row.notes,
      createdById: row.createdById ?? '',
      createdByName: row.createdByName ?? '',
    );
  }

  String? _dateQuery(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  String? _stringQuery(String? value) => _blankToNull(value);

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
