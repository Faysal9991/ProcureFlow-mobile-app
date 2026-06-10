import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:procurement_management/app/router/app_router.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart'
    hide Quotation, QuotationItem, Rfq, RfqItem, RfqVendor;
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';
import 'package:procurement_management/features/rfq/data/rfq_repository_impl.dart';
import 'package:procurement_management/features/rfq/domain/rfq_entity.dart';
import 'package:procurement_management/features/rfq/domain/rfq_repository.dart';
import 'package:procurement_management/features/rfq/presentation/quotation_details_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_comparison_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_providers.dart';

const _managerSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Procurement User',
  email: 'procurement@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['PROCUREMENT'],
  permissions: ['rfq.view', 'rfq.manage'],
);

void main() {
  testWidgets('comparison route is registered and bottom nav is unchanged', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _managerSession),
    );
    await authController.restoreSession();
    final repository = _FakeRfqRepository();
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(),
          ),
          rfqRepositoryProvider.overrideWithValue(repository),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/rfqs/rfq-1/comparison');
    await tester.pumpAndSettle();

    expect(find.text('Quotation Comparison'), findsOneWidget);
    expect(find.text('Best Co'), findsWidgets);
    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
  });

  test('repository loads comparison and sends selection payload', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _FakeRfqApi();
    final repository = RfqRepositoryImpl(
      dao: ProcurementDao(database),
      api: api,
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test/api/v1',
        useMockApi: false,
      ),
    );
    addTearDown(database.close);

    final comparison = await repository.getComparison('rfq-1');
    expect(api.comparisonId, 'rfq-1');
    expect(comparison.quotations.first.vendorName, 'Best Co');
    expect(comparison.lowestQuotationId, 'quotation-best');

    final selected = await repository.selectQuotation(
      'rfq-1',
      const SelectedQuotationPayload(quotationId: 'quotation-best'),
    );
    expect(api.selectedRfqId, 'rfq-1');
    expect(api.lastSelectedPayload, {'quotationId': 'quotation-best'});
    expect(selected.normalizedStatus, RfqStatus.completed);
    expect(selected.selectedQuotationId, 'quotation-best');
  });

  test(
    'mock mode persists selected quotation and completed RFQ status',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dao = ProcurementDao(database);
      final repository = RfqRepositoryImpl(
        dao: dao,
        api: _FakeRfqApi(),
        config: const AppConfig(
          appName: 'Test',
          apiBaseUrl: '',
          useMockApi: true,
        ),
      );
      addTearDown(database.close);

      await dao.seedDemoData(
        companyId: 'company-demo',
        userId: 'user-1',
        userName: 'Test User',
        email: 'test@example.com',
        roleName: 'PROCUREMENT',
      );
      final eligible = await repository.getEligiblePurchaseRequests();
      final rfq = await repository.createRfq(
        CreateRfqPayload(
          purchaseRequestId: eligible.single.id,
          dueDate: DateTime(2026, 2, 1),
          notes: null,
        ),
      );
      await repository.assignVendors(
        rfq.localId,
        const AssignRfqVendorsPayload(vendorIds: ['vendor-officehub']),
      );
      final opened = await repository.openRfq(rfq.localId);
      final quotation = await repository.createQuotation(
        rfq.localId,
        CreateQuotationPayload(
          vendorId: 'vendor-officehub',
          quotationNumber: 'Q-001',
          quotationDate: DateTime(2026, 2, 2),
          validUntil: null,
          notes: null,
          items: [
            CreateQuotationItemInput(
              rfqItemId: opened.items.single.id,
              itemName: opened.items.single.itemName,
              quantity: opened.items.single.quantity,
              unitPrice: 1000,
            ),
          ],
        ),
      );

      final comparison = await repository.getComparison(rfq.localId);
      expect(comparison.quotations.single.quotationId, quotation.localId);

      await repository.selectQuotation(
        rfq.localId,
        SelectedQuotationPayload(quotationId: quotation.localId),
      );
      final completed = await repository.getById(rfq.localId);
      expect(completed?.normalizedStatus, RfqStatus.completed);
      expect(completed?.selectedQuotationId, quotation.localId);
    },
  );

  testWidgets('comparison is view-only without rfq.manage', (tester) async {
    final authController = AuthController(
      _FakeAuthRepository(
        restoredSession: _managerSession.copyWith(permissions: ['rfq.view']),
      ),
    );
    await authController.restoreSession();
    final repository = _FakeRfqRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: RfqComparisonScreen(
            rfqId: 'rfq-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best Co'), findsWidgets);
    await tester.tap(find.textContaining('Q-BEST'));
    await tester.pumpAndSettle();
    expect(find.text('LOWEST PRICE'), findsOneWidget);
    expect(find.text('Select Winner'), findsNothing);
    expect(find.textContaining('rfq.manage is required'), findsOneWidget);
  });

  testWidgets('comparison selects winner with rfq.manage', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _managerSession),
    );
    await authController.restoreSession();
    final repository = _FakeRfqRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: RfqComparisonScreen(
            rfqId: 'rfq-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Q-BEST'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('selectQuotationButton-quotation-best')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSelectQuotationButton')));
    await tester.pumpAndSettle();

    expect(repository.selectedPayloads.single.quotationId, 'quotation-best');
    expect(find.text('SELECTED'), findsOneWidget);
  });

  testWidgets('comparison empty state renders without quotations', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _managerSession),
    );
    await authController.restoreSession();
    final repository = _FakeRfqRepository(
      comparison: _comparison(quotations: const []),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: RfqComparisonScreen(
            rfqId: 'rfq-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No quotations submitted yet.'), findsOneWidget);
  });

  testWidgets('quotation details renders selected quotation fields', (
    tester,
  ) async {
    final repository = _FakeRfqRepository(
      comparison: _comparison(selectedQuotationId: 'quotation-best'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [rfqRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: QuotationDetailsScreen(
            rfqId: 'rfq-1',
            quotationId: 'quotation-best',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best Co'), findsOneWidget);
    expect(find.text('Q-BEST'), findsOneWidget);
    expect(find.text('LOWEST PRICE'), findsOneWidget);
    expect(find.text('SELECTED'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
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

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return const DashboardSummary(cards: [], activities: []);
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 0;
}

RfqComparison _comparison({
  String status = RfqStatus.quotationReceived,
  String? selectedQuotationId,
  List<RfqComparisonQuotation>? quotations,
}) {
  final resolvedQuotations =
      quotations ??
      [
        _comparisonQuotation(
          quotationId: 'quotation-best',
          vendorId: 'vendor-best',
          vendorName: 'Best Co',
          quotationNumber: 'Q-BEST',
          totalAmount: 1800,
          rank: 1,
        ),
        _comparisonQuotation(
          quotationId: 'quotation-high',
          vendorId: 'vendor-high',
          vendorName: 'High Co',
          quotationNumber: 'Q-HIGH',
          totalAmount: 2200,
          rank: 2,
        ),
      ];
  return RfqComparison(
    rfqId: 'rfq-1',
    rfqNumber: 'RFQ-001',
    status: status,
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    quotations: resolvedQuotations,
    lowestQuotationId: resolvedQuotations.isEmpty
        ? null
        : resolvedQuotations.first.quotationId,
    selectedQuotationId: selectedQuotationId,
  );
}

RfqComparisonQuotation _comparisonQuotation({
  required String quotationId,
  required String vendorId,
  required String vendorName,
  required String quotationNumber,
  required double totalAmount,
  required int rank,
}) {
  return RfqComparisonQuotation(
    quotationId: quotationId,
    vendorId: vendorId,
    vendorName: vendorName,
    quotationNumber: quotationNumber,
    quotationDate: DateTime(2026, 2, 2),
    validUntil: DateTime(2026, 2, 15),
    totalAmount: totalAmount,
    rank: rank,
    items: [
      RfqComparisonItem(
        rfqItemId: 'rfq-item-1',
        itemName: 'Laptop',
        quantity: 2,
        unit: 'pcs',
        unitPrice: totalAmount / 2,
        lineTotal: totalAmount,
      ),
    ],
  );
}

Rfq _rfq({
  String status = RfqStatus.quotationReceived,
  String? selectedQuotationId,
}) {
  final now = DateTime(2026, 1, 10);
  return Rfq(
    localId: 'rfq-1',
    serverId: 'rfq-1',
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    rfqNumber: 'RFQ-001',
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    dueDate: DateTime(2026, 2, 1),
    status: status,
    notes: null,
    vendorCount: 2,
    quotationCount: 2,
    selectedQuotationId: selectedQuotationId,
    items: const [],
    vendors: const [],
    quotations: const [],
  );
}

RfqDto _rfqDto({
  String status = RfqStatus.completed,
  String? selectedQuotationId,
}) {
  final now = DateTime(2026, 1, 10);
  return RfqDto(
    id: 'rfq-1',
    companyId: 'company-demo',
    rfqNumber: 'RFQ-001',
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    dueDate: DateTime(2026, 2, 1),
    status: status,
    notes: null,
    vendorCount: 2,
    quotationCount: 2,
    selectedQuotationId: selectedQuotationId,
    items: const [],
    vendors: const [],
    quotations: const [],
    createdAt: now,
    updatedAt: now,
  );
}

RfqComparisonDto _comparisonDto() {
  return const RfqComparisonDto(
    rfqId: 'rfq-1',
    rfqNumber: 'RFQ-001',
    status: RfqStatus.quotationReceived,
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    quotations: [
      RfqComparisonQuotationDto(
        quotationId: 'quotation-high',
        vendorId: 'vendor-high',
        vendorName: 'High Co',
        quotationNumber: 'Q-HIGH',
        quotationDate: null,
        validUntil: null,
        totalAmount: 2200,
        rank: 2,
        items: [
          RfqComparisonItemDto(
            rfqItemId: 'rfq-item-1',
            itemName: 'Laptop',
            quantity: 2,
            unit: 'pcs',
            unitPrice: 1100,
            lineTotal: 2200,
          ),
        ],
      ),
      RfqComparisonQuotationDto(
        quotationId: 'quotation-best',
        vendorId: 'vendor-best',
        vendorName: 'Best Co',
        quotationNumber: 'Q-BEST',
        quotationDate: null,
        validUntil: null,
        totalAmount: 1800,
        rank: 1,
        items: [
          RfqComparisonItemDto(
            rfqItemId: 'rfq-item-1',
            itemName: 'Laptop',
            quantity: 2,
            unit: 'pcs',
            unitPrice: 900,
            lineTotal: 1800,
          ),
        ],
      ),
    ],
    lowestQuotationId: null,
    selectedQuotationId: null,
  );
}

class _FakeRfqApi implements ProcurementApi {
  String? comparisonId;
  String? selectedRfqId;
  Map<String, dynamic>? lastSelectedPayload;

  @override
  Future<RfqComparisonDto> getRfqComparison(String id) async {
    comparisonId = id;
    return _comparisonDto();
  }

  @override
  Future<RfqDto> selectRfqQuotation(
    String id,
    SelectedQuotationPayloadDto request,
  ) async {
    selectedRfqId = id;
    lastSelectedPayload = request.toJson();
    return _rfqDto(selectedQuotationId: request.quotationId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRfqRepository implements RfqRepository {
  _FakeRfqRepository({RfqComparison? comparison})
    : comparison = comparison ?? _comparison();

  RfqComparison comparison;
  final selectedPayloads = <SelectedQuotationPayload>[];

  @override
  Future<RfqComparison> getComparison(String id) async => comparison;

  @override
  Future<Rfq> selectQuotation(
    String id,
    SelectedQuotationPayload payload,
  ) async {
    selectedPayloads.add(payload);
    comparison = _comparison(
      status: RfqStatus.completed,
      selectedQuotationId: payload.quotationId,
    );
    return _rfq(
      status: RfqStatus.completed,
      selectedQuotationId: payload.quotationId,
    );
  }

  @override
  Future<RfqPage> getRfqs(RfqFilters filters) async {
    return const RfqPage(items: [], page: 1, limit: 10, total: 0);
  }

  @override
  Future<Rfq> createRfq(CreateRfqPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<Rfq?> getById(String id) async => _rfq();

  @override
  Future<Rfq> assignVendors(String id, AssignRfqVendorsPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<Rfq> openRfq(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Quotation> createQuotation(String id, CreateQuotationPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<List<EligiblePurchaseRequest>> getEligiblePurchaseRequests({
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }
}
