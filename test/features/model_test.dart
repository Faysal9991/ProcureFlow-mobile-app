import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/features/purchase_request/domain/purchase_request_entity.dart';

void main() {
  test('purchase request entities use value equality', () {
    final createdAt = DateTime(2026);
    final first = PurchaseRequestEntity(
      localId: 'local-1',
      serverId: null,
      companyId: 'company-1',
      syncStatus: SyncStatus.pendingCreate,
      createdAt: createdAt,
      updatedAt: createdAt,
      lastSyncedAt: null,
      isDeleted: false,
      requestNumber: 'PR-1',
      title: 'Laptop',
      description: null,
      requesterId: 'user-1',
      departmentId: null,
      priority: 'medium',
      neededDate: null,
      status: 'submitted',
      totalAmount: 1200,
      items: const [],
    );
    final second = PurchaseRequestEntity(
      localId: 'local-1',
      serverId: null,
      companyId: 'company-1',
      syncStatus: SyncStatus.pendingCreate,
      createdAt: createdAt,
      updatedAt: createdAt,
      lastSyncedAt: null,
      isDeleted: false,
      requestNumber: 'PR-1',
      title: 'Laptop',
      description: null,
      requesterId: 'user-1',
      departmentId: null,
      priority: 'medium',
      neededDate: null,
      status: 'submitted',
      totalAmount: 1200,
      items: const [],
    );

    expect(first, second);
  });
}
