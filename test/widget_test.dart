import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/features/auth/domain/auth_repository.dart';
import 'package:procurement_management/features/auth/domain/auth_session.dart';
import 'package:procurement_management/features/auth/presentation/auth_controller.dart';
import 'package:procurement_management/features/auth/presentation/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    session = AuthSession(
      accessToken: 'test-token',
      userId: 'user-test',
      userName: 'Test User',
      email: email,
      companyId: 'company-test',
      companyName: 'Test Company',
      roles: const ['employee'],
    );
    return session!;
  }

  @override
  Future<void> logout() async {
    session = null;
  }

  @override
  Future<AuthSession?> restoreSession() async => session;
}

void main() {
  testWidgets('login screen submits through auth controller', (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Procurement Management'), findsOneWidget);
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

    expect(repository.session?.email, 'employee@test.com');
  });
}
