import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../auth/domain/auth_session.dart';
import '../../purchase_request/domain/purchase_request_entity.dart';
import '../domain/approval_repository.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  const ApprovalRepositoryImpl({
    required AppConfig config,
    required ProcurementApi api,
    required ProcurementDao dao,
  }) : _config = config,
       _api = api,
       _dao = dao;

  final AppConfig _config;
  final ProcurementApi _api;
  final ProcurementDao _dao;

  @override
  Future<ApprovalInboxPage> getInbox(
    AuthSession session,
    ApprovalInboxFilters filters,
  ) async {
    if (_config.useMockApi) {
      final rows = await _dao.getPurchaseRequests(session.companyId);
      final items = rows
          .where(
            (row) =>
                normalizePurchaseRequestStatus(row.status) ==
                PurchaseRequestStatus.submitted,
          )
          .map(_localItem)
          .where((item) => _matches(item, filters))
          .toList();
      final start = (filters.page - 1) * filters.limit;
      final pageItems = start >= items.length
          ? <ApprovalInboxItem>[]
          : items.skip(start).take(filters.limit).toList();
      return ApprovalInboxPage(
        items: pageItems,
        page: filters.page,
        limit: filters.limit,
        total: items.length,
      );
    }

    final response = await _api.getApprovalInbox(
      _stringQuery(filters.search),
      filters.priority == null
          ? null
          : normalizeApprovalPriority(filters.priority!),
      _stringQuery(filters.departmentId),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );

    return ApprovalInboxPage(
      items: response.items.map(_remoteItem).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<void> approve(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    payload.validateApprove();
    if (_config.useMockApi) {
      return _dao.updatePurchaseRequestStatus(
        requestLocalId: requestId,
        actorId: session.userId,
        companyId: session.companyId,
        action: 'approved',
        comment: payload.normalizedComment ?? '',
      );
    }

    return _api.approveRequest(
      requestId,
      ApprovalDecisionRequestDto(comment: payload.normalizedComment),
    );
  }

  @override
  Future<void> reject(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    payload.validateReject();
    if (_config.useMockApi) {
      return _dao.updatePurchaseRequestStatus(
        requestLocalId: requestId,
        actorId: session.userId,
        companyId: session.companyId,
        action: 'rejected',
        comment: payload.normalizedComment!,
      );
    }

    return _api.rejectRequest(
      requestId,
      ApprovalDecisionRequestDto(comment: payload.normalizedComment),
    );
  }

  ApprovalInboxItem _remoteItem(ApprovalInboxItemDto dto) {
    return ApprovalInboxItem(
      requestId: dto.requestId,
      requestNumber: dto.requestNumber,
      title: dto.title,
      requesterName: dto.requesterName,
      departmentId: dto.departmentId,
      departmentName: dto.departmentName,
      priority: dto.priority,
      neededDate: dto.neededDate,
      estimatedTotal: dto.estimatedTotal,
      currentApprovalStep: dto.currentApprovalStep,
      createdAt: dto.createdAt,
    );
  }

  ApprovalInboxItem _localItem(PurchaseRequest row) {
    return ApprovalInboxItem(
      requestId: row.localId,
      requestNumber: row.requestNumber,
      title: row.title,
      requesterName: row.requesterId,
      departmentId: row.departmentId,
      departmentName: row.departmentId ?? 'General',
      priority: normalizePurchaseRequestPriority(row.priority),
      neededDate: row.neededDate,
      estimatedTotal: row.totalAmount,
      currentApprovalStep: 'Pending approval',
      createdAt: row.createdAt,
    );
  }

  bool _matches(ApprovalInboxItem item, ApprovalInboxFilters filters) {
    final search = filters.search?.trim().toLowerCase();
    if (search != null &&
        search.isNotEmpty &&
        !item.title.toLowerCase().contains(search) &&
        !item.requestNumber.toLowerCase().contains(search) &&
        !item.requesterName.toLowerCase().contains(search)) {
      return false;
    }
    if (filters.priority != null &&
        item.priority != normalizeApprovalPriority(filters.priority!)) {
      return false;
    }
    if (filters.departmentId != null &&
        filters.departmentId!.trim().isNotEmpty &&
        item.departmentId != filters.departmentId!.trim()) {
      return false;
    }
    if (filters.dateFrom != null &&
        item.createdAt.isBefore(filters.dateFrom!)) {
      return false;
    }
    if (filters.dateTo != null &&
        item.createdAt.isAfter(filters.dateTo!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  String? _stringQuery(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _dateQuery(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }
}
