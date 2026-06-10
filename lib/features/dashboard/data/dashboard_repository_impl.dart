import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
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
  Future<DashboardSummary> getSummary(AuthSession session) async {
    if (_config.useMockApi) {
      return _mockSummary(session);
    }
    final response = await _api.getDashboardSummary();
    return _summaryFromDto(response);
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) {
    if (_config.useMockApi) {
      return _dao.countUnreadNotifications(session.companyId);
    }
    return _api.getNotificationUnreadCount().then((response) => response.count);
  }

  Future<DashboardSummary> _mockSummary(AuthSession session) async {
    final requests = await _dao.getPurchaseRequests(session.companyId);
    final orders = await _dao.getPurchaseOrders(session.companyId);
    final notifications = await _dao.getNotifications(
      session.companyId,
      limit: 5,
    );
    final pendingApprovals = requests
        .where((request) => request.status == 'submitted')
        .length;
    final totalSpend = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return DashboardSummary(
      cards: [
        DashboardSummaryCard(
          key: 'my_requests',
          label: 'My Requests',
          value: requests.length.toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'pending_approvals',
          label: 'Pending Approvals',
          value: pendingApprovals.toString(),
          requiredPermissions: const [
            'approvals.manage',
            'purchase_requests.approve',
          ],
        ),
        DashboardSummaryCard(
          key: 'purchase_orders',
          label: 'Purchase Orders',
          value: orders.length.toString(),
          requiredPermissions: const [
            'purchase_orders.view',
            'purchase_orders.create',
            'purchase_orders.manage',
          ],
        ),
        const DashboardSummaryCard(
          key: 'invoices',
          label: 'Invoices',
          value: '0',
          requiredPermissions: ['invoices.view', 'finance.view'],
        ),
        DashboardSummaryCard(
          key: 'total_spend',
          label: 'Total Spend',
          value: 'BDT ${totalSpend.toStringAsFixed(0)}',
          requiredPermissions: const ['finance.view'],
        ),
        const DashboardSummaryCard(
          key: 'due_amount',
          label: 'Due Amount',
          value: 'BDT 0',
          requiredPermissions: ['finance.view'],
        ),
      ],
      activities: [
        for (final notification in notifications)
          DashboardActivity(
            title: notification.title,
            message: notification.body,
            createdAt: notification.createdAt,
            route: notification.route,
          ),
      ],
    );
  }

  DashboardSummary _summaryFromDto(DashboardSummaryDto dto) {
    return DashboardSummary(
      cards: dto.cards.map(_cardFromDto).toList(),
      activities: [
        for (final activity in dto.activities)
          DashboardActivity(
            title: activity.title,
            message: activity.message,
            createdAt: activity.createdAt,
            route: activity.route,
          ),
      ],
    );
  }

  DashboardSummaryCard _cardFromDto(DashboardSummaryCardDto dto) {
    return DashboardSummaryCard(
      key: dto.key,
      label: dto.label,
      value: dto.value,
      requiredPermissions: _permissionsForCard(dto),
    );
  }

  List<String> _permissionsForCard(DashboardSummaryCardDto dto) {
    final permission = dto.permission;
    if (permission != null && permission.isNotEmpty) {
      return [permission];
    }
    return switch (dto.key) {
      'my_requests' || 'myRequests' => const ['purchase_requests.view'],
      'pending_approvals' || 'pendingApprovals' => const [
        'approvals.manage',
        'purchase_requests.approve',
      ],
      'purchase_orders' || 'purchaseOrders' => const [
        'purchase_orders.view',
        'purchase_orders.create',
        'purchase_orders.manage',
      ],
      'invoices' => const ['invoices.view', 'finance.view'],
      'total_spend' || 'totalSpend' => const ['finance.view'],
      'due_amount' || 'dueAmount' => const ['finance.view'],
      _ => const [],
    };
  }
}
