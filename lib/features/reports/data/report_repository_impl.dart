import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required ProcurementApi api,
    required Dio dio,
    required ProcurementDao dao,
    required AppConfig config,
  }) : _api = api,
       _dio = dio,
       _dao = dao,
       _config = config;

  final ProcurementApi _api;
  final Dio _dio;
  final ProcurementDao _dao;
  final AppConfig _config;

  @override
  Future<ReportPage> getReport(ReportType type, ReportFilters filters) async {
    if (_config.useMockApi) {
      final page = await _mockReport(type, filters);
      return page;
    }

    final queries = _queries(filters);
    final dto = switch (type) {
      ReportType.purchaseRequests => await _api.getPurchaseRequestReport(
        queries,
      ),
      ReportType.approvals => await _api.getApprovalReport(queries),
      ReportType.purchaseOrders => await _api.getPurchaseOrderReport(queries),
      ReportType.invoices => await _api.getInvoiceReport(queries),
      ReportType.payments => await _api.getPaymentReport(queries),
    };
    return _fromDto(dto);
  }

  @override
  Future<String> exportReport({
    required ReportType type,
    required ReportFilters filters,
    required String format,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final normalizedFormat = _normalizeFormat(format);
    final dir = await getTemporaryDirectory();
    final fileName =
        '${type.apiKey}-${DateTime.now().millisecondsSinceEpoch}.$normalizedFormat';
    final path = p.join(dir.path, fileName);

    if (_config.useMockApi) {
      final page = await _mockReport(type, filters);
      final file = File(path);
      await file.writeAsString(_toCsv(page.items));
      return path;
    }

    await _dio.download(
      _exportEndpoint(type),
      path,
      queryParameters: {..._queries(filters), 'format': normalizedFormat},
      onReceiveProgress: onReceiveProgress,
    );
    return path;
  }

  Future<ReportPage> _mockReport(ReportType type, ReportFilters filters) async {
    final items = switch (type) {
      ReportType.purchaseRequests => [
        for (final item in await _dao.getPurchaseRequests('company-demo'))
          {
            'number': item.requestNumber,
            'title': item.title,
            'status': item.status,
            'total': item.totalAmount,
            'createdAt': item.createdAt.toIso8601String(),
          },
      ],
      ReportType.approvals => [
        for (final item in await _dao.getPurchaseRequests('company-demo'))
          if (item.status.toUpperCase() == 'SUBMITTED')
            {
              'number': item.requestNumber,
              'title': item.title,
              'status': item.status,
              'createdAt': item.createdAt.toIso8601String(),
            },
      ],
      ReportType.purchaseOrders => [
        for (final item in await _dao.getPurchaseOrders('company-demo'))
          {
            'number': item.poNumber,
            'vendor': item.vendorName,
            'status': item.status,
            'total': item.totalAmount,
            'createdAt': item.createdAt.toIso8601String(),
          },
      ],
      ReportType.invoices => [
        for (final item in await _dao.getInvoices('company-demo'))
          {
            'number': item.invoiceNumber,
            'vendor': item.vendorName,
            'status': item.status,
            'amount': item.invoiceAmount,
            'due': item.dueAmount,
          },
      ],
      ReportType.payments => [
        for (final item in await _dao.getPayments('company-demo'))
          {
            'invoice': item.invoiceNumber,
            'vendor': item.vendorName,
            'method': item.paymentMethod,
            'amount': item.amount,
            'paymentDate': item.paymentDate.toIso8601String(),
          },
      ],
    };
    final search = filters.search?.trim().toLowerCase();
    final filtered = search == null || search.length < 2
        ? items
        : items
              .where((item) => jsonEncode(item).toLowerCase().contains(search))
              .toList();
    final start = (filters.page - 1) * filters.limit;
    final pageItems = start >= filtered.length
        ? <Map<String, dynamic>>[]
        : filtered.skip(start).take(filters.limit).toList();
    return ReportPage(
      items: pageItems,
      summary: {'totalRecords': filtered.length},
      page: filters.page,
      limit: filters.limit,
      total: filtered.length,
    );
  }

  ReportPage _fromDto(ReportResponseDto dto) {
    return ReportPage(
      items: dto.items,
      summary: dto.summary,
      page: dto.page,
      limit: dto.limit,
      total: dto.total,
    );
  }

  Map<String, dynamic> _queries(ReportFilters filters) {
    final values = <String, dynamic>{
      'search': _search(filters.search),
      'dateFrom': _date(filters.dateFrom),
      'dateTo': _date(filters.dateTo),
      'status': _string(filters.status),
      'departmentId': _string(filters.departmentId),
      'vendorId': _string(filters.vendorId),
      'userId': _string(filters.userId),
      'page': filters.page,
      'limit': filters.limit,
    };
    values.removeWhere((key, value) => value == null);
    return values;
  }

  String _exportEndpoint(ReportType type) {
    return switch (type) {
      ReportType.purchaseRequests => ApiEndpoints.reportPurchaseRequestsExport,
      ReportType.approvals => ApiEndpoints.reportApprovalsExport,
      ReportType.purchaseOrders => ApiEndpoints.reportPurchaseOrdersExport,
      ReportType.invoices => ApiEndpoints.reportInvoicesExport,
      ReportType.payments => ApiEndpoints.reportPaymentsExport,
    };
  }

  String _toCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 'No data\n';
    final keys = rows.expand((row) => row.keys).toSet().toList();
    final buffer = StringBuffer('${keys.join(',')}\n');
    for (final row in rows) {
      buffer.writeln(
        [
          for (final key in keys)
            '"${(row[key] ?? '').toString().replaceAll('"', '""')}"',
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String _normalizeFormat(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'xlsx' => 'xlsx',
      'pdf' => 'pdf',
      _ => 'csv',
    };
  }

  String? _search(String? value) {
    final trimmed = _string(value);
    if (trimmed == null || trimmed.length < 2) return null;
    return trimmed;
  }

  String? _string(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _date(DateTime? value) => value?.toIso8601String().split('T').first;
}
