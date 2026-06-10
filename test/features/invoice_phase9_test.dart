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
    hide Invoice, PurchaseOrder, PurchaseOrderItem;
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';
import 'package:procurement_management/features/invoice/data/invoice_repository_impl.dart';
import 'package:procurement_management/features/invoice/domain/invoice_entity.dart';
import 'package:procurement_management/features/invoice/domain/invoice_repository.dart';
import 'package:procurement_management/features/invoice/presentation/invoice_providers.dart';
import 'package:procurement_management/features/purchase_order/domain/purchase_order_entity.dart';
import 'package:procurement_management/features/purchase_order/domain/purchase_order_repository.dart';
import 'package:procurement_management/features/purchase_order/presentation/purchase_order_details_screen.dart';
import 'package:procurement_management/features/purchase_order/presentation/purchase_order_providers.dart';

const _financeSession = AuthSession(
  accessToken: 'token',
  userId: 'finance-1',
  userName: 'Finance User',
  email: 'finance@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['FINANCE'],
  permissions: ['invoices.view', 'invoices.create', 'invoices.manage'],
);

void main() {
  test('Phase 9 enables Invoices without changing bottom navigation', () {
    final items = visiblePhase2MenuItems(_financeSession);
    final createPermission = visiblePhase2MenuItems(
      _financeSession.copyWith(
        roles: const [],
        permissions: const ['invoices.create'],
      ),
    );
    final adminRole = visiblePhase2MenuItems(
      _financeSession.copyWith(
        roles: const ['COMPANY_ADMIN'],
        permissions: const [],
      ),
    );
    final withoutPermission = visiblePhase2MenuItems(
      _financeSession.copyWith(roles: const [], permissions: const []),
    );

    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
    expect(items.map((item) => item.title), contains('Invoices'));
    final invoices = items.firstWhere((item) => item.title == 'Invoices');
    expect(invoices.route, '/invoices');
    expect(invoices.isImplemented, isTrue);
    expect(createPermission.map((item) => item.title), contains('Invoices'));
    expect(adminRole.map((item) => item.title), contains('Invoices'));
    expect(
      withoutPermission.map((item) => item.title),
      isNot(contains('Invoices')),
    );
  });

  testWidgets('invoice routes are registered', (tester) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _financeSession),
    );
    await authController.restoreSession();
    final invoiceRepository = _FakeInvoiceRepository();
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(),
          ),
          invoiceRepositoryProvider.overrideWithValue(invoiceRepository),
          purchaseOrderRepositoryProvider.overrideWithValue(
            _FakePurchaseOrderRepository(
              detail: _purchaseOrder(status: PurchaseOrderStatus.received),
            ),
          ),
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

    router.go('/invoices');
    await tester.pumpAndSettle();
    expect(find.text('Invoices'), findsWidgets);

    router.go('/invoices/invoice-1');
    await tester.pumpAndSettle();
    expect(find.text('Invoice Details'), findsOneWidget);

    router.go('/invoices/invoice-1/edit');
    await tester.pumpAndSettle();
    expect(find.text('Edit Invoice'), findsOneWidget);

    router.go('/invoices/new?purchaseOrderId=po-1');
    await tester.pumpAndSettle();
    expect(find.text('Create Invoice'), findsWidgets);
  });

  test('repository sends invoice filters and camelCase payloads', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _FakeInvoiceApi();
    final repository = InvoiceRepositoryImpl(
      dao: ProcurementDao(database),
      api: api,
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test/api/v1',
        useMockApi: false,
      ),
    );
    addTearDown(database.close);

    await repository.getInvoices(
      InvoiceFilters(
        search: ' INV ',
        status: InvoiceStatus.pending,
        vendorId: ' vendor-1 ',
        purchaseOrderId: ' po-1 ',
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
        page: 2,
        limit: 25,
      ),
    );
    expect(api.lastListQuery, {
      'search': 'INV',
      'status': InvoiceStatus.pending,
      'vendorId': 'vendor-1',
      'purchaseOrderId': 'po-1',
      'dateFrom': '2026-07-01',
      'dateTo': '2026-07-31',
      'page': 2,
      'limit': 25,
    });

    await repository.getInvoices(
      const InvoiceFilters(search: 'i', status: '', vendorId: ''),
    );
    expect(api.lastListQuery?['search'], isNull);
    expect(api.lastListQuery?['status'], isNull);
    expect(api.lastListQuery?['vendorId'], isNull);

    await repository.create(
      CreateInvoicePayload(
        purchaseOrderId: ' po-1 ',
        invoiceNumber: ' INV-2026-001 ',
        invoiceDate: DateTime(2026, 7, 1),
        dueDate: DateTime(2026, 7, 31),
        invoiceAmount: 2360,
        notes: ' First invoice for PO. ',
      ),
    );
    expect(api.lastCreatePayload, {
      'purchaseOrderId': 'po-1',
      'invoiceNumber': 'INV-2026-001',
      'invoiceDate': '2026-07-01',
      'dueDate': '2026-07-31',
      'invoiceAmount': 2360.0,
      'notes': 'First invoice for PO.',
    });

    await repository.update(
      'invoice-1',
      UpdateInvoicePayload(
        invoiceNumber: ' INV-2026-002 ',
        invoiceDate: DateTime(2026, 7, 2),
        dueDate: DateTime(2026, 8, 1),
        invoiceAmount: 2400,
        notes: ' Updated invoice. ',
      ),
    );
    expect(api.updatedId, 'invoice-1');
    expect(api.lastUpdatePayload, {
      'invoiceNumber': 'INV-2026-002',
      'invoiceDate': '2026-07-02',
      'dueDate': '2026-08-01',
      'invoiceAmount': 2400.0,
      'notes': 'Updated invoice.',
    });

    await repository.cancel('invoice-1');
    expect(api.cancelledId, 'invoice-1');
  });

  test(
    'mock mode creates, updates, cancels, and blocks invalid invoice flows',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dao = ProcurementDao(database);
      final repository = InvoiceRepositoryImpl(
        dao: dao,
        api: _FakeInvoiceApi(),
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
        roleName: 'FINANCE',
      );

      final seeded = await repository.getInvoices(const InvoiceFilters());
      expect(
        seeded.items.map((invoice) => invoice.normalizedStatus),
        containsAll([InvoiceStatus.pending, InvoiceStatus.partiallyPaid]),
      );

      final created = await repository.create(
        CreateInvoicePayload(
          purchaseOrderId: 'po-demo-received-open',
          invoiceNumber: 'INV-MOCK-001',
          invoiceDate: DateTime(2026, 7),
          dueDate: DateTime(2026, 7, 31),
          invoiceAmount: 1800,
          notes: 'Created from received PO.',
        ),
      );
      expect(created.normalizedStatus, InvoiceStatus.pending);
      expect(created.purchaseOrderId, 'po-demo-received-open');
      expect(
        await repository.getByPurchaseOrderId('po-demo-received-open'),
        isNotNull,
      );

      expect(
        repository.create(
          CreateInvoicePayload(
            purchaseOrderId: 'po-demo-received-open',
            invoiceNumber: 'INV-DUP',
            invoiceDate: DateTime(2026, 7),
            dueDate: DateTime(2026, 7, 31),
            invoiceAmount: 1800,
            notes: null,
          ),
        ),
        throwsStateError,
      );
      expect(
        repository.create(
          CreateInvoicePayload(
            purchaseOrderId: 'po-demo-draft',
            invoiceNumber: 'INV-BLOCKED',
            invoiceDate: DateTime(2026, 7),
            dueDate: DateTime(2026, 7, 31),
            invoiceAmount: 500,
            notes: null,
          ),
        ),
        throwsStateError,
      );

      final updated = await repository.update(
        'invoice-demo-pending',
        UpdateInvoicePayload(
          invoiceNumber: 'INV-DEMO-PENDING-UPDATED',
          invoiceDate: DateTime(2026, 7, 2),
          dueDate: DateTime(2026, 8, 2),
          invoiceAmount: 1300,
          notes: 'Updated pending invoice.',
        ),
      );
      expect(updated.invoiceNumber, 'INV-DEMO-PENDING-UPDATED');
      expect(updated.dueAmount, 1300);

      final cancelled = await repository.cancel('invoice-demo-pending');
      expect(cancelled.normalizedStatus, InvoiceStatus.cancelled);

      expect(
        repository.update(
          'invoice-demo-partial',
          UpdateInvoicePayload(
            invoiceNumber: 'INV-PARTIAL-EDIT',
            invoiceDate: DateTime(2026, 7, 1),
            dueDate: DateTime(2026, 7, 31),
            invoiceAmount: 2200,
            notes: null,
          ),
        ),
        throwsStateError,
      );
      expect(repository.cancel('invoice-demo-partial'), throwsStateError);
    },
  );

  testWidgets(
    'PO details shows Create Invoice for received PO without invoice',
    (tester) async {
      final authController = AuthController(
        _FakeAuthRepository(restoredSession: _financeSession),
      );
      await authController.restoreSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => authController),
            purchaseOrderRepositoryProvider.overrideWithValue(
              _FakePurchaseOrderRepository(
                detail: _purchaseOrder(status: PurchaseOrderStatus.received),
              ),
            ),
            invoiceRepositoryProvider.overrideWithValue(
              _FakeInvoiceRepository(existingInvoice: null),
            ),
          ],
          child: const MaterialApp(
            home: PurchaseOrderDetailsScreen(
              orderId: 'po-1',
              showBottomNavigation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Invoice'), findsOneWidget);
      expect(find.text('View Invoice'), findsNothing);
    },
  );

  testWidgets('PO details shows View Invoice when invoice already exists', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(
        restoredSession: _financeSession.copyWith(
          permissions: const ['invoices.view'],
        ),
      ),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          purchaseOrderRepositoryProvider.overrideWithValue(
            _FakePurchaseOrderRepository(
              detail: _purchaseOrder(status: PurchaseOrderStatus.closed),
            ),
          ),
          invoiceRepositoryProvider.overrideWithValue(
            _FakeInvoiceRepository(existingInvoice: _invoice()),
          ),
        ],
        child: const MaterialApp(
          home: PurchaseOrderDetailsScreen(
            orderId: 'po-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Invoice'), findsOneWidget);
    expect(find.text('Create Invoice'), findsNothing);
  });
}

class _FakeInvoiceApi implements ProcurementApi {
  Map<String, Object?>? lastListQuery;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;
  String? updatedId;
  String? cancelledId;

  @override
  Future<InvoicePageDto> getInvoices(
    String? search,
    String? status,
    String? vendorId,
    String? purchaseOrderId,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) async {
    lastListQuery = {
      'search': search,
      'status': status,
      'vendorId': vendorId,
      'purchaseOrderId': purchaseOrderId,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'page': page,
      'limit': limit,
    };
    return InvoicePageDto(
      items: [_invoiceDto()],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<InvoiceDto> createInvoice(CreateInvoicePayloadDto request) async {
    lastCreatePayload = request.toJson();
    return _invoiceDto(
      id: 'invoice-created',
      purchaseOrderId: request.purchaseOrderId,
      invoiceNumber: request.invoiceNumber,
      invoiceAmount: request.invoiceAmount,
      notes: request.notes,
    );
  }

  @override
  Future<InvoiceDto> updateInvoice(
    String id,
    UpdateInvoicePayloadDto request,
  ) async {
    updatedId = id;
    lastUpdatePayload = request.toJson();
    return _invoiceDto(
      id: id,
      invoiceNumber: request.invoiceNumber,
      invoiceAmount: request.invoiceAmount,
      notes: request.notes,
    );
  }

  @override
  Future<InvoiceDto> getInvoice(String id) async => _invoiceDto(id: id);

  @override
  Future<InvoiceDto> cancelInvoice(String id) async {
    cancelledId = id;
    return _invoiceDto(id: id, status: InvoiceStatus.cancelled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInvoiceRepository implements InvoiceRepository {
  _FakeInvoiceRepository({this.existingInvoice});

  final Invoice? existingInvoice;
  InvoiceFilters? lastFilters;

  @override
  Future<InvoicePage> getInvoices(InvoiceFilters filters) async {
    lastFilters = filters;
    final invoice = existingInvoice ?? _invoice();
    return InvoicePage(
      items: [invoice],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<Invoice> create(CreateInvoicePayload payload) async => _invoice(
    purchaseOrderId: payload.purchaseOrderId,
    invoiceNumber: payload.invoiceNumber,
    invoiceAmount: payload.invoiceAmount,
    notes: payload.notes,
  );

  @override
  Future<Invoice?> getById(String id) async => _invoice(localId: id);

  @override
  Future<Invoice> update(String id, UpdateInvoicePayload payload) async =>
      _invoice(
        localId: id,
        invoiceNumber: payload.invoiceNumber,
        invoiceAmount: payload.invoiceAmount,
        notes: payload.notes,
      );

  @override
  Future<Invoice> cancel(String id) async =>
      _invoice(localId: id, status: InvoiceStatus.cancelled);

  @override
  Future<Invoice?> getByPurchaseOrderId(String purchaseOrderId) async {
    if (existingInvoice == null) return null;
    return _invoice(purchaseOrderId: purchaseOrderId);
  }
}

class _FakePurchaseOrderRepository implements PurchaseOrderRepository {
  const _FakePurchaseOrderRepository({required this.detail});

  final PurchaseOrder detail;

  @override
  Future<PurchaseOrder?> getById(String id) async => detail;

  @override
  Future<PurchaseOrderPage> getPurchaseOrders(
    PurchaseOrderFilters filters,
  ) async {
    return PurchaseOrderPage(
      items: [detail],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<PurchaseOrder> create(CreatePurchaseOrderPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrder> update(String id, UpdatePurchaseOrderPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrder> issue(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrder> receive(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrder> cancel(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrder> close(String id) {
    throw UnimplementedError();
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return const DashboardSummary(cards: [], activities: []);
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 0;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.restoredSession});

  final AuthSession restoredSession;

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
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}

InvoiceDto _invoiceDto({
  String id = 'invoice-1',
  String invoiceNumber = 'INV-2026-001',
  String purchaseOrderId = 'po-1',
  String status = InvoiceStatus.pending,
  double invoiceAmount = 2360,
  double paidAmount = 0,
  String? notes = 'First invoice for PO.',
}) {
  final now = DateTime(2026, 7);
  return InvoiceDto(
    id: id,
    companyId: 'company-demo',
    invoiceNumber: invoiceNumber,
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    purchaseOrderId: purchaseOrderId,
    purchaseOrderNumber: 'PO-001',
    status: status,
    invoiceDate: now,
    dueDate: DateTime(2026, 7, 31),
    invoiceAmount: invoiceAmount,
    paidAmount: paidAmount,
    dueAmount: invoiceAmount - paidAmount,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );
}

Invoice _invoice({
  String localId = 'invoice-1',
  String invoiceNumber = 'INV-2026-001',
  String purchaseOrderId = 'po-1',
  String status = InvoiceStatus.pending,
  double invoiceAmount = 2360,
  String? notes = 'First invoice for PO.',
}) {
  final now = DateTime(2026, 7);
  return Invoice(
    localId: localId,
    serverId: localId,
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    invoiceNumber: invoiceNumber,
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    purchaseOrderId: purchaseOrderId,
    purchaseOrderNumber: 'PO-001',
    status: status,
    invoiceDate: now,
    dueDate: DateTime(2026, 7, 31),
    invoiceAmount: invoiceAmount,
    paidAmount: 0,
    dueAmount: invoiceAmount,
    notes: notes,
  );
}

PurchaseOrder _purchaseOrder({required String status}) {
  final now = DateTime(2026, 7);
  return PurchaseOrder(
    localId: 'po-1',
    serverId: 'po-1',
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    poNumber: 'PO-001',
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    rfqId: 'rfq-1',
    rfqNumber: 'RFQ-001',
    quotationId: 'quotation-1',
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    createdById: 'user-1',
    createdByName: 'Procurement User',
    status: status,
    totalAmount: 2360,
    notes: 'Use selected quotation.',
    issueDate: status == PurchaseOrderStatus.issued ? now : null,
    receivedDate: status == PurchaseOrderStatus.received ? now : null,
    closedDate: status == PurchaseOrderStatus.closed ? now : null,
    cancelledDate: status == PurchaseOrderStatus.cancelled ? now : null,
    items: const [
      PurchaseOrderItem(
        id: 'po-item-1',
        rfqItemId: 'rfq-item-1',
        itemName: 'Laptop',
        quantity: 2,
        unit: 'pcs',
        unitPrice: 1180,
        lineTotal: 2360,
      ),
    ],
  );
}
