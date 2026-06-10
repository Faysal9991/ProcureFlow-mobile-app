import 'package:equatable/equatable.dart';

enum ReportType {
  purchaseRequests(
    'purchase-requests',
    'Purchase Requests',
    '/reports/purchase-requests',
  ),
  approvals('approvals', 'Approvals', '/reports/approvals'),
  purchaseOrders(
    'purchase-orders',
    'Purchase Orders',
    '/reports/purchase-orders',
  ),
  invoices('invoices', 'Invoices', '/reports/invoices'),
  payments('payments', 'Payments', '/reports/payments');

  const ReportType(this.apiKey, this.label, this.route);

  final String apiKey;
  final String label;
  final String route;
}

class ReportFilters extends Equatable {
  const ReportFilters({
    this.search,
    this.dateFrom,
    this.dateTo,
    this.status,
    this.departmentId,
    this.vendorId,
    this.userId,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status;
  final String? departmentId;
  final String? vendorId;
  final String? userId;
  final int page;
  final int limit;

  ReportFilters copyWith({
    String? search,
    bool clearSearch = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? status,
    bool clearStatus = false,
    String? departmentId,
    bool clearDepartmentId = false,
    String? vendorId,
    bool clearVendorId = false,
    String? userId,
    bool clearUserId = false,
    int? page,
    int? limit,
  }) {
    return ReportFilters(
      search: clearSearch ? null : search ?? this.search,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      status: clearStatus ? null : status ?? this.status,
      departmentId: clearDepartmentId
          ? null
          : departmentId ?? this.departmentId,
      vendorId: clearVendorId ? null : vendorId ?? this.vendorId,
      userId: clearUserId ? null : userId ?? this.userId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    search,
    dateFrom,
    dateTo,
    status,
    departmentId,
    vendorId,
    userId,
    page,
    limit,
  ];
}

class ReportPage extends Equatable {
  const ReportPage({
    required this.items,
    required this.summary,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> summary;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, summary, page, limit, total];
}
