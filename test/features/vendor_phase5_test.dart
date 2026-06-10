import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/vendor/data/vendor_repository_impl.dart';
import 'package:procurement_management/features/vendor/domain/vendor_entity.dart';
import 'package:procurement_management/features/vendor/domain/vendor_repository.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_controller.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_details_screen.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_form_screen.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_list_screen.dart';
import 'package:procurement_management/features/vendor/presentation/vendor_providers.dart';

const _vendorSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Tanvir Hasan',
  email: 'tanvir@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['PROCUREMENT'],
  permissions: ['vendors.view'],
);

void main() {
  test('Phase 5 enables Vendors without changing bottom navigation', () {
    final items = visiblePhase2MenuItems(_vendorSession);
    final withoutPermission = visiblePhase2MenuItems(
      _vendorSession.copyWith(permissions: const [], roles: const []),
    );

    expect(appBottomTabs.map((tab) => tab.label), [
      'Home',
      'Notifications',
      'Profile',
    ]);
    expect(items.map((item) => item.title), contains('Vendors'));
    expect(
      items.firstWhere((item) => item.title == 'Vendors').route,
      '/vendors',
    );
    expect(
      items.firstWhere((item) => item.title == 'Vendors').isImplemented,
      isTrue,
    );
    expect(
      withoutPermission.map((item) => item.title),
      isNot(contains('Vendors')),
    );
  });

  test('repository sends vendor queries and camelCase CRUD payloads', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _FakeVendorApi();
    final repository = VendorRepositoryImpl(
      dao: ProcurementDao(database),
      api: api,
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test/api/v1',
        useMockApi: false,
      ),
    );
    addTearDown(database.close);

    await repository.getVendors(
      const VendorFilters(
        search: ' office ',
        status: VendorStatus.inactive,
        page: 2,
        limit: 20,
      ),
    );
    expect(api.lastListQuery, {
      'search': 'office',
      'status': VendorStatus.inactive,
      'page': 2,
      'limit': 20,
    });

    await repository.getVendors(const VendorFilters(search: '', status: null));
    expect(api.lastListQuery?['search'], isNull);
    expect(api.lastListQuery?['status'], isNull);

    final payload = const VendorPayload(
      name: 'Acme Supplies',
      contactPerson: 'Nadia Islam',
      phone: '+8801700000000',
      email: 'sales@acme.test',
      address: 'Dhaka',
      status: VendorStatus.active,
    );

    await repository.create(payload);
    expect(api.lastCreatePayload, {
      'name': 'Acme Supplies',
      'contactPerson': 'Nadia Islam',
      'phone': '+8801700000000',
      'email': 'sales@acme.test',
      'address': 'Dhaka',
      'status': VendorStatus.active,
    });

    await repository.update('vendor-1', payload);
    expect(api.updatedId, 'vendor-1');
    expect(api.lastUpdatePayload?['contactPerson'], 'Nadia Islam');

    await repository.getById('vendor-1');
    expect(api.detailId, 'vendor-1');

    await repository.delete('vendor-1');
    expect(api.deletedId, 'vendor-1');
  });

  test(
    'mock repository persists contactPerson and filters local vendors',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dao = ProcurementDao(database);
      final repository = VendorRepositoryImpl(
        dao: dao,
        api: _FakeVendorApi(),
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
        roleName: 'procurement',
      );

      final contactMatch = await repository.getVendors(
        const VendorFilters(search: 'avery'),
      );
      expect(contactMatch.items.single.name, 'OfficeHub Supplies');

      final created = await repository.create(
        const VendorPayload(
          name: 'Metro Traders',
          contactPerson: 'Rafi Ahmed',
          phone: '+8801800000000',
          email: null,
          address: 'Chattogram',
          status: VendorStatus.active,
        ),
      );
      expect(created.contactPerson, 'Rafi Ahmed');

      final inactive = await repository.update(
        created.localId,
        const VendorPayload(
          name: 'Metro Traders',
          contactPerson: 'Rafi Ahmed',
          phone: '+8801800000000',
          email: null,
          address: 'Chattogram',
          status: VendorStatus.inactive,
        ),
      );
      expect(inactive.isActive, isFalse);

      await repository.delete(created.localId);
      expect(await repository.getById(created.localId), isNull);
    },
  );

  test(
    'controller loads, filters, creates, updates, and deletes vendors',
    () async {
      final repository = _FakeVendorRepository();
      final controller = VendorController(repository);
      const filters = VendorFilters(
        search: 'acme',
        status: VendorStatus.active,
        page: 1,
        limit: 10,
      );

      await controller.loadList(filters);
      expect(repository.lastFilters, filters);
      expect(controller.state.vendors, repository.vendors);

      final created = await controller.create(_payload(name: 'New Vendor'));
      expect(created?.name, 'New Vendor');

      final updated = await controller.update(
        'vendor-1',
        _payload(name: 'Updated Vendor'),
      );
      expect(updated?.name, 'Updated Vendor');

      final deleted = await controller.delete('vendor-1');
      expect(deleted, isTrue);
      expect(repository.deletedIds, ['vendor-1']);
    },
  );

  testWidgets('VendorListScreen renders vendors and applies filters', (
    tester,
  ) async {
    final repository = _FakeVendorRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: VendorListScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Supplies'), findsOneWidget);
    expect(find.textContaining('Nadia Islam'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('vendorSearchField')), 'acme');
    await tester.tap(find.byKey(const Key('vendorFilterApplyButton')));
    await tester.pumpAndSettle();

    expect(repository.lastFilters?.search, 'acme');
  });

  testWidgets('VendorFormScreen validates and creates vendor', (tester) async {
    final repository = _FakeVendorRepository();
    final router = GoRouter(
      initialLocation: '/vendors/new',
      routes: [
        GoRoute(
          path: '/vendors/new',
          builder: (context, state) =>
              const VendorFormScreen(showBottomNavigation: false),
        ),
        GoRoute(
          path: '/vendors/:id',
          builder: (context, state) =>
              Text('Vendor details ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('saveVendorButton')));
    await tester.tap(find.byKey(const Key('saveVendorButton')));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('vendorNameField')),
      'New Vendor',
    );
    await tester.enterText(
      find.byKey(const Key('vendorPhoneField')),
      '+8801711111111',
    );
    await tester.enterText(
      find.byKey(const Key('vendorEmailField')),
      'new@example.com',
    );
    await tester.ensureVisible(find.byKey(const Key('saveVendorButton')));
    await tester.tap(find.byKey(const Key('saveVendorButton')));
    await tester.pumpAndSettle();

    expect(repository.createdPayloads.single.name, 'New Vendor');
    expect(find.text('Vendor details vendor-created'), findsOneWidget);
  });

  testWidgets('VendorFormScreen loads edit data and updates vendor', (
    tester,
  ) async {
    final repository = _FakeVendorRepository();
    final router = GoRouter(
      initialLocation: '/vendors/vendor-1/edit',
      routes: [
        GoRoute(
          path: '/vendors/vendor-1/edit',
          builder: (context, state) => const VendorFormScreen(
            vendorId: 'vendor-1',
            showBottomNavigation: false,
          ),
        ),
        GoRoute(
          path: '/vendors/:id',
          builder: (context, state) =>
              Text('Vendor details ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Supplies'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('vendorNameField')),
      'Acme Updated',
    );
    await tester.ensureVisible(find.byKey(const Key('saveVendorButton')));
    await tester.tap(find.byKey(const Key('saveVendorButton')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, ['vendor-1']);
    expect(repository.updatedPayloads.single.name, 'Acme Updated');
  });

  testWidgets('VendorDetailsScreen renders fields and deletes after confirm', (
    tester,
  ) async {
    final repository = _FakeVendorRepository();
    final router = GoRouter(
      initialLocation: '/vendors/vendor-1',
      routes: [
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const Text('Vendor list'),
        ),
        GoRoute(
          path: '/vendors/:id',
          builder: (context, state) => VendorDetailsScreen(
            vendorId: state.pathParameters['id'] ?? '',
            showBottomNavigation: false,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [vendorRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Supplies'), findsOneWidget);
    expect(find.text('Nadia Islam'), findsOneWidget);
    expect(find.text('+8801711111111'), findsOneWidget);

    await tester.tap(find.byKey(const Key('deleteVendorButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteVendorButton')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, ['vendor-1']);
    expect(find.text('Vendor list'), findsOneWidget);
  });
}

VendorPayload _payload({String name = 'Acme Supplies'}) {
  return VendorPayload(
    name: name,
    contactPerson: 'Nadia Islam',
    phone: '+8801711111111',
    email: 'sales@acme.test',
    address: 'Dhaka',
    status: VendorStatus.active,
  );
}

VendorEntity _vendor({
  String id = 'vendor-1',
  String name = 'Acme Supplies',
  String status = VendorStatus.active,
}) {
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
    email: 'sales@acme.test',
    phone: '+8801711111111',
    address: 'Dhaka',
    status: status,
  );
}

VendorDto _vendorDto({String id = 'vendor-1', String name = 'Acme Supplies'}) {
  final now = DateTime(2026, 1, 1);
  return VendorDto(
    id: id,
    companyId: 'company-demo',
    name: name,
    contactPerson: 'Nadia Islam',
    phone: '+8801711111111',
    email: 'sales@acme.test',
    address: 'Dhaka',
    status: VendorStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeVendorApi implements ProcurementApi {
  Map<String, Object?>? lastListQuery;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;
  String? detailId;
  String? updatedId;
  String? deletedId;

  @override
  Future<VendorPageDto> getVendors(
    String? search,
    String? status,
    int page,
    int limit,
  ) async {
    lastListQuery = {
      'search': search,
      'status': status,
      'page': page,
      'limit': limit,
    };
    return VendorPageDto(
      items: [_vendorDto()],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<VendorDto> createVendor(VendorPayloadDto request) async {
    lastCreatePayload = request.toJson();
    return _vendorDto(id: 'vendor-created', name: request.name);
  }

  @override
  Future<VendorDto> getVendor(String id) async {
    detailId = id;
    return _vendorDto(id: id);
  }

  @override
  Future<VendorDto> updateVendor(String id, VendorPayloadDto request) async {
    updatedId = id;
    lastUpdatePayload = request.toJson();
    return _vendorDto(id: id, name: request.name);
  }

  @override
  Future<void> deleteVendor(String id) async {
    deletedId = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVendorRepository implements VendorRepository {
  final vendors = [_vendor()];
  final createdPayloads = <VendorPayload>[];
  final updatedPayloads = <VendorPayload>[];
  final updatedIds = <String>[];
  final deletedIds = <String>[];
  VendorFilters? lastFilters;

  @override
  Future<VendorEntity> create(VendorPayload payload) async {
    createdPayloads.add(payload);
    final vendor = _vendor(id: 'vendor-created', name: payload.name);
    vendors.add(vendor);
    return vendor;
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
    vendors.removeWhere((vendor) => vendor.localId == id);
  }

  @override
  Future<List<VendorEntity>> getByCompany(String companyId) async => vendors;

  @override
  Future<VendorEntity?> getById(String id) async {
    return vendors.where((vendor) => vendor.localId == id).firstOrNull;
  }

  @override
  Future<VendorPage> getVendors(VendorFilters filters) async {
    lastFilters = filters;
    return VendorPage(
      items: vendors,
      page: filters.page,
      limit: filters.limit,
      total: vendors.length,
    );
  }

  @override
  Future<VendorEntity> update(String id, VendorPayload payload) async {
    updatedIds.add(id);
    updatedPayloads.add(payload);
    final index = vendors.indexWhere((vendor) => vendor.localId == id);
    final vendor = _vendor(id: id, name: payload.name, status: payload.status);
    if (index >= 0) {
      vendors[index] = vendor;
    } else {
      vendors.add(vendor);
    }
    return vendor;
  }

  @override
  Stream<List<VendorEntity>> watchByCompany(String companyId) {
    return Stream.value(vendors);
  }
}
