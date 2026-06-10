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
  Future<AuthSession?> restoreSession() async => const AuthSession(
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
}

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
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Purchase Orders'), findsNothing);
    expect(find.text('Coming Soon'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
  });
}
