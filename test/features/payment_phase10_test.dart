import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/api/api_dtos.dart';
import 'package:procurement_management/core/api/procurement_api.dart';
import 'package:procurement_management/core/config/app_config.dart';
import 'package:procurement_management/core/database/app_database.dart'
    hide Invoice, Payment;
import 'package:procurement_management/core/database/daos/procurement_dao.dart';
import 'package:procurement_management/core/sync/sync_status.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/invoice/data/invoice_repository_impl.dart';
import 'package:procurement_management/features/invoice/data/payment_repository_impl.dart';
import 'package:procurement_management/features/invoice/domain/invoice_entity.dart';
import 'package:procurement_management/features/invoice/domain/invoice_repository.dart';
import 'package:procurement_management/features/invoice/domain/payment_entity.dart';
import 'package:procurement_management/features/invoice/domain/payment_repository.dart';
import 'package:procurement_management/features/invoice/presentation/invoice_details_screen.dart';
import 'package:procurement_management/features/invoice/presentation/invoice_providers.dart';
import 'package:procurement_management/features/invoice/presentation/record_payment_screen.dart';

const _paymentSession = AuthSession(
  accessToken: 'token',
  userId: 'finance-1',
  userName: 'Finance User',
  email: 'finance@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['FINANCE'],
  permissions: ['payments.view', 'payments.create', 'payments.manage'],
);

void main() {
  test('repository sends payment filters and create payload', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _FakePaymentApi();
    final repository = PaymentRepositoryImpl(
      dao: ProcurementDao(database),
      api: api,
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: 'https://api.example.test/api/v1',
        useMockApi: false,
      ),
    );
    addTearDown(database.close);

    await repository.getPayments(
      PaymentFilters(
        invoiceId: ' invoice-1 ',
        vendorId: ' vendor-1 ',
        paymentMethod: PaymentMethod.bankTransfer,
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
        page: 2,
        limit: 25,
      ),
    );
    expect(api.lastListQuery, {
      'invoiceId': 'invoice-1',
      'vendorId': 'vendor-1',
      'paymentMethod': PaymentMethod.bankTransfer,
      'dateFrom': '2026-07-01',
      'dateTo': '2026-07-31',
      'page': 2,
      'limit': 25,
    });

    await repository.getPayments(
      const PaymentFilters(invoiceId: '', vendorId: '', paymentMethod: ''),
    );
    expect(api.lastListQuery?['invoiceId'], isNull);
    expect(api.lastListQuery?['vendorId'], isNull);
    expect(api.lastListQuery?['paymentMethod'], isNull);

    await repository.recordInvoicePayment(
      ' invoice-1 ',
      CreatePaymentPayload(
        paymentDate: DateTime(2026, 7, 5),
        amount: 2360,
        paymentMethod: PaymentMethod.bankTransfer,
        referenceNumber: ' TXN-001 ',
        notes: ' Paid in full. ',
      ),
    );
    expect(api.invoicePaymentId, 'invoice-1');
    expect(api.lastCreatePayload, {
      'paymentDate': '2026-07-05',
      'amount': 2360.0,
      'paymentMethod': PaymentMethod.bankTransfer,
      'referenceNumber': 'TXN-001',
      'notes': 'Paid in full.',
    });
  });

  test('mock mode updates invoice paid, due, and status', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dao = ProcurementDao(database);
    final payments = PaymentRepositoryImpl(
      dao: dao,
      api: _FakePaymentApi(),
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: '',
        useMockApi: true,
      ),
    );
    final invoices = InvoiceRepositoryImpl(
      dao: dao,
      api: _FakePaymentApi(),
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: '',
        useMockApi: true,
      ),
    );
    addTearDown(database.close);

    await dao.seedDemoData(
      companyId: 'company-demo',
      userId: 'finance-1',
      userName: 'Finance User',
      email: 'finance@example.com',
      roleName: 'FINANCE',
    );

    await payments.recordInvoicePayment(
      'invoice-demo-pending',
      CreatePaymentPayload(
        paymentDate: DateTime(2026, 7, 5),
        amount: 500,
        paymentMethod: PaymentMethod.cash,
        referenceNumber: null,
        notes: 'Partial payment.',
      ),
    );
    var invoice = await invoices.getById('invoice-demo-pending');
    expect(invoice?.paidAmount, 500);
    expect(invoice?.dueAmount, 700);
    expect(invoice?.normalizedStatus, InvoiceStatus.partiallyPaid);

    await payments.recordInvoicePayment(
      'invoice-demo-pending',
      CreatePaymentPayload(
        paymentDate: DateTime(2026, 7, 8),
        amount: 700,
        paymentMethod: PaymentMethod.cash,
        referenceNumber: null,
        notes: 'Final payment.',
      ),
    );
    invoice = await invoices.getById('invoice-demo-pending');
    expect(invoice?.paidAmount, 1200);
    expect(invoice?.dueAmount, 0);
    expect(invoice?.normalizedStatus, InvoiceStatus.paid);

    final history = await payments.getPayments(
      const PaymentFilters(invoiceId: 'invoice-demo-pending'),
    );
    expect(history.items, hasLength(2));
  });

  test('payment validation blocks invalid requests', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dao = ProcurementDao(database);
    final repository = PaymentRepositoryImpl(
      dao: dao,
      api: _FakePaymentApi(),
      config: const AppConfig(
        appName: 'Test',
        apiBaseUrl: '',
        useMockApi: true,
      ),
    );
    addTearDown(database.close);

    await dao.seedDemoData(
      companyId: 'company-demo',
      userId: 'finance-1',
      userName: 'Finance User',
      email: 'finance@example.com',
      roleName: 'FINANCE',
    );

    expect(
      repository.recordInvoicePayment(
        'invoice-demo-pending',
        CreatePaymentPayload(
          paymentDate: DateTime(2026, 7, 5),
          amount: 10,
          paymentMethod: PaymentMethod.bankTransfer,
          referenceNumber: null,
          notes: null,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      repository.recordInvoicePayment(
        'invoice-demo-pending',
        CreatePaymentPayload(
          paymentDate: DateTime(2026, 7, 5),
          amount: 1201,
          paymentMethod: PaymentMethod.cash,
          referenceNumber: null,
          notes: null,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      repository.recordInvoicePayment(
        'invoice-demo-partial',
        CreatePaymentPayload(
          paymentDate: DateTime(2026, 7, 5),
          amount: 1401,
          paymentMethod: PaymentMethod.cash,
          referenceNumber: null,
          notes: null,
        ),
      ),
      throwsArgumentError,
    );
  });

  testWidgets(
    'InvoiceDetailsScreen shows payment actions for payable invoices',
    (tester) async {
      final authController = AuthController(
        _FakeAuthRepository(restoredSession: _paymentSession),
      );
      await authController.restoreSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => authController),
            invoiceRepositoryProvider.overrideWithValue(
              _FakeInvoiceRepository(invoice: _invoice()),
            ),
          ],
          child: const MaterialApp(
            home: InvoiceDetailsScreen(
              invoiceId: 'invoice-1',
              showBottomNavigation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('View Payments'), findsOneWidget);
    },
  );

  testWidgets('InvoiceDetailsScreen hides record action for paid invoice', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _paymentSession),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          invoiceRepositoryProvider.overrideWithValue(
            _FakeInvoiceRepository(
              invoice: _invoice(
                status: InvoiceStatus.paid,
                paidAmount: 1200,
                dueAmount: 0,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: InvoiceDetailsScreen(
            invoiceId: 'invoice-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record Payment'), findsNothing);
    expect(find.text('View Payments'), findsOneWidget);
  });

  testWidgets('RecordPaymentScreen validates due amount and reference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _paymentSession),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          invoiceRepositoryProvider.overrideWithValue(
            _FakeInvoiceRepository(invoice: _invoice(dueAmount: 100)),
          ),
          paymentRepositoryProvider.overrideWithValue(_FakePaymentRepository()),
        ],
        child: const MaterialApp(
          home: RecordPaymentScreen(
            invoiceId: 'invoice-1',
            showBottomNavigation: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '150');
    await tester.scrollUntilVisible(
      find.byKey(const Key('submitPaymentButton')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pump();
    expect(find.text('Amount cannot exceed due amount'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('paymentAmountField')), '50');
    await tester.tap(find.byKey(const Key('submitPaymentButton')));
    await tester.pump();
    expect(
      find.text('Reference number is required for non-cash payments'),
      findsOneWidget,
    );
  });
}

class _FakePaymentApi implements ProcurementApi {
  Map<String, Object?>? lastListQuery;
  Map<String, dynamic>? lastCreatePayload;
  String? invoicePaymentId;

  @override
  Future<PaymentPageDto> getPayments(
    String? invoiceId,
    String? vendorId,
    String? paymentMethod,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) async {
    lastListQuery = {
      'invoiceId': invoiceId,
      'vendorId': vendorId,
      'paymentMethod': paymentMethod,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'page': page,
      'limit': limit,
    };
    return PaymentPageDto(
      items: [_paymentDto(invoiceId: invoiceId ?? 'invoice-1')],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<PaymentDto> createInvoicePayment(
    String invoiceId,
    CreatePaymentPayloadDto request,
  ) async {
    invoicePaymentId = invoiceId;
    lastCreatePayload = request.toJson();
    return _paymentDto(
      invoiceId: invoiceId,
      paymentDate: request.paymentDate,
      amount: request.amount,
      paymentMethod: request.paymentMethod,
      referenceNumber: request.referenceNumber,
      notes: request.notes,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<PaymentPage> getPayments(PaymentFilters filters) async {
    return PaymentPage(
      items: [_payment(invoiceId: filters.invoiceId ?? 'invoice-1')],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<Payment?> getById(String id) async => _payment(localId: id);

  @override
  Future<Payment> recordInvoicePayment(
    String invoiceId,
    CreatePaymentPayload payload,
  ) async {
    return _payment(
      invoiceId: invoiceId,
      paymentDate: payload.paymentDate,
      amount: payload.amount,
      paymentMethod: payload.paymentMethod,
      referenceNumber: payload.referenceNumber,
      notes: payload.notes,
    );
  }
}

class _FakeInvoiceRepository implements InvoiceRepository {
  const _FakeInvoiceRepository({required this.invoice});

  final Invoice invoice;

  @override
  Future<Invoice?> getById(String id) async => invoice;

  @override
  Future<InvoicePage> getInvoices(InvoiceFilters filters) async {
    return InvoicePage(
      items: [invoice],
      page: filters.page,
      limit: filters.limit,
      total: 1,
    );
  }

  @override
  Future<Invoice> create(CreateInvoicePayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<Invoice> update(String id, UpdateInvoicePayload payload) {
    throw UnimplementedError();
  }

  @override
  Future<Invoice> cancel(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Invoice?> getByPurchaseOrderId(String purchaseOrderId) async =>
      invoice;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.restoredSession});

  final AuthSession restoredSession;

  @override
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}

Invoice _invoice({
  String localId = 'invoice-1',
  String status = InvoiceStatus.pending,
  double paidAmount = 0,
  double dueAmount = 1200,
}) {
  final now = DateTime(2026, 7);
  return Invoice(
    localId: localId,
    serverId: localId,
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    invoiceNumber: 'INV-2026-001',
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    purchaseOrderId: 'po-1',
    purchaseOrderNumber: 'PO-001',
    status: status,
    invoiceDate: now,
    dueDate: DateTime(2026, 7, 31),
    invoiceAmount: 1200,
    paidAmount: paidAmount,
    dueAmount: dueAmount,
    notes: null,
  );
}

PaymentDto _paymentDto({
  String id = 'payment-1',
  String invoiceId = 'invoice-1',
  DateTime? paymentDate,
  double amount = 500,
  String paymentMethod = PaymentMethod.bankTransfer,
  String? referenceNumber = 'TXN-001',
  String? notes = 'Paid.',
}) {
  final now = DateTime(2026, 7, 5);
  return PaymentDto(
    id: id,
    companyId: 'company-demo',
    invoiceId: invoiceId,
    invoiceNumber: 'INV-2026-001',
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    paymentDate: paymentDate ?? now,
    amount: amount,
    paymentMethod: paymentMethod,
    referenceNumber: referenceNumber,
    notes: notes,
    createdById: 'finance-1',
    createdByName: 'Finance User',
    createdAt: now,
    updatedAt: now,
  );
}

Payment _payment({
  String localId = 'payment-1',
  String invoiceId = 'invoice-1',
  DateTime? paymentDate,
  double amount = 500,
  String paymentMethod = PaymentMethod.bankTransfer,
  String? referenceNumber = 'TXN-001',
  String? notes = 'Paid.',
}) {
  final now = DateTime(2026, 7, 5);
  return Payment(
    localId: localId,
    serverId: localId,
    companyId: 'company-demo',
    syncStatus: SyncStatus.synced,
    createdAt: now,
    updatedAt: now,
    lastSyncedAt: now,
    isDeleted: false,
    invoiceId: invoiceId,
    invoiceNumber: 'INV-2026-001',
    vendorId: 'vendor-1',
    vendorName: 'Best Co',
    paymentDate: paymentDate ?? now,
    amount: amount,
    paymentMethod: paymentMethod,
    referenceNumber: referenceNumber,
    notes: notes,
    createdById: 'finance-1',
    createdByName: 'Finance User',
  );
}
