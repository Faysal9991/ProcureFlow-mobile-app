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
    final rfqs = await _dao.getRfqs(session.companyId);
    final orders = await _dao.getPurchaseOrders(session.companyId);
    final invoices = await _dao.getInvoices(session.companyId);
    final payments = await _dao.getPayments(session.companyId);
    final budgets = await _dao.getBudgets(session.companyId);
    final notifications = await _dao.getNotifications(
      session.companyId,
      limit: 5,
    );
    final pendingSync = await _dao.countPendingSync(session.companyId);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final pendingApprovals = requests.where(_isSubmitted).length;
    final approvedToday = requests
        .where(
          (request) =>
              _status(request.status) == 'APPROVED' &&
              _sameDate(request.updatedAt, now),
        )
        .length;
    final totalSpend = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final monthlySpend = payments
        .where(
          (payment) =>
              !payment.paymentDate.isBefore(monthStart) &&
              payment.paymentDate.isBefore(nextMonth),
        )
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final dueAmount = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.dueAmount,
    );

    return DashboardSummary(
      cards: [
        DashboardSummaryCard(
          key: 'my_drafts',
          label: 'My Drafts',
          value: requests
              .where((request) => _status(request.status) == 'DRAFT')
              .length
              .toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'submitted_requests',
          label: 'Submitted',
          value: requests.where(_isSubmitted).length.toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'approved_requests',
          label: 'Approved',
          value: requests
              .where((request) => _status(request.status) == 'APPROVED')
              .length
              .toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'rejected_requests',
          label: 'Rejected',
          value: requests
              .where((request) => _status(request.status) == 'REJECTED')
              .length
              .toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'pending_sync',
          label: 'Pending Sync',
          value: pendingSync.toString(),
          requiredPermissions: const ['purchase_requests.create'],
        ),
        DashboardSummaryCard(
          key: 'pending_approvals',
          label: 'Pending Approvals',
          value: pendingApprovals.toString(),
          requiredPermissions: const [
            'approvals.view',
            'purchase_requests.approve',
          ],
        ),
        DashboardSummaryCard(
          key: 'approved_today',
          label: 'Approved Today',
          value: approvedToday.toString(),
          requiredPermissions: const [
            'approvals.view',
            'purchase_requests.approve',
          ],
        ),
        DashboardSummaryCard(
          key: 'rejected',
          label: 'Rejected',
          value: requests
              .where((request) => _status(request.status) == 'REJECTED')
              .length
              .toString(),
          requiredPermissions: const [
            'approvals.view',
            'purchase_requests.approve',
          ],
        ),
        DashboardSummaryCard(
          key: 'high_priority',
          label: 'High Priority',
          value: requests
              .where(
                (request) =>
                    _isSubmitted(request) &&
                    (_status(request.priority) == 'HIGH' ||
                        _status(request.priority) == 'URGENT'),
              )
              .length
              .toString(),
          requiredPermissions: const [
            'approvals.view',
            'purchase_requests.approve',
          ],
        ),
        DashboardSummaryCard(
          key: 'open_rfqs',
          label: 'Open RFQs',
          value: rfqs
              .where((rfq) => _status(rfq.status) == 'OPEN')
              .length
              .toString(),
          requiredPermissions: const ['rfq.view', 'rfq.manage'],
        ),
        DashboardSummaryCard(
          key: 'quotations_received',
          label: 'Quotations Received',
          value: rfqs
              .fold<int>(0, (sum, rfq) => sum + rfq.quotationCount)
              .toString(),
          requiredPermissions: const ['rfq.view', 'rfq.manage'],
        ),
        DashboardSummaryCard(
          key: 'draft_pos',
          label: 'Draft POs',
          value: orders
              .where((order) => _status(order.status) == 'DRAFT')
              .length
              .toString(),
          requiredPermissions: const [
            'purchase_orders.view',
            'purchase_orders.create',
            'purchase_orders.manage',
          ],
        ),
        DashboardSummaryCard(
          key: 'issued_pos',
          label: 'Issued POs',
          value: orders
              .where((order) => _status(order.status) == 'ISSUED')
              .length
              .toString(),
          requiredPermissions: const [
            'purchase_orders.view',
            'purchase_orders.create',
            'purchase_orders.manage',
          ],
        ),
        DashboardSummaryCard(
          key: 'received_pos',
          label: 'Received POs',
          value: orders
              .where((order) => _status(order.status) == 'RECEIVED')
              .length
              .toString(),
          requiredPermissions: const [
            'purchase_orders.view',
            'purchase_orders.create',
            'purchase_orders.manage',
          ],
        ),
        DashboardSummaryCard(
          key: 'pending_invoices',
          label: 'Pending Invoices',
          value: invoices
              .where((invoice) => _status(invoice.status) == 'PENDING')
              .length
              .toString(),
          requiredPermissions: ['invoices.view', 'payments.view'],
        ),
        DashboardSummaryCard(
          key: 'due_amount',
          label: 'Due Amount',
          value: 'BDT ${dueAmount.toStringAsFixed(0)}',
          requiredPermissions: const ['invoices.view', 'payments.view'],
        ),
        DashboardSummaryCard(
          key: 'paid_this_month',
          label: 'Paid This Month',
          value: 'BDT ${monthlySpend.toStringAsFixed(0)}',
          requiredPermissions: const ['payments.view'],
        ),
        DashboardSummaryCard(
          key: 'active_budgets',
          label: 'Active Budgets',
          value: budgets
              .where((budget) => _status(budget.status) == 'ACTIVE')
              .length
              .toString(),
          requiredPermissions: const ['budgets.view'],
        ),
        DashboardSummaryCard(
          key: 'overdue_invoices',
          label: 'Overdue Invoices',
          value: invoices
              .where(
                (invoice) =>
                    invoice.dueDate.isBefore(now) &&
                    _status(invoice.status) != 'PAID' &&
                    _status(invoice.status) != 'CANCELLED',
              )
              .length
              .toString(),
          requiredPermissions: ['invoices.view', 'payments.view'],
        ),
        DashboardSummaryCard(
          key: 'total_requests',
          label: 'Total Requests',
          value: requests.length.toString(),
          requiredPermissions: const ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'monthly_spend',
          label: 'Monthly Spend',
          value: 'BDT ${monthlySpend.toStringAsFixed(0)}',
          requiredPermissions: const ['reports.view', 'payments.view'],
        ),
        DashboardSummaryCard(
          key: 'outstanding_due',
          label: 'Outstanding Due',
          value: 'BDT ${dueAmount.toStringAsFixed(0)}',
          requiredPermissions: const ['invoices.view', 'payments.view'],
        ),
        DashboardSummaryCard(
          key: 'total_spend',
          label: 'Total Spend',
          value: 'BDT ${totalSpend.toStringAsFixed(0)}',
          requiredPermissions: const ['reports.view', 'payments.view'],
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

  bool _isSubmitted(dynamic request) => _status(request.status) == 'SUBMITTED';

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _status(String value) {
    return value.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
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
        'approvals.view',
        'purchase_requests.approve',
      ],
      'purchase_orders' || 'purchaseOrders' => const [
        'purchase_orders.view',
        'purchase_orders.create',
        'purchase_orders.manage',
      ],
      'invoices' => const ['invoices.view', 'payments.view'],
      'total_spend' || 'totalSpend' => const ['reports.view', 'payments.view'],
      'due_amount' || 'dueAmount' => const ['invoices.view', 'payments.view'],
      _ => const [],
    };
  }
}
