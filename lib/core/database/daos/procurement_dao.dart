import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_status.dart';
import '../app_database.dart';

class ProcurementDao {
  ProcurementDao(this.db);

  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  Future<void> seedDemoData({
    required String companyId,
    required String userId,
    required String userName,
    required String email,
    required String roleName,
  }) async {
    final now = DateTime.now();
    await db.batch((batch) {
      batch.insert(
        db.companies,
        CompaniesCompanion.insert(
          localId: companyId,
          serverId: Value('srv-$companyId'),
          name: 'Demo Company',
          domain: const Value('demo.local'),
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrReplace,
      );
      for (final role in ['employee', 'manager', 'procurement', 'finance']) {
        batch.insert(
          db.roles,
          RolesCompanion.insert(
            localId: 'role-$role',
            serverId: Value('srv-role-$role'),
            companyId: companyId,
            name: role,
            createdAt: now,
            updatedAt: now,
            lastSyncedAt: Value(now),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      batch.insert(
        db.users,
        UsersCompanion.insert(
          localId: userId,
          serverId: Value('srv-$userId'),
          companyId: companyId,
          name: userName,
          email: email,
          roleId: Value('role-$roleName'),
          roleName: roleName,
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
        mode: InsertMode.insertOrReplace,
      );
      for (final vendor in _demoVendors(companyId, now)) {
        batch.insert(db.vendors, vendor, mode: InsertMode.insertOrReplace);
      }
    });
  }

  List<VendorsCompanion> _demoVendors(String companyId, DateTime now) {
    return [
      VendorsCompanion.insert(
        localId: 'vendor-officehub',
        serverId: const Value('srv-vendor-officehub'),
        companyId: companyId,
        name: 'OfficeHub Supplies',
        email: const Value('sales@officehub.example'),
        phone: const Value('+1 555 0101'),
        address: const Value('120 Market Street'),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      VendorsCompanion.insert(
        localId: 'vendor-techline',
        serverId: const Value('srv-vendor-techline'),
        companyId: companyId,
        name: 'Techline Distribution',
        email: const Value('orders@techline.example'),
        phone: const Value('+1 555 0134'),
        address: const Value('45 Industrial Avenue'),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  Stream<List<PurchaseRequest>> watchPurchaseRequests(String companyId) {
    return (db.select(db.purchaseRequests)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<List<PurchaseRequest>> getPurchaseRequests(String companyId) {
    return (db.select(db.purchaseRequests)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<PurchaseRequest?> getPurchaseRequest(String localId) {
    return (db.select(
      db.purchaseRequests,
    )..where((row) => row.localId.equals(localId))).getSingleOrNull();
  }

  Stream<List<PurchaseRequestItem>> watchPurchaseRequestItems(
    String requestLocalId,
  ) {
    return (db.select(db.purchaseRequestItems)..where(
          (row) =>
              row.requestLocalId.equals(requestLocalId) &
              row.isDeleted.equals(false),
        ))
        .watch();
  }

  Future<List<PurchaseRequestItem>> getPurchaseRequestItems(
    String requestLocalId,
  ) {
    return (db.select(db.purchaseRequestItems)..where(
          (row) =>
              row.requestLocalId.equals(requestLocalId) &
              row.isDeleted.equals(false),
        ))
        .get();
  }

  Future<void> insertPurchaseRequestWithItems({
    required PurchaseRequestsCompanion request,
    required List<PurchaseRequestItemsCompanion> items,
  }) {
    return db.transaction(() async {
      await db.into(db.purchaseRequests).insert(request);
      for (final item in items) {
        await db.into(db.purchaseRequestItems).insert(item);
      }
      await addNotification(
        companyId: request.companyId.value,
        title: 'Purchase request created',
        body: request.title.value,
        route: '/requests/${request.localId.value}',
      );
    });
  }

  Future<List<PurchaseRequest>> getPendingPurchaseRequestCreates(
    String companyId,
  ) {
    return (db.select(db.purchaseRequests)..where(
          (row) =>
              row.companyId.equals(companyId) &
              row.syncStatus.equals(SyncStatus.pendingCreate.storageValue) &
              row.isDeleted.equals(false),
        ))
        .get();
  }

  Future<int> countPendingSync(String companyId) async {
    final expression = db.purchaseRequests.localId.count();
    final query = db.selectOnly(db.purchaseRequests)
      ..addColumns([expression])
      ..where(
        db.purchaseRequests.companyId.equals(companyId) &
            db.purchaseRequests.syncStatus.isNotValue(
              SyncStatus.synced.storageValue,
            ),
      );
    return query.map((row) => row.read(expression) ?? 0).getSingle();
  }

  Future<void> markPurchaseRequestSynced({
    required String localId,
    required String serverId,
    required String requestNumber,
    required DateTime syncedAt,
  }) async {
    await (db.update(
      db.purchaseRequests,
    )..where((row) => row.localId.equals(localId))).write(
      PurchaseRequestsCompanion(
        serverId: Value(serverId),
        requestNumber: Value(requestNumber),
        syncStatus: Value(SyncStatus.synced.storageValue),
        lastSyncedAt: Value(syncedAt),
        updatedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markPurchaseRequestSyncFailed({
    required String localId,
    required String message,
  }) async {
    final now = DateTime.now();
    await (db.update(
      db.purchaseRequests,
    )..where((row) => row.localId.equals(localId))).write(
      PurchaseRequestsCompanion(
        syncStatus: Value(SyncStatus.syncFailed.storageValue),
        updatedAt: Value(now),
      ),
    );
    final request = await getPurchaseRequest(localId);
    if (request != null) {
      await addSyncLog(
        companyId: request.companyId,
        entityType: 'purchase_request',
        entityLocalId: localId,
        action: 'create',
        status: SyncStatus.syncFailed.storageValue,
        message: message,
      );
    }
  }

  Future<void> addSyncLog({
    required String companyId,
    required String entityType,
    required String entityLocalId,
    required String action,
    required String status,
    String? message,
  }) {
    return db
        .into(db.syncLogs)
        .insert(
          SyncLogsCompanion.insert(
            localId: _uuid.v4(),
            companyId: companyId,
            entityType: entityType,
            entityLocalId: entityLocalId,
            action: action,
            status: status,
            message: Value(message),
            createdAt: DateTime.now(),
          ),
        );
  }

  Stream<List<SyncLog>> watchSyncLogs(String companyId) {
    return (db.select(db.syncLogs)
          ..where((row) => row.companyId.equals(companyId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(30))
        .watch();
  }

  Future<List<Vendor>> getVendors(String companyId) {
    return (db.select(db.vendors)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  Stream<List<Vendor>> watchVendors(String companyId) {
    return (db.select(db.vendors)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .watch();
  }

  Future<void> updatePurchaseRequestStatus({
    required String requestLocalId,
    required String actorId,
    required String companyId,
    required String action,
    required String comment,
  }) async {
    final now = DateTime.now();
    final nextStatus = action == 'approved' ? 'approved' : 'rejected';
    await db.transaction(() async {
      await (db.update(
        db.purchaseRequests,
      )..where((row) => row.localId.equals(requestLocalId))).write(
        PurchaseRequestsCompanion(
          status: Value(nextStatus),
          syncStatus: Value(SyncStatus.pendingUpdate.storageValue),
          updatedAt: Value(now),
        ),
      );
      await db
          .into(db.approvalActions)
          .insert(
            ApprovalActionsCompanion.insert(
              localId: _uuid.v4(),
              companyId: companyId,
              requestLocalId: requestLocalId,
              actorId: actorId,
              action: action,
              comment: Value(comment),
              syncStatus: Value(SyncStatus.pendingUpdate.storageValue),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await addNotification(
        companyId: companyId,
        title: 'Request ${nextStatus == 'approved' ? 'approved' : 'rejected'}',
        body: 'Approval action recorded locally.',
        route: '/requests/$requestLocalId',
      );
    });
  }

  Stream<List<PurchaseRequest>> watchApprovalInbox(String companyId) {
    return (db.select(db.purchaseRequests)
          ..where(
            (row) =>
                row.companyId.equals(companyId) &
                row.status.equals('submitted') &
                row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .watch();
  }

  Stream<List<PurchaseOrder>> watchPurchaseOrders(String companyId) {
    return (db.select(db.purchaseOrders)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<List<PurchaseOrder>> getPurchaseOrders(String companyId) {
    return (db.select(db.purchaseOrders)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<void> createPurchaseOrderFromRequest({
    required PurchaseRequest request,
    required List<PurchaseRequestItem> items,
    required String createdById,
  }) async {
    final now = DateTime.now();
    final poLocalId = _uuid.v4();
    await db.transaction(() async {
      await db
          .into(db.purchaseOrders)
          .insert(
            PurchaseOrdersCompanion.insert(
              localId: poLocalId,
              serverId: Value('mock-po-$poLocalId'),
              companyId: request.companyId,
              poNumber: _numberWithPrefix('PO'),
              requestLocalId: Value(request.localId),
              createdById: createdById,
              status: const Value('issued'),
              totalAmount: Value(request.totalAmount),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
          );
      for (final item in items) {
        await db
            .into(db.purchaseOrderItems)
            .insert(
              PurchaseOrderItemsCompanion.insert(
                localId: _uuid.v4(),
                serverId: Value('mock-po-item-${item.localId}'),
                companyId: request.companyId,
                purchaseOrderLocalId: poLocalId,
                itemName: item.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                lineTotal: item.lineTotal,
                syncStatus: Value(SyncStatus.synced.storageValue),
                createdAt: now,
                updatedAt: now,
                lastSyncedAt: Value(now),
              ),
            );
      }
      await (db.update(
        db.purchaseRequests,
      )..where((row) => row.localId.equals(request.localId))).write(
        PurchaseRequestsCompanion(
          status: const Value('po_created'),
          updatedAt: Value(now),
        ),
      );
      await addNotification(
        companyId: request.companyId,
        title: 'Purchase order created',
        body: 'PO was created from ${request.requestNumber}.',
        route: '/purchase-orders',
      );
    });
  }

  Stream<List<LocalNotification>> watchNotifications(String companyId) {
    return (db.select(db.localNotifications)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<void> addNotification({
    required String companyId,
    required String title,
    required String body,
    String? route,
  }) {
    final now = DateTime.now();
    return db
        .into(db.localNotifications)
        .insert(
          LocalNotificationsCompanion.insert(
            localId: _uuid.v4(),
            companyId: companyId,
            title: title,
            body: body,
            route: Value(route),
            syncStatus: Value(SyncStatus.synced.storageValue),
            createdAt: now,
            updatedAt: now,
            lastSyncedAt: Value(now),
          ),
        );
  }

  Future<void> markAllNotificationsRead(String companyId) {
    return (db.update(db.localNotifications)
          ..where((row) => row.companyId.equals(companyId)))
        .write(const LocalNotificationsCompanion(isRead: Value(true)));
  }

  String nextPurchaseRequestNumber() => _numberWithPrefix('PR');

  String _numberWithPrefix(String prefix) {
    final now = DateTime.now();
    return '$prefix-${now.year}${_two(now.month)}${_two(now.day)}'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
