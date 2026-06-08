import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_service.dart';
import 'package:procurement_management/core/sync/sync_status.dart';

class _FakeProcurementApi implements ProcurementApi {
  @override
  Future<PurchaseRequestSyncResponseDto> createPurchaseRequest(
    PurchaseRequestSyncRequestDto request,
  ) async {
    return PurchaseRequestSyncResponseDto(
      serverId: 'server-${request.localId}',
      requestNumber: 'PR-SERVER',
      syncedAt: DateTime(2026, 1, 2),
    );
  }

  @override
  Future<List<VendorDto>> getVendors(String companyId) async => [];

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> submitApprovalAction(
    String serverId,
    ApprovalActionRequestDto request,
  ) async {}
}

void main() {
  late AppDatabase database;
  late ProcurementDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = ProcurementDao(database);
  });

  tearDown(() => database.close());

  test('sync service pushes pending creates and marks them synced', () async {
    await _insertPendingRequest(dao);
    final service = SyncService(
      dao: dao,
      api: _FakeProcurementApi(),
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test',
        useMockApi: false,
      ),
    );

    final summary = await service.syncPendingPurchaseRequests('company-demo');
    final request = await dao.getPurchaseRequest('request-local');
    final logs = await dao.watchSyncLogs('company-demo').first;

    expect(summary.attempted, 1);
    expect(summary.succeeded, 1);
    expect(summary.failed, 0);
    expect(request?.syncStatus, SyncStatus.synced.storageValue);
    expect(request?.serverId, 'server-request-local');
    expect(logs.single.status, SyncStatus.synced.storageValue);
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
