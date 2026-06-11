import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:procurement_management/app/router/app_router.dart';
import 'package:procurement_management/features/attachments/domain/attachment_entity.dart';
import 'package:procurement_management/features/attachments/presentation/attachment_section.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/domain/permission_policy.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

  final AuthSession? session;

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
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => session;
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return const DashboardSummary(cards: [], activities: []);
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 0;
}

void main() {
  group('PermissionPolicy', () {
    test('employee can only use own purchase request workflow', () {
      final session = _session(roles: const ['employee']);

      expect(PermissionPolicy.canViewRoute(session, '/requests'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/requests/new'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/vendors'), isFalse);
      expect(PermissionPolicy.canViewRoute(session, '/rfqs'), isFalse);
      expect(PermissionPolicy.canViewRoute(session, '/invoices'), isFalse);
      expect(PermissionPolicy.canUseOfflineSync(session), isTrue);
    });

    test('manager gets approvals but not reports by role fallback', () {
      final session = _session(roles: const ['manager']);

      expect(PermissionPolicy.canViewRoute(session, '/approvals'), isTrue);
      expect(PermissionPolicy.canApprove(session), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/reports'), isFalse);

      final explicitReports = session.copyWith(
        permissions: const [AppPermissions.reportsView],
      );
      expect(
        PermissionPolicy.canViewRoute(explicitReports, '/reports'),
        isTrue,
      );
      expect(PermissionPolicy.canExportReports(explicitReports), isFalse);
    });

    test('procurement can manage sourcing and PO but not finance modules', () {
      final session = _session(roles: const ['procurement']);

      expect(PermissionPolicy.canViewRoute(session, '/vendors'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/rfqs/new'), isTrue);
      expect(
        PermissionPolicy.canViewRoute(session, '/purchase-orders/new'),
        isTrue,
      );
      expect(PermissionPolicy.canViewRoute(session, '/reports'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/invoices'), isFalse);
      expect(PermissionPolicy.canViewRoute(session, '/budgets'), isFalse);
    });

    test('finance can access finance modules and PO detail context only', () {
      final session = _session(roles: const ['finance']);

      expect(PermissionPolicy.canViewRoute(session, '/invoices'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/payments'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/budgets'), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/reports'), isTrue);
      expect(PermissionPolicy.canExportReports(session), isTrue);
      expect(PermissionPolicy.canViewRoute(session, '/approvals'), isFalse);
      expect(
        PermissionPolicy.canViewRoute(session, '/purchase-orders'),
        isFalse,
      );
      expect(
        PermissionPolicy.canViewRoute(session, '/purchase-orders/po-1'),
        isTrue,
      );
    });

    test('company admin gets all tenant modules and super admin gets none', () {
      final companyAdmin = _session(roles: const ['company_admin']);
      final superAdmin = _session(roles: const ['super_admin']);

      expect(PermissionPolicy.canViewRoute(companyAdmin, '/vendors'), isTrue);
      expect(PermissionPolicy.canViewRoute(companyAdmin, '/budgets'), isTrue);
      expect(PermissionPolicy.canViewRoute(superAdmin, '/dashboard'), isFalse);
      expect(PermissionPolicy.canViewRoute(superAdmin, '/profile'), isTrue);
      expect(PermissionPolicy.canViewRoute(superAdmin, '/vendors'), isFalse);
    });
  });

  test('dashboard menu follows role defaults', () {
    expect(
      visiblePhase2MenuItems(
        _session(roles: const ['employee']),
      ).map((item) => item.title),
      ['My Requests'],
    );
    expect(
      visiblePhase2MenuItems(
        _session(roles: const ['manager']),
      ).map((item) => item.title),
      ['Approvals', 'My Requests'],
    );
    expect(
      visiblePhase2MenuItems(
        _session(roles: const ['finance']),
      ).map((item) => item.title),
      ['Invoices', 'Payments', 'Budgets', 'Reports'],
    );
    expect(
      visiblePhase2MenuItems(_session(roles: const ['super_admin'])),
      isEmpty,
    );
  });

  test('dashboard modules use explicit permission union before roles', () {
    final procurementFinance = _session(
      roles: const ['PROCUREMENT', 'FINANCE'],
      permissions: const [
        AppPermissions.vendorsView,
        AppPermissions.rfqView,
        AppPermissions.purchaseOrdersView,
        AppPermissions.invoicesView,
        AppPermissions.paymentsView,
        AppPermissions.budgetsView,
        AppPermissions.reportsView,
      ],
    );

    expect(
      visibleDashboardModules(procurementFinance).map((item) => item.title),
      [
        'Vendors',
        'RFQ',
        'Purchase Orders',
        'Invoices',
        'Payments',
        'Budgets',
        'Reports',
      ],
    );

    final procurementWithoutRfq = _session(
      roles: const ['PROCUREMENT'],
      permissions: const [AppPermissions.invoicesView],
    );

    expect(
      visibleDashboardModules(procurementWithoutRfq).map((item) => item.title),
      ['Invoices'],
    );
  });

  testWidgets('blocked direct route renders access denied screen', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(_session(roles: const ['employee'])),
    );
    await authController.restoreSession();

    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/vendors');
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(
      find.text('You do not have permission to open this page.'),
      findsOneWidget,
    );
  });

  testWidgets('attachment section hides completely when canView is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AttachmentSection(
              entityType: AttachmentEntityType.purchaseRequest,
              entityId: 'request-1',
              canView: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Attachments'), findsNothing);
    expect(find.byKey(const Key('uploadAttachmentButton')), findsNothing);
  });
}

AuthSession _session({
  required List<String> roles,
  List<String> permissions = const [],
}) {
  return AuthSession(
    accessToken: 'token',
    userId: 'user-1',
    userName: 'Demo User',
    email: 'demo@example.test',
    companyId: 'company-demo',
    companyName: 'Demo Company',
    roles: roles,
    permissions: permissions,
  );
}
