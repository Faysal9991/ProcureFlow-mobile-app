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
  TextColumn get contactPerson => text().nullable()();
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
  DateTimeColumn get lastKnownServerUpdatedAt => dateTime().nullable()();
  TextColumn get lastSyncError => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
}

class PurchaseRequestItems extends Table with SyncColumns {
  TextColumn get requestLocalId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
  DateTimeColumn get lastKnownServerUpdatedAt => dateTime().nullable()();
  TextColumn get lastSyncError => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
}

class Rfqs extends Table with SyncColumns {
  TextColumn get rfqNumber => text()();
  TextColumn get purchaseRequestId => text()();
  TextColumn get purchaseRequestNumber => text()();
  TextColumn get purchaseRequestTitle => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  IntColumn get vendorCount => integer().withDefault(const Constant(0))();
  IntColumn get quotationCount => integer().withDefault(const Constant(0))();
  TextColumn get selectedQuotationId => text().nullable()();
}

class RfqItems extends Table with SyncColumns {
  TextColumn get rfqLocalId => text()();
  TextColumn get itemName => text()();
  TextColumn get description => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get estimatedUnitPrice => real().withDefault(const Constant(0))();
}

class RfqVendors extends Table with SyncColumns {
  TextColumn get rfqLocalId => text()();
  TextColumn get vendorId => text()();
  TextColumn get vendorName => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
}

class Quotations extends Table with SyncColumns {
  TextColumn get rfqLocalId => text()();
  TextColumn get vendorId => text()();
  TextColumn get vendorName => text()();
  TextColumn get quotationNumber => text()();
  DateTimeColumn get quotationDate => dateTime().nullable()();
  DateTimeColumn get validUntil => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('SUBMITTED'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
}

class QuotationItems extends Table with SyncColumns {
  TextColumn get quotationLocalId => text()();
  TextColumn get rfqItemId => text()();
  TextColumn get itemName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
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
  TextColumn get purchaseRequestNumber => text().nullable()();
  TextColumn get purchaseRequestTitle => text().nullable()();
  TextColumn get rfqId => text().nullable()();
  TextColumn get rfqNumber => text().nullable()();
  TextColumn get quotationId => text().nullable()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get vendorName => text().nullable()();
  TextColumn get createdById => text()();
  TextColumn get createdByName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get issueDate => dateTime().nullable()();
  DateTimeColumn get receivedDate => dateTime().nullable()();
  DateTimeColumn get closedDate => dateTime().nullable()();
  DateTimeColumn get cancelledDate => dateTime().nullable()();
}

class PurchaseOrderItems extends Table with SyncColumns {
  TextColumn get purchaseOrderLocalId => text()();
  TextColumn get rfqItemId => text().nullable()();
  TextColumn get itemName => text()();
  IntColumn get quantity => integer()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
}

class Invoices extends Table with SyncColumns {
  TextColumn get invoiceNumber => text()();
  TextColumn get purchaseOrderId => text()();
  TextColumn get purchaseOrderNumber => text()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get vendorName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get invoiceAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get dueAmount => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get cancelledDate => dateTime().nullable()();
}

class Payments extends Table with SyncColumns {
  TextColumn get invoiceId => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get vendorName => text().nullable()();
  DateTimeColumn get paymentDate => dateTime()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()();
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdById => text().nullable()();
  TextColumn get createdByName => text().nullable()();
}

class Budgets extends Table with SyncColumns {
  TextColumn get departmentId => text()();
  TextColumn get departmentName => text().nullable()();
  TextColumn get name => text()();
  TextColumn get periodType => text().withDefault(const Constant('MONTHLY'))();
  DateTimeColumn get periodStartDate => dateTime()();
  DateTimeColumn get periodEndDate => dateTime()();
  RealColumn get allocatedAmount => real()();
  RealColumn get spentAmount => real().withDefault(const Constant(0))();
  RealColumn get availableAmount => real()();
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get activatedAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

class BudgetTransactions extends Table with SyncColumns {
  TextColumn get budgetId => text()();
  TextColumn get transactionType => text()();
  RealColumn get amount => real()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get createdById => text().nullable()();
  TextColumn get createdByName => text().nullable()();
}

class Attachments extends Table with SyncColumns {
  TextColumn get ownerType => text()();
  TextColumn get ownerLocalId => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  TextColumn get fileName => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get uploadedById => text().nullable()();
  TextColumn get uploadedByName => text().nullable()();
}

class SyncQueue extends Table {
  TextColumn get localId => text()();
  TextColumn get companyId => text()();
  TextColumn get entityType => text()();
  TextColumn get operation => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class SyncMetadata extends Table {
  TextColumn get companyId => text()();
  TextColumn get scope => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {companyId, scope};
}

class DeviceTokens extends Table with SyncColumns {
  TextColumn get deviceId => text()();
  TextColumn get platform => text()();
  TextColumn get fcmToken => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
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
    Rfqs,
    RfqItems,
    RfqVendors,
    Quotations,
    QuotationItems,
    ApprovalWorkflows,
    ApprovalSteps,
    ApprovalActions,
    PurchaseOrders,
    PurchaseOrderItems,
    Invoices,
    Payments,
    Budgets,
    BudgetTransactions,
    Attachments,
    SyncQueue,
    SyncMetadata,
    DeviceTokens,
    SyncLogs,
    AuditLogs,
    LocalNotifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(purchaseRequests, purchaseRequests.priority);
        await migrator.addColumn(purchaseRequests, purchaseRequests.neededDate);
      }
      if (from < 3) {
        await migrator.addColumn(vendors, vendors.contactPerson);
      }
      if (from < 4) {
        await migrator.createTable(rfqs);
        await migrator.createTable(rfqItems);
        await migrator.createTable(rfqVendors);
        await migrator.createTable(quotations);
        await migrator.createTable(quotationItems);
      }
      if (from < 5) {
        await migrator.addColumn(rfqs, rfqs.selectedQuotationId);
      }
      if (from < 6) {
        await migrator.addColumn(
          purchaseOrders,
          purchaseOrders.purchaseRequestNumber,
        );
        await migrator.addColumn(
          purchaseOrders,
          purchaseOrders.purchaseRequestTitle,
        );
        await migrator.addColumn(purchaseOrders, purchaseOrders.rfqId);
        await migrator.addColumn(purchaseOrders, purchaseOrders.rfqNumber);
        await migrator.addColumn(purchaseOrders, purchaseOrders.quotationId);
        await migrator.addColumn(purchaseOrders, purchaseOrders.vendorName);
        await migrator.addColumn(purchaseOrders, purchaseOrders.createdByName);
        await migrator.addColumn(purchaseOrders, purchaseOrders.notes);
        await migrator.addColumn(purchaseOrders, purchaseOrders.issueDate);
        await migrator.addColumn(purchaseOrders, purchaseOrders.receivedDate);
        await migrator.addColumn(purchaseOrders, purchaseOrders.closedDate);
        await migrator.addColumn(purchaseOrders, purchaseOrders.cancelledDate);
        await migrator.addColumn(
          purchaseOrderItems,
          purchaseOrderItems.rfqItemId,
        );
        await migrator.addColumn(purchaseOrderItems, purchaseOrderItems.unit);
      }
      if (from < 7) {
        await migrator.createTable(invoices);
      }
      if (from < 8) {
        await migrator.createTable(payments);
      }
      if (from < 9) {
        await migrator.createTable(budgets);
        await migrator.createTable(budgetTransactions);
      }
      if (from < 10) {
        await migrator.addColumn(attachments, attachments.entityType);
        await migrator.addColumn(attachments, attachments.entityId);
        await migrator.addColumn(attachments, attachments.fileSize);
        await migrator.addColumn(attachments, attachments.uploadedById);
        await migrator.addColumn(attachments, attachments.uploadedByName);
      }
      if (from < 11) {
        await migrator.addColumn(
          purchaseRequests,
          purchaseRequests.lastKnownServerUpdatedAt,
        );
        await migrator.addColumn(
          purchaseRequests,
          purchaseRequests.lastSyncError,
        );
        await migrator.addColumn(purchaseRequests, purchaseRequests.isDirty);
        await migrator.addColumn(
          purchaseRequestItems,
          purchaseRequestItems.lastKnownServerUpdatedAt,
        );
        await migrator.addColumn(
          purchaseRequestItems,
          purchaseRequestItems.lastSyncError,
        );
        await migrator.addColumn(
          purchaseRequestItems,
          purchaseRequestItems.isDirty,
        );
        await migrator.createTable(syncQueue);
        await migrator.createTable(syncMetadata);
        await migrator.createTable(deviceTokens);
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
