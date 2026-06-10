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
  Future<void> approveRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto request) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> createPurchaseRequest(
    PurchaseRequestPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> cancelPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ApprovalHistoryResponseDto> getPurchaseRequestApprovalHistory(
    String id,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> getPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestPageDto> getMyPurchaseRequests(
    String? search,
    String? status,
    String? priority,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestDto> submitPurchaseRequest(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseRequestSyncResponseDto> syncCreatePurchaseRequest(
    PurchaseRequestSyncRequestDto request,
  ) async {
    return PurchaseRequestSyncResponseDto(
      serverId: 'server-${request.localId}',
      requestNumber: 'PR-SERVER',
      syncedAt: DateTime(2026, 1, 2),
    );
  }

  @override
  Future<PurchaseRequestDto> updatePurchaseRequest(
    String id,
    PurchaseRequestPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VendorDto> createVendor(VendorPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteVendor(String id) {
    throw UnimplementedError();
  }

  @override
  Future<VendorDto> getVendor(String id) {
    throw UnimplementedError();
  }

  @override
  Future<VendorPageDto> getVendors(
    String? search,
    String? status,
    int page,
    int limit,
  ) async {
    return VendorPageDto(items: const [], page: page, limit: limit, total: 0);
  }

  @override
  Future<VendorDto> updateVendor(String id, VendorPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> assignRfqVendors(
    String id,
    AssignRfqVendorsPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> createRfq(CreateRfqPayloadDto request) {
    throw UnimplementedError();
  }

  @override
  Future<QuotationDto> createRfqQuotation(
    String id,
    CreateQuotationPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<EligiblePurchaseRequestPageDto> getEligiblePurchaseRequestsForRfq(
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> getRfq(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqPageDto> getRfqs(
    String? search,
    String? status,
    String? purchaseRequestId,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> openRfq(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqComparisonDto> getRfqComparison(String id) {
    throw UnimplementedError();
  }

  @override
  Future<RfqDto> selectRfqQuotation(
    String id,
    SelectedQuotationPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> cancelPurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> closePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> createPurchaseOrder(
    CreatePurchaseOrderPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> getPurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderPageDto> getPurchaseOrders(
    String? search,
    String? status,
    String? vendorId,
    String? purchaseRequestId,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> issuePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> receivePurchaseOrder(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PurchaseOrderDto> updatePurchaseOrder(
    String id,
    UpdatePurchaseOrderPayloadDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<DashboardSummaryDto> getDashboardSummary() {
    throw UnimplementedError();
  }

  @override
  Future<ApprovalInboxPageDto> getApprovalInbox(
    String? search,
    String? priority,
    String? departmentId,
    String? dateFrom,
    String? dateTo,
    int page,
    int limit,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUserDto> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<NotificationPageDto> getNotifications(int page, int limit) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationUnreadCountDto> getNotificationUnreadCount() {
    throw UnimplementedError();
  }

  @override
  Future<PermissionsResponseDto> getPermissions() {
    throw UnimplementedError();
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> markAllNotificationsRead() {
    throw UnimplementedError();
  }

  @override
  Future<void> markNotificationRead(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectRequest(
    String requestId,
    ApprovalDecisionRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
