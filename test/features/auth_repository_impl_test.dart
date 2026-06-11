import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/storage/secure_session_storage.dart';
import 'package:procurement_management/features/auth/data/auth_repository_impl.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';

class _FakeProcurementApi implements ProcurementApi {
  LoginResponseDto loginResponse = const LoginResponseDto(
    accessToken: 'server-token',
  );
  AuthUserDto currentUser = const AuthUserDto(
    userId: 'user-1',
    userName: 'Test User',
    email: 'test@example.com',
    companyId: 'company-1',
    companyName: 'Test Company',
    roles: ['employee'],
  );
  PermissionsResponseDto permissionsResponse = const PermissionsResponseDto(
    permissions: ['purchase_requests.view'],
  );
  Exception? currentUserError;
  var loginCalled = false;
  var currentUserCalls = 0;
  var permissionsCalls = 0;
  var logoutCalled = false;
  var changePasswordCalled = false;

  @override
  Future<void> approveRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto request) async {
    changePasswordCalled = true;
  }

  @override
  Future<PurchaseRequestDto> createPurchaseRequest(
    PurchaseRequestPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> cancelPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ApprovalHistoryResponseDto> getPurchaseRequestApprovalHistory(
    String id,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> getPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestPageDto> getMyPurchaseRequests(
    String? search,
    String? status,
    String? priority,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> submitPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestSyncResponseDto> syncCreatePurchaseRequest(
    PurchaseRequestSyncRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> updatePurchaseRequest(
    String id,
    PurchaseRequestPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUserDto> getCurrentUser() async {
    currentUserCalls++;
    final error = currentUserError;
    if (error != null) throw error;
    return currentUser;
  }

  @override
  Future<PermissionsResponseDto> getPermissions() async {
    permissionsCalls++;
    return permissionsResponse;
  }

  @override
  Future<VendorDto> createVendor(VendorPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteVendor(String id) {
    throw UnimplementedError();
  }

  @override
  Future<VendorDto> getVendor(String id) {
    throw UnimplementedError();
  }

  @override
  Future<VendorPageDto> getVendors(
    String? search,
    String? status,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VendorDto> updateVendor(String id, VendorPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> assignRfqVendors(
    String id,
    AssignRfqVendorsPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> createRfq(CreateRfqPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<QuotationDto> createRfqQuotation(
    String id,
    CreateQuotationPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<EligiblePurchaseRequestPageDto> getEligiblePurchaseRequestsForRfq(
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> getRfq(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqPageDto> getRfqs(
    String? search,
    String? status,
    String? purchaseRequestId,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> openRfq(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqComparisonDto> getRfqComparison(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> selectRfqQuotation(
    String id,
    SelectedQuotationPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> cancelPurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> closePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> createPurchaseOrder(
    CreatePurchaseOrderPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> getPurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderPageDto> getPurchaseOrders(
    String? search,
    String? status,
    String? vendorId,
    String? purchaseRequestId,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> issuePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> receivePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> updatePurchaseOrder(
    String id,
    UpdatePurchaseOrderPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<DashboardSummaryDto> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<ApprovalInboxPageDto> getApprovalInbox(
    String? search,
    String? priority,
    String? departmentId,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationPageDto> getNotifications(int page, int limit) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationUnreadCountDto> getNotificationUnreadCount() {
    throw UnimplementedError();
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    loginCalled = true;
    return loginResponse;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> markAllNotificationsRead() {
    throw UnimplementedError();
  }

  @override
  Future<void> markNotificationRead(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth DTOs parse singular backend role and permission objects', () {
    final login = LoginResponseDto.fromJson({
      'success': true,
      'data': {
        'accessToken': 'server-token',
        'user': {
          'uuid': 'user-uuid',
          'companyId': 1,
          'name': 'Company Admin',
          'email': 'admin@example.test',
          'role': 'COMPANY_ADMIN',
        },
      },
    });
    final permissions = PermissionsResponseDto.fromJson({
      'success': true,
      'data': {
        'items': [
          {'key': 'Purchase request create'},
          {'permissionKey': 'vendors.manage'},
        ],
      },
    });

    expect(login.userId, 'user-uuid');
    expect(login.roles, ['COMPANY_ADMIN']);
    expect(permissions.permissions, [
      'Purchase request create',
      'vendors.manage',
    ]);
  });

  late AppDatabase database;
  late SecureSessionStorage storage;
  late _FakeProcurementApi api;
  late AuthRepositoryImpl repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    storage = SecureSessionStorage();
    api = _FakeProcurementApi();
    repository = AuthRepositoryImpl(
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test/api/v1',
        useMockApi: false,
      ),
      api: api,
      storage: storage,
      dao: ProcurementDao(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('login saves access token and loads permissions', () async {
    final session = await repository.login(
      email: 'test@example.com',
      password: 'password',
    );

    expect(api.loginCalled, isTrue);
    expect(api.currentUserCalls, 1);
    expect(api.permissionsCalls, 1);
    expect(await storage.readAccessToken(), 'server-token');
    expect(session.accessToken, 'server-token');
    expect(session.permissions, [
      'purchase_requests.view',
      'purchase_requests.create',
    ]);
  });

  test('login normalizes backend role and permission names', () async {
    api.currentUser = const AuthUserDto(
      userId: 'admin-1',
      userName: 'Admin User',
      email: 'admin@example.com',
      companyId: 'company-1',
      companyName: 'Test Company',
      roles: ['company admin'],
    );
    api.permissionsResponse = const PermissionsResponseDto(
      permissions: [
        'Purchase request create',
        'vendors_manage',
        'rfq.create',
        'reports.manage',
      ],
    );

    final session = await repository.login(
      email: 'admin@example.com',
      password: 'password',
    );

    expect(session.roles, ['COMPANY_ADMIN']);
    expect(session.permissions, [
      'purchase_requests.create',
      'vendors.manage',
      'rfq.manage',
      'reports.manage',
    ]);
  });

  test(
    'employee role keeps purchase request baseline with partial backend permissions',
    () async {
      api.currentUser = const AuthUserDto(
        userId: 'employee-1',
        userName: 'Employee User',
        email: 'employee@example.com',
        companyId: 'company-1',
        companyName: 'Test Company',
        roles: ['EMPLOYEE'],
      );
      api.permissionsResponse = const PermissionsResponseDto(
        permissions: [
          'attachment.view',
          'budget.view',
          'report.purchase_request.view',
        ],
      );

      final session = await repository.login(
        email: 'employee@example.com',
        password: 'password',
      );

      expect(session.roles, ['EMPLOYEE']);
      expect(session.permissions, contains('purchase_requests.view'));
      expect(session.permissions, contains('purchase_requests.create'));
    },
  );

  test('restoreSession validates token with me and permissions', () async {
    await storage.writeAccessToken('stored-token');

    final session = await repository.restoreSession();

    expect(api.currentUserCalls, 1);
    expect(api.permissionsCalls, 1);
    expect(session?.accessToken, 'stored-token');
    expect(session?.email, 'test@example.com');
    expect(session?.permissions, [
      'purchase_requests.view',
      'purchase_requests.create',
    ]);
  });

  test('restoreSession clears invalid token', () async {
    final requestOptions = RequestOptions(path: '/auth/me');
    api.currentUserError = DioException(
      requestOptions: requestOptions,
      response: Response<void>(requestOptions: requestOptions, statusCode: 401),
    );
    await storage.writeAccessToken('expired-token');

    final session = await repository.restoreSession();

    expect(session, isNull);
    expect(await storage.readAccessToken(), isNull);
  });

  test('restoreSession routes password change before permissions', () async {
    api.currentUser = const AuthUserDto(
      userId: 'user-1',
      userName: 'Test User',
      email: 'test@example.com',
      companyId: 'company-1',
      companyName: 'Test Company',
      roles: ['employee'],
      mustChangePassword: true,
    );
    await storage.writeAccessToken('stored-token');

    final session = await repository.restoreSession();

    expect(session?.mustChangePassword, isTrue);
    expect(api.currentUserCalls, 1);
    expect(api.permissionsCalls, 0);
  });

  test('changePassword calls backend and refreshes permissions', () async {
    await storage.writeAccessToken('stored-token');
    await storage.writeSessionJson(
      jsonEncode(
        const AuthSession(
          accessToken: 'stored-token',
          userId: 'user-1',
          userName: 'Test User',
          email: 'test@example.com',
          companyId: 'company-1',
          companyName: 'Test Company',
          roles: ['employee'],
          mustChangePassword: true,
        ).toJson(),
      ),
    );

    final session = await repository.changePassword(
      currentPassword: 'old-password',
      newPassword: 'new-password',
    );

    expect(api.changePasswordCalled, isTrue);
    expect(api.permissionsCalls, 1);
    expect(session.mustChangePassword, isFalse);
  });
}
