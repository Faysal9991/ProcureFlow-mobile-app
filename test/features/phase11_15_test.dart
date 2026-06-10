import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart';
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/features/attachments/data/attachment_repository_impl.dart';
import 'package:procurement_management/features/attachments/domain/attachment_entity.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/budget/data/budget_repository_impl.dart';
import 'package:procurement_management/features/budget/domain/budget_entity.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';

class _FakeApi implements ProcurementApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase database;
  late ProcurementDao dao;

  const config = AppConfig(appName: 'Test', apiBaseUrl: '', useMockApi: true);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = ProcurementDao(database);
    await dao.seedDemoData(
      companyId: 'company-demo',
      userId: 'user-demo',
      userName: 'Demo User',
      email: 'demo@example.test',
      roleName: 'finance',
    );
  });

  tearDown(() => database.close());

  test('Phase 11 and 12 menus are enabled for finance/admin permissions', () {
    final session = _session(
      roles: const ['FINANCE'],
      permissions: const ['budgets.view', 'reports.view'],
    );

    final visible = visiblePhase2MenuItems(session).map((item) => item.title);

    expect(visible, contains('Budgets'));
    expect(visible, contains('Reports'));
    expect(
      phase2ModuleMenuItems
          .firstWhere((item) => item.title == 'Budgets')
          .isImplemented,
      isTrue,
    );
    expect(
      phase2ModuleMenuItems
          .firstWhere((item) => item.title == 'Reports')
          .isImplemented,
      isTrue,
    );
  });

  test(
    'mock budget lifecycle creates, activates, adjusts, and closes',
    () async {
      final repository = BudgetRepositoryImpl(
        dao: dao,
        api: _FakeApi(),
        config: config,
      );

      final created = await repository.create(
        BudgetPayload(
          departmentId: 'FINANCE',
          name: 'Finance Custom Budget',
          periodType: BudgetPeriodType.custom,
          periodStartDate: DateTime(2026, 1),
          periodEndDate: DateTime(2026, 12, 31),
          allocatedAmount: 15000,
          notes: 'Test budget',
        ),
      );
      final active = await repository.activate(created.localId);
      final adjusted = await repository.addAdjustment(
        active.localId,
        const BudgetAdjustmentPayload(amount: 500, description: 'Top up'),
      );
      final closed = await repository.close(adjusted.localId);
      final transactions = await repository.getTransactions(closed.localId);

      expect(created.normalizedStatus, BudgetStatus.draft);
      expect(active.normalizedStatus, BudgetStatus.active);
      expect(adjusted.allocatedAmount, 15500);
      expect(closed.normalizedStatus, BudgetStatus.closed);
      expect(transactions, isNotEmpty);
    },
  );

  test('mock attachments upload, list, and delete metadata', () async {
    final repository = AttachmentRepositoryImpl(
      api: _FakeApi(),
      dio: Dio(),
      dao: dao,
      config: config,
    );
    final dir = await Directory.systemTemp.createTemp();
    final file = File('${dir.path}/invoice.pdf');
    await file.writeAsString('demo');

    final uploaded = await repository.uploadAttachment(
      entityType: AttachmentEntityType.invoice,
      entityId: 'invoice-demo-pending',
      file: file,
    );
    final page = await repository.getAttachments(
      entityType: AttachmentEntityType.invoice,
      entityId: 'invoice-demo-pending',
    );
    await repository.deleteAttachment(uploaded.localId);
    final afterDelete = await repository.getAttachments(
      entityType: AttachmentEntityType.invoice,
      entityId: 'invoice-demo-pending',
    );

    expect(page.items.single.fileName, 'invoice.pdf');
    expect(afterDelete.items, isEmpty);
    await dir.delete(recursive: true);
  });

  test(
    'purchase request conflicts are stored without duplicate PR tables',
    () async {
      final now = DateTime(2026);
      await dao.insertPurchaseRequestWithItems(
        request: PurchaseRequestsCompanion.insert(
          localId: 'local-conflict',
          companyId: 'company-demo',
          requestNumber: 'PR-CONFLICT',
          title: 'Conflict draft',
          requesterId: 'user-demo',
          syncStatus: Value(SyncStatus.pendingUpdate.storageValue),
          createdAt: now,
          updatedAt: now,
        ),
        items: const [],
      );

      await dao.markPurchaseRequestConflict(
        localId: 'local-conflict',
        message: 'Server changed.',
      );
      final request = await dao.getPurchaseRequest('local-conflict');

      expect(request?.syncStatus, SyncStatus.conflict.storageValue);
      expect(request?.lastSyncError, 'Server changed.');
      expect(request?.isDirty, isTrue);
    },
  );
}

AuthSession _session({
  required List<String> roles,
  required List<String> permissions,
}) {
  return AuthSession(
    accessToken: 'token',
    userId: 'user-demo',
    userName: 'Demo User',
    email: 'demo@example.test',
    companyId: 'company-demo',
    companyName: 'Demo Company',
    roles: roles,
    permissions: permissions,
  );
}
