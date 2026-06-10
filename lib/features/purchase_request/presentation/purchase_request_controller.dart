import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/purchase_request_entity.dart';
import '../domain/purchase_request_repository.dart';
import 'purchase_request_providers.dart';
import 'purchase_request_state.dart';

final purchaseRequestControllerProvider =
    StateNotifierProvider.autoDispose<
      PurchaseRequestController,
      PurchaseRequestState
    >((ref) {
      return PurchaseRequestController(
        ref.watch(purchaseRequestRepositoryProvider),
      );
    });

class PurchaseRequestController extends StateNotifier<PurchaseRequestState> {
  PurchaseRequestController(this._repository)
    : super(const PurchaseRequestState());

  final PurchaseRequestRepository _repository;

  Future<void> loadList([PurchaseRequestFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getMyRequests(nextFilters);
      state = state.copyWith(
        isLoading: false,
        requests: page.items,
        total: page.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadDetail(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelectedRequest: true,
    );
    try {
      final request = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedRequest: request);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<PurchaseRequestEntity?> saveDraft({
    required PurchaseRequestPayload payload,
    String? id,
  }) async {
    return _mutate(() {
      if (id == null) {
        return _repository.saveDraft(payload);
      }
      return _repository.updateDraft(id, payload);
    });
  }

  Future<PurchaseRequestEntity?> createAndSubmit(
    PurchaseRequestPayload payload,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final draft = await _repository.saveDraft(payload);
      final submitted = await _repository.submit(draft.localId);
      state = state.copyWith(isMutating: false, selectedRequest: submitted);
      return submitted;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<PurchaseRequestEntity?> submit(String id) {
    return _mutate(() => _repository.submit(id));
  }

  Future<PurchaseRequestEntity?> cancel(String id) {
    return _mutate(() => _repository.cancel(id));
  }

  Future<void> loadApprovalHistory(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final history = await _repository.getApprovalHistory(id);
      state = state.copyWith(isLoading: false, approvalHistory: history);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<PurchaseRequestEntity?> _mutate(
    Future<PurchaseRequestEntity> Function() action,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final request = await action();
      state = state.copyWith(isMutating: false, selectedRequest: request);
      return request;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
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
