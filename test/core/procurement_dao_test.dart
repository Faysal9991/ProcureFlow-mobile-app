import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';

void main() {
  late AppDatabase database;
  late ProcurementDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = ProcurementDao(database);
  });

  tearDown(() => database.close());

  test('seeds tenant data and filters vendors by company', () async {
    await dao.seedDemoData(
      companyId: 'company-demo',
      userId: 'user-employee',
      userName: 'Employee',
      email: 'employee@demo.com',
      roleName: 'employee',
    );

    final vendors = await dao.getVendors('company-demo');

    expect(vendors, hasLength(2));
    expect(
      vendors.every((vendor) => vendor.companyId == 'company-demo'),
      isTrue,
    );
  });

  test('stores offline purchase requests as pending sync', () async {
    await _insertPendingRequest(dao);

    final pendingCount = await dao.countPendingSync('company-demo');
    final pending = await dao.getPendingPurchaseRequestCreates('company-demo');

    expect(pendingCount, 1);
    expect(pending.single.syncStatus, SyncStatus.pendingCreate.storageValue);
  });
}

Future<void> _insertPendingRequest(ProcurementDao dao) {
  final now = DateTime(2026);
  return dao.insertPurchaseRequestWithItems(
    request: PurchaseRequestsCompanion.insert(
      localId: 'request-local',
      companyId: 'company-demo',
      requestNumber: 'PR-TEST',
      title: 'Printer',
      requesterId: 'user-employee',
      status: const Value('submitted'),
      totalAmount: const Value(250),
      syncStatus: Value(SyncStatus.pendingCreate.storageValue),
      createdAt: now,
      updatedAt: now,
    ),
    items: [
      PurchaseRequestItemsCompanion.insert(
        localId: 'item-local',
        companyId: 'company-demo',
        requestLocalId: 'request-local',
        name: 'Printer',
        quantity: 1,
        unitPrice: 250,
        lineTotal: 250,
        syncStatus: Value(SyncStatus.pendingCreate.storageValue),
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}
