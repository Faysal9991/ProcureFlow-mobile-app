import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

mixin SyncColumns on Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get companyId => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Companies extends Table {
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get domain => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Branches extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
}

class Departments extends Table with SyncColumns {
  TextColumn get name => text()();
}

class Roles extends Table with SyncColumns {
  TextColumn get name => text()();
}

class Users extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get roleId => text().nullable()();
  TextColumn get roleName => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Vendors extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class PurchaseRequests extends Table with SyncColumns {
  TextColumn get requestNumber => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get requesterId => text()();
  TextColumn get departmentId => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  DateTimeColumn get neededDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('submitted'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
}

class PurchaseRequestItems extends Table with SyncColumns {
  TextColumn get requestLocalId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
}

class ApprovalWorkflows extends Table with SyncColumns {
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class ApprovalSteps extends Table with SyncColumns {
  TextColumn get workflowLocalId => text()();
  TextColumn get roleId => text().nullable()();
  TextColumn get approverRoleName => text()();
  IntColumn get stepOrder => integer()();
}

class ApprovalActions extends Table with SyncColumns {
  TextColumn get requestLocalId => text()();
  TextColumn get actorId => text()();
  TextColumn get action => text()();
  TextColumn get comment => text().nullable()();
}

class PurchaseOrders extends Table with SyncColumns {
  TextColumn get poNumber => text()();
  TextColumn get requestLocalId => text().nullable()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get createdById => text()();
  TextColumn get status => text().withDefault(const Constant('issued'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
}

class PurchaseOrderItems extends Table with SyncColumns {
  TextColumn get purchaseOrderLocalId => text()();
  TextColumn get itemName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
}

class Attachments extends Table with SyncColumns {
  TextColumn get ownerType => text()();
  TextColumn get ownerLocalId => text()();
  TextColumn get fileName => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get mimeType => text().nullable()();
}

class SyncLogs extends Table {
  TextColumn get localId => text()();
  TextColumn get companyId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get action => text()();
  TextColumn get status => text()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class AuditLogs extends Table with SyncColumns {
  TextColumn get actorId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get action => text()();
  TextColumn get details => text().nullable()();
}

class LocalNotifications extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get route => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Companies,
    Branches,
    Departments,
    Users,
    Roles,
    Vendors,
    PurchaseRequests,
    PurchaseRequestItems,
    ApprovalWorkflows,
    ApprovalSteps,
    ApprovalActions,
    PurchaseOrders,
    PurchaseOrderItems,
    Attachments,
    SyncLogs,
    AuditLogs,
    LocalNotifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(purchaseRequests, purchaseRequests.priority);
        await migrator.addColumn(purchaseRequests, purchaseRequests.neededDate);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'procurement_management.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
