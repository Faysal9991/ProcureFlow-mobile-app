import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../core/widgets/app_icons.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/permission_policy.dart';

enum DashboardModuleId {
  approvals,
  requests,
  vendors,
  rfq,
  purchaseOrders,
  invoices,
  payments,
  budgets,
  reports,
}

enum DashboardQuickActionId {
  assistant,
  createRequest,
  offlineDrafts,
  notifications,
  approvalHistory,
  createVendor,
  createRfq,
  quotationComparison,
  createPurchaseOrder,
  createInvoice,
  recordPayment,
  createBudget,
}

class DashboardAccessProfile extends Equatable {
  const DashboardAccessProfile({
    required this.primaryLabel,
    required this.roleLabels,
  });

  factory DashboardAccessProfile.fromSession(AuthSession? session) {
    if (session == null || session.roles.isEmpty) {
      return const DashboardAccessProfile(
        primaryLabel: 'Employee',
        roleLabels: ['Employee'],
      );
    }

    final labels = [for (final role in session.roles) _roleLabel(role)];
    return DashboardAccessProfile(
      primaryLabel: labels.first,
      roleLabels: labels,
    );
  }

  final String primaryLabel;
  final List<String> roleLabels;

  String get additionalAccessLabel {
    if (roleLabels.length <= 1) return '';
    return roleLabels.skip(1).join(', ');
  }

  static String _roleLabel(String value) {
    final normalized = RoleType.normalize(value);
    return switch (normalized) {
      'COMPANY_ADMIN' => 'Company Admin',
      'SUPER_ADMIN' => 'Super Admin',
      'PROCUREMENT' => 'Procurement Officer',
      'FINANCE' => 'Finance Executive',
      'MANAGER' => 'Manager',
      _ => 'Employee',
    };
  }

  @override
  List<Object?> get props => [primaryLabel, roleLabels];
}

class DashboardModule extends Equatable {
  const DashboardModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.viewPermissions,
    this.countKeys = const [],
    this.isImplemented = true,
  });

  final DashboardModuleId id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final List<String> viewPermissions;
  final List<String> countKeys;
  final bool isImplemented;

  bool isVisibleFor(AuthSession session) {
    return PermissionPolicy.canViewRoute(session, route) ||
        PermissionPolicy.hasAnyPermission(session, viewPermissions);
  }

  AppMenuItem toMenuItem() {
    return AppMenuItem(
      title: title,
      subtitle: subtitle,
      route: route,
      icon: icon,
      requiredPermission: viewPermissions.isEmpty ? '' : viewPermissions.first,
      additionalPermissions: viewPermissions.skip(1).toList(),
      isImplemented: isImplemented,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    route,
    icon,
    viewPermissions,
    countKeys,
    isImplemented,
  ];
}

class DashboardQuickAction extends Equatable {
  const DashboardQuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.permissions,
    this.countKeys = const [],
    this.isImplemented = true,
  });

  final DashboardQuickActionId id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final List<String> permissions;
  final List<String> countKeys;
  final bool isImplemented;

  bool isVisibleFor(AuthSession session) {
    return PermissionPolicy.canViewRoute(session, route) ||
        PermissionPolicy.hasAnyPermission(session, permissions);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    route,
    icon,
    permissions,
    countKeys,
    isImplemented,
  ];
}

class AppMenuItem extends Equatable {
  const AppMenuItem({
    required this.title,
    required this.route,
    required this.requiredPermission,
    this.subtitle,
    this.icon = AppIcons.list,
    this.additionalPermissions = const [],
    this.allowedRoles = const [],
    required this.isImplemented,
  });

  final String title;
  final String? subtitle;
  final String route;
  final IconData icon;
  final String requiredPermission;
  final List<String> additionalPermissions;
  final List<String> allowedRoles;
  final bool isImplemented;

  bool isVisibleFor(AuthSession session) {
    return PermissionPolicy.canViewRoute(session, route);
  }

  @override
  List<Object?> get props => [
    title,
    subtitle,
    route,
    icon,
    requiredPermission,
    additionalPermissions,
    allowedRoles,
    isImplemented,
  ];
}

const dashboardModules = [
  DashboardModule(
    id: DashboardModuleId.approvals,
    title: 'Approvals',
    subtitle: 'Review pending requests',
    route: '/approvals',
    icon: AppIcons.approval,
    viewPermissions: [
      AppPermissions.purchaseRequestsApprove,
      AppPermissions.approvalsView,
    ],
    countKeys: ['pending_approvals', 'pendingApprovals'],
  ),
  DashboardModule(
    id: DashboardModuleId.requests,
    title: 'My Requests',
    subtitle: 'Track purchase requests',
    route: '/requests',
    icon: AppIcons.description,
    viewPermissions: [AppPermissions.purchaseRequestsView],
    countKeys: ['my_requests', 'myRequests', 'total_requests', 'totalRequests'],
  ),
  DashboardModule(
    id: DashboardModuleId.vendors,
    title: 'Vendors',
    subtitle: 'Manage supplier records',
    route: '/vendors',
    icon: AppIcons.vendors,
    viewPermissions: [
      AppPermissions.vendorsView,
      AppPermissions.vendorsCreate,
      AppPermissions.vendorsManage,
    ],
  ),
  DashboardModule(
    id: DashboardModuleId.rfq,
    title: 'RFQ',
    subtitle: 'Source vendor quotations',
    route: '/rfqs',
    icon: AppIcons.compare,
    viewPermissions: [AppPermissions.rfqView, AppPermissions.rfqManage],
    countKeys: ['open_rfqs', 'openRfqs'],
  ),
  DashboardModule(
    id: DashboardModuleId.purchaseOrders,
    title: 'Purchase Orders',
    subtitle: 'Issue and receive POs',
    route: '/purchase-orders',
    icon: AppIcons.order,
    viewPermissions: [
      AppPermissions.purchaseOrdersView,
      AppPermissions.purchaseOrdersCreate,
      AppPermissions.purchaseOrdersManage,
    ],
    countKeys: ['purchase_orders', 'purchaseOrders', 'issued_pos', 'issuedPos'],
  ),
  DashboardModule(
    id: DashboardModuleId.invoices,
    title: 'Invoices',
    subtitle: 'Track bills and due amounts',
    route: '/invoices',
    icon: AppIcons.money,
    viewPermissions: [
      AppPermissions.invoicesView,
      AppPermissions.invoicesCreate,
      AppPermissions.invoicesManage,
    ],
    countKeys: ['pending_invoices', 'pendingInvoices', 'invoices'],
  ),
  DashboardModule(
    id: DashboardModuleId.payments,
    title: 'Payments',
    subtitle: 'Record and audit payments',
    route: '/payments',
    icon: AppIcons.money,
    viewPermissions: [
      AppPermissions.paymentsView,
      AppPermissions.paymentsCreate,
      AppPermissions.paymentsManage,
    ],
  ),
  DashboardModule(
    id: DashboardModuleId.budgets,
    title: 'Budgets',
    subtitle: 'Monitor active budgets',
    route: '/budgets',
    icon: AppIcons.money,
    viewPermissions: [
      AppPermissions.budgetsView,
      AppPermissions.budgetsCreate,
      AppPermissions.budgetsManage,
    ],
    countKeys: ['active_budgets', 'activeBudgets'],
  ),
  DashboardModule(
    id: DashboardModuleId.reports,
    title: 'Reports',
    subtitle: 'Review spend and activity',
    route: '/reports',
    icon: AppIcons.history,
    viewPermissions: [
      AppPermissions.reportsView,
      AppPermissions.reportsExport,
      AppPermissions.reportsManage,
    ],
  ),
];

const dashboardQuickActions = [
  DashboardQuickAction(
    id: DashboardQuickActionId.assistant,
    title: 'AI Assistant',
    subtitle: 'Guide workflows and drafts',
    route: '/assistant',
    icon: AppIcons.assistant,
    permissions: [],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createRequest,
    title: 'Create Request',
    subtitle: 'Start a purchase request',
    route: '/requests/new',
    icon: AppIcons.add,
    permissions: [
      AppPermissions.purchaseRequestsCreate,
      AppPermissions.purchaseRequestsManage,
    ],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.offlineDrafts,
    title: 'Offline Drafts',
    subtitle: 'Review pending sync',
    route: '/sync-status',
    icon: AppIcons.sync,
    permissions: [
      AppPermissions.purchaseRequestsCreate,
      AppPermissions.purchaseRequestsManage,
    ],
    countKeys: ['pending_sync', 'pendingSync'],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.notifications,
    title: 'Notifications',
    subtitle: 'Unread alerts and updates',
    route: '/notifications',
    icon: AppIcons.bellActive,
    permissions: [],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.approvalHistory,
    title: 'Approval History',
    subtitle: 'Review past decisions',
    route: '/requests',
    icon: AppIcons.history,
    permissions: [
      AppPermissions.purchaseRequestsApprove,
      AppPermissions.approvalsView,
    ],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createVendor,
    title: 'Add Vendor',
    subtitle: 'Create supplier profile',
    route: '/vendors/new',
    icon: AppIcons.vendors,
    permissions: [AppPermissions.vendorsCreate, AppPermissions.vendorsManage],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createRfq,
    title: 'Create RFQ',
    subtitle: 'Request vendor pricing',
    route: '/rfqs/new',
    icon: AppIcons.compare,
    permissions: [AppPermissions.rfqManage],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.quotationComparison,
    title: 'Quotation Comparison',
    subtitle: 'Compare received quotes',
    route: '/rfqs',
    icon: AppIcons.compare,
    permissions: [AppPermissions.rfqView, AppPermissions.rfqManage],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createPurchaseOrder,
    title: 'Create PO',
    subtitle: 'Convert awarded RFQ',
    route: '/purchase-orders/new',
    icon: AppIcons.order,
    permissions: [
      AppPermissions.purchaseOrdersCreate,
      AppPermissions.purchaseOrdersManage,
    ],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createInvoice,
    title: 'Create Invoice',
    subtitle: 'Register supplier invoice',
    route: '/invoices/new',
    icon: AppIcons.money,
    permissions: [AppPermissions.invoicesCreate, AppPermissions.invoicesManage],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.recordPayment,
    title: 'Record Payment',
    subtitle: 'Apply payment to invoice',
    route: '/invoices',
    icon: AppIcons.money,
    permissions: [AppPermissions.paymentsCreate, AppPermissions.paymentsManage],
  ),
  DashboardQuickAction(
    id: DashboardQuickActionId.createBudget,
    title: 'Create Budget',
    subtitle: 'Allocate department funds',
    route: '/budgets/new',
    icon: AppIcons.money,
    permissions: [AppPermissions.budgetsCreate, AppPermissions.budgetsManage],
  ),
];

final phase2ModuleMenuItems = dashboardModules
    .map((module) => module.toMenuItem())
    .toList(growable: false);

List<DashboardModule> visibleDashboardModules(AuthSession? session) {
  if (session == null) return const [];
  return [
    for (final module in dashboardModules)
      if (module.isVisibleFor(session)) module,
  ];
}

List<DashboardQuickAction> visibleDashboardQuickActions(AuthSession? session) {
  if (session == null) return const [];
  return [
    for (final action in dashboardQuickActions)
      if (_isVisibleQuickAction(action, session)) action,
  ];
}

List<AppMenuItem> visiblePhase2MenuItems(AuthSession? session) {
  return visibleDashboardModules(
    session,
  ).map((module) => module.toMenuItem()).toList(growable: false);
}

bool _isVisibleQuickAction(DashboardQuickAction action, AuthSession session) {
  if (action.id == DashboardQuickActionId.assistant) {
    return PermissionPolicy.canUseAssistant(session);
  }
  if (action.id == DashboardQuickActionId.notifications) return true;
  if (action.id == DashboardQuickActionId.offlineDrafts) {
    return PermissionPolicy.canUseOfflineSync(session);
  }
  return action.isVisibleFor(session);
}
