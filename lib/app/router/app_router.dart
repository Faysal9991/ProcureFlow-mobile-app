import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/procurement_assistant_screen.dart';
import '../../features/approval/presentation/approval_inbox_screen.dart';
import '../../features/auth/domain/permission_policy.dart';
import '../../features/auth/presentation/access_denied_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/budget/presentation/budget_details_screen.dart';
import '../../features/budget/presentation/budget_form_screen.dart';
import '../../features/budget/presentation/budget_list_screen.dart';
import '../../features/budget/presentation/budget_transactions_screen.dart';
import '../../features/invoice/presentation/create_invoice_screen.dart';
import '../../features/invoice/presentation/invoice_details_screen.dart';
import '../../features/invoice/presentation/invoice_edit_screen.dart';
import '../../features/invoice/presentation/invoice_list_screen.dart';
import '../../features/invoice/presentation/invoice_payment_list_screen.dart';
import '../../features/invoice/presentation/payment_list_screen.dart';
import '../../features/invoice/presentation/payment_details_screen.dart';
import '../../features/invoice/presentation/record_payment_screen.dart';
import '../../features/purchase_order/presentation/create_purchase_order_screen.dart';
import '../../features/purchase_order/presentation/purchase_order_details_screen.dart';
import '../../features/purchase_order/presentation/purchase_order_edit_screen.dart';
import '../../features/purchase_order/presentation/purchase_order_list_screen.dart';
import '../../features/purchase_request/presentation/approval_history_screen.dart';
import '../../features/purchase_request/presentation/my_requests_screen.dart';
import '../../features/purchase_request/presentation/purchase_request_details_screen.dart';
import '../../features/purchase_request/presentation/purchase_request_form_screen.dart';
import '../../features/reports/domain/report_entity.dart';
import '../../features/reports/presentation/report_screen.dart';
import '../../features/reports/presentation/reports_home_screen.dart';
import '../../features/rfq/presentation/quotation_details_screen.dart';
import '../../features/rfq/presentation/quotation_entry_screen.dart';
import '../../features/rfq/presentation/rfq_comparison_screen.dart';
import '../../features/rfq/presentation/rfq_create_screen.dart';
import '../../features/rfq/presentation/rfq_details_screen.dart';
import '../../features/rfq/presentation/rfq_list_screen.dart';
import '../../features/rfq/presentation/rfq_vendor_assignment_screen.dart';
import '../../features/sync/presentation/offline_sync_status_screen.dart';
import '../../features/vendor/presentation/vendor_details_screen.dart';
import '../../features/vendor/presentation/vendor_form_screen.dart';
import '../../features/vendor/presentation/vendor_list_screen.dart';
import 'main_tab_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.uri.path;
      final isSplash = path == '/splash';
      final isLogin = path == '/login';
      final isChangePassword = path == '/change-password';

      if (authState.isLoading) {
        return isSplash || isLogin || isChangePassword ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        if (authState.requiresPasswordChange) {
          return isChangePassword ? null : '/change-password';
        }
        return isLogin ? null : '/login';
      }

      if (isSplash || isLogin || isChangePassword) {
        if (PermissionPolicy.getIsSuperAdminOnly(authState.session)) {
          return '/profile';
        }
        return '/dashboard';
      }
      if (path == '/dashboard' &&
          PermissionPolicy.getIsSuperAdminOnly(authState.session)) {
        return '/profile';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => _guardedMainTabPage(
          authState: authState,
          state: state,
          child: const MainTabShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/assistant',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const ProcurementAssistantScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _guardedMainTabPage(
          authState: authState,
          state: state,
          child: const MainTabShell(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _guardedMainTabPage(
          authState: authState,
          state: state,
          child: const MainTabShell(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/approvals',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const ApprovalInboxScreen(),
        ),
      ),
      GoRoute(
        path: '/approvals/:requestId',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PurchaseRequestDetailsScreen(
            requestId: state.pathParameters['requestId'] ?? '',
            approvalMode: true,
          ),
        ),
      ),
      GoRoute(
        path: '/vendors',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const VendorListScreen(),
        ),
      ),
      GoRoute(
        path: '/vendors/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const VendorFormScreen(),
        ),
      ),
      GoRoute(
        path: '/vendors/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: VendorDetailsScreen(
            vendorId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/vendors/:id/edit',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: VendorFormScreen(vendorId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rfqs',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const RfqListScreen(),
        ),
      ),
      GoRoute(
        path: '/rfqs/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const RfqCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/rfqs/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: RfqDetailsScreen(rfqId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rfqs/:id/comparison',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: RfqComparisonScreen(rfqId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rfqs/:id/vendors',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: RfqVendorAssignmentScreen(
            rfqId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/rfqs/:id/quotations',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: QuotationEntryScreen(rfqId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/rfqs/:id/quotations/:quotationId',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: QuotationDetailsScreen(
            rfqId: state.pathParameters['id'] ?? '',
            quotationId: state.pathParameters['quotationId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/purchase-orders',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const PurchaseOrderListScreen(),
        ),
      ),
      GoRoute(
        path: '/purchase-orders/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: CreatePurchaseOrderScreen(
            rfqId: state.uri.queryParameters['rfqId'],
            quotationId: state.uri.queryParameters['quotationId'],
          ),
        ),
      ),
      GoRoute(
        path: '/purchase-orders/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PurchaseOrderDetailsScreen(
            orderId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/purchase-orders/:id/edit',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PurchaseOrderEditScreen(
            orderId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/invoices',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const InvoiceListScreen(),
        ),
      ),
      GoRoute(
        path: '/invoices/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: CreateInvoiceScreen(
            purchaseOrderId: state.uri.queryParameters['purchaseOrderId'],
          ),
        ),
      ),
      GoRoute(
        path: '/invoices/:id/payments',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: InvoicePaymentListScreen(
            invoiceId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/invoices/:id/payments/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: RecordPaymentScreen(
            invoiceId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/invoices/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: InvoiceDetailsScreen(
            invoiceId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/invoices/:id/edit',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: InvoiceEditScreen(invoiceId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/payments',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const PaymentListScreen(),
        ),
      ),
      GoRoute(
        path: '/payments/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PaymentDetailsScreen(
            paymentId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/budgets',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const BudgetListScreen(),
        ),
      ),
      GoRoute(
        path: '/budgets/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const BudgetFormScreen(),
        ),
      ),
      GoRoute(
        path: '/budgets/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: BudgetDetailsScreen(
            budgetId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: BudgetFormScreen(budgetId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/budgets/:id/transactions',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: BudgetTransactionsScreen(
            budgetId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const ReportsHomeScreen(),
        ),
      ),
      for (final reportType in ReportType.values)
        GoRoute(
          path: reportType.route,
          pageBuilder: (context, state) => _guardedFadeSlidePage(
            authState: authState,
            state: state,
            child: ReportScreen(type: reportType),
          ),
        ),
      GoRoute(
        path: '/sync-status',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const OfflineSyncStatusScreen(),
        ),
      ),
      GoRoute(
        path: '/requests',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const MyRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/requests/new',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: const PurchaseRequestFormScreen(),
        ),
      ),
      GoRoute(
        path: '/requests/:id',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PurchaseRequestDetailsScreen(
            requestId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/requests/:id/edit',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: PurchaseRequestFormScreen(
            requestId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/requests/:id/approval-history',
        pageBuilder: (context, state) => _guardedFadeSlidePage(
          authState: authState,
          state: state,
          child: ApprovalHistoryScreen(
            requestId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
    ],
  );
});

NoTransitionPage<void> _mainTabPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(key: const ValueKey('main-tabs'), child: child);
}

NoTransitionPage<void> _guardedMainTabPage({
  required AuthState authState,
  required GoRouterState state,
  required Widget child,
}) {
  final path = state.uri.path;
  return _mainTabPage(
    state: state,
    child: PermissionPolicy.canViewRoute(authState.session, path)
        ? child
        : AccessDeniedScreen(path: path, showBottomNavigation: false),
  );
}

CustomTransitionPage<void> _guardedFadeSlidePage({
  required AuthState authState,
  required GoRouterState state,
  required Widget child,
  bool showBottomNavigation = true,
}) {
  final path = state.uri.path;
  return _fadeSlidePage(
    state: state,
    child: PermissionPolicy.canViewRoute(authState.session, path)
        ? child
        : AccessDeniedScreen(
            path: path,
            showBottomNavigation: showBottomNavigation,
          ),
  );
}

CustomTransitionPage<void> _fadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ColoredBox(
        color: backgroundColor,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.012, 0.018),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
