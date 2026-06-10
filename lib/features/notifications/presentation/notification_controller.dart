import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../data/notification_repository_impl.dart';
import '../domain/notification_repository.dart';
import 'notification_state.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    config: ref.watch(appConfigProvider),
    api: ref.watch(procurementApiProvider),
    dao: ref.watch(procurementDaoProvider),
  );
});

final notificationControllerProvider =
    StateNotifierProvider.autoDispose<
      NotificationController,
      NotificationState
    >(
      (ref) =>
          NotificationController(ref.watch(notificationRepositoryProvider)),
    );

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._repository) : super(const NotificationState());

  final NotificationRepository _repository;

  Future<void> load(
    AuthSession? session, {
    int page = 1,
    int limit = 10,
  }) async {
    if (session == null) {
      state = const NotificationState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final unreadCount = await _repository.getUnreadCount(session);
      final notifications = await _repository.getNotifications(
        session,
        page: page,
        limit: limit,
      );
      state = NotificationState(
        items: notifications.items,
        unreadCount: unreadCount,
        page: notifications.page,
        limit: notifications.limit,
        total: notifications.total,
      );
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> markRead(AuthSession? session, String id) async {
    if (session == null || state.isMutating) return;
    final item = state.items.where((notification) => notification.id == id);
    if (item.isNotEmpty && item.first.isRead) return;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.markRead(session, id);
      state = state.copyWith(
        isMutating: false,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        items: [
          for (final notification in state.items)
            notification.id == id
                ? notification.copyWith(isRead: true)
                : notification,
        ],
      );
    } on Exception catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> markAllRead(AuthSession? session) async {
    if (session == null || state.isMutating) return;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.markAllRead(session);
      state = state.copyWith(
        isMutating: false,
        unreadCount: 0,
        items: [
          for (final notification in state.items)
            notification.copyWith(isRead: true),
        ],
      );
    } on Exception catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  String _messageFromError(Exception error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
