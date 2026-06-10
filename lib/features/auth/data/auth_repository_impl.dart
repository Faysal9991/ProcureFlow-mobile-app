import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/storage/secure_session_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

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
    final session = baseSession.copyWith(
      permissions: permissions.isEmpty ? baseSession.permissions : permissions,
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
    return response.permissions;
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
    final role = response.roles.isEmpty ? 'employee' : response.roles.first;
    final permissions = response.permissions.isEmpty
        ? _config.useMockApi
              ? _mockPermissions(role)
              : const <String>[]
        : response.permissions;
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
      roles: response.roles.isEmpty ? [role] : response.roles,
      departmentName: response.departmentName.isEmpty
          ? 'General'
          : response.departmentName,
      permissions: permissions,
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
    final roles = user.roles.isEmpty
        ? fallback?.roles ?? const ['employee']
        : user.roles;
    final primaryRole = roles.isEmpty ? 'employee' : roles.first;
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
      permissions: user.permissions.isEmpty
          ? fallback?.permissions ?? const []
          : user.permissions,
      mustChangePassword: user.mustChangePassword,
    );
  }

  LoginResponseDto _mockLogin(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final role = normalizedEmail.contains('manager')
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
    return switch (role) {
      'manager' => const [
        'purchase_requests.view',
        'purchase_requests.create',
        'purchase_requests.approve',
        'approvals.manage',
      ],
      'procurement' => const [
        'purchase_requests.view',
        'vendors.view',
        'rfq.view',
        'rfq.manage',
        'quotations.compare',
        'purchase_orders.create',
        'purchase_orders.manage',
      ],
      'finance' => const [
        'purchase_requests.view',
        'purchase_orders.view',
        'finance.view',
      ],
      _ => const ['purchase_requests.view', 'purchase_requests.create'],
    };
  }

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
