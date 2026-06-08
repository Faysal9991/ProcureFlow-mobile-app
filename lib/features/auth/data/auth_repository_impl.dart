import 'dart:convert';

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
    if (rawSession == null) {
      return null;
    }
    final session = AuthSession.fromJson(
      jsonDecode(rawSession) as Map<String, dynamic>,
    );
    await _seedSessionData(session);
    return session;
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
        ? _mockLogin(email)
        : await _api.login(
            LoginRequestDto(email: email.trim(), password: password),
          );

    final session = AuthSession(
      accessToken: response.accessToken,
      userId: response.userId,
      userName: response.userName,
      email: response.email,
      companyId: response.companyId,
      companyName: response.companyName,
      roles: response.roles,
    );

    await _storage.writeSessionJson(jsonEncode(session.toJson()));
    await _seedSessionData(session);
    return session;
  }

  @override
  Future<void> logout() {
    return _storage.clear();
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

  LoginResponseDto _mockLogin(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final role = normalizedEmail.contains('manager')
        ? 'manager'
        : normalizedEmail.contains('procurement')
        ? 'procurement'
        : normalizedEmail.contains('finance')
        ? 'finance'
        : 'employee';
    final name = normalizedEmail
        .split('@')
        .first
        .split(RegExp('[-._]'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return LoginResponseDto(
      accessToken: 'mock-token-$role',
      userId: 'user-$role',
      userName: name.isEmpty ? 'Demo User' : name,
      email: normalizedEmail,
      companyId: 'company-demo',
      companyName: 'Demo Company',
      roles: [role],
    );
  }
}
