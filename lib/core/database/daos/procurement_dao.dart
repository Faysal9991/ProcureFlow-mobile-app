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
      for (final request in _demoApprovedRequests(companyId, userId, now)) {
        batch.insert(
          db.purchaseRequests,
          request,
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final item in _demoApprovedRequestItems(companyId, now)) {
        batch.insert(
          db.purchaseRequestItems,
          item,
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final rfq in _demoCompletedRfqs(companyId, now)) {
        batch.insert(db.rfqs, rfq, mode: InsertMode.insertOrReplace);
      }
      for (final item in _demoCompletedRfqItems(companyId, now)) {
        batch.insert(db.rfqItems, item, mode: InsertMode.insertOrReplace);
      }
      for (final vendor in _demoCompletedRfqVendors(companyId, now)) {
        batch.insert(db.rfqVendors, vendor, mode: InsertMode.insertOrReplace);
      }
      for (final quotation in _demoCompletedQuotations(companyId, now)) {
        batch.insert(
          db.quotations,
          quotation,
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final item in _demoCompletedQuotationItems(companyId, now)) {
        batch.insert(db.quotationItems, item, mode: InsertMode.insertOrReplace);
      }
      for (final order in _demoDraftPurchaseOrders(companyId, userId, now)) {
        batch.insert(
          db.purchaseOrders,
          order,
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final item in _demoDraftPurchaseOrderItems(companyId, now)) {
        batch.insert(
          db.purchaseOrderItems,
          item,
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final invoice in _demoInvoices(companyId, now)) {
        batch.insert(db.invoices, invoice, mode: InsertMode.insertOrReplace);
      }
      for (final payment in _demoPayments(companyId, userId, userName, now)) {
        batch.insert(db.payments, payment, mode: InsertMode.insertOrReplace);
      }
      for (final budget in _demoBudgets(companyId, now)) {
        batch.insert(db.budgets, budget, mode: InsertMode.insertOrReplace);
      }
      for (final transaction in _demoBudgetTransactions(
        companyId,
        userId,
        userName,
        now,
      )) {
        batch.insert(
          db.budgetTransactions,
          transaction,
          mode: InsertMode.insertOrReplace,
        );
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
        contactPerson: const Value('Avery Clarke'),
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
        contactPerson: const Value('Maya Rahman'),
        email: const Value('orders@techline.example'),
        phone: const Value('+1 555 0134'),
        address: const Value('45 Industrial Avenue'),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<PurchaseRequestsCompanion> _demoApprovedRequests(
    String companyId,
    String userId,
    DateTime now,
  ) {
    return [
      PurchaseRequestsCompanion.insert(
        localId: 'request-approved-laptops',
        serverId: const Value('srv-request-approved-laptops'),
        companyId: companyId,
        requestNumber: 'PR-DEMO-001',
        title: 'Laptop Purchase',
        description: const Value('Approved request ready for RFQ.'),
        requesterId: userId,
        departmentId: const Value('IT'),
        priority: const Value('HIGH'),
        neededDate: Value(now.add(const Duration(days: 21))),
        status: const Value('APPROVED'),
        totalAmount: const Value(2400),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<PurchaseRequestItemsCompanion> _demoApprovedRequestItems(
    String companyId,
    DateTime now,
  ) {
    return [
      PurchaseRequestItemsCompanion.insert(
        localId: 'request-approved-laptops-item-1',
        serverId: const Value('srv-request-approved-laptops-item-1'),
        companyId: companyId,
        requestLocalId: 'request-approved-laptops',
        name: 'Laptop',
        description: const Value('16GB RAM, 512GB SSD'),
        quantity: 2,
        unitPrice: 1200,
        lineTotal: 2400,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<RfqsCompanion> _demoCompletedRfqs(String companyId, DateTime now) {
    return [
      RfqsCompanion.insert(
        localId: 'rfq-demo-completed',
        serverId: const Value('srv-rfq-demo-completed'),
        companyId: companyId,
        rfqNumber: 'RFQ-DEMO-001',
        purchaseRequestId: 'request-demo-po-source',
        purchaseRequestNumber: 'PR-DEMO-000',
        purchaseRequestTitle: 'Completed RFQ Source',
        dueDate: Value(now.add(const Duration(days: 10))),
        notes: const Value('Completed RFQ with a selected quotation.'),
        status: const Value('COMPLETED'),
        vendorCount: const Value(1),
        quotationCount: const Value(1),
        selectedQuotationId: const Value('quotation-demo-selected'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<RfqItemsCompanion> _demoCompletedRfqItems(
    String companyId,
    DateTime now,
  ) {
    return [
      RfqItemsCompanion.insert(
        localId: 'rfq-demo-item-laptop',
        serverId: const Value('srv-rfq-demo-item-laptop'),
        companyId: companyId,
        rfqLocalId: 'rfq-demo-completed',
        itemName: 'Laptop',
        description: const Value('16GB RAM, 512GB SSD'),
        quantity: 2,
        unit: const Value('pcs'),
        estimatedUnitPrice: const Value(1200),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<RfqVendorsCompanion> _demoCompletedRfqVendors(
    String companyId,
    DateTime now,
  ) {
    return [
      RfqVendorsCompanion.insert(
        localId: 'rfq-demo-vendor-officehub',
        serverId: const Value('srv-rfq-demo-vendor-officehub'),
        companyId: companyId,
        rfqLocalId: 'rfq-demo-completed',
        vendorId: 'vendor-officehub',
        vendorName: 'OfficeHub Supplies',
        contactPerson: const Value('Avery Clarke'),
        email: const Value('sales@officehub.example'),
        phone: const Value('+1 555 0101'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<QuotationsCompanion> _demoCompletedQuotations(
    String companyId,
    DateTime now,
  ) {
    return [
      QuotationsCompanion.insert(
        localId: 'quotation-demo-selected',
        serverId: const Value('srv-quotation-demo-selected'),
        companyId: companyId,
        rfqLocalId: 'rfq-demo-completed',
        vendorId: 'vendor-officehub',
        vendorName: 'OfficeHub Supplies',
        quotationNumber: 'Q-DEMO-001',
        quotationDate: Value(now.subtract(const Duration(days: 2))),
        validUntil: Value(now.add(const Duration(days: 30))),
        notes: const Value('Selected demo quotation.'),
        status: const Value('SUBMITTED'),
        totalAmount: const Value(1800),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<QuotationItemsCompanion> _demoCompletedQuotationItems(
    String companyId,
    DateTime now,
  ) {
    return [
      QuotationItemsCompanion.insert(
        localId: 'quotation-demo-selected-item-1',
        serverId: const Value('srv-quotation-demo-selected-item-1'),
        companyId: companyId,
        quotationLocalId: 'quotation-demo-selected',
        rfqItemId: 'rfq-demo-item-laptop',
        itemName: 'Laptop',
        quantity: 2,
        unitPrice: 900,
        totalPrice: 1800,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<PurchaseOrdersCompanion> _demoDraftPurchaseOrders(
    String companyId,
    String userId,
    DateTime now,
  ) {
    return [
      PurchaseOrdersCompanion.insert(
        localId: 'po-demo-draft',
        serverId: const Value('srv-po-demo-draft'),
        companyId: companyId,
        poNumber: 'PO-DEMO-001',
        requestLocalId: const Value('request-demo-po-source'),
        purchaseRequestNumber: const Value('PR-DEMO-000'),
        purchaseRequestTitle: const Value('Completed RFQ Source'),
        rfqId: const Value('rfq-demo-completed'),
        rfqNumber: const Value('RFQ-DEMO-001'),
        quotationId: const Value('quotation-demo-selected'),
        vendorId: const Value('vendor-officehub'),
        vendorName: const Value('OfficeHub Supplies'),
        createdById: userId,
        createdByName: const Value('Demo User'),
        status: const Value('DRAFT'),
        totalAmount: const Value(1800),
        notes: const Value('Draft PO from selected demo quotation.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrdersCompanion.insert(
        localId: 'po-demo-received-open',
        serverId: const Value('srv-po-demo-received-open'),
        companyId: companyId,
        poNumber: 'PO-DEMO-002',
        requestLocalId: const Value('request-demo-po-source'),
        purchaseRequestNumber: const Value('PR-DEMO-000'),
        purchaseRequestTitle: const Value('Completed RFQ Source'),
        rfqId: const Value('rfq-demo-completed'),
        rfqNumber: const Value('RFQ-DEMO-001'),
        quotationId: const Value('quotation-demo-selected'),
        vendorId: const Value('vendor-officehub'),
        vendorName: const Value('OfficeHub Supplies'),
        createdById: userId,
        createdByName: const Value('Demo User'),
        status: const Value('RECEIVED'),
        totalAmount: const Value(1800),
        receivedDate: Value(now),
        notes: const Value('Received PO ready for invoice creation.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrdersCompanion.insert(
        localId: 'po-demo-received-pending-invoice',
        serverId: const Value('srv-po-demo-received-pending-invoice'),
        companyId: companyId,
        poNumber: 'PO-DEMO-003',
        requestLocalId: const Value('request-demo-po-source'),
        purchaseRequestNumber: const Value('PR-DEMO-000'),
        purchaseRequestTitle: const Value('Completed RFQ Source'),
        rfqId: const Value('rfq-demo-completed'),
        rfqNumber: const Value('RFQ-DEMO-001'),
        quotationId: const Value('quotation-demo-selected'),
        vendorId: const Value('vendor-officehub'),
        vendorName: const Value('OfficeHub Supplies'),
        createdById: userId,
        createdByName: const Value('Demo User'),
        status: const Value('RECEIVED'),
        totalAmount: const Value(1200),
        receivedDate: Value(now.subtract(const Duration(days: 3))),
        notes: const Value('Received PO with pending invoice.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrdersCompanion.insert(
        localId: 'po-demo-received-partial-invoice',
        serverId: const Value('srv-po-demo-received-partial-invoice'),
        companyId: companyId,
        poNumber: 'PO-DEMO-004',
        requestLocalId: const Value('request-demo-po-source'),
        purchaseRequestNumber: const Value('PR-DEMO-000'),
        purchaseRequestTitle: const Value('Completed RFQ Source'),
        rfqId: const Value('rfq-demo-completed'),
        rfqNumber: const Value('RFQ-DEMO-001'),
        quotationId: const Value('quotation-demo-selected'),
        vendorId: const Value('vendor-techline'),
        vendorName: const Value('Techline Distribution'),
        createdById: userId,
        createdByName: const Value('Demo User'),
        status: const Value('RECEIVED'),
        totalAmount: const Value(2200),
        receivedDate: Value(now.subtract(const Duration(days: 8))),
        notes: const Value('Received PO with partial payment demo invoice.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<PurchaseOrderItemsCompanion> _demoDraftPurchaseOrderItems(
    String companyId,
    DateTime now,
  ) {
    return [
      PurchaseOrderItemsCompanion.insert(
        localId: 'po-demo-draft-item-1',
        serverId: const Value('srv-po-demo-draft-item-1'),
        companyId: companyId,
        purchaseOrderLocalId: 'po-demo-draft',
        rfqItemId: const Value('rfq-demo-item-laptop'),
        itemName: 'Laptop',
        quantity: 2,
        unit: const Value('pcs'),
        unitPrice: 900,
        lineTotal: 1800,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrderItemsCompanion.insert(
        localId: 'po-demo-received-open-item-1',
        serverId: const Value('srv-po-demo-received-open-item-1'),
        companyId: companyId,
        purchaseOrderLocalId: 'po-demo-received-open',
        rfqItemId: const Value('rfq-demo-item-laptop'),
        itemName: 'Laptop',
        quantity: 2,
        unit: const Value('pcs'),
        unitPrice: 900,
        lineTotal: 1800,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrderItemsCompanion.insert(
        localId: 'po-demo-received-pending-invoice-item-1',
        serverId: const Value('srv-po-demo-received-pending-invoice-item-1'),
        companyId: companyId,
        purchaseOrderLocalId: 'po-demo-received-pending-invoice',
        rfqItemId: const Value('rfq-demo-item-laptop'),
        itemName: 'Monitor',
        quantity: 2,
        unit: const Value('pcs'),
        unitPrice: 600,
        lineTotal: 1200,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      PurchaseOrderItemsCompanion.insert(
        localId: 'po-demo-received-partial-invoice-item-1',
        serverId: const Value('srv-po-demo-received-partial-invoice-item-1'),
        companyId: companyId,
        purchaseOrderLocalId: 'po-demo-received-partial-invoice',
        rfqItemId: const Value('rfq-demo-item-laptop'),
        itemName: 'Printer',
        quantity: 2,
        unit: const Value('pcs'),
        unitPrice: 1100,
        lineTotal: 2200,
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now,
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<InvoicesCompanion> _demoInvoices(String companyId, DateTime now) {
    return [
      InvoicesCompanion.insert(
        localId: 'invoice-demo-pending',
        serverId: const Value('srv-invoice-demo-pending'),
        companyId: companyId,
        invoiceNumber: 'INV-DEMO-001',
        purchaseOrderId: 'po-demo-received-pending-invoice',
        purchaseOrderNumber: 'PO-DEMO-003',
        vendorId: const Value('vendor-officehub'),
        vendorName: const Value('OfficeHub Supplies'),
        status: const Value('PENDING'),
        invoiceDate: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 28)),
        invoiceAmount: 1200,
        paidAmount: const Value(0),
        dueAmount: 1200,
        notes: const Value('Pending demo invoice.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      InvoicesCompanion.insert(
        localId: 'invoice-demo-partial',
        serverId: const Value('srv-invoice-demo-partial'),
        companyId: companyId,
        invoiceNumber: 'INV-DEMO-002',
        purchaseOrderId: 'po-demo-received-partial-invoice',
        purchaseOrderNumber: 'PO-DEMO-004',
        vendorId: const Value('vendor-techline'),
        vendorName: const Value('Techline Distribution'),
        status: const Value('PARTIALLY_PAID'),
        invoiceDate: now.subtract(const Duration(days: 7)),
        dueDate: now.add(const Duration(days: 23)),
        invoiceAmount: 2200,
        paidAmount: const Value(800),
        dueAmount: 1400,
        notes: const Value('Partially paid demo invoice.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<PaymentsCompanion> _demoPayments(
    String companyId,
    String userId,
    String userName,
    DateTime now,
  ) {
    return [
      PaymentsCompanion.insert(
        localId: 'payment-demo-partial',
        serverId: const Value('srv-payment-demo-partial'),
        companyId: companyId,
        invoiceId: 'invoice-demo-partial',
        invoiceNumber: 'INV-DEMO-002',
        vendorId: const Value('vendor-techline'),
        vendorName: const Value('Techline Distribution'),
        paymentDate: now.subtract(const Duration(days: 1)),
        amount: 800,
        paymentMethod: 'BANK_TRANSFER',
        referenceNumber: const Value('TXN-DEMO-001'),
        notes: const Value('Partial demo payment.'),
        createdById: Value(userId),
        createdByName: Value(userName),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<BudgetsCompanion> _demoBudgets(String companyId, DateTime now) {
    return [
      BudgetsCompanion.insert(
        localId: 'budget-it-active',
        serverId: const Value('srv-budget-it-active'),
        companyId: companyId,
        departmentId: 'IT',
        departmentName: const Value('IT'),
        name: 'IT Equipment Budget',
        periodType: const Value('YEARLY'),
        periodStartDate: DateTime(now.year, 1, 1),
        periodEndDate: DateTime(now.year, 12, 31),
        allocatedAmount: 50000,
        spentAmount: const Value(4200),
        availableAmount: 45800,
        status: const Value('ACTIVE'),
        notes: const Value('Demo active budget.'),
        activatedAt: Value(now.subtract(const Duration(days: 20))),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
      BudgetsCompanion.insert(
        localId: 'budget-admin-draft',
        serverId: const Value('srv-budget-admin-draft'),
        companyId: companyId,
        departmentId: 'ADMIN',
        departmentName: const Value('Admin'),
        name: 'Admin Monthly Budget',
        periodType: const Value('MONTHLY'),
        periodStartDate: DateTime(now.year, now.month, 1),
        periodEndDate: DateTime(now.year, now.month + 1, 0),
        allocatedAmount: 10000,
        availableAmount: 10000,
        status: const Value('DRAFT'),
        notes: const Value('Demo draft budget.'),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
        lastSyncedAt: Value(now),
      ),
    ];
  }

  List<BudgetTransactionsCompanion> _demoBudgetTransactions(
    String companyId,
    String userId,
    String userName,
    DateTime now,
  ) {
    return [
      BudgetTransactionsCompanion.insert(
        localId: 'budget-it-active-opening',
        serverId: const Value('srv-budget-it-active-opening'),
        companyId: companyId,
        budgetId: 'budget-it-active',
        transactionType: 'ALLOCATION',
        amount: 50000,
        description: const Value('Opening allocation.'),
        createdById: Value(userId),
        createdByName: Value(userName),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
        lastSyncedAt: Value(now),
      ),
      BudgetTransactionsCompanion.insert(
        localId: 'budget-it-active-spend',
        serverId: const Value('srv-budget-it-active-spend'),
        companyId: companyId,
        budgetId: 'budget-it-active',
        transactionType: 'RESERVED',
        amount: -4200,
        referenceType: const Value('PURCHASE_ORDER'),
        referenceId: const Value('po-demo-received-open'),
        description: const Value('Demo reserved spend.'),
        createdById: Value(userId),
        createdByName: Value(userName),
        syncStatus: Value(SyncStatus.synced.storageValue),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
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

  Future<PurchaseRequest?> getPurchaseRequestByServerId(String serverId) {
    return (db.select(db.purchaseRequests)..where(
          (row) => row.serverId.equals(serverId) & row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
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

  Future<List<PurchaseRequest>> getEligiblePurchaseRequestsForRfq(
    String companyId,
  ) async {
    final existingRfqs =
        await (db.select(db.rfqs)..where(
              (row) =>
                  row.companyId.equals(companyId) &
                  row.isDeleted.equals(false) &
                  row.status.isNotIn(['CANCELLED', 'cancelled']),
            ))
            .get();
    final usedRequestIds = existingRfqs
        .map((rfq) => rfq.purchaseRequestId)
        .toSet();
    final approved =
        await (db.select(db.purchaseRequests)
              ..where(
                (row) =>
                    row.companyId.equals(companyId) &
                    row.isDeleted.equals(false) &
                    row.status.isIn(['APPROVED', 'approved']),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
            .get();
    return [
      for (final request in approved)
        if (!usedRequestIds.contains(request.localId) &&
            (request.serverId == null ||
                !usedRequestIds.contains(request.serverId)))
          request,
    ];
  }

  Future<List<Rfq>> getRfqs(String companyId) {
    return (db.select(db.rfqs)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<Rfq?> getRfq(String localId) {
    return (db.select(db.rfqs)..where(
          (row) => row.localId.equals(localId) & row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<List<RfqItem>> getRfqItems(String rfqLocalId) {
    return (db.select(db.rfqItems)
          ..where(
            (row) =>
                row.rfqLocalId.equals(rfqLocalId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<List<RfqVendor>> getRfqVendors(String rfqLocalId) {
    return (db.select(db.rfqVendors)
          ..where(
            (row) =>
                row.rfqLocalId.equals(rfqLocalId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.vendorName)]))
        .get();
  }

  Future<List<Quotation>> getRfqQuotations(String rfqLocalId) {
    return (db.select(db.quotations)
          ..where(
            (row) =>
                row.rfqLocalId.equals(rfqLocalId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<Quotation?> getRfqQuotation(String rfqLocalId, String quotationId) {
    return (db.select(db.quotations)..where(
          (row) =>
              row.rfqLocalId.equals(rfqLocalId) &
              row.localId.equals(quotationId) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<List<QuotationItem>> getQuotationItems(String quotationLocalId) {
    return (db.select(db.quotationItems)..where(
          (row) =>
              row.quotationLocalId.equals(quotationLocalId) &
              row.isDeleted.equals(false),
        ))
        .get();
  }

  Future<Quotation?> getQuotationById(String quotationId) {
    return (db.select(db.quotations)..where(
          (row) =>
              row.localId.equals(quotationId) |
              row.serverId.equalsNullable(quotationId),
        ))
        .getSingleOrNull();
  }

  Future<void> insertRfqWithItems({
    required RfqsCompanion rfq,
    required List<RfqItemsCompanion> items,
  }) {
    return db.transaction(() async {
      await db.into(db.rfqs).insert(rfq);
      for (final item in items) {
        await db.into(db.rfqItems).insert(item);
      }
      await addNotification(
        companyId: rfq.companyId.value,
        title: 'RFQ created',
        body: rfq.rfqNumber.value,
        route: '/rfqs/${rfq.localId.value}',
      );
    });
  }

  Future<void> assignRfqVendors({
    required String rfqLocalId,
    required List<RfqVendorsCompanion> vendors,
  }) {
    return db.transaction(() async {
      await (db.delete(
        db.rfqVendors,
      )..where((row) => row.rfqLocalId.equals(rfqLocalId))).go();
      for (final vendor in vendors) {
        await db.into(db.rfqVendors).insert(vendor);
      }
      await (db.update(
        db.rfqs,
      )..where((row) => row.localId.equals(rfqLocalId))).write(
        RfqsCompanion(
          vendorCount: Value(vendors.length),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> openRfq(String rfqLocalId) {
    final now = DateTime.now();
    return (db.update(
      db.rfqs,
    )..where((row) => row.localId.equals(rfqLocalId))).write(
      RfqsCompanion(status: const Value('OPEN'), updatedAt: Value(now)),
    );
  }

  Future<void> insertQuotationWithItems({
    required QuotationsCompanion quotation,
    required List<QuotationItemsCompanion> items,
  }) {
    return db.transaction(() async {
      await db.into(db.quotations).insert(quotation);
      for (final item in items) {
        await db.into(db.quotationItems).insert(item);
      }
      final countExpression = db.quotations.localId.count();
      final countQuery = db.selectOnly(db.quotations)
        ..addColumns([countExpression])
        ..where(
          db.quotations.rfqLocalId.equals(quotation.rfqLocalId.value) &
              db.quotations.isDeleted.equals(false),
        );
      final count = await countQuery
          .map((row) => row.read(countExpression) ?? 0)
          .getSingle();
      await (db.update(
        db.rfqs,
      )..where((row) => row.localId.equals(quotation.rfqLocalId.value))).write(
        RfqsCompanion(
          quotationCount: Value(count),
          status: const Value('QUOTATION_RECEIVED'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> selectWinningRfqQuotation({
    required String rfqLocalId,
    required String quotationId,
  }) {
    final now = DateTime.now();
    return db.transaction(() async {
      final quotation = await getRfqQuotation(rfqLocalId, quotationId);
      if (quotation == null) {
        throw StateError('Quotation not found.');
      }
      await (db.update(
        db.rfqs,
      )..where((row) => row.localId.equals(rfqLocalId))).write(
        RfqsCompanion(
          status: const Value('COMPLETED'),
          selectedQuotationId: Value(quotationId),
          updatedAt: Value(now),
        ),
      );
    });
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

  Future<void> updatePurchaseRequestWithItems({
    required String requestLocalId,
    required PurchaseRequestsCompanion request,
    required List<PurchaseRequestItemsCompanion> items,
  }) {
    return db.transaction(() async {
      await (db.update(
        db.purchaseRequests,
      )..where((row) => row.localId.equals(requestLocalId))).write(request);
      await (db.delete(
        db.purchaseRequestItems,
      )..where((row) => row.requestLocalId.equals(requestLocalId))).go();
      for (final item in items) {
        await db.into(db.purchaseRequestItems).insert(item);
      }
    });
  }

  Future<void> updatePurchaseRequestLifecycleStatus({
    required String localId,
    required String status,
    required String actorId,
    String? comment,
  }) async {
    final now = DateTime.now();
    final request = await getPurchaseRequest(localId);
    await db.transaction(() async {
      await (db.update(
        db.purchaseRequests,
      )..where((row) => row.localId.equals(localId))).write(
        PurchaseRequestsCompanion(status: Value(status), updatedAt: Value(now)),
      );
      if (request != null) {
        await db
            .into(db.approvalActions)
            .insert(
              ApprovalActionsCompanion.insert(
                localId: _uuid.v4(),
                companyId: request.companyId,
                requestLocalId: localId,
                actorId: actorId,
                action: status,
                comment: Value(comment),
                syncStatus: Value(SyncStatus.synced.storageValue),
                createdAt: now,
                updatedAt: now,
                lastSyncedAt: Value(now),
              ),
            );
      }
    });
  }

  Future<List<ApprovalAction>> getApprovalHistory(String requestLocalId) {
    return (db.select(db.approvalActions)
          ..where((row) => row.requestLocalId.equals(requestLocalId))
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
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
    DateTime? serverUpdatedAt,
  }) async {
    await (db.update(
      db.purchaseRequests,
    )..where((row) => row.localId.equals(localId))).write(
      PurchaseRequestsCompanion(
        serverId: Value(serverId),
        requestNumber: Value(requestNumber),
        syncStatus: Value(SyncStatus.synced.storageValue),
        lastSyncedAt: Value(syncedAt),
        lastKnownServerUpdatedAt: Value(serverUpdatedAt ?? syncedAt),
        lastSyncError: const Value(null),
        isDirty: const Value(false),
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
        lastSyncError: Value(message),
        isDirty: const Value(true),
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

  Future<void> markPurchaseRequestConflict({
    required String localId,
    required String message,
  }) async {
    final now = DateTime.now();
    await (db.update(
      db.purchaseRequests,
    )..where((row) => row.localId.equals(localId))).write(
      PurchaseRequestsCompanion(
        syncStatus: Value(SyncStatus.conflict.storageValue),
        lastSyncError: Value(message),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    final request = await getPurchaseRequest(localId);
    if (request != null) {
      await addSyncLog(
        companyId: request.companyId,
        entityType: 'purchase_request',
        entityLocalId: localId,
        action: 'sync_conflict',
        status: SyncStatus.conflict.storageValue,
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

  Future<DateTime?> getLastSyncAt({
    required String companyId,
    required String scope,
  }) async {
    final row =
        await (db.select(db.syncMetadata)..where(
              (item) =>
                  item.companyId.equals(companyId) & item.scope.equals(scope),
            ))
            .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> setLastSyncAt({
    required String companyId,
    required String scope,
    required DateTime syncedAt,
  }) {
    final now = DateTime.now();
    return db
        .into(db.syncMetadata)
        .insertOnConflictUpdate(
          SyncMetadataCompanion.insert(
            companyId: companyId,
            scope: scope,
            lastSyncedAt: Value(syncedAt),
            updatedAt: now,
          ),
        );
  }

  Future<void> enqueueSyncChange({
    required String companyId,
    required String entityType,
    required String operation,
    required String entityLocalId,
    required String payloadJson,
    String? serverId,
  }) {
    final now = DateTime.now();
    return db
        .into(db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            localId: _uuid.v4(),
            companyId: companyId,
            entityType: entityType,
            operation: operation,
            entityLocalId: entityLocalId,
            serverId: Value(serverId),
            payloadJson: payloadJson,
            createdAt: now,
            updatedAt: now,
          ),
        );
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

  Future<Vendor?> getVendor(String localId) {
    return (db.select(db.vendors)..where(
          (row) => row.localId.equals(localId) & row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
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

  Future<void> insertVendor(VendorsCompanion vendor) {
    return db.into(db.vendors).insert(vendor);
  }

  Future<void> updateVendor(String localId, VendorsCompanion vendor) {
    return (db.update(
      db.vendors,
    )..where((row) => row.localId.equals(localId))).write(vendor);
  }

  Future<void> softDeleteVendor(String localId) {
    final now = DateTime.now();
    return (db.update(
      db.vendors,
    )..where((row) => row.localId.equals(localId))).write(
      VendorsCompanion(isDeleted: const Value(true), updatedAt: Value(now)),
    );
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

  Future<PurchaseOrder?> getPurchaseOrder(String id) {
    return (db.select(db.purchaseOrders)..where(
          (row) =>
              (row.localId.equals(id) | row.serverId.equalsNullable(id)) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<PurchaseOrder?> getPurchaseOrderByQuotationId(String quotationId) {
    return (db.select(db.purchaseOrders)..where(
          (row) =>
              row.quotationId.equals(quotationId) & row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<List<PurchaseOrderItem>> getPurchaseOrderItems(
    String purchaseOrderLocalId,
  ) {
    return (db.select(db.purchaseOrderItems)..where(
          (row) =>
              row.purchaseOrderLocalId.equals(purchaseOrderLocalId) &
              row.isDeleted.equals(false),
        ))
        .get();
  }

  Future<void> createPurchaseOrderFromSelectedQuotation({
    required Rfq rfq,
    required Quotation quotation,
    required List<QuotationItem> items,
    required String createdById,
    String? createdByName,
    String? notes,
  }) async {
    final existing = await getPurchaseOrderByQuotationId(quotation.localId);
    if (existing != null) {
      throw StateError('Purchase order already exists for this quotation.');
    }
    if (rfq.status != 'COMPLETED') {
      throw StateError('RFQ must be completed before creating a PO.');
    }
    if (rfq.selectedQuotationId != quotation.localId &&
        rfq.selectedQuotationId != quotation.serverId) {
      throw StateError('Create a PO from the selected quotation.');
    }

    final now = DateTime.now();
    final poLocalId = _uuid.v4();
    await db.transaction(() async {
      await db
          .into(db.purchaseOrders)
          .insert(
            PurchaseOrdersCompanion.insert(
              localId: poLocalId,
              serverId: Value('mock-po-$poLocalId'),
              companyId: rfq.companyId,
              poNumber: _numberWithPrefix('PO'),
              requestLocalId: Value(rfq.purchaseRequestId),
              purchaseRequestNumber: Value(rfq.purchaseRequestNumber),
              purchaseRequestTitle: Value(rfq.purchaseRequestTitle),
              rfqId: Value(rfq.localId),
              rfqNumber: Value(rfq.rfqNumber),
              quotationId: Value(quotation.localId),
              vendorId: Value(quotation.vendorId),
              vendorName: Value(quotation.vendorName),
              createdById: createdById,
              createdByName: Value(createdByName),
              status: const Value('DRAFT'),
              totalAmount: Value(quotation.totalAmount),
              notes: Value(notes),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
          );
      for (final item in items) {
        final quantity = item.quantity.round();
        await db
            .into(db.purchaseOrderItems)
            .insert(
              PurchaseOrderItemsCompanion.insert(
                localId: _uuid.v4(),
                serverId: Value('mock-po-item-${item.localId}'),
                companyId: rfq.companyId,
                purchaseOrderLocalId: poLocalId,
                rfqItemId: Value(item.rfqItemId),
                itemName: item.itemName,
                quantity: quantity <= 0 ? 1 : quantity,
                unit: const Value('pcs'),
                unitPrice: item.unitPrice,
                lineTotal: item.totalPrice,
                syncStatus: Value(SyncStatus.synced.storageValue),
                createdAt: now,
                updatedAt: now,
                lastSyncedAt: Value(now),
              ),
            );
      }
      await addNotification(
        companyId: rfq.companyId,
        title: 'Purchase order drafted',
        body: 'PO was created from ${rfq.rfqNumber}.',
        route: '/purchase-orders/$poLocalId',
      );
    });
  }

  Future<void> updatePurchaseOrderNotes(String id, String? notes) async {
    final order = await getPurchaseOrder(id);
    if (order == null) throw StateError('Purchase order not found.');
    if (order.status != 'DRAFT') {
      throw StateError('Only draft purchase orders can be edited.');
    }
    await (db.update(
      db.purchaseOrders,
    )..where((row) => row.localId.equals(order.localId))).write(
      PurchaseOrdersCompanion(
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> issuePurchaseOrder(String id) {
    return _transitionPurchaseOrder(
      id: id,
      expectedStatus: 'DRAFT',
      nextStatus: 'ISSUED',
      dateWriter: (now) => PurchaseOrdersCompanion(issueDate: Value(now)),
    );
  }

  Future<void> receivePurchaseOrder(String id) {
    return _transitionPurchaseOrder(
      id: id,
      expectedStatus: 'ISSUED',
      nextStatus: 'RECEIVED',
      dateWriter: (now) => PurchaseOrdersCompanion(receivedDate: Value(now)),
    );
  }

  Future<void> closePurchaseOrder(String id) {
    return _transitionPurchaseOrder(
      id: id,
      expectedStatus: 'RECEIVED',
      nextStatus: 'CLOSED',
      dateWriter: (now) => PurchaseOrdersCompanion(closedDate: Value(now)),
    );
  }

  Future<void> cancelPurchaseOrder(String id) {
    return _transitionPurchaseOrder(
      id: id,
      expectedStatus: 'DRAFT',
      nextStatus: 'CANCELLED',
      dateWriter: (now) => PurchaseOrdersCompanion(cancelledDate: Value(now)),
    );
  }

  Future<void> _transitionPurchaseOrder({
    required String id,
    required String expectedStatus,
    required String nextStatus,
    required PurchaseOrdersCompanion Function(DateTime now) dateWriter,
  }) async {
    final order = await getPurchaseOrder(id);
    if (order == null) throw StateError('Purchase order not found.');
    if (order.status != expectedStatus) {
      throw StateError('Purchase order cannot move to $nextStatus.');
    }
    final now = DateTime.now();
    final dates = dateWriter(now);
    await (db.update(
      db.purchaseOrders,
    )..where((row) => row.localId.equals(order.localId))).write(
      dates.copyWith(status: Value(nextStatus), updatedAt: Value(now)),
    );
  }

  Future<List<Invoice>> getInvoices(String companyId) {
    return (db.select(db.invoices)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<Invoice?> getInvoice(String id) {
    return (db.select(db.invoices)..where(
          (row) =>
              (row.localId.equals(id) | row.serverId.equalsNullable(id)) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<Invoice?> getInvoiceByPurchaseOrderId(String purchaseOrderId) {
    return (db.select(db.invoices)..where(
          (row) =>
              row.purchaseOrderId.equals(purchaseOrderId) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<void> insertInvoice(InvoicesCompanion invoice) async {
    final existing = await getInvoiceByPurchaseOrderId(
      invoice.purchaseOrderId.value,
    );
    if (existing != null) {
      throw StateError('Invoice already exists for this purchase order.');
    }
    await db.transaction(() async {
      await db.into(db.invoices).insert(invoice);
      await addNotification(
        companyId: invoice.companyId.value,
        title: 'Invoice created',
        body: invoice.invoiceNumber.value,
        route: '/invoices/${invoice.localId.value}',
      );
    });
  }

  Future<void> updateInvoice(String id, InvoicesCompanion invoice) async {
    final existing = await getInvoice(id);
    if (existing == null) throw StateError('Invoice not found.');
    if (existing.status != 'PENDING') {
      throw StateError('Only pending invoices can be edited.');
    }
    await (db.update(
      db.invoices,
    )..where((row) => row.localId.equals(existing.localId))).write(invoice);
  }

  Future<void> cancelInvoice(String id) async {
    final existing = await getInvoice(id);
    if (existing == null) throw StateError('Invoice not found.');
    if (existing.status != 'PENDING') {
      throw StateError('Only pending invoices can be cancelled.');
    }
    final now = DateTime.now();
    await (db.update(
      db.invoices,
    )..where((row) => row.localId.equals(existing.localId))).write(
      InvoicesCompanion(
        status: const Value('CANCELLED'),
        cancelledDate: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<Payment>> getPayments(String companyId) {
    return (db.select(db.payments)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.paymentDate)]))
        .get();
  }

  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) {
    return (db.select(db.payments)
          ..where(
            (row) =>
                row.invoiceId.equals(invoiceId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.paymentDate)]))
        .get();
  }

  Future<Payment?> getPayment(String id) {
    return (db.select(db.payments)..where(
          (row) =>
              (row.localId.equals(id) | row.serverId.equalsNullable(id)) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<void> recordPayment(PaymentsCompanion payment) async {
    final invoice = await getInvoice(payment.invoiceId.value);
    if (invoice == null) throw StateError('Invoice not found.');
    final status = invoice.status.trim().toUpperCase().replaceAll('-', '_');
    if (status == 'PAID' || status == 'CANCELLED' || status == 'CANCELED') {
      throw StateError('This invoice is not payable.');
    }
    final amount = payment.amount.value;
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    if (amount > invoice.dueAmount + 0.0001) {
      throw ArgumentError('Payment amount cannot exceed due amount.');
    }

    final paidAmount = invoice.paidAmount + amount;
    final dueAmount = (invoice.invoiceAmount - paidAmount)
        .clamp(0.0, invoice.invoiceAmount)
        .toDouble();
    final nextStatus = dueAmount <= 0.0001
        ? 'PAID'
        : paidAmount > 0
        ? 'PARTIALLY_PAID'
        : 'PENDING';
    final now = DateTime.now();

    await db.transaction(() async {
      await db.into(db.payments).insert(payment);
      await (db.update(
        db.invoices,
      )..where((row) => row.localId.equals(invoice.localId))).write(
        InvoicesCompanion(
          paidAmount: Value(paidAmount),
          dueAmount: Value(dueAmount),
          status: Value(nextStatus),
          updatedAt: Value(now),
        ),
      );
      await addNotification(
        companyId: invoice.companyId,
        title: 'Payment recorded',
        body: invoice.invoiceNumber,
        route: '/invoices/${invoice.localId}/payments',
      );
    });
  }

  Future<List<Budget>> getBudgets(String companyId) {
    return (db.select(db.budgets)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<Budget?> getBudget(String id) {
    return (db.select(db.budgets)..where(
          (row) =>
              (row.localId.equals(id) | row.serverId.equalsNullable(id)) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<void> insertBudget(BudgetsCompanion budget) async {
    await db.transaction(() async {
      await db.into(db.budgets).insert(budget);
      await db
          .into(db.budgetTransactions)
          .insert(
            BudgetTransactionsCompanion.insert(
              localId: _uuid.v4(),
              serverId: Value(
                'mock-budget-transaction-${budget.localId.value}',
              ),
              companyId: budget.companyId.value,
              budgetId: budget.localId.value,
              transactionType: 'ALLOCATION',
              amount: budget.allocatedAmount.value,
              description: const Value('Opening allocation.'),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: budget.createdAt.value,
              updatedAt: budget.updatedAt.value,
              lastSyncedAt: budget.lastSyncedAt,
            ),
          );
    });
  }

  Future<void> updateBudget(String id, BudgetsCompanion budget) async {
    final existing = await getBudget(id);
    if (existing == null) throw StateError('Budget not found.');
    if (existing.status != 'DRAFT') {
      throw StateError('Only draft budgets can be edited.');
    }
    await (db.update(
      db.budgets,
    )..where((row) => row.localId.equals(existing.localId))).write(budget);
  }

  Future<void> activateBudget(String id) async {
    final budget = await getBudget(id);
    if (budget == null) throw StateError('Budget not found.');
    if (budget.status != 'DRAFT') {
      throw StateError('Only draft budgets can be activated.');
    }
    final now = DateTime.now();
    await (db.update(
      db.budgets,
    )..where((row) => row.localId.equals(budget.localId))).write(
      BudgetsCompanion(
        status: const Value('ACTIVE'),
        activatedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> closeBudget(String id) async {
    final budget = await getBudget(id);
    if (budget == null) throw StateError('Budget not found.');
    if (budget.status != 'ACTIVE') {
      throw StateError('Only active budgets can be closed.');
    }
    final now = DateTime.now();
    await (db.update(
      db.budgets,
    )..where((row) => row.localId.equals(budget.localId))).write(
      BudgetsCompanion(
        status: const Value('CLOSED'),
        closedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> addBudgetAdjustment({
    required String id,
    required double amount,
    required String description,
    String? createdById,
    String? createdByName,
  }) async {
    final budget = await getBudget(id);
    if (budget == null) throw StateError('Budget not found.');
    if (budget.status != 'ACTIVE') {
      throw StateError('Only active budgets can be adjusted.');
    }
    final now = DateTime.now();
    final allocatedAmount = budget.allocatedAmount + amount;
    final availableAmount = budget.availableAmount + amount;
    await db.transaction(() async {
      await (db.update(
        db.budgets,
      )..where((row) => row.localId.equals(budget.localId))).write(
        BudgetsCompanion(
          allocatedAmount: Value(allocatedAmount),
          availableAmount: Value(availableAmount),
          updatedAt: Value(now),
        ),
      );
      await db
          .into(db.budgetTransactions)
          .insert(
            BudgetTransactionsCompanion.insert(
              localId: _uuid.v4(),
              serverId: Value('mock-budget-adj-${budget.localId}'),
              companyId: budget.companyId,
              budgetId: budget.localId,
              transactionType: 'ADJUSTMENT',
              amount: amount,
              description: Value(description),
              createdById: Value(createdById),
              createdByName: Value(createdByName),
              syncStatus: Value(SyncStatus.synced.storageValue),
              createdAt: now,
              updatedAt: now,
              lastSyncedAt: Value(now),
            ),
          );
    });
  }

  Future<List<BudgetTransaction>> getBudgetTransactions(String budgetId) {
    return (db.select(db.budgetTransactions)
          ..where(
            (row) =>
                row.budgetId.equals(budgetId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<Budget?> getActiveBudgetForAvailability({
    required String companyId,
    required String departmentId,
    required DateTime date,
  }) {
    return (db.select(db.budgets)..where(
          (row) =>
              row.companyId.equals(companyId) &
              row.departmentId.equals(departmentId) &
              row.status.equals('ACTIVE') &
              row.isDeleted.equals(false) &
              row.periodStartDate.isSmallerOrEqualValue(date) &
              row.periodEndDate.isBiggerOrEqualValue(date),
        ))
        .getSingleOrNull();
  }

  Future<List<Attachment>> getAttachments({
    required String entityType,
    required String entityId,
    int limit = 10,
    int offset = 0,
  }) {
    return (db.select(db.attachments)
          ..where(
            (row) =>
                (row.entityType.equals(entityType) |
                    row.ownerType.equals(entityType)) &
                (row.entityId.equals(entityId) |
                    row.ownerLocalId.equals(entityId)) &
                row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> countAttachments({
    required String entityType,
    required String entityId,
  }) async {
    final expression = db.attachments.localId.count();
    final query = db.selectOnly(db.attachments)
      ..addColumns([expression])
      ..where(
        (db.attachments.entityType.equals(entityType) |
                db.attachments.ownerType.equals(entityType)) &
            (db.attachments.entityId.equals(entityId) |
                db.attachments.ownerLocalId.equals(entityId)) &
            db.attachments.isDeleted.equals(false),
      );
    return query.map((row) => row.read(expression) ?? 0).getSingle();
  }

  Future<Attachment?> getAttachment(String id) {
    return (db.select(db.attachments)..where(
          (row) =>
              (row.localId.equals(id) | row.serverId.equalsNullable(id)) &
              row.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<void> insertAttachment(AttachmentsCompanion attachment) {
    return db.into(db.attachments).insert(attachment);
  }

  Future<void> deleteAttachment(String id) async {
    final attachment = await getAttachment(id);
    if (attachment == null) return;
    await (db.update(
      db.attachments,
    )..where((row) => row.localId.equals(attachment.localId))).write(
      AttachmentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
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

  Future<List<LocalNotification>> getNotifications(
    String companyId, {
    int limit = 10,
    int offset = 0,
  }) {
    return (db.select(db.localNotifications)
          ..where(
            (row) =>
                row.companyId.equals(companyId) & row.isDeleted.equals(false),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> countUnreadNotifications(String companyId) async {
    final expression = db.localNotifications.localId.count();
    final query = db.selectOnly(db.localNotifications)
      ..addColumns([expression])
      ..where(
        db.localNotifications.companyId.equals(companyId) &
            db.localNotifications.isRead.equals(false) &
            db.localNotifications.isDeleted.equals(false),
      );
    return query.map((row) => row.read(expression) ?? 0).getSingle();
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

  Future<void> markNotificationRead(String localId) {
    return (db.update(
      db.localNotifications,
    )..where((row) => row.localId.equals(localId))).write(
      LocalNotificationsCompanion(
        isRead: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAllNotificationsRead(String companyId) {
    return (db.update(
      db.localNotifications,
    )..where((row) => row.companyId.equals(companyId))).write(
      LocalNotificationsCompanion(
        isRead: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String nextPurchaseRequestNumber() => _numberWithPrefix('PR');

  String nextRfqNumber() => _numberWithPrefix('RFQ');

  String nextQuotationNumber() => _numberWithPrefix('QT');

  String _numberWithPrefix(String prefix) {
    final now = DateTime.now();
    return '$prefix-${now.year}${_two(now.month)}${_two(now.day)}'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
