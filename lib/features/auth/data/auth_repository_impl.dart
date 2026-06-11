import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/storage/secure_session_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/permission_policy.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AppConfig config,
    required ProcurementApi api,
    required SecureSessionStorage storage,
    required ProcurementDao dao,
  }) : _config = config,
       _api = api,
       _storage = storage,
       _dao = dao;

  final AppConfig _config;
  final ProcurementApi _api;
  final SecureSessionStorage _storage;
  final ProcurementDao _dao;

  @override
  Future<AuthSession?> restoreSession() async {
    final rawSession = await _storage.readSessionJson();
    final storedSession = rawSession == null
        ? null
        : AuthSession.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);
    final accessToken =
        await _storage.readAccessToken() ?? storedSession?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    if (_config.useMockApi) {
      final session =
          storedSession ??
          _mockSessionFromEmail(
            email: 'employee@demo.com',
            accessToken: accessToken,
          );
      await _persistSession(session);
      return session;
    }

    try {
      return await _loadRemoteSession(
        accessToken: accessToken,
        fallback: storedSession,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.clear();
        return null;
      }
      if (storedSession != null) {
        await _seedSessionData(storedSession);
        return storedSession;
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Email and password are required.');
    }

    final response = _config.useMockApi
        ? _mockLogin(email.trim())
        : await _api.login(
            LoginRequestDto(email: email.trim(), password: password),
          );

    await _storage.writeAccessToken(response.accessToken);

    final fallback = _sessionFromLoginResponse(response, email: email.trim());

    final session = _config.useMockApi
        ? fallback
        : await _loadRemoteSession(
            accessToken: response.accessToken,
            fallback: fallback,
          );

    await _persistSession(session);
    return session;
  }

  @override
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      throw ArgumentError('Current password and new password are required.');
    }
    if (newPassword.trim().length < 6) {
      throw ArgumentError('New password must be at least 6 characters.');
    }

    final rawSession = await _storage.readSessionJson();
    final storedSession = rawSession == null
        ? null
        : AuthSession.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);
    final accessToken =
        await _storage.readAccessToken() ?? storedSession?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('No active session found.');
    }

    if (_config.useMockApi) {
      final session =
          (storedSession ??
                  _mockSessionFromEmail(
                    email: 'employee@demo.com',
                    accessToken: accessToken,
                  ))
              .copyWith(
                mustChangePassword: false,
                permissions: _mockPermissions(
                  storedSession?.primaryRole ?? 'employee',
                ),
              );
      await _persistSession(session);
      return session;
    }

    await _api.changePassword(
      ChangePasswordRequestDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPassword,
      ),
    );

    final session = await _loadRemoteSession(
      accessToken: accessToken,
      fallback: storedSession?.copyWith(mustChangePassword: false),
    );
    await _persistSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    if (!_config.useMockApi) {
      try {
        await _api.logout();
      } on Exception {
        // Local logout must complete even if the backend request fails.
      }
    }
    await _storage.clear();
  }

  Future<AuthSession> _loadRemoteSession({
    required String accessToken,
    required AuthSession? fallback,
  }) async {
    final user = await _api.getCurrentUser();
    final baseSession = _sessionFromCurrentUser(
      user,
      accessToken: accessToken,
      fallback: fallback,
    );

    if (baseSession.mustChangePassword) {
      await _persistSession(baseSession);
      return baseSession;
    }

    final permissions = await _loadPermissions();
    final mergedPermissions = _mergeRoleBaselinePermissions(
      roles: baseSession.roles,
      permissions: permissions.isEmpty ? baseSession.permissions : permissions,
    );
    final session = baseSession.copyWith(
      permissions: mergedPermissions,
      mustChangePassword: false,
    );
    await _persistSession(session);
    return session;
  }

  Future<List<String>> _loadPermissions() async {
    if (_config.useMockApi) {
      return const [];
    }
    final response = await _api.getPermissions();
    return _normalizePermissions(response.permissions);
  }

  Future<void> _persistSession(AuthSession session) async {
    await _storage.writeAccessToken(session.accessToken);
    await _storage.writeSessionJson(jsonEncode(session.toJson()));
    await _seedSessionData(session);
  }

  Future<void> _seedSessionData(AuthSession session) {
    return _dao.seedDemoData(
      companyId: session.companyId,
      userId: session.userId,
      userName: session.userName,
      email: session.email,
      roleName: session.primaryRole,
    );
  }

  AuthSession _sessionFromLoginResponse(
    LoginResponseDto response, {
    required String email,
  }) {
    final roles = _normalizeRoles(
      response.roles.isEmpty ? const ['employee'] : response.roles,
    );
    final role = roles.first;
    final permissions = _normalizePermissions(response.permissions);
    final resolvedPermissions = permissions.isEmpty
        ? _config.useMockApi
              ? _mockPermissions(role)
              : const <String>[]
        : permissions;
    final mergedPermissions = _mergeRoleBaselinePermissions(
      roles: roles,
      permissions: resolvedPermissions,
    );
    return AuthSession(
      accessToken: response.accessToken,
      userId: response.userId.isEmpty ? 'user-$role' : response.userId,
      userName: response.userName.isEmpty
          ? _nameFromEmail(response.email.isEmpty ? email : response.email)
          : response.userName,
      email: response.email.isEmpty ? email : response.email,
      companyId: response.companyId.isEmpty
          ? 'company-demo'
          : response.companyId,
      companyName: response.companyName.isEmpty
          ? 'Demo Company'
          : response.companyName,
      roles: roles,
      departmentName: response.departmentName.isEmpty
          ? 'General'
          : response.departmentName,
      permissions: mergedPermissions,
      mustChangePassword: response.mustChangePassword,
    );
  }

  AuthSession _sessionFromCurrentUser(
    AuthUserDto user, {
    required String accessToken,
    required AuthSession? fallback,
  }) {
    final email = user.email.isEmpty
        ? fallback?.email ?? 'employee@demo.com'
        : user.email;
    final roles = _normalizeRoles(
      user.roles.isEmpty ? fallback?.roles ?? const ['employee'] : user.roles,
    );
    final primaryRole = roles.isEmpty ? 'employee' : roles.first;
    final permissions = _normalizePermissions(user.permissions);
    final fallbackPermissions = _normalizePermissions(
      fallback?.permissions ?? const [],
    );
    final mergedPermissions = _mergeRoleBaselinePermissions(
      roles: roles,
      permissions: permissions.isEmpty ? fallbackPermissions : permissions,
    );
    return AuthSession(
      accessToken: accessToken,
      userId: user.userId.isEmpty
          ? fallback?.userId ?? 'user-$primaryRole'
          : user.userId,
      userName: user.userName.isEmpty
          ? fallback?.userName ?? _nameFromEmail(email)
          : user.userName,
      email: email,
      companyId: user.companyId.isEmpty
          ? fallback?.companyId ?? 'company-demo'
          : user.companyId,
      companyName: user.companyName.isEmpty
          ? fallback?.companyName ?? 'Demo Company'
          : user.companyName,
      roles: roles,
      departmentName: user.departmentName.isEmpty
          ? fallback?.departmentName ?? 'General'
          : user.departmentName,
      permissions: mergedPermissions,
      mustChangePassword: user.mustChangePassword,
    );
  }

  LoginResponseDto _mockLogin(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final role = normalizedEmail.contains('super')
        ? 'super_admin'
        : normalizedEmail.contains('admin')
        ? 'company_admin'
        : normalizedEmail.contains('manager')
        ? 'manager'
        : normalizedEmail.contains('procurement')
        ? 'procurement'
        : normalizedEmail.contains('finance')
        ? 'finance'
        : 'employee';
    final name = _nameFromEmail(normalizedEmail);
    return LoginResponseDto(
      accessToken: 'mock-token-$role',
      userId: 'user-$role',
      userName: name.isEmpty ? 'Demo User' : name,
      email: normalizedEmail,
      companyId: 'company-demo',
      companyName: 'Demo Company',
      departmentName: 'General',
      roles: [role],
      permissions: _mockPermissions(role),
      mustChangePassword: normalizedEmail.contains('change-password'),
    );
  }

  AuthSession _mockSessionFromEmail({
    required String email,
    required String accessToken,
  }) {
    final response = _mockLogin(email);
    return _sessionFromLoginResponse(
      LoginResponseDto(
        accessToken: accessToken,
        userId: response.userId,
        userName: response.userName,
        email: response.email,
        companyId: response.companyId,
        companyName: response.companyName,
        departmentName: response.departmentName,
        roles: response.roles,
        permissions: response.permissions,
        mustChangePassword: response.mustChangePassword,
      ),
      email: email,
    );
  }

  List<String> _mockPermissions(String role) {
    final normalizedRole = role.trim().toLowerCase();
    return switch (normalizedRole) {
      'manager' => const [
        'purchase_requests.view',
        'approvals.view',
        'purchase_requests.approve',
        'attachments.view',
      ],
      'procurement' => const [
        'purchase_requests.view',
        'approvals.view',
        'vendors.view',
        'vendors.create',
        'vendors.manage',
        'rfq.view',
        'rfq.manage',
        'quotations.compare',
        'purchase_orders.view',
        'purchase_orders.create',
        'purchase_orders.manage',
        'reports.view',
        'attachments.view',
        'attachments.upload',
        'attachments.delete',
      ],
      'finance' => const [
        'approvals.view',
        'invoices.view',
        'invoices.create',
        'invoices.manage',
        'payments.view',
        'payments.create',
        'payments.manage',
        'budgets.view',
        'budgets.create',
        'budgets.manage',
        'reports.view',
        'reports.export',
        'attachments.view',
        'attachments.upload',
        'attachments.delete',
      ],
      'company_admin' => const ['*'],
      'super_admin' => const [],
      _ => const ['purchase_requests.view', 'purchase_requests.create'],
    };
  }

  List<String> _normalizeRoles(List<String> roles) {
    return [
      for (final role in roles)
        if (role.trim().isNotEmpty)
          role.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_'),
    ];
  }

  List<String> _normalizePermissions(List<String> permissions) {
    final values = <String>{};
    for (final permission in permissions) {
      values.addAll(_canonicalPermissionsFor(permission));
    }
    return values.toList(growable: false);
  }

  List<String> _mergeRoleBaselinePermissions({
    required List<String> roles,
    required List<String> permissions,
  }) {
    final values = <String>{...permissions};
    if (roles.contains('EMPLOYEE')) {
      values.addAll(const [
        AppPermissions.purchaseRequestsView,
        AppPermissions.purchaseRequestsCreate,
      ]);
    }
    return values.toList(growable: false);
  }

  List<String> _canonicalPermissionsFor(String permission) {
    final normalized = _normalizePermissionText(permission);
    if (normalized.isEmpty) return const [];
    if (normalized == '*' ||
        normalized == 'all' ||
        normalized == 'all_access') {
      return const ['*'];
    }
    if (_canonicalPermissionKeys.contains(normalized)) {
      return [normalized];
    }
    final aliased = _permissionAliases[normalized];
    if (aliased != null) return aliased;
    final underscored = normalized.replaceAll('.', '_');
    return _permissionAliases[underscored] ?? const [];
  }

  String _normalizePermissionText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(':', '.')
        .replaceAll('/', '.')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll('purchase_request.', 'purchase_requests.')
        .replaceAll('purchase_request_', 'purchase_requests_')
        .replaceAll('purchase_order.', 'purchase_orders.')
        .replaceAll('purchase_order_', 'purchase_orders_')
        .replaceAll('invoice.', 'invoices.')
        .replaceAll('invoice_', 'invoices_')
        .replaceAll('payment.', 'payments.')
        .replaceAll('payment_', 'payments_')
        .replaceAll('budget.', 'budgets.')
        .replaceAll('budget_', 'budgets_')
        .replaceAll('vendor.', 'vendors.')
        .replaceAll('vendor_', 'vendors_')
        .replaceAll('approval.', 'approvals.')
        .replaceAll('approval_', 'approvals_')
        .replaceAll('attachment.', 'attachments.')
        .replaceAll('attachment_', 'attachments_')
        .replaceAll('report.', 'reports.')
        .replaceAll('report_', 'reports_');
  }

  static const Set<String> _canonicalPermissionKeys = {
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

  static const Map<String, List<String>> _permissionAliases = {
    'purchase_requests_read': [AppPermissions.purchaseRequestsView],
    'purchase_requests_list': [AppPermissions.purchaseRequestsView],
    'purchase_requests_index': [AppPermissions.purchaseRequestsView],
    'purchase_requests_create': [AppPermissions.purchaseRequestsCreate],
    'purchase_requests_submit': [AppPermissions.purchaseRequestsCreate],
    'purchase_requests_update': [AppPermissions.purchaseRequestsManage],
    'purchase_requests_edit': [AppPermissions.purchaseRequestsManage],
    'purchase_requests_delete': [AppPermissions.purchaseRequestsManage],
    'purchase_requests_cancel': [AppPermissions.purchaseRequestsManage],
    'purchase_requests_manage': [AppPermissions.purchaseRequestsManage],
    'purchase_requests_approve': [AppPermissions.purchaseRequestsApprove],
    'purchase_requests_reject': [AppPermissions.purchaseRequestsApprove],
    'approvals_read': [AppPermissions.approvalsView],
    'approvals_list': [AppPermissions.approvalsView],
    'approvals_inbox': [AppPermissions.approvalsView],
    'approvals_view': [AppPermissions.approvalsView],
    'vendors_read': [AppPermissions.vendorsView],
    'vendors_list': [AppPermissions.vendorsView],
    'vendors_create': [AppPermissions.vendorsCreate],
    'vendors_update': [AppPermissions.vendorsManage],
    'vendors_edit': [AppPermissions.vendorsManage],
    'vendors_delete': [AppPermissions.vendorsManage],
    'vendors_manage': [AppPermissions.vendorsManage],
    'rfqs_view': [AppPermissions.rfqView],
    'rfqs_read': [AppPermissions.rfqView],
    'rfqs_list': [AppPermissions.rfqView],
    'rfqs_create': [AppPermissions.rfqManage],
    'rfqs_update': [AppPermissions.rfqManage],
    'rfqs_open': [AppPermissions.rfqManage],
    'rfqs_cancel': [AppPermissions.rfqManage],
    'rfqs_manage': [AppPermissions.rfqManage],
    'rfqs_assign_vendors': [AppPermissions.rfqManage],
    'rfqs_add_quotation': [AppPermissions.rfqManage],
    'rfqs_select_quotation': [AppPermissions.rfqManage],
    'rfq_create': [AppPermissions.rfqManage],
    'rfq_read': [AppPermissions.rfqView],
    'rfq_list': [AppPermissions.rfqView],
    'rfq_update': [AppPermissions.rfqManage],
    'rfq_open': [AppPermissions.rfqManage],
    'rfq_cancel': [AppPermissions.rfqManage],
    'rfq_manage': [AppPermissions.rfqManage],
    'rfq_assign_vendors': [AppPermissions.rfqManage],
    'rfq_add_quotation': [AppPermissions.rfqManage],
    'rfq_select_quotation': [AppPermissions.rfqManage],
    'quotations_compare': [AppPermissions.rfqView],
    'quotations_comparison': [AppPermissions.rfqView],
    'quotations_select': [AppPermissions.rfqManage],
    'purchase_orders_read': [AppPermissions.purchaseOrdersView],
    'purchase_orders_list': [AppPermissions.purchaseOrdersView],
    'purchase_orders_create': [AppPermissions.purchaseOrdersCreate],
    'purchase_orders_update': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_edit': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_issue': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_receive': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_close': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_cancel': [AppPermissions.purchaseOrdersManage],
    'purchase_orders_manage': [AppPermissions.purchaseOrdersManage],
    'po_view': [AppPermissions.purchaseOrdersView],
    'po_create': [AppPermissions.purchaseOrdersCreate],
    'po_manage': [AppPermissions.purchaseOrdersManage],
    'invoices_read': [AppPermissions.invoicesView],
    'invoices_list': [AppPermissions.invoicesView],
    'invoices_create': [AppPermissions.invoicesCreate],
    'invoices_update': [AppPermissions.invoicesManage],
    'invoices_edit': [AppPermissions.invoicesManage],
    'invoices_cancel': [AppPermissions.invoicesManage],
    'invoices_manage': [AppPermissions.invoicesManage],
    'payments_read': [AppPermissions.paymentsView],
    'payments_list': [AppPermissions.paymentsView],
    'payments_create': [AppPermissions.paymentsCreate],
    'payments_record': [AppPermissions.paymentsCreate],
    'payments_update': [AppPermissions.paymentsManage],
    'payments_manage': [AppPermissions.paymentsManage],
    'budgets_read': [AppPermissions.budgetsView],
    'budgets_list': [AppPermissions.budgetsView],
    'budgets_create': [AppPermissions.budgetsCreate],
    'budgets_update': [AppPermissions.budgetsManage],
    'budgets_edit': [AppPermissions.budgetsManage],
    'budgets_activate': [AppPermissions.budgetsManage],
    'budgets_close': [AppPermissions.budgetsManage],
    'budgets_adjust': [AppPermissions.budgetsManage],
    'budgets_manage': [AppPermissions.budgetsManage],
    'reports_read': [AppPermissions.reportsView],
    'reports_list': [AppPermissions.reportsView],
    'reports_export': [AppPermissions.reportsExport],
    'reports_manage': [AppPermissions.reportsManage],
    'attachments_read': [AppPermissions.attachmentsView],
    'attachments_list': [AppPermissions.attachmentsView],
    'attachments_create': [AppPermissions.attachmentsUpload],
    'attachments_upload': [AppPermissions.attachmentsUpload],
    'attachments_delete': [AppPermissions.attachmentsDelete],
    'attachments_manage': [
      AppPermissions.attachmentsView,
      AppPermissions.attachmentsUpload,
      AppPermissions.attachmentsDelete,
    ],
  };

  String _nameFromEmail(String email) {
    return email
        .trim()
        .split('@')
        .first
        .split(RegExp('[-._]'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
