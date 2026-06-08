import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/dashboard/presentation/dashboard_screen.dart';
import 'package:procurement_management/features/purchase_order/presentation/purchase_order_providers.dart';
import 'package:procurement_management/features/purchase_request/presentation/purchase_request_providers.dart';
import 'package:procurement_management/features/sync/presentation/sync_providers.dart';

class _FakeAuthRepository implements AuthRepository {
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
    roles: ['employee'],
  );
}

void main() {
  testWidgets('dashboard renders enterprise summary', (tester) async {
    final authController = AuthController(_FakeAuthRepository());
    await authController.restoreSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => authController),
          purchaseRequestsProvider.overrideWith((ref) => const Stream.empty()),
          approvalInboxProvider.overrideWith((ref) => const Stream.empty()),
          purchaseOrdersProvider.overrideWith((ref) => const Stream.empty()),
          pendingSyncCountProvider.overrideWith((ref) async => 0),
          onlineStatusProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tanvir'), findsOneWidget);
    expect(find.text('Pending Approvals'), findsOneWidget);
  });
}
