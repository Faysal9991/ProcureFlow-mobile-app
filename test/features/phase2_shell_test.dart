import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/app/router/app_router.dart';
import 'package:procurement_management/core/widgets/app_scaffold.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/domain/app_menu_item.dart';
import 'package:procurement_management/features/dashboard/domain/dashboard_repository.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_controller.dart';
import 'package:procurement_management/features/notifications/domain/notification_repository.dart';
import 'package:procurement_management/features/notifications/presentation/notification_controller.dart';
import 'package:procurement_management/features/notifications/presentation/notifications_screen.dart';
import 'package:procurement_management/features/profile/presentation/profile_screen.dart';

const _session = AuthSession(
  accessToken: 'token',
  userId: 'user-1',
  userName: 'Tanvir Hasan',
  email: 'tanvir@example.com',
  companyId: 'company-1',
  companyName: 'Demo Company',
  departmentName: 'Operations',
  roles: ['employee'],
  permissions: ['purchase_requests.view'],
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredSession});

  AuthSession? restoredSession;
  var logoutCalled = false;

  @override
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    restoredSession = _session.copyWith(email: email);
    return restoredSession!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    restoredSession = null;
  }

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary(AuthSession session) async {
    return const DashboardSummary(
      cards: [
        DashboardSummaryCard(
          key: 'my_requests',
          label: 'My Requests',
          value: '1',
          requiredPermissions: ['purchase_requests.view'],
        ),
      ],
      activities: [],
    );
  }

  @override
  Future<int> getUnreadNotificationCount(AuthSession session) async => 2;
}

class _FakeNotificationRepository implements NotificationRepository {
  var unreadCount = 1;
  var markReadCalled = false;
  var markAllReadCalled = false;

  @override
  Future<int> getUnreadCount(AuthSession session) async => unreadCount;

  @override
  Future<NotificationPage> getNotifications(
    AuthSession session, {
    required int page,
    required int limit,
  }) async {
    return NotificationPage(
      items: [
        AppNotification(
          id: 'notification-1',
          title: 'Approval needed',
          message: 'A request is waiting.',
          createdAt: DateTime(2026, 1, 1),
          isRead: unreadCount == 0,
        ),
      ],
      page: page,
      limit: limit,
      total: 1,
    );
  }

  @override
  Future<void> markAllRead(AuthSession session) async {
    markAllReadCalled = true;
    unreadCount = 0;
  }

  @override
  Future<void> markRead(AuthSession session, String id) async {
    markReadCalled = true;
    unreadCount = 0;
  }
}

void main() {
  testWidgets('bottom nav has only Home, Notifications, Profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Requests'), findsNothing);
    expect(find.text('Approvals'), findsNothing);
  });

  testWidgets('app scaffold uses navigation rail on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppScaffold(title: 'Wide Layout', child: Text('Body')),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Wide Layout'), findsOneWidget);
  });

  testWidgets('login redirects to dashboard', (tester) async {
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
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('loginEmailField')),
      'employee@test.com',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('ProcureFlow'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  test('permission menu enables My Requests when permitted', () {
    final items = visiblePhase2MenuItems(_session);

    expect(items.map((item) => item.title), contains('My Requests'));
    expect(items.single.title, 'My Requests');
    expect(items.single.isImplemented, isTrue);
  });

  testWidgets('notifications list can mark one read', (tester) async {
    final repository = _FakeNotificationRepository();
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _session),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: NotificationsScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 unread notification'), findsOneWidget);
    expect(find.text('Approval needed'), findsOneWidget);

    await tester.tap(find.text('Approval needed'));
    await tester.pumpAndSettle();

    expect(repository.markReadCalled, isTrue);
    expect(find.text('0 unread notifications'), findsOneWidget);
  });

  testWidgets('notifications can mark all read', (tester) async {
    final repository = _FakeNotificationRepository();
    final authController = AuthController(
      _FakeAuthRepository(restoredSession: _session),
    );
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: NotificationsScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark all read'));
    await tester.pumpAndSettle();

    expect(repository.markAllReadCalled, isTrue);
    expect(find.text('0 unread notifications'), findsOneWidget);
  });

  testWidgets('profile renders user details and logout clears auth', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(restoredSession: _session);
    final authController = AuthController(repository);
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
        ],
        child: const MaterialApp(
          home: ProfileScreen(showBottomNavigation: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tanvir Hasan'), findsOneWidget);
    expect(find.text('tanvir@example.com'), findsOneWidget);
    expect(find.text('Demo Company'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Logout'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(repository.logoutCalled, isTrue);
    expect(authController.state.isAuthenticated, isFalse);
  });
}
