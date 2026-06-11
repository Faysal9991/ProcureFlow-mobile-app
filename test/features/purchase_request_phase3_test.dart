import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procurement_management/app/theme/app_theme.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/sync/sync_summary.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/purchase_request/domain/purchase_request_entity.dart';
import 'package:procurement_management/features/purchase_request/domain/purchase_request_repository.dart';
import 'package:procurement_management/features/purchase_request/presentation/approval_history_screen.dart';
import 'package:procurement_management/features/purchase_request/presentation/my_requests_screen.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_controller.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_details_screen.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_form_screen.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_providers.dart';

const _session = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Tanvir Hasan',
  email: 'tanvir@example.com',
  companyId: 'company-1',
  companyName: 'Demo Company',
  roles: ['employee'],
  permissions: ['purchase_requests.view', 'purchase_requests.create'],
);

void main() {
  test('Phase 3 enables My Requests without changing bottom navigation', () {
    final menuItems = visiblePhase2MenuItems(_session);

    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
    expect(menuItems.single.title, 'My Requests');
    expect(menuItems.single.route, '/requests');
    expect(menuItems.single.isImplemented, isTrue);
  });

  test('controller sends list filters to repository', () async {
    final repository = _FakePurchaseRequestRepository();
    final controller = PurchaseRequestController(repository);
    final filters = PurchaseRequestFilters(
      search: 'laptop',
      status: PurchaseRequestStatus.draft,
      priority: PurchaseRequestPriority.high,
      dateFrom: DateTime(2026, 1, 1),
      dateTo: DateTime(2026, 1, 31),
      page: 2,
      limit: 25,
    );

    await controller.loadList(filters);

    expect(repository.lastFilters, same(filters));
    expect(controller.state.requests, repository.requests);
  });

  test('payload total is calculated across multiple items', () {
    final payload = PurchaseRequestPayload(
      title: 'Office supplies',
      description: null,
      priority: PurchaseRequestPriority.normal,
      neededDate: null,
      items: const [
        PurchaseRequestItemInput(
          name: 'Paper',
          description: null,
          quantity: 2,
          unit: 'ream',
          estimatedUnitPrice: 300,
        ),
        PurchaseRequestItemInput(
          name: 'Ink',
          description: null,
          quantity: 3,
          unit: 'pcs',
          estimatedUnitPrice: 125,
        ),
      ],
    );

    expect(payload.totalAmount, 975);
  });

  testWidgets('request filters render themed action buttons', (tester) async {
    final authController = await _authController();
    final repository = _FakePurchaseRequestRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          purchaseRequestRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MyRequestsScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('requestFilterApplyButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'controller create, update, submit, and cancel call backend methods',
    () async {
      final repository = _FakePurchaseRequestRepository();
      final controller = PurchaseRequestController(repository);
      final payload = _payload();

      await controller.saveDraft(payload: payload);
      await controller.saveDraft(payload: payload, id: 'draft-1');
      await controller.createAndSubmit(payload);
      await controller.submit('draft-1');
      await controller.cancel('submitted-1');

      expect(repository.savedPayload, same(payload));
      expect(repository.updatedPayload, same(payload));
      expect(repository.calls, [
        'create',
        'update:draft-1',
        'create',
        'submit:created-1',
        'submit:draft-1',
        'cancel:submitted-1',
      ]);
    },
  );

  testWidgets('edit form blocks non-draft requests', (tester) async {
    final authController = await _authController();
    final repository = _FakePurchaseRequestRepository(
      detail: _request(
        id: 'submitted-1',
        status: PurchaseRequestStatus.submitted,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          purchaseRequestRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: PurchaseRequestFormScreen(
            requestId: 'submitted-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('own draft requests'), findsOneWidget);
  });

  testWidgets('details actions follow request status rules', (tester) async {
    await _pumpDetails(
      tester,
      _request(id: 'draft-1', status: PurchaseRequestStatus.draft),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('editRequestButton')),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.byKey(const Key('editRequestButton')), findsOneWidget);
    expect(find.byKey(const Key('submitDraftButton')), findsOneWidget);
    expect(find.byKey(const Key('cancelRequestButton')), findsOneWidget);
    expect(
      _request(status: PurchaseRequestStatus.draft).canViewApprovalHistory,
      isFalse,
    );

    final submitted = _request(
      id: 'submitted-1',
      status: PurchaseRequestStatus.submitted,
    );
    expect(submitted.canEdit, isFalse);
    expect(submitted.canSubmit, isFalse);
    expect(submitted.canCancel, isTrue);
    expect(submitted.canViewApprovalHistory, isTrue);
  });

  testWidgets('approval history loads and renders timeline entries', (
    tester,
  ) async {
    final repository = _FakePurchaseRequestRepository(
      history: [
        ApprovalHistoryEntry(
          id: 'history-1',
          approverName: 'Manager',
          action: 'Submitted',
          status: PurchaseRequestStatus.submitted,
          comment: 'Looks ready',
          createdAt: DateTime(2026, 1, 2, 10),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchaseRequestRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: ApprovalHistoryScreen(
            requestId: 'submitted-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.calls, ['history:submitted-1']);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Looks ready'), findsOneWidget);
  });
}

Future<void> _pumpDetails(
  WidgetTester tester,
  PurchaseRequestEntity request,
) async {
  final authController = await _authController();
  final repository = _FakePurchaseRequestRepository(detail: request);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => authController),
        purchaseRequestRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: PurchaseRequestDetailsScreen(
          requestId: request.localId,
          showBottomNavigation: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<AuthController> _authController([AuthSession session = _session]) async {
  final controller = AuthController(
    _FakeAuthRepository(restoredSession: session),
  );
  await controller.restoreSession();
  return controller;
}

PurchaseRequestPayload _payload() {
  return const PurchaseRequestPayload(
    title: 'Laptop',
    description: 'Developer laptop',
    priority: PurchaseRequestPriority.high,
    neededDate: null,
    items: [
      PurchaseRequestItemInput(
        name: 'Laptop',
        description: null,
        quantity: 1,
        unit: 'pcs',
        estimatedUnitPrice: 1200,
      ),
    ],
  );
}

PurchaseRequestEntity _request({
  String id = 'draft-1',
  String status = PurchaseRequestStatus.draft,
}) {
  final now = DateTime(2026, 1, 1);
  return PurchaseRequestEntity(
    localId: id,
    serverId: id,
    companyId: 'company-1',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    requestNumber: 'PR-001',
    title: 'Laptop',
    description: 'Developer laptop',
    requesterId: 'user-1',
    requesterName: 'Tanvir Hasan',
    departmentId: 'dept-1',
    departmentName: 'Operations',
    priority: PurchaseRequestPriority.high,
    neededDate: DateTime(2026, 1, 10),
    status: status,
    totalAmount: 1200,
    items: [
      PurchaseRequestItemEntity(
        localId: 'item-1',
        serverId: 'item-1',
        companyId: 'company-1',
        syncStatus: SyncStatus.synced,
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: now,
        isDeleted: false,
        requestLocalId: id,
        name: 'Laptop',
        description: null,
        quantity: 1,
        unit: 'pcs',
        unitPrice: 1200,
        lineTotal: 1200,
      ),
    ],
  );
}

class _FakePurchaseRequestRepository implements PurchaseRequestRepository {
  _FakePurchaseRequestRepository({
    this.detail,
    this.history = const [],
    List<PurchaseRequestEntity>? requests,
  }) : requests = requests ?? [_request()];

  final PurchaseRequestEntity? detail;
  final List<ApprovalHistoryEntry> history;
  final List<PurchaseRequestEntity> requests;
  final calls = <String>[];
  PurchaseRequestFilters? lastFilters;
  PurchaseRequestPayload? savedPayload;
  PurchaseRequestPayload? updatedPayload;

  @override
  Future<PurchaseRequestEntity> cancel(String id) async {
    calls.add('cancel:$id');
    return _request(id: id, status: PurchaseRequestStatus.cancelled);
  }

  @override
  Future<PurchaseRequestEntity> create(CreatePurchaseRequestInput input) {
    return saveDraft(input);
  }

  @override
  Future<List<PurchaseRequestEntity>> getAll() async => requests;

  @override
  Future<List<ApprovalHistoryEntry>> getApprovalHistory(String id) async {
    calls.add('history:$id');
    return history;
  }

  @override
  Future<PurchaseRequestEntity?> getById(String localId) async {
    if (detail != null) return detail;
    for (final request in requests) {
      if (request.localId == localId) return request;
    }
    return null;
  }

  @override
  Future<PurchaseRequestPage> getMyRequests(
    PurchaseRequestFilters filters,
  ) async {
    lastFilters = filters;
    return PurchaseRequestPage(
      items: requests,
      page: filters.page,
      limit: filters.limit,
      total: requests.length,
    );
  }

  @override
  Future<PurchaseRequestEntity> saveDraft(
    PurchaseRequestPayload payload,
  ) async {
    calls.add('create');
    savedPayload = payload;
    return _request(id: 'created-1');
  }

  @override
  Future<PurchaseRequestEntity> submit(String id) async {
    calls.add('submit:$id');
    return _request(id: id, status: PurchaseRequestStatus.submitted);
  }

  @override
  Future<SyncSummary> syncPending() async => const SyncSummary.empty();

  @override
  Future<PurchaseRequestEntity> updateDraft(
    String id,
    PurchaseRequestPayload payload,
  ) async {
    calls.add('update:$id');
    updatedPayload = payload;
    return _request(id: id);
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchApprovalInbox(String companyId) {
    return Stream.value(requests);
  }

  @override
  Stream<List<PurchaseRequestEntity>> watchByCompany(String companyId) {
    return Stream.value(requests);
  }

  @override
  Future<void> approve({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) async {}

  @override
  Future<void> reject({
    required String companyId,
    required String requestLocalId,
    required String actorId,
    required String comment,
  }) async {}
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
