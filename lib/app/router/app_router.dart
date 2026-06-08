import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/purchase_order/presentation/purchase_order_list_screen.dart';
import '../../features/purchase_request/presentation/create_purchase_request_screen.dart';
import '../../features/purchase_request/presentation/request_details_screen.dart';
import '../../features/quotation/presentation/quotation_compare_screen.dart';
import '../../features/sync/presentation/offline_sync_status_screen.dart';
import '../../features/vendor/presentation/vendor_list_screen.dart';
import 'main_tab_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLogin = state.uri.path == '/login';
      if (authState.status == AuthStatus.unknown) {
        return isLogin ? null : '/login';
      }
      if (!authState.isAuthenticated) {
        return isLogin ? null : '/login';
      }
      if (isLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => _mainTabPage(
          state: state,
          child: const MainTabShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/requests/new',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: const CreatePurchaseRequestScreen(),
        ),
      ),
      GoRoute(
        path: '/requests',
        pageBuilder: (context, state) => _mainTabPage(
          state: state,
          child: const MainTabShell(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: '/requests/:localId',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: RequestDetailsScreen(
            localId: state.pathParameters['localId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/approvals',
        pageBuilder: (context, state) => _mainTabPage(
          state: state,
          child: const MainTabShell(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: '/vendors',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const VendorListScreen()),
      ),
      GoRoute(
        path: '/quotations',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const QuotationCompareScreen()),
      ),
      GoRoute(
        path: '/purchase-orders',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: const PurchaseOrderListScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _mainTabPage(
          state: state,
          child: const MainTabShell(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/sync',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: const OfflineSyncStatusScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _mainTabPage(
          state: state,
          child: const MainTabShell(initialIndex: 4),
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
