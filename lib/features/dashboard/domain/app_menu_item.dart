import 'package:equatable/equatable.dart';

import '../../auth/domain/auth_session.dart';

class AppMenuItem extends Equatable {
  const AppMenuItem({
    required this.title,
    required this.route,
    required this.requiredPermission,
    this.additionalPermissions = const [],
    this.allowedRoles = const [],
    required this.isImplemented,
  });

  final String title;
  final String route;
  final String requiredPermission;
  final List<String> additionalPermissions;
  final List<String> allowedRoles;
  final bool isImplemented;

  bool isVisibleFor(AuthSession session) {
    return session.hasAnyPermission([
          requiredPermission,
          ...additionalPermissions,
        ]) ||
        session.hasAnyRole(allowedRoles);
  }

  @override
  List<Object?> get props => [
    title,
    route,
    requiredPermission,
    additionalPermissions,
    allowedRoles,
    isImplemented,
  ];
}

const phase2ModuleMenuItems = [
  AppMenuItem(
    title: 'My Requests',
    route: '/requests',
    requiredPermission: 'purchase_requests.view',
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Approvals',
    route: '/approvals',
    requiredPermission: 'approvals.manage',
    additionalPermissions: ['purchase_requests.approve'],
    allowedRoles: ['MANAGER', 'COMPANY_ADMIN', 'PROCUREMENT', 'FINANCE'],
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Vendors',
    route: '/vendors',
    requiredPermission: 'vendors.view',
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'RFQ',
    route: '/rfqs',
    requiredPermission: 'rfq.view',
    additionalPermissions: ['rfq.manage'],
    allowedRoles: ['PROCUREMENT', 'COMPANY_ADMIN'],
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Purchase Orders',
    route: '/purchase-orders',
    requiredPermission: 'purchase_orders.view',
    additionalPermissions: ['purchase_orders.create', 'purchase_orders.manage'],
    allowedRoles: ['PROCUREMENT', 'COMPANY_ADMIN'],
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Invoices',
    route: '/invoices',
    requiredPermission: 'invoices.view',
    additionalPermissions: ['invoices.create', 'invoices.manage'],
    allowedRoles: ['FINANCE', 'COMPANY_ADMIN'],
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Budgets',
    route: '/budgets',
    requiredPermission: 'budgets.view',
    additionalPermissions: ['budgets.create', 'budgets.manage'],
    allowedRoles: ['FINANCE', 'COMPANY_ADMIN'],
    isImplemented: true,
  ),
  AppMenuItem(
    title: 'Reports',
    route: '/reports',
    requiredPermission: 'reports.view',
    additionalPermissions: ['reports.export', 'reports.manage'],
    allowedRoles: ['FINANCE', 'PROCUREMENT', 'COMPANY_ADMIN'],
    isImplemented: true,
  ),
];

List<AppMenuItem> visiblePhase2MenuItems(AuthSession? session) {
  if (session == null) return const [];
  return [
    for (final item in phase2ModuleMenuItems)
      if (item.isVisibleFor(session)) item,
  ];
}
