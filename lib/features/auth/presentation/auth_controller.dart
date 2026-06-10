import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

enum AuthStatus {
  unknown,
  loading,
  unauthenticated,
  mustChangePassword,
  authenticated,
  error,
}

class AuthState extends Equatable {
  const AuthState({required this.status, this.session, this.errorMessage});

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isLoading =>
      status == AuthStatus.unknown || status == AuthStatus.loading;

  bool get requiresPasswordChange => status == AuthStatus.mustChangePassword;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    config: ref.watch(appConfigProvider),
    api: ref.watch(procurementApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
    dao: ref.watch(procurementDaoProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(ref.watch(authRepositoryProvider));
    ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      if (previous != null && previous != next) {
        controller.invalidateSession();
      }
    });
    return controller;
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState.unknown());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final session = await _repository.restoreSession();
      state = _stateForSession(session);
    } on Exception catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final session = await _repository.login(email: email, password: password);
      state = _stateForSession(session);
    } on Exception catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentSession = state.session;
    state = AuthState(status: AuthStatus.loading, session: currentSession);
    try {
      final session = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = _stateForSession(session);
    } on Exception catch (error) {
      state = AuthState(
        status: currentSession?.mustChangePassword == true
            ? AuthStatus.mustChangePassword
            : AuthStatus.error,
        session: currentSession,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void invalidateSession() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  AuthState _stateForSession(AuthSession? session) {
    if (session == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    if (session.mustChangePassword) {
      return AuthState(status: AuthStatus.mustChangePassword, session: session);
    }
    return AuthState(status: AuthStatus.authenticated, session: session);
  }

  String _messageFromError(Exception error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('Invalid argument(s): ')) {
      return message.substring('Invalid argument(s): '.length);
    }
    return message;
  }
}
