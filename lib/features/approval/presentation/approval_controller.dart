import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../data/approval_repository_impl.dart';
import '../domain/approval_repository.dart';
import 'approval_state.dart';

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return ApprovalRepositoryImpl(
    config: ref.watch(appConfigProvider),
    api: ref.watch(procurementApiProvider),
    dao: ref.watch(procurementDaoProvider),
  );
});

final approvalControllerProvider =
    StateNotifierProvider.autoDispose<ApprovalController, ApprovalState>(
      (ref) => ApprovalController(ref.watch(approvalRepositoryProvider)),
    );

class ApprovalController extends StateNotifier<ApprovalState> {
  ApprovalController(this._repository) : super(const ApprovalState());

  final ApprovalRepository _repository;

  Future<void> load(
    AuthSession? session, [
    ApprovalInboxFilters? filters,
  ]) async {
    if (session == null) {
      state = const ApprovalState();
      return;
    }

    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getInbox(session, nextFilters);
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        page: page.page,
        limit: page.limit,
        total: page.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> approve(
    AuthSession? session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    return _decide(
      session,
      requestId,
      payload,
      (session, requestId, payload) =>
          _repository.approve(session, requestId, payload),
    );
  }

  Future<bool> reject(
    AuthSession? session,
    String requestId,
    ApprovalDecisionPayload payload,
  ) async {
    return _decide(
      session,
      requestId,
      payload,
      (session, requestId, payload) =>
          _repository.reject(session, requestId, payload),
    );
  }

  Future<bool> _decide(
    AuthSession? session,
    String requestId,
    ApprovalDecisionPayload payload,
    Future<void> Function(
      AuthSession session,
      String requestId,
      ApprovalDecisionPayload payload,
    )
    action,
  ) async {
    if (session == null || state.isMutating) return false;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await action(session, requestId, payload);
      final nextItems = [
        for (final item in state.items)
          if (item.requestId != requestId) item,
      ];
      state = state.copyWith(
        isMutating: false,
        items: nextItems,
        total: state.total > 0 ? state.total - 1 : 0,
      );
      await load(session, state.filters);
      return true;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  String _messageFromError(Object error) {
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
