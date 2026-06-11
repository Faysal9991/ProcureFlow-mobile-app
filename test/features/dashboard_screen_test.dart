import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository([this.session = _employeeSession]);

  final AuthSession session;

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

const _employeeSession = AuthSession(
  accessToken: 'token',
  userId: 'user-employee',
  userName: 'Tanvir Hasan',
  email: 'tanvir@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  departmentName: 'Operations',
  roles: ['employee'],
  permissions: ['purchase_requests.view'],
);

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return DashboardSummary(
      cards: const [
        DashboardSummaryCard(
          key: 'my_requests',
          label: 'My Requests',
          value: '4',
          requiredPermissions: ['purchase_requests.view'],
        ),
        DashboardSummaryCard(
          key: 'purchase_orders',
          label: 'Purchase Orders',
          value: '2',
          requiredPermissions: ['purchase_orders.view'],
        ),
      ],
      activities: [
        DashboardActivity(
          title: 'Welcome',
          message: 'Dashboard ready',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 3;
}

void main() {
  testWidgets('dashboard renders summary and enabled My Requests menu', (
    tester,
  ) async {
    final authController = AuthController(_FakeAuthRepository());
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          dashboardRepositoryProvider.overrideWithValue(
            _FakeDashboardRepository(),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tanvir'), findsOneWidget);
    expect(find.text('ProcureFlow'), findsOneWidget);
    expect(find.text('My Requests'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Purchase Orders'), findsNothing);
    expect(find.text('Coming Soon'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Welcome'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets(
    'dashboard renders explicit permission union for multi-role user',
    (tester) async {
      final authController = AuthController(
        _FakeAuthRepository(
          const AuthSession(
            accessToken: 'token',
            userId: 'user-multi',
            userName: 'Nadia Rahman',
            email: 'nadia@example.com',
            companyId: 'company-demo',
            companyName: 'Demo Company',
            roles: ['PROCUREMENT', 'FINANCE'],
            permissions: [
              'vendors.view',
              'rfq.view',
              'purchase_orders.view',
              'invoices.view',
              'payments.view',
              'budgets.view',
              'reports.view',
            ],
          ),
        ),
      );
      await authController.restoreSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith((ref) => authController),
            dashboardRepositoryProvider.overrideWithValue(
              _FakeDashboardRepository(),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Procurement Officer / Demo Company'), findsOneWidget);
      expect(find.text('Vendors'), findsOneWidget);
      expect(find.text('RFQ'), findsOneWidget);
      expect(find.text('Purchase Orders'), findsWidgets);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('My Requests'), findsNothing);
      expect(find.text('Approvals'), findsNothing);
    },
  );
}
