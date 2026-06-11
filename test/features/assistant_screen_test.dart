import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/features/assistant/presentation/procurement_assistant_screen.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/domain/permission_policy.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';

const _employeeSession = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Tanvir Hasan',
  email: 'tanvir@example.com',
  companyId: 'company-demo',
  companyName: 'Demo Company',
  roles: ['employee'],
  permissions: [
    AppPermissions.purchaseRequestsView,
    AppPermissions.purchaseRequestsCreate,
  ],
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

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

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return const DashboardSummary(
      cards: [
        DashboardSummaryCard(
          key: 'my_requests',
          label: 'My Requests',
          value: '3',
          requiredPermissions: [AppPermissions.purchaseRequestsView],
        ),
        DashboardSummaryCard(
          key: 'pending_sync',
          label: 'Pending Sync',
          value: '1',
          requiredPermissions: [AppPermissions.purchaseRequestsCreate],
        ),
      ],
      activities: [],
    );
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 0;
}

void main() {
  test('assistant route and quick action follow tenant access rules', () {
    final superAdmin = _employeeSession.copyWith(roles: const ['super_admin']);

    expect(
      PermissionPolicy.canViewRoute(_employeeSession, '/assistant'),
      isTrue,
    );
    expect(PermissionPolicy.canViewRoute(superAdmin, '/assistant'), isFalse);
    expect(
      visibleDashboardQuickActions(
        _employeeSession,
      ).map((action) => action.title),
      contains('AI Assistant'),
    );
    expect(
      visibleDashboardQuickActions(superAdmin).map((action) => action.title),
      isNot(contains('AI Assistant')),
    );
  });

  testWidgets('assistant renders GenUI draft preview from prompt', (
    tester,
  ) async {
    final authController = AuthController(
      _FakeAuthRepository(_employeeSession),
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
        child: const MaterialApp(
          home: ProcurementAssistantScreen(showBottomNavigation: false),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Procurement Assistant'), findsOneWidget);
    expect(find.text('Safe actions'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('assistantPromptField')),
      'Create a laptop request',
    );
    await tester.tap(find.byKey(const Key('assistantSendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Laptop purchase request'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Open request form'), findsWidgets);
  });
}
