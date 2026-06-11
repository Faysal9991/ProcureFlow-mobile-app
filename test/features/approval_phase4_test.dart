import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/sync/sync_summary.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/approval/data/approval_repository_impl.dart';
import 'package:procurement_management/features/approval/domain/approval_repository.dart';
import 'package:procurement_management/features/approval/presentation/approval_controller.dart';
import 'package:procurement_management/features/approval/presentation/approval_inbox_screen.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/purchase_request/domain/purchase_request_entity.dart';
import 'package:procurement_management/features/purchase_request/domain/purchase_request_repository.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_details_screen.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_providers.dart';

const _approverSession = AuthSession(
  accessToken: 'token',
  userId: 'manager-1',
  userName: 'Manager User',
  email: 'manager@example.com',
  companyId: 'company-1',
  companyName: 'Demo Company',
  roles: ['MANAGER'],
  permissions: [],
);

void main() {
  test('approval menu enables for backend roles and approval permissions', () {
    for (final role in ['MANAGER', 'COMPANY_ADMIN', 'PROCUREMENT']) {
      final session = _approverSession.copyWith(roles: [role]);
      final approvals = visiblePhase2MenuItems(
        session,
      ).where((item) => item.title == 'Approvals');

      expect(approvals.single.isImplemented, isTrue);
    }

    final financeSession = _approverSession.copyWith(roles: ['FINANCE']);
    expect(
      visiblePhase2MenuItems(financeSession).map((item) => item.title),
      isNot(contains('Approvals')),
    );

    final permissionSession = _approverSession.copyWith(
      roles: ['EMPLOYEE'],
      permissions: ['purchase_requests.approve'],
    );
    expect(
      visiblePhase2MenuItems(
        permissionSession,
      ).where((item) => item.title == 'Approvals').single.isImplemented,
      isTrue,
    );

    final employeeSession = _approverSession.copyWith(roles: ['EMPLOYEE']);
    expect(
      visiblePhase2MenuItems(employeeSession).map((item) => item.title),
      isNot(contains('Approvals')),
    );
    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
  });

  test(
    'approval repository sends inbox filters and decision payloads',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final api = _FakeProcurementApi();
      final repository = ApprovalRepositoryImpl(
        config: const AppConfig(
          appName: 'Test',
          apiBaseUrl: 'https://api.example.test/api/v1',
          useMockApi: false,
        ),
        api: api,
        dao: ProcurementDao(database),
      );
      addTearDown(database.close);

      final filters = ApprovalInboxFilters(
        search: ' laptop ',
        priority: PurchaseRequestPriority.high,
        departmentId: ' dep-1 ',
        dateFrom: DateTime(2026, 1, 2),
        dateTo: DateTime(2026, 1, 3),
        page: 2,
        limit: 20,
      );

      await repository.getInbox(_approverSession, filters);
      await repository.approve(
        _approverSession,
        'request-1',
        const ApprovalDecisionPayload(comment: '   '),
      );
      await repository.reject(
        _approverSession,
        'request-1',
        const ApprovalDecisionPayload(comment: 'Budget missing details'),
      );

      expect(api.lastInboxQuery, {
        'search': 'laptop',
        'priority': 'HIGH',
        'departmentId': 'dep-1',
        'dateFrom': '2026-01-02',
        'dateTo': '2026-01-03',
        'page': 2,
        'limit': 20,
      });
      expect(api.lastApprovePayload, isEmpty);
      expect(api.lastRejectPayload, {'comment': 'Budget missing details'});
    },
  );

  test('reject comment is required and must be at least 10 characters', () {
    expect(
      () => const ApprovalDecisionPayload(comment: '').validateReject(),
      throwsArgumentError,
    );
    expect(
      () => const ApprovalDecisionPayload(comment: 'Budget').validateReject(),
      throwsArgumentError,
    );
    expect(
      () => const ApprovalDecisionPayload(
        comment: 'Budget allocation not available.',
      ).validateReject(),
      returnsNormally,
    );
  });

  testWidgets('approval inbox renders backend items and applies filters', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _approverSession),
    );
    await authController.restoreSession();
    final repository = _FakeApprovalRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          approvalRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: ApprovalInboxScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laptop Request'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('approvalSearchField')),
      'laptop',
    );
    await tester.enterText(
      find.byKey(const Key('approvalDepartmentField')),
      'dep-1',
    );
    await tester.tap(find.byKey(const Key('approvalFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(repository.lastFilters?.search, 'laptop');
    expect(repository.lastFilters?.departmentId, 'dep-1');
  });

  testWidgets('approval details approve and reject use approval mode actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _approverSession),
    );
    await authController.restoreSession();
    final approvalRepository = _FakeApprovalRepository();
    final requestRepository = _FakePurchaseRequestRepository(
      detail: _request(status: PurchaseRequestStatus.submitted),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          approvalRepositoryProvider.overrideWithValue(approvalRepository),
          purchaseRequestRepositoryProvider.overrideWithValue(
            requestRepository,
          ),
        ],
        child: const MaterialApp(
          home: PurchaseRequestDetailsScreen(
            requestId: 'request-1',
            approvalMode: true,
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('approveRequestButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('approveRequestButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmApproveButton')));
    await tester.pumpAndSettle();

    expect(approvalRepository.approvedRequestIds, ['request-1']);
    expect(approvalRepository.approveComments.single, isNull);

    await tester.tap(find.byKey(const Key('rejectRequestButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rejectReasonField')),
      'Budget',
    );
    await tester.tap(find.byKey(const Key('confirmRejectButton')));
    await tester.pump();
    expect(find.text('Reason must be at least 10 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('rejectReasonField')),
      'Budget justification is missing',
    );
    await tester.tap(find.byKey(const Key('confirmRejectButton')));
    await tester.pumpAndSettle();

    expect(approvalRepository.rejectedRequestIds, ['request-1']);
    expect(
      approvalRepository.rejectComments.single,
      'Budget justification is missing',
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.restoredSession});

  AuthSession? restoredSession;

  @override
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    restoredSession = null;
  }

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}

class _FakeApprovalRepository implements ApprovalRepository {
  final approvedRequestIds = <String>[];
  final rejectedRequestIds = <String>[];
  final approveComments = <String?>[];
  final rejectComments = <String?>[];
  ApprovalInboxFilters? lastFilters;

  @override
  Future<void> approve(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    payload.validateApprove();
    approvedRequestIds.add(requestId);
    approveComments.add(payload.normalizedComment);
  }

  @override
  Future<ApprovalInboxPage> getInbox(
    AuthSession session,
    ApprovalInboxFilters filters,
  ) async {
    lastFilters = filters;
    return ApprovalInboxPage(
      items: [
        ApprovalInboxItem(
          requestId: 'request-1',
          requestNumber: 'PR-001',
          title: 'Laptop Request',
          requesterName: 'Tanvir Hasan',
          departmentId: 'dep-1',
          departmentName: 'Operations',
          priority: PurchaseRequestPriority.high,
          neededDate: DateTime(2026, 1, 10),
          estimatedTotal: 1200,
          currentApprovalStep: 'Pending approval',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<void> reject(
    AuthSession session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    payload.validateReject();
    rejectedRequestIds.add(requestId);
    rejectComments.add(payload.normalizedComment);
  }
}

class _FakeProcurementApi implements ProcurementApi {
  Map<String, Object?>? lastInboxQuery;
  Map<String, dynamic>? lastApprovePayload;
  Map<String, dynamic>? lastRejectPayload;

  @override
  Future<void> approveRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) async {
    lastApprovePayload = request.toJson();
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
  ) async {
    lastInboxQuery = {
      'search': search,
      'priority': priority,
      'departmentId': departmentId,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'page': page,
      'limit': limit,
    };
    return const ApprovalInboxPageDto(items: [], page: 1, limit: 10, total: 0);
  }

  @override
  Future<void> rejectRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) async {
    lastRejectPayload = request.toJson();
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto request) {
    throw UnimplementedError();
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
  Future<DashboardSummaryDto> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<AuthUserDto> getCurrentUser() {
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
  Future<NotificationPageDto> getNotifications(int page, int limit) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationUnreadCountDto> getNotificationUnreadCount() {
    throw UnimplementedError();
  }

  @override
  Future<PermissionsResponseDto> getPermissions() {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> getPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ApprovalHistoryResponseDto> getPurchaseRequestApprovalHistory(
    String id,
  ) {
    throw UnimplementedError();
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
  Future<LoginResponseDto> login(LoginRequestDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePurchaseRequestRepository implements PurchaseRequestRepository {
  _FakePurchaseRequestRepository({required this.detail});

  final PurchaseRequestEntity detail;

  @override
  Future<void> approve({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestEntity> cancel(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestEntity> create(CreatePurchaseRequestInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<PurchaseRequestEntity>> getAll() async => [detail];

  @override
  Future<List<ApprovalHistoryEntry>> getApprovalHistory(String id) async => [];

  @override
  Future<PurchaseRequestEntity?> getById(String localId) async => detail;

  @override
  Future<PurchaseRequestPage> getMyRequests(PurchaseRequestFilters filters) {
    throw UnimplementedError();
  }

  @override
  Future<void> reject({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestEntity> saveDraft(PurchaseRequestPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestEntity> submit(String id) {
    throw UnimplementedError();
  }

  @override
  Future<SyncSummary> syncPending() async => const SyncSummary.empty();

  @override
  Future<PurchaseRequestEntity> updateDraft(
    String id,
    PurchaseRequestPayload payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchApprovalInbox(String companyId) {
    return Stream.value([detail]);
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchByCompany(String companyId) {
    return Stream.value([detail]);
  }
}

PurchaseRequestEntity _request({required String status}) {
  final now = DateTime(2026, 1, 1);
  return PurchaseRequestEntity(
    localId: 'request-1',
    serverId: 'request-1',
    companyId: 'company-1',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    requestNumber: 'PR-001',
    title: 'Laptop Request',
    description: 'Developer laptop',
    requesterId: 'user-1',
    requesterName: 'Tanvir Hasan',
    departmentId: 'dep-1',
    departmentName: 'Operations',
    priority: PurchaseRequestPriority.high,
    neededDate: DateTime(2026, 1, 10),
    status: status,
    totalAmount: 1200,
    items: const [],
  );
}
