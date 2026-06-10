abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authMe = '/auth/me';
  static const authPermissions = '/auth/permissions';
  static const authLogout = '/auth/logout';
  static const authChangePassword = '/auth/change-password';

  static const dashboardSummary = '/dashboard/summary';

  static const notifications = '/notifications';
  static const notificationUnreadCount = '/notifications/unread-count';
  static const notificationRead = '/notifications/{id}/read';
  static const notificationsReadAll = '/notifications/read-all';

  static const purchaseRequests = '/purchase-requests';
  static const myPurchaseRequests = '/purchase-requests/my';
  static const purchaseRequestById = '/purchase-requests/{id}';
  static const purchaseRequestSubmit = '/purchase-requests/{id}/submit';
  static const purchaseRequestCancel = '/purchase-requests/{id}/cancel';
  static const purchaseRequestApprovalHistory =
      '/purchase-requests/{id}/approval-history';

  static const approvalsInbox = '/approvals/inbox';
  static const approvalApprove = '/approvals/{requestId}/approve';
  static const approvalReject = '/approvals/{requestId}/reject';

  static const vendors = '/vendors';
  static const vendorById = '/vendors/{id}';

  static const rfqs = '/rfqs';
  static const rfqById = '/rfqs/{id}';
  static const rfqVendors = '/rfqs/{id}/vendors';
  static const rfqOpen = '/rfqs/{id}/open';
  static const rfqQuotations = '/rfqs/{id}/quotations';
  static const rfqEligiblePurchaseRequests = '/rfqs/eligible-purchase-requests';
  static const rfqComparison = '/rfqs/{id}/comparison';
  static const rfqSelectQuotation = '/rfqs/{id}/select-quotation';

  static const purchaseOrders = '/purchase-orders';
  static const purchaseOrderById = '/purchase-orders/{id}';
  static const purchaseOrderIssue = '/purchase-orders/{id}/issue';
  static const purchaseOrderReceive = '/purchase-orders/{id}/receive';
  static const purchaseOrderCancel = '/purchase-orders/{id}/cancel';
  static const purchaseOrderClose = '/purchase-orders/{id}/close';

  static const invoices = '/invoices';
  static const invoiceById = '/invoices/{id}';
  static const invoiceCancel = '/invoices/{id}/cancel';
  static const invoicePayments = '/invoices/{id}/payments';
  static const payments = '/payments';

  static const budgets = '/budgets';
  static const budgetById = '/budgets/{id}';
  static const budgetActivate = '/budgets/{id}/activate';
  static const budgetClose = '/budgets/{id}/close';
  static const budgetAdjustments = '/budgets/{id}/adjustments';
  static const budgetTransactions = '/budgets/{id}/transactions';
  static const budgetAvailability = '/budgets/availability';

  static const reportPurchaseRequests = '/reports/purchase-requests';
  static const reportPurchaseRequestsExport =
      '/reports/purchase-requests/export';
  static const reportApprovals = '/reports/approvals';
  static const reportApprovalsExport = '/reports/approvals/export';
  static const reportPurchaseOrders = '/reports/purchase-orders';
  static const reportPurchaseOrdersExport = '/reports/purchase-orders/export';
  static const reportInvoices = '/reports/invoices';
  static const reportInvoicesExport = '/reports/invoices/export';
  static const reportPayments = '/reports/payments';
  static const reportPaymentsExport = '/reports/payments/export';

  static const attachmentUpload = '/attachments/upload';
  static const attachments = '/attachments';
  static const attachmentDownloadUrl = '/attachments/{id}/download-url';
  static const attachmentById = '/attachments/{id}';

  static const deviceTokens = '/device-tokens';
  static const deviceTokenById = '/device-tokens/{deviceId}';

  static const syncPull = '/sync/pull';
  static const syncPush = '/sync/push';
}
