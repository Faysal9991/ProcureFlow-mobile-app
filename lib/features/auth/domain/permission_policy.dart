import 'auth_session.dart';

abstract final class AppPermissions {
  static const purchaseRequestsView = 'purchase_requests.view';
  static const purchaseRequestsCreate = 'purchase_requests.create';
  static const purchaseRequestsManage = 'purchase_requests.manage';
  static const purchaseRequestsApprove = 'purchase_requests.approve';

  static const approvalsView = 'approvals.view';

  static const vendorsView = 'vendors.view';
  static const vendorsCreate = 'vendors.create';
  static const vendorsManage = 'vendors.manage';

  static const rfqView = 'rfq.view';
  static const rfqManage = 'rfq.manage';

  static const purchaseOrdersView = 'purchase_orders.view';
  static const purchaseOrdersCreate = 'purchase_orders.create';
  static const purchaseOrdersManage = 'purchase_orders.manage';

  static const invoicesView = 'invoices.view';
  static const invoicesCreate = 'invoices.create';
  static const invoicesManage = 'invoices.manage';

  static const paymentsView = 'payments.view';
  static const paymentsCreate = 'payments.create';
  static const paymentsManage = 'payments.manage';

  static const budgetsView = 'budgets.view';
  static const budgetsCreate = 'budgets.create';
  static const budgetsManage = 'budgets.manage';

  static const reportsView = 'reports.view';
  static const reportsExport = 'reports.export';
  static const reportsManage = 'reports.manage';

  static const attachmentsView = 'attachments.view';
  static const attachmentsUpload = 'attachments.upload';
  static const attachmentsDelete = 'attachments.delete';
}

enum RoleType {
  employee('EMPLOYEE'),
  manager('MANAGER'),
  procurement('PROCUREMENT'),
  finance('FINANCE'),
  companyAdmin('COMPANY_ADMIN'),
  superAdmin('SUPER_ADMIN');

  const RoleType(this.value);

  final String value;

  static String normalize(String role) {
    return role.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}

abstract final class PermissionPolicy {
  static bool hasExplicitPermission(AuthSession? session, String permission) {
    if (session == null) return false;
    return session.permissions.contains('*') ||
        session.permissions.contains(permission);
  }

  static bool hasPermission(AuthSession? session, String permission) {
    if (session == null) return false;
    if (session.isCompanyAdmin) return true;
    if (hasExplicitPermission(session, permission)) return true;
    if (session.permissions.isNotEmpty) return false;
    return _roleFallbackPermissions(session).contains(permission);
  }

  static bool hasAnyPermission(
    AuthSession? session,
    Iterable<String> permissions,
  ) {
    return permissions.any((permission) => hasPermission(session, permission));
  }

  static bool hasRole(AuthSession? session, RoleType role) {
    if (session == null) return false;
    return session.roles.any((item) => RoleType.normalize(item) == role.value);
  }

  static bool getIsSuperAdminOnly(AuthSession? session) {
    return hasRole(session, RoleType.superAdmin) &&
        !hasRole(session, RoleType.companyAdmin);
  }

  static bool canViewDashboard(AuthSession? session) {
    return session != null && !getIsSuperAdminOnly(session);
  }

  static bool canViewNotifications(AuthSession? session) {
    return session != null && !getIsSuperAdminOnly(session);
  }

  static bool canUseAssistant(AuthSession? session) {
    return session != null && !getIsSuperAdminOnly(session);
  }

  static bool canViewMyRequests(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseRequestsView);
  }

  static bool canCreatePurchaseRequest(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseRequestsCreate) ||
        hasPermission(session, AppPermissions.purchaseRequestsManage);
  }

  static bool canManagePurchaseRequests(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseRequestsManage);
  }

  static bool canEditPurchaseRequest({
    required AuthSession? session,
    required String requesterId,
    required String status,
  }) {
    if (canManagePurchaseRequests(session)) return true;
    return _isOwn(session, requesterId) &&
        canCreatePurchaseRequest(session) &&
        status == 'DRAFT';
  }

  static bool canSubmitPurchaseRequest({
    required AuthSession? session,
    required String requesterId,
    required String status,
  }) {
    return _isOwn(session, requesterId) &&
        canCreatePurchaseRequest(session) &&
        status == 'DRAFT';
  }

  static bool canCancelPurchaseRequest({
    required AuthSession? session,
    required String requesterId,
    required String status,
  }) {
    if (canManagePurchaseRequests(session)) return true;
    return _isOwn(session, requesterId) &&
        canCreatePurchaseRequest(session) &&
        (status == 'DRAFT' || status == 'SUBMITTED');
  }

  static bool canViewApprovals(AuthSession? session) {
    return hasPermission(session, AppPermissions.approvalsView) ||
        hasPermission(session, AppPermissions.purchaseRequestsApprove);
  }

  static bool canApprove(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseRequestsApprove);
  }

  static bool canViewVendors(AuthSession? session) {
    return hasPermission(session, AppPermissions.vendorsView) ||
        hasPermission(session, AppPermissions.vendorsCreate) ||
        hasPermission(session, AppPermissions.vendorsManage);
  }

  static bool canCreateVendor(AuthSession? session) {
    return hasPermission(session, AppPermissions.vendorsCreate) ||
        hasPermission(session, AppPermissions.vendorsManage);
  }

  static bool canManageVendors(AuthSession? session) {
    return hasPermission(session, AppPermissions.vendorsManage);
  }

  static bool canViewRfq(AuthSession? session) {
    return hasPermission(session, AppPermissions.rfqView) ||
        hasPermission(session, AppPermissions.rfqManage);
  }

  static bool canManageRfq(AuthSession? session) {
    return hasPermission(session, AppPermissions.rfqManage);
  }

  static bool canViewPurchaseOrders(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseOrdersView) ||
        hasPermission(session, AppPermissions.purchaseOrdersCreate) ||
        hasPermission(session, AppPermissions.purchaseOrdersManage);
  }

  static bool canViewPurchaseOrderDetail(AuthSession? session) {
    return canViewPurchaseOrders(session) ||
        canViewPoForInvoiceContext(session);
  }

  static bool canViewPoForInvoiceContext(AuthSession? session) {
    return hasRole(session, RoleType.finance) ||
        hasAnyPermission(session, const [
          AppPermissions.invoicesView,
          AppPermissions.invoicesCreate,
          AppPermissions.invoicesManage,
        ]);
  }

  static bool canCreatePurchaseOrder(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseOrdersCreate) ||
        hasPermission(session, AppPermissions.purchaseOrdersManage);
  }

  static bool canManagePurchaseOrders(AuthSession? session) {
    return hasPermission(session, AppPermissions.purchaseOrdersManage);
  }

  static bool canViewInvoices(AuthSession? session) {
    return hasPermission(session, AppPermissions.invoicesView) ||
        hasPermission(session, AppPermissions.invoicesCreate) ||
        hasPermission(session, AppPermissions.invoicesManage);
  }

  static bool canCreateInvoice(AuthSession? session) {
    return hasPermission(session, AppPermissions.invoicesCreate) ||
        hasPermission(session, AppPermissions.invoicesManage);
  }

  static bool canManageInvoices(AuthSession? session) {
    return hasPermission(session, AppPermissions.invoicesManage);
  }

  static bool canViewPayments(AuthSession? session) {
    return hasPermission(session, AppPermissions.paymentsView) ||
        hasPermission(session, AppPermissions.paymentsCreate) ||
        hasPermission(session, AppPermissions.paymentsManage);
  }

  static bool canCreatePayment(AuthSession? session) {
    return hasPermission(session, AppPermissions.paymentsCreate) ||
        hasPermission(session, AppPermissions.paymentsManage);
  }

  static bool canManagePayments(AuthSession? session) {
    return hasPermission(session, AppPermissions.paymentsManage);
  }

  static bool canViewBudgets(AuthSession? session) {
    return hasPermission(session, AppPermissions.budgetsView) ||
        hasPermission(session, AppPermissions.budgetsCreate) ||
        hasPermission(session, AppPermissions.budgetsManage);
  }

  static bool canCreateBudget(AuthSession? session) {
    return hasPermission(session, AppPermissions.budgetsCreate) ||
        hasPermission(session, AppPermissions.budgetsManage);
  }

  static bool canManageBudgets(AuthSession? session) {
    return hasPermission(session, AppPermissions.budgetsManage);
  }

  static bool canViewReports(AuthSession? session) {
    return hasPermission(session, AppPermissions.reportsView) ||
        hasPermission(session, AppPermissions.reportsManage);
  }

  static bool canExportReports(AuthSession? session) {
    return hasPermission(session, AppPermissions.reportsExport) ||
        hasPermission(session, AppPermissions.reportsManage);
  }

  static bool canViewAttachments({
    required AuthSession? session,
    bool isOwnPurchaseRequest = false,
  }) {
    return hasPermission(session, AppPermissions.attachmentsView) ||
        isOwnPurchaseRequest;
  }

  static bool canUploadAttachments({
    required AuthSession? session,
    bool isOwnPurchaseRequest = false,
  }) {
    return hasPermission(session, AppPermissions.attachmentsUpload) ||
        isOwnPurchaseRequest;
  }

  static bool canDeleteAttachments({
    required AuthSession? session,
    bool isOwnPurchaseRequest = false,
  }) {
    return hasPermission(session, AppPermissions.attachmentsDelete) ||
        isOwnPurchaseRequest;
  }

  static bool canUseOfflineSync(AuthSession? session) {
    return canCreatePurchaseRequest(session) || session?.isCompanyAdmin == true;
  }

  static bool canViewRoute(AuthSession? session, String path) {
    if (session == null) return false;
    if (path == '/profile' || path == '/change-password') return true;
    if (getIsSuperAdminOnly(session)) return false;
    if (path == '/dashboard') return canViewDashboard(session);
    if (path == '/assistant') return canUseAssistant(session);
    if (path == '/notifications') return canViewNotifications(session);
    if (path == '/sync-status') return canUseOfflineSync(session);

    if (path == '/requests') return canViewMyRequests(session);
    if (path == '/requests/new') return canCreatePurchaseRequest(session);
    if (_matches(path, 'requests', suffix: 'edit')) {
      return canCreatePurchaseRequest(session) ||
          canManagePurchaseRequests(session);
    }
    if (_matches(path, 'requests', suffix: 'approval-history')) {
      return canViewMyRequests(session) || canViewApprovals(session);
    }
    if (_matches(path, 'requests')) return canViewMyRequests(session);

    if (path == '/approvals') return canViewApprovals(session);
    if (_matches(path, 'approvals')) return canViewApprovals(session);

    if (path == '/vendors') return canViewVendors(session);
    if (path == '/vendors/new') return canCreateVendor(session);
    if (_matches(path, 'vendors', suffix: 'edit')) {
      return canManageVendors(session);
    }
    if (_matches(path, 'vendors')) return canViewVendors(session);

    if (path == '/rfqs') return canViewRfq(session);
    if (path == '/rfqs/new') return canManageRfq(session);
    if (_matches(path, 'rfqs', suffix: 'vendors') ||
        _matches(path, 'rfqs', suffix: 'quotations')) {
      return canManageRfq(session);
    }
    if (_matches(path, 'rfqs')) return canViewRfq(session);

    if (path == '/purchase-orders') return canViewPurchaseOrders(session);
    if (path == '/purchase-orders/new') return canCreatePurchaseOrder(session);
    if (_matches(path, 'purchase-orders', suffix: 'edit')) {
      return canManagePurchaseOrders(session);
    }
    if (_matches(path, 'purchase-orders')) {
      return canViewPurchaseOrderDetail(session);
    }

    if (path == '/invoices') return canViewInvoices(session);
    if (path == '/invoices/new') return canCreateInvoice(session);
    if (_matches(path, 'invoices', suffix: 'edit')) {
      return canManageInvoices(session);
    }
    if (_matches(path, 'invoices', suffix: 'payments/new')) {
      return canCreatePayment(session);
    }
    if (_matches(path, 'invoices', suffix: 'payments')) {
      return canViewPayments(session) || canCreatePayment(session);
    }
    if (_matches(path, 'invoices')) return canViewInvoices(session);

    if (path == '/payments') return canViewPayments(session);
    if (_matches(path, 'payments')) return canViewPayments(session);

    if (path == '/budgets') return canViewBudgets(session);
    if (path == '/budgets/new') return canCreateBudget(session);
    if (_matches(path, 'budgets', suffix: 'edit')) {
      return canManageBudgets(session);
    }
    if (_matches(path, 'budgets')) return canViewBudgets(session);

    if (path == '/reports' || path.startsWith('/reports/')) {
      return canViewReports(session);
    }

    return false;
  }

  static Set<String> _roleFallbackPermissions(AuthSession session) {
    if (session.isCompanyAdmin) return _allTenantPermissions;
    final values = <String>{};
    if (hasRole(session, RoleType.employee)) {
      values.addAll({
        AppPermissions.purchaseRequestsView,
        AppPermissions.purchaseRequestsCreate,
      });
    }
    if (hasRole(session, RoleType.manager)) {
      values.addAll({
        AppPermissions.purchaseRequestsView,
        AppPermissions.approvalsView,
        AppPermissions.purchaseRequestsApprove,
        AppPermissions.attachmentsView,
      });
    }
    if (hasRole(session, RoleType.procurement)) {
      values.addAll({
        AppPermissions.purchaseRequestsView,
        AppPermissions.approvalsView,
        AppPermissions.vendorsView,
        AppPermissions.vendorsCreate,
        AppPermissions.vendorsManage,
        AppPermissions.rfqView,
        AppPermissions.rfqManage,
        AppPermissions.purchaseOrdersView,
        AppPermissions.purchaseOrdersCreate,
        AppPermissions.purchaseOrdersManage,
        AppPermissions.reportsView,
        AppPermissions.attachmentsView,
        AppPermissions.attachmentsUpload,
        AppPermissions.attachmentsDelete,
      });
    }
    if (hasRole(session, RoleType.finance)) {
      values.addAll({
        AppPermissions.invoicesView,
        AppPermissions.invoicesCreate,
        AppPermissions.invoicesManage,
        AppPermissions.paymentsView,
        AppPermissions.paymentsCreate,
        AppPermissions.paymentsManage,
        AppPermissions.budgetsView,
        AppPermissions.budgetsCreate,
        AppPermissions.budgetsManage,
        AppPermissions.reportsView,
        AppPermissions.reportsExport,
        AppPermissions.attachmentsView,
        AppPermissions.attachmentsUpload,
        AppPermissions.attachmentsDelete,
      });
    }
    return values;
  }

  static bool _isOwn(AuthSession? session, String ownerId) {
    return session != null &&
        (ownerId == session.userId || ownerId == 'current-user');
  }

  static bool _matches(String path, String root, {String? suffix}) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 2 || parts.first != root) return false;
    if (suffix == null) return parts.length == 2 || parts.length > 2;
    final suffixParts = suffix.split('/');
    if (parts.length != 2 + suffixParts.length) return false;
    for (var i = 0; i < suffixParts.length; i++) {
      if (parts[2 + i] != suffixParts[i]) return false;
    }
    return true;
  }

  static const _allTenantPermissions = {
    AppPermissions.purchaseRequestsView,
    AppPermissions.purchaseRequestsCreate,
    AppPermissions.purchaseRequestsManage,
    AppPermissions.purchaseRequestsApprove,
    AppPermissions.approvalsView,
    AppPermissions.vendorsView,
    AppPermissions.vendorsCreate,
    AppPermissions.vendorsManage,
    AppPermissions.rfqView,
    AppPermissions.rfqManage,
    AppPermissions.purchaseOrdersView,
    AppPermissions.purchaseOrdersCreate,
    AppPermissions.purchaseOrdersManage,
    AppPermissions.invoicesView,
    AppPermissions.invoicesCreate,
    AppPermissions.invoicesManage,
    AppPermissions.paymentsView,
    AppPermissions.paymentsCreate,
    AppPermissions.paymentsManage,
    AppPermissions.budgetsView,
    AppPermissions.budgetsCreate,
    AppPermissions.budgetsManage,
    AppPermissions.reportsView,
    AppPermissions.reportsExport,
    AppPermissions.reportsManage,
    AppPermissions.attachmentsView,
    AppPermissions.attachmentsUpload,
    AppPermissions.attachmentsDelete,
  };
}
