import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart'
    hide Quotation, QuotationItem, Rfq, RfqItem, RfqVendor;
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/rfq/data/rfq_repository_impl.dart';
import 'package:procurement_management/features/rfq/domain/rfq_entity.dart';
import 'package:procurement_management/features/rfq/domain/rfq_repository.dart';
import 'package:procurement_management/features/rfq/presentation/quotation_entry_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_controller.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_details_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_list_screen.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_providers.dart';
import 'package:procurement_management/features/rfq/presentation/rfq_vendor_assignment_screen.dart';
import 'package:procurement_management/features/vendor/domain/vendor_entity.dart';
import 'package:procurement_management/features/vendor/domain/vendor_repository.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_providers.dart';

const _rfqSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Procurement User',
  email: 'procurement@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['PROCUREMENT'],
  permissions: [],
);

void main() {
  test('Phase 6 enables RFQ without changing bottom navigation', () {
    for (final session in [
      _rfqSession.copyWith(permissions: ['rfq.view'], roles: const []),
      _rfqSession.copyWith(permissions: ['rfq.manage'], roles: const []),
      _rfqSession.copyWith(permissions: const [], roles: ['PROCUREMENT']),
      _rfqSession.copyWith(permissions: const [], roles: ['COMPANY_ADMIN']),
    ]) {
      final rfq = visiblePhase2MenuItems(
        session,
      ).where((item) => item.title == 'RFQ');

      expect(rfq.single.route, '/rfqs');
      expect(rfq.single.isImplemented, isTrue);
    }

    final withoutPermission = _rfqSession.copyWith(
      permissions: const [],
      roles: const [],
    );
    expect(
      visiblePhase2MenuItems(withoutPermission).map((item) => item.title),
      isNot(contains('RFQ')),
    );
    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
  });

  test('RFQ repository sends query values and camelCase payloads', () async {
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

    await repository.getRfqs(
      const RfqFilters(
        search: ' laptop ',
        status: RfqStatus.open,
        purchaseRequestId: ' pr-1 ',
        page: 2,
        limit: 20,
      ),
    );
    expect(api.lastListQuery, {
      'search': 'laptop',
      'status': RfqStatus.open,
      'purchaseRequestId': 'pr-1',
      'page': 2,
      'limit': 20,
    });

    await repository.getRfqs(const RfqFilters(search: '', status: null));
    expect(api.lastListQuery?['search'], isNull);
    expect(api.lastListQuery?['status'], isNull);

    await repository.getEligiblePurchaseRequests(page: 3, limit: 30);
    expect(api.lastEligibleQuery, {'page': 3, 'limit': 30});

    await repository.createRfq(
      CreateRfqPayload(
        purchaseRequestId: ' pr-1 ',
        dueDate: DateTime(2026, 2, 1),
        notes: ' Need vendor prices ',
      ),
    );
    expect(api.lastCreatePayload, {
      'purchaseRequestId': 'pr-1',
      'dueDate': '2026-02-01',
      'notes': 'Need vendor prices',
    });

    await repository.assignVendors(
      'rfq-1',
      const AssignRfqVendorsPayload(vendorIds: ['vendor-1', 'vendor-2']),
    );
    expect(api.assignedRfqId, 'rfq-1');
    expect(api.lastAssignPayload, {
      'vendorIds': ['vendor-1', 'vendor-2'],
    });

    await repository.openRfq('rfq-1');
    expect(api.openedRfqId, 'rfq-1');

    await repository.createQuotation(
      'rfq-1',
      CreateQuotationPayload(
        vendorId: 'vendor-1',
        quotationNumber: ' Q-001 ',
        quotationDate: DateTime(2026, 2, 2),
        validUntil: DateTime(2026, 2, 15),
        notes: ' Best price ',
        items: const [
          CreateQuotationItemInput(
            rfqItemId: 'rfq-item-1',
            itemName: 'Laptop',
            quantity: 2,
            unitPrice: 1100,
          ),
        ],
      ),
    );
    expect(api.quotationRfqId, 'rfq-1');
    expect(api.lastQuotationPayload, {
      'vendorId': 'vendor-1',
      'quotationNumber': 'Q-001',
      'quotationDate': '2026-02-02',
      'validUntil': '2026-02-15',
      'notes': 'Best price',
      'items': [
        {'rfqItemId': 'rfq-item-1', 'unitPrice': 1100.0},
      ],
    });
  });

  test(
    'mock RFQ flow creates, assigns vendors, opens, and stores quotation',
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
      expect(eligible.single.id, 'request-approved-laptops');

      final created = await repository.createRfq(
        CreateRfqPayload(
          purchaseRequestId: eligible.single.id,
          dueDate: DateTime(2026, 2, 1),
          notes: 'Demo RFQ',
        ),
      );
      expect(created.status, RfqStatus.draft);
      expect(created.items.single.itemName, 'Laptop');

      final assigned = await repository.assignVendors(
        created.localId,
        const AssignRfqVendorsPayload(vendorIds: ['vendor-officehub']),
      );
      expect(assigned.vendorCount, 1);

      final opened = await repository.openRfq(created.localId);
      expect(opened.normalizedStatus, RfqStatus.open);

      final quotation = await repository.createQuotation(
        created.localId,
        CreateQuotationPayload(
          vendorId: 'vendor-officehub',
          quotationNumber: 'Q-DEMO-001',
          quotationDate: DateTime(2026, 2, 2),
          validUntil: null,
          notes: null,
          items: [
            CreateQuotationItemInput(
              rfqItemId: opened.items.single.id,
              itemName: opened.items.single.itemName,
              quantity: opened.items.single.quantity,
              unitPrice: 1150,
            ),
          ],
        ),
      );
      expect(quotation.vendorName, 'OfficeHub Supplies');

      final withQuotation = await repository.getById(created.localId);
      expect(withQuotation?.quotationCount, 1);
      expect(withQuotation?.normalizedStatus, RfqStatus.quotationReceived);
    },
  );

  test('controller blocks opening RFQ without assigned vendors', () async {
    final repository = _FakeRfqRepository(rfq: _rfq(vendorCount: 0));
    final controller = RfqController(repository);

    final opened = await controller.openRfq('rfq-1');

    expect(opened, isNull);
    expect(repository.openCalled, isTrue);
    expect(
      controller.state.errorMessage,
      'Please assign at least one vendor before opening this RFQ.',
    );
  });

  test('repository rejects quotation for unassigned vendor', () async {
    final repository = _FakeRfqRepository(
      rfq: _rfq(vendors: [_rfqVendor(vendorId: 'vendor-1')], vendorCount: 1),
    );

    expect(
      () => repository.createQuotation(
        'rfq-1',
        CreateQuotationPayload(
          vendorId: 'vendor-2',
          quotationNumber: 'Q-001',
          quotationDate: DateTime(2026, 2, 2),
          validUntil: null,
          notes: null,
          items: const [
            CreateQuotationItemInput(
              rfqItemId: 'rfq-item-1',
              itemName: 'Laptop',
              quantity: 2,
              unitPrice: 1100,
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('RfqListScreen renders RFQs and applies filters', (tester) async {
    final repository = _FakeRfqRepository(rfq: _rfq());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rfqRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: RfqListScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RFQ-001'), findsOneWidget);
    expect(find.textContaining('Laptop Purchase'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('rfqSearchField')), 'laptop');
    await tester.enterText(
      find.byKey(const Key('rfqPurchaseRequestFilterField')),
      'pr-1',
    );
    await tester.tap(find.byKey(const Key('rfqFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(repository.lastFilters?.search, 'laptop');
    expect(repository.lastFilters?.purchaseRequestId, 'pr-1');
  });

  testWidgets('RfqDetailsScreen blocks opening RFQ before vendor assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeRfqRepository(rfq: _rfq(vendorCount: 0));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rfqRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: RfqDetailsScreen(rfqId: 'rfq-1', showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final openButton = find.text('Open RFQ', skipOffstage: false);
    await tester.ensureVisible(openButton);
    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Please assign at least one vendor before opening this RFQ.'),
      findsOneWidget,
    );
    expect(repository.openCalled, isFalse);
  });

  testWidgets('QuotationEntryScreen only exposes assigned vendors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeRfqRepository(
      rfq: _rfq(
        status: RfqStatus.open,
        vendorCount: 1,
        vendors: [_rfqVendor(vendorId: 'vendor-1', vendorName: 'Assigned Co')],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rfqRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: QuotationEntryScreen(
            rfqId: 'rfq-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned Co'), findsOneWidget);
    expect(find.text('Unassigned Co'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('quotationNumberField')),
      'Q-1',
    );
    final saveButton = find.text('Save Quotation', skipOffstage: false);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter unit price'), findsOneWidget);
    expect(repository.createdQuotations, isEmpty);
  });

  testWidgets('RfqVendorAssignmentScreen requires at least one vendor', (
    tester,
  ) async {
    final rfqRepository = _FakeRfqRepository(rfq: _rfq(vendors: const []));
    final vendorRepository = _FakeVendorRepository([
      _vendor(id: 'vendor-1', name: 'Assigned Co'),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rfqRepositoryProvider.overrideWithValue(rfqRepository),
          vendorRepositoryProvider.overrideWithValue(vendorRepository),
        ],
        child: const MaterialApp(
          home: RfqVendorAssignmentScreen(
            rfqId: 'rfq-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned Co'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveRfqVendorsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Select at least one vendor.'), findsOneWidget);
    expect(rfqRepository.assignedPayloads, isEmpty);
  });
}

Rfq _rfq({
  String id = 'rfq-1',
  String status = RfqStatus.draft,
  int vendorCount = 1,
  String? selectedQuotationId,
  List<RfqVendor>? vendors,
  List<RfqItem>? items,
  List<Quotation>? quotations,
}) {
  final now = DateTime(2026, 1, 10, 10);
  final resolvedVendors =
      vendors ?? [_rfqVendor(vendorId: 'vendor-1', vendorName: 'Assigned Co')];
  final resolvedQuotations = quotations ?? const <Quotation>[];
  return Rfq(
    localId: id,
    serverId: id,
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
    notes: 'Collect quotations',
    vendorCount: vendorCount,
    quotationCount: resolvedQuotations.length,
    selectedQuotationId: selectedQuotationId,
    items: items ?? const [_RfqTestData.item],
    vendors: resolvedVendors,
    quotations: resolvedQuotations,
  );
}

RfqVendor _rfqVendor({
  String id = 'rfq-vendor-1',
  String vendorId = 'vendor-1',
  String vendorName = 'Assigned Co',
}) {
  return RfqVendor(
    id: id,
    vendorId: vendorId,
    vendorName: vendorName,
    contactPerson: 'Nadia Islam',
    email: 'sales@example.test',
    phone: '+8801711111111',
  );
}

Quotation _quotation() {
  final now = DateTime(2026, 2, 2, 10);
  return Quotation(
    localId: 'quotation-1',
    serverId: 'quotation-1',
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    rfqId: 'rfq-1',
    vendorId: 'vendor-1',
    vendorName: 'Assigned Co',
    quotationNumber: 'Q-001',
    quotationDate: DateTime(2026, 2, 2),
    validUntil: null,
    status: 'SUBMITTED',
    totalAmount: 2200,
    notes: null,
    items: const [
      QuotationItem(
        id: 'quotation-item-1',
        rfqItemId: 'rfq-item-1',
        itemName: 'Laptop',
        quantity: 2,
        unitPrice: 1100,
        totalPrice: 2200,
      ),
    ],
  );
}

VendorEntity _vendor({String id = 'vendor-1', String name = 'Assigned Co'}) {
  final now = DateTime(2026, 1, 1, 10);
  return VendorEntity(
    localId: id,
    serverId: id,
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    name: name,
    contactPerson: 'Nadia Islam',
    email: 'sales@example.test',
    phone: '+8801711111111',
    address: 'Dhaka',
    status: VendorStatus.active,
  );
}

RfqDto _rfqDto({
  String id = 'rfq-1',
  String status = RfqStatus.draft,
  int vendorCount = 1,
  String? selectedQuotationId,
  List<RfqVendorDto>? vendors,
  List<QuotationDto>? quotations,
}) {
  final now = DateTime(2026, 1, 10, 10);
  return RfqDto(
    id: id,
    companyId: 'company-demo',
    rfqNumber: 'RFQ-001',
    purchaseRequestId: 'pr-1',
    purchaseRequestNumber: 'PR-001',
    purchaseRequestTitle: 'Laptop Purchase',
    dueDate: DateTime(2026, 2, 1),
    status: status,
    notes: 'Collect quotations',
    vendorCount: vendorCount,
    quotationCount: quotations?.length ?? 0,
    selectedQuotationId: selectedQuotationId,
    items: const [
      RfqItemDto(
        id: 'rfq-item-1',
        itemName: 'Laptop',
        description: '16GB RAM',
        quantity: 2,
        unit: 'pcs',
        estimatedUnitPrice: 1200,
      ),
    ],
    vendors: vendors ?? [_rfqVendorDto()],
    quotations: quotations ?? const [],
    createdAt: now,
    updatedAt: now,
  );
}

RfqVendorDto _rfqVendorDto({
  String id = 'rfq-vendor-1',
  String vendorId = 'vendor-1',
  String vendorName = 'Assigned Co',
}) {
  return RfqVendorDto(
    id: id,
    vendorId: vendorId,
    vendorName: vendorName,
    contactPerson: 'Nadia Islam',
    email: 'sales@example.test',
    phone: '+8801711111111',
  );
}

QuotationDto _quotationDto() {
  final now = DateTime(2026, 2, 2, 10);
  return QuotationDto(
    id: 'quotation-1',
    rfqId: 'rfq-1',
    vendorId: 'vendor-1',
    vendorName: 'Assigned Co',
    quotationNumber: 'Q-001',
    quotationDate: DateTime(2026, 2, 2),
    validUntil: DateTime(2026, 2, 15),
    status: 'SUBMITTED',
    totalAmount: 2200,
    notes: 'Best price',
    items: const [
      QuotationItemDto(
        id: 'quotation-item-1',
        rfqItemId: 'rfq-item-1',
        itemName: 'Laptop',
        quantity: 2,
        unitPrice: 1100,
        totalPrice: 2200,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

abstract final class _RfqTestData {
  static const item = RfqItem(
    id: 'rfq-item-1',
    itemName: 'Laptop',
    description: '16GB RAM',
    quantity: 2,
    unit: 'pcs',
    estimatedUnitPrice: 1200,
  );
}

class _FakeRfqApi implements ProcurementApi {
  Map<String, Object?>? lastListQuery;
  Map<String, Object?>? lastEligibleQuery;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastAssignPayload;
  Map<String, dynamic>? lastQuotationPayload;
  Map<String, dynamic>? lastSelectedPayload;
  String? assignedRfqId;
  String? openedRfqId;
  String? quotationRfqId;
  String? selectedRfqId;

  @override
  Future<RfqPageDto> getRfqs(
    String? search,
    String? status,
    String? purchaseRequestId,
    int page,
    int limit,
  ) async {
    lastListQuery = {
      'search': search,
      'status': status,
      'purchaseRequestId': purchaseRequestId,
      'page': page,
      'limit': limit,
    };
    return RfqPageDto(items: [_rfqDto()], page: page, limit: limit, total: 1);
  }

  @override
  Future<EligiblePurchaseRequestPageDto> getEligiblePurchaseRequestsForRfq(
    int page,
    int limit,
  ) async {
    lastEligibleQuery = {'page': page, 'limit': limit};
    return EligiblePurchaseRequestPageDto(
      items: const [
        EligiblePurchaseRequestDto(
          id: 'pr-1',
          requestNumber: 'PR-001',
          title: 'Laptop Purchase',
          departmentName: 'IT',
          estimatedTotal: 2400,
          status: 'APPROVED',
        ),
      ],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<RfqDto> createRfq(CreateRfqPayloadDto request) async {
    lastCreatePayload = request.toJson();
    return _rfqDto(id: 'rfq-created', vendorCount: 0, vendors: const []);
  }

  @override
  Future<RfqDto> getRfq(String id) async {
    return _rfqDto(id: id);
  }

  @override
  Future<RfqDto> assignRfqVendors(
    String id,
    AssignRfqVendorsPayloadDto request,
  ) async {
    assignedRfqId = id;
    lastAssignPayload = request.toJson();
    return _rfqDto(
      id: id,
      vendorCount: request.vendorIds.length,
      vendors: [
        for (final vendorId in request.vendorIds)
          _rfqVendorDto(vendorId: vendorId, vendorName: vendorId),
      ],
    );
  }

  @override
  Future<RfqDto> openRfq(String id) async {
    openedRfqId = id;
    return _rfqDto(id: id, status: RfqStatus.open);
  }

  @override
  Future<QuotationDto> createRfqQuotation(
    String id,
    CreateQuotationPayloadDto request,
  ) async {
    quotationRfqId = id;
    lastQuotationPayload = request.toJson();
    return _quotationDto();
  }

  @override
  Future<RfqComparisonDto> getRfqComparison(String id) async {
    return RfqComparisonDto(
      rfqId: id,
      rfqNumber: 'RFQ-001',
      status: RfqStatus.quotationReceived,
      purchaseRequestId: 'pr-1',
      purchaseRequestNumber: 'PR-001',
      purchaseRequestTitle: 'Laptop Purchase',
      quotations: const [
        RfqComparisonQuotationDto(
          quotationId: 'quotation-1',
          vendorId: 'vendor-1',
          vendorName: 'Assigned Co',
          quotationNumber: 'Q-001',
          quotationDate: null,
          validUntil: null,
          totalAmount: 2200,
          rank: 1,
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
      ],
      lowestQuotationId: 'quotation-1',
      selectedQuotationId: null,
    );
  }

  @override
  Future<RfqDto> selectRfqQuotation(
    String id,
    SelectedQuotationPayloadDto request,
  ) async {
    selectedRfqId = id;
    lastSelectedPayload = request.toJson();
    return _rfqDto(
      id: id,
      status: RfqStatus.completed,
      selectedQuotationId: request.quotationId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRfqRepository implements RfqRepository {
  _FakeRfqRepository({required this.rfq});

  Rfq rfq;
  RfqFilters? lastFilters;
  bool openCalled = false;
  final assignedPayloads = <AssignRfqVendorsPayload>[];
  final createdQuotations = <CreateQuotationPayload>[];
  final selectedPayloads = <SelectedQuotationPayload>[];

  @override
  Future<RfqPage> getRfqs(RfqFilters filters) async {
    lastFilters = filters;
    return RfqPage(
      items: [rfq],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<Rfq> createRfq(CreateRfqPayload payload) async => rfq;

  @override
  Future<Rfq?> getById(String id) async => rfq;

  @override
  Future<Rfq> assignVendors(String id, AssignRfqVendorsPayload payload) async {
    assignedPayloads.add(payload);
    rfq = _rfq(vendorCount: payload.vendorIds.length);
    return rfq;
  }

  @override
  Future<Rfq> openRfq(String id) async {
    openCalled = true;
    if (rfq.vendorCount <= 0) {
      throw ArgumentError(
        'Please assign at least one vendor before opening this RFQ.',
      );
    }
    rfq = _rfq(status: RfqStatus.open, vendorCount: rfq.vendorCount);
    return rfq;
  }

  @override
  Future<RfqComparison> getComparison(String id) async {
    final quotations = [
      for (var index = 0; index < rfq.quotations.length; index++)
        RfqComparisonQuotation(
          quotationId: rfq.quotations[index].localId,
          vendorId: rfq.quotations[index].vendorId,
          vendorName: rfq.quotations[index].vendorName,
          quotationNumber: rfq.quotations[index].quotationNumber,
          quotationDate: rfq.quotations[index].quotationDate,
          validUntil: rfq.quotations[index].validUntil,
          totalAmount: rfq.quotations[index].totalAmount,
          rank: index + 1,
          items: const [
            RfqComparisonItem(
              rfqItemId: 'rfq-item-1',
              itemName: 'Laptop',
              quantity: 2,
              unit: 'pcs',
              unitPrice: 1100,
              lineTotal: 2200,
            ),
          ],
        ),
    ];
    return RfqComparison(
      rfqId: rfq.localId,
      rfqNumber: rfq.rfqNumber,
      status: rfq.normalizedStatus,
      purchaseRequestId: rfq.purchaseRequestId,
      purchaseRequestNumber: rfq.purchaseRequestNumber,
      purchaseRequestTitle: rfq.purchaseRequestTitle,
      quotations: quotations,
      lowestQuotationId: quotations.isEmpty
          ? null
          : quotations.first.quotationId,
      selectedQuotationId: rfq.selectedQuotationId,
    );
  }

  @override
  Future<Rfq> selectQuotation(
    String id,
    SelectedQuotationPayload payload,
  ) async {
    selectedPayloads.add(payload);
    rfq = _rfq(
      status: RfqStatus.completed,
      vendorCount: rfq.vendorCount,
      vendors: rfq.vendors,
      quotations: rfq.quotations,
      selectedQuotationId: payload.quotationId,
    );
    return rfq;
  }

  @override
  Future<Quotation> createQuotation(
    String id,
    CreateQuotationPayload payload,
  ) async {
    final assigned = rfq.vendors.any(
      (vendor) => vendor.vendorId == payload.vendorId,
    );
    if (!assigned) {
      throw ArgumentError('Select an assigned vendor.');
    }
    createdQuotations.add(payload);
    final quotation = _quotation();
    rfq = _rfq(
      status: RfqStatus.quotationReceived,
      vendorCount: rfq.vendorCount,
      vendors: rfq.vendors,
      quotations: [quotation],
    );
    return quotation;
  }

  @override
  Future<List<EligiblePurchaseRequest>> getEligiblePurchaseRequests({
    int page = 1,
    int limit = 20,
  }) async {
    return const [
      EligiblePurchaseRequest(
        id: 'pr-1',
        requestNumber: 'PR-001',
        title: 'Laptop Purchase',
        departmentName: 'IT',
        estimatedTotal: 2400,
        status: 'APPROVED',
      ),
    ];
  }
}

class _FakeVendorRepository implements VendorRepository {
  _FakeVendorRepository(this.vendors);

  final List<VendorEntity> vendors;

  @override
  Future<VendorPage> getVendors(VendorFilters filters) async {
    return VendorPage(
      items: vendors,
      page: filters.page,
      limit: filters.limit,
      total: vendors.length,
    );
  }

  @override
  Future<VendorEntity?> getById(String id) async {
    return vendors.where((vendor) => vendor.localId == id).firstOrNull;
  }

  @override
  Future<List<VendorEntity>> getByCompany(String companyId) async => vendors;

  @override
  Stream<List<VendorEntity>> watchByCompany(String companyId) {
    return Stream.value(vendors);
  }

  @override
  Future<VendorEntity> create(VendorPayload payload) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<VendorEntity> update(String id, VendorPayload payload) async {
    throw UnimplementedError();
  }
}
