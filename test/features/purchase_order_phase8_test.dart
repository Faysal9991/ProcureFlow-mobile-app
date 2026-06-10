import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart'
    hide Quotation, Rfq;
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/purchase_order/data/purchase_order_repository_impl.dart';
import 'package:procurement_management/features/purchase_order/domain/purchase_order_entity.dart';
import 'package:procurement_management/features/rfq/domain/rfq_entity.dart';
import 'package:procurement_management/features/rfq/domain/rfq_repository.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_comparison_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_providers.dart';

const _poSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Procurement User',
  email: 'procurement@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['PROCUREMENT'],
  permissions: ['purchase_orders.view', 'purchase_orders.create'],
);

void main() {
  test('Phase 8 enables Purchase Orders without changing bottom nav', () {
    final items = visiblePhase2MenuItems(_poSession);
    final withoutPermission = visiblePhase2MenuItems(
      _poSession.copyWith(permissions: const [], roles: const []),
    );

    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
    expect(items.map((item) => item.title), contains('Purchase Orders'));
    final purchaseOrders = items.firstWhere(
      (item) => item.title == 'Purchase Orders',
    );
    expect(purchaseOrders.route, '/purchase-orders');
    expect(purchaseOrders.isImplemented, isTrue);
    expect(
      withoutPermission.map((item) => item.title),
      isNot(contains('Purchase Orders')),
    );
  });

  test(
    'repository sends PO filters, payloads, and lifecycle endpoints',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final api = _FakePurchaseOrderApi();
      final repository = PurchaseOrderRepositoryImpl(
        dao: ProcurementDao(database),
        api: api,
        config: const AppConfig(
          appName: 'Test',
          apiBaseUrl: 'https://api.example.test/api/v1',
          useMockApi: false,
        ),
      );
      addTearDown(database.close);

      await repository.getPurchaseOrders(
        PurchaseOrderFilters(
          search: ' PO-001 ',
          status: PurchaseOrderStatus.issued,
          vendorId: ' vendor-1 ',
          purchaseRequestId: ' pr-1 ',
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 1, 31),
          page: 2,
          limit: 25,
        ),
      );
      expect(api.lastListQuery, {
        'search': 'PO-001',
        'status': PurchaseOrderStatus.issued,
        'vendorId': 'vendor-1',
        'purchaseRequestId': 'pr-1',
        'dateFrom': '2026-01-01',
        'dateTo': '2026-01-31',
        'page': 2,
        'limit': 25,
      });

      await repository.getPurchaseOrders(
        const PurchaseOrderFilters(search: ''),
      );
      expect(api.lastListQuery?['search'], isNull);

      await repository.create(
        const CreatePurchaseOrderPayload(
          quotationId: 'quotation-1',
          notes: ' Use selected RFQ quotation. ',
        ),
      );
      expect(api.lastCreatePayload, {
        'quotationId': 'quotation-1',
        'notes': 'Use selected RFQ quotation.',
      });

      await repository.update(
        'po-1',
        const UpdatePurchaseOrderPayload(notes: ' Updated note '),
      );
      expect(api.updatedId, 'po-1');
      expect(api.lastUpdatePayload, {'notes': 'Updated note'});

      await repository.issue('po-1');
      await repository.receive('po-1');
      await repository.close('po-1');
      await repository.cancel('po-2');
      expect(api.issuedId, 'po-1');
      expect(api.receivedId, 'po-1');
      expect(api.closedId, 'po-1');
      expect(api.cancelledId, 'po-2');
    },
  );

  testWidgets('RFQ comparison shows Create PO only when allowed', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _poSession),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(
            _FakeRfqRepository(
              comparison: _comparison(
                status: RfqStatus.completed,
                selectedQuotationId: 'quotation-1',
              ),
            ),
          ),
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

    expect(find.text('Create Purchase Order'), findsOneWidget);
    expect(find.text('View Purchase Order'), findsNothing);
  });

  testWidgets('RFQ comparison shows View PO when PO already exists', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(
        restoredSession: _poSession.copyWith(permissions: ['rfq.view']),
      ),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(
            _FakeRfqRepository(
              comparison: _comparison(
                status: RfqStatus.completed,
                selectedQuotationId: 'quotation-1',
                purchaseOrderId: 'po-1',
              ),
            ),
          ),
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

    expect(find.text('View Purchase Order'), findsOneWidget);
    expect(find.text('Create Purchase Order'), findsNothing);
  });

  testWidgets('RFQ comparison hides Create PO without create permission', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(
        restoredSession: _poSession.copyWith(permissions: ['rfq.view']),
      ),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          rfqRepositoryProvider.overrideWithValue(
            _FakeRfqRepository(
              comparison: _comparison(
                status: RfqStatus.completed,
                selectedQuotationId: 'quotation-1',
              ),
            ),
          ),
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

    expect(find.text('Create Purchase Order'), findsNothing);
    expect(find.text('View Purchase Order'), findsNothing);
  });
}

class _FakePurchaseOrderApi implements ProcurementApi {
  Map<String, Object?>? lastListQuery;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;
  String? updatedId;
  String? issuedId;
  String? receivedId;
  String? closedId;
  String? cancelledId;

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
  ) async {
    lastListQuery = {
      'search': search,
      'status': status,
      'vendorId': vendorId,
      'purchaseRequestId': purchaseRequestId,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'page': page,
      'limit': limit,
    };
    return PurchaseOrderPageDto(
      items: [_poDto()],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<PurchaseOrderDto> createPurchaseOrder(
    CreatePurchaseOrderPayloadDto request,
  ) async {
    lastCreatePayload = request.toJson();
    return _poDto(id: 'po-created', quotationId: request.quotationId);
  }

  @override
  Future<PurchaseOrderDto> updatePurchaseOrder(
    String id,
    UpdatePurchaseOrderPayloadDto request,
  ) async {
    updatedId = id;
    lastUpdatePayload = request.toJson();
    return _poDto(id: id, notes: request.notes);
  }

  @override
  Future<PurchaseOrderDto> getPurchaseOrder(String id) async => _poDto(id: id);

  @override
  Future<PurchaseOrderDto> issuePurchaseOrder(String id) async {
    issuedId = id;
    return _poDto(id: id, status: PurchaseOrderStatus.issued);
  }

  @override
  Future<PurchaseOrderDto> receivePurchaseOrder(String id) async {
    receivedId = id;
    return _poDto(id: id, status: PurchaseOrderStatus.received);
  }

  @override
  Future<PurchaseOrderDto> closePurchaseOrder(String id) async {
    closedId = id;
    return _poDto(id: id, status: PurchaseOrderStatus.closed);
  }

  @override
  Future<PurchaseOrderDto> cancelPurchaseOrder(String id) async {
    cancelledId = id;
    return _poDto(id: id, status: PurchaseOrderStatus.cancelled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class _FakeRfqRepository implements RfqRepository {
  _FakeRfqRepository({required this.comparison});

  final RfqComparison comparison;

  @override
  Future<RfqComparison> getComparison(String id) async => comparison;

  @override
  Future<RfqPage> getRfqs(RfqFilters filters) {
    throw UnimplementedError();
  }

  @override
  Future<Rfq> createRfq(CreateRfqPayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<Rfq?> getById(String id) {
    throw UnimplementedError();
  }

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
  Future<Rfq> selectQuotation(String id, SelectedQuotationPayload payload) {
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

PurchaseOrderDto _poDto({
  String id = 'po-1',
  String quotationId = 'quotation-1',
  String status = PurchaseOrderStatus.draft,
  String? notes = 'Use selected RFQ quotation.',
}) {
  final now = DateTime(2026, 1, 1);
  return PurchaseOrderDto(
    id: id,
    companyId: 'company-demo',
    poNumber: 'PO-001',
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    rfqId: 'rfq-1',
    rfqNumber: 'RFQ-001',
    quotationId: quotationId,
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    createdById: 'user-1',
    createdByName: 'Procurement User',
    status: status,
    totalAmount: 1800,
    notes: notes,
    issueDate: status == PurchaseOrderStatus.issued ? now : null,
    receivedDate: status == PurchaseOrderStatus.received ? now : null,
    closedDate: status == PurchaseOrderStatus.closed ? now : null,
    cancelledDate: status == PurchaseOrderStatus.cancelled ? now : null,
    items: const [
      PurchaseOrderItemDto(
        id: 'po-item-1',
        rfqItemId: 'rfq-item-1',
        itemName: 'Laptop',
        quantity: 2,
        unit: 'pcs',
        unitPrice: 900,
        lineTotal: 1800,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

RfqComparison _comparison({
  String status = RfqStatus.completed,
  String? selectedQuotationId,
  String? purchaseOrderId,
}) {
  return RfqComparison(
    rfqId: 'rfq-1',
    rfqNumber: 'RFQ-001',
    status: status,
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    quotations: const [
      RfqComparisonQuotation(
        quotationId: 'quotation-1',
        vendorId: 'vendor-1',
        vendorName: 'Best Co',
        quotationNumber: 'Q-001',
        quotationDate: null,
        validUntil: null,
        totalAmount: 1800,
        rank: 1,
        items: [
          RfqComparisonItem(
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
    lowestQuotationId: 'quotation-1',
    selectedQuotationId: selectedQuotationId,
    purchaseOrderId: purchaseOrderId,
  );
}
