import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'api_endpoints.dart';
import 'api_dtos.dart';

part 'procurement_api.g.dart';

@RestApi()
abstract class ProcurementApi {
  factory ProcurementApi(Dio dio, {String baseUrl}) = _ProcurementApi;

  @POST(ApiEndpoints.authLogin)
  Future<LoginResponseDto> login(@Body() LoginRequestDto request);

  @GET(ApiEndpoints.authMe)
  Future<AuthUserDto> getCurrentUser();

  @GET(ApiEndpoints.authPermissions)
  Future<PermissionsResponseDto> getPermissions();

  @POST(ApiEndpoints.authLogout)
  Future<void> logout();

  @POST(ApiEndpoints.authChangePassword)
  Future<void> changePassword(@Body() ChangePasswordRequestDto request);

  @GET(ApiEndpoints.dashboardSummary)
  Future<DashboardSummaryDto> getDashboardSummary();

  @GET(ApiEndpoints.notificationUnreadCount)
  Future<NotificationUnreadCountDto> getNotificationUnreadCount();

  @GET(ApiEndpoints.notifications)
  Future<NotificationPageDto> getNotifications(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.notificationRead)
  Future<void> markNotificationRead(@Path('id') String id);

  @POST(ApiEndpoints.notificationsReadAll)
  Future<void> markAllNotificationsRead();

  @POST(ApiEndpoints.purchaseRequests)
  Future<PurchaseRequestDto> createPurchaseRequest(
    @Body() PurchaseRequestPayloadDto request,
  );

  @GET(ApiEndpoints.myPurchaseRequests)
  Future<PurchaseRequestPageDto> getMyPurchaseRequests(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('priority') String? priority,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET(ApiEndpoints.purchaseRequestById)
  Future<PurchaseRequestDto> getPurchaseRequest(@Path('id') String id);

  @PATCH(ApiEndpoints.purchaseRequestById)
  Future<PurchaseRequestDto> updatePurchaseRequest(
    @Path('id') String id,
    @Body() PurchaseRequestPayloadDto request,
  );

  @POST(ApiEndpoints.purchaseRequestSubmit)
  Future<PurchaseRequestDto> submitPurchaseRequest(@Path('id') String id);

  @POST(ApiEndpoints.purchaseRequestCancel)
  Future<PurchaseRequestDto> cancelPurchaseRequest(@Path('id') String id);

  @GET(ApiEndpoints.purchaseRequestApprovalHistory)
  Future<ApprovalHistoryResponseDto> getPurchaseRequestApprovalHistory(
    @Path('id') String id,
  );

  @GET(ApiEndpoints.approvalsInbox)
  Future<ApprovalInboxPageDto> getApprovalInbox(
    @Query('search') String? search,
    @Query('priority') String? priority,
    @Query('departmentId') String? departmentId,
    @Query('dateFrom') String? dateFrom,
    @Query('dateTo') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.approvalApprove)
  Future<void> approveRequest(
    @Path('requestId') String requestId,
    @Body() ApprovalDecisionRequestDto request,
  );

  @POST(ApiEndpoints.approvalReject)
  Future<void> rejectRequest(
    @Path('requestId') String requestId,
    @Body() ApprovalDecisionRequestDto request,
  );

  @POST(ApiEndpoints.purchaseRequests)
  Future<PurchaseRequestSyncResponseDto> syncCreatePurchaseRequest(
    @Body() PurchaseRequestSyncRequestDto request,
  );

  @GET(ApiEndpoints.vendors)
  Future<VendorPageDto> getVendors(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.vendors)
  Future<VendorDto> createVendor(@Body() VendorPayloadDto request);

  @GET(ApiEndpoints.vendorById)
  Future<VendorDto> getVendor(@Path('id') String id);

  @PATCH(ApiEndpoints.vendorById)
  Future<VendorDto> updateVendor(
    @Path('id') String id,
    @Body() VendorPayloadDto request,
  );

  @DELETE(ApiEndpoints.vendorById)
  Future<void> deleteVendor(@Path('id') String id);

  @GET(ApiEndpoints.rfqs)
  Future<RfqPageDto> getRfqs(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('purchaseRequestId') String? purchaseRequestId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.rfqs)
  Future<RfqDto> createRfq(@Body() CreateRfqPayloadDto request);

  @GET(ApiEndpoints.rfqById)
  Future<RfqDto> getRfq(@Path('id') String id);

  @POST(ApiEndpoints.rfqVendors)
  Future<RfqDto> assignRfqVendors(
    @Path('id') String id,
    @Body() AssignRfqVendorsPayloadDto request,
  );

  @POST(ApiEndpoints.rfqOpen)
  Future<RfqDto> openRfq(@Path('id') String id);

  @POST(ApiEndpoints.rfqQuotations)
  Future<QuotationDto> createRfqQuotation(
    @Path('id') String id,
    @Body() CreateQuotationPayloadDto request,
  );

  @GET(ApiEndpoints.rfqEligiblePurchaseRequests)
  Future<EligiblePurchaseRequestPageDto> getEligiblePurchaseRequestsForRfq(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET(ApiEndpoints.rfqComparison)
  Future<RfqComparisonDto> getRfqComparison(@Path('id') String id);

  @POST(ApiEndpoints.rfqSelectQuotation)
  Future<RfqDto> selectRfqQuotation(
    @Path('id') String id,
    @Body() SelectedQuotationPayloadDto request,
  );

  @GET(ApiEndpoints.purchaseOrders)
  Future<PurchaseOrderPageDto> getPurchaseOrders(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('vendorId') String? vendorId,
    @Query('purchaseRequestId') String? purchaseRequestId,
    @Query('dateFrom') String? dateFrom,
    @Query('dateTo') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.purchaseOrders)
  Future<PurchaseOrderDto> createPurchaseOrder(
    @Body() CreatePurchaseOrderPayloadDto request,
  );

  @GET(ApiEndpoints.purchaseOrderById)
  Future<PurchaseOrderDto> getPurchaseOrder(@Path('id') String id);

  @PATCH(ApiEndpoints.purchaseOrderById)
  Future<PurchaseOrderDto> updatePurchaseOrder(
    @Path('id') String id,
    @Body() UpdatePurchaseOrderPayloadDto request,
  );

  @POST(ApiEndpoints.purchaseOrderIssue)
  Future<PurchaseOrderDto> issuePurchaseOrder(@Path('id') String id);

  @POST(ApiEndpoints.purchaseOrderReceive)
  Future<PurchaseOrderDto> receivePurchaseOrder(@Path('id') String id);

  @POST(ApiEndpoints.purchaseOrderCancel)
  Future<PurchaseOrderDto> cancelPurchaseOrder(@Path('id') String id);

  @POST(ApiEndpoints.purchaseOrderClose)
  Future<PurchaseOrderDto> closePurchaseOrder(@Path('id') String id);

  @GET(ApiEndpoints.invoices)
  Future<InvoicePageDto> getInvoices(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('vendorId') String? vendorId,
    @Query('purchaseOrderId') String? purchaseOrderId,
    @Query('dateFrom') String? dateFrom,
    @Query('dateTo') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.invoices)
  Future<InvoiceDto> createInvoice(@Body() CreateInvoicePayloadDto request);

  @GET(ApiEndpoints.invoiceById)
  Future<InvoiceDto> getInvoice(@Path('id') String id);

  @PATCH(ApiEndpoints.invoiceById)
  Future<InvoiceDto> updateInvoice(
    @Path('id') String id,
    @Body() UpdateInvoicePayloadDto request,
  );

  @POST(ApiEndpoints.invoiceCancel)
  Future<InvoiceDto> cancelInvoice(@Path('id') String id);

  @GET(ApiEndpoints.payments)
  Future<PaymentPageDto> getPayments(
    @Query('invoiceId') String? invoiceId,
    @Query('vendorId') String? vendorId,
    @Query('paymentMethod') String? paymentMethod,
    @Query('dateFrom') String? dateFrom,
    @Query('dateTo') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.invoicePayments)
  Future<PaymentDto> createInvoicePayment(
    @Path('id') String invoiceId,
    @Body() CreatePaymentPayloadDto request,
  );

  @GET(ApiEndpoints.budgets)
  Future<BudgetPageDto> getBudgets(
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('departmentId') String? departmentId,
    @Query('dateFrom') String? dateFrom,
    @Query('dateTo') String? dateTo,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST(ApiEndpoints.budgets)
  Future<BudgetDto> createBudget(@Body() BudgetPayloadDto request);

  @GET(ApiEndpoints.budgetById)
  Future<BudgetDto> getBudget(@Path('id') String id);

  @PATCH(ApiEndpoints.budgetById)
  Future<BudgetDto> updateBudget(
    @Path('id') String id,
    @Body() BudgetPayloadDto request,
  );

  @POST(ApiEndpoints.budgetActivate)
  Future<BudgetDto> activateBudget(@Path('id') String id);

  @POST(ApiEndpoints.budgetClose)
  Future<BudgetDto> closeBudget(@Path('id') String id);

  @POST(ApiEndpoints.budgetAdjustments)
  Future<BudgetDto> addBudgetAdjustment(
    @Path('id') String id,
    @Body() BudgetAdjustmentPayloadDto request,
  );

  @GET(ApiEndpoints.budgetTransactions)
  Future<BudgetTransactionPageDto> getBudgetTransactions(
    @Path('id') String id,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET(ApiEndpoints.budgetAvailability)
  Future<BudgetAvailabilityDto> getBudgetAvailability(
    @Query('departmentId') String departmentId,
    @Query('amount') double amount,
    @Query('date') String date,
  );

  @GET(ApiEndpoints.reportPurchaseRequests)
  Future<ReportResponseDto> getPurchaseRequestReport(
    @Queries() Map<String, dynamic> queries,
  );

  @GET(ApiEndpoints.reportApprovals)
  Future<ReportResponseDto> getApprovalReport(
    @Queries() Map<String, dynamic> queries,
  );

  @GET(ApiEndpoints.reportPurchaseOrders)
  Future<ReportResponseDto> getPurchaseOrderReport(
    @Queries() Map<String, dynamic> queries,
  );

  @GET(ApiEndpoints.reportInvoices)
  Future<ReportResponseDto> getInvoiceReport(
    @Queries() Map<String, dynamic> queries,
  );

  @GET(ApiEndpoints.reportPayments)
  Future<ReportResponseDto> getPaymentReport(
    @Queries() Map<String, dynamic> queries,
  );

  @GET(ApiEndpoints.attachments)
  Future<AttachmentPageDto> getAttachments(
    @Query('entityType') String entityType,
    @Query('entityId') String entityId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET(ApiEndpoints.attachmentDownloadUrl)
  Future<AttachmentDownloadUrlDto> getAttachmentDownloadUrl(
    @Path('id') String id,
  );

  @DELETE(ApiEndpoints.attachmentById)
  Future<void> deleteAttachment(@Path('id') String id);

  @POST(ApiEndpoints.deviceTokens)
  Future<void> registerDeviceToken(@Body() DeviceTokenPayloadDto request);

  @DELETE(ApiEndpoints.deviceTokenById)
  Future<void> deleteDeviceToken(@Path('deviceId') String deviceId);

  @POST(ApiEndpoints.syncPush)
  Future<SyncPushResponseDto> pushSync(@Body() SyncPushRequestDto request);

  @GET(ApiEndpoints.syncPull)
  Future<SyncPullResponseDto> pullSync(@Query('lastSyncedAt') String? value);
}
