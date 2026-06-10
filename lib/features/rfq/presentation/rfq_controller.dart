import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rfq_entity.dart';
import '../domain/rfq_repository.dart';
import 'rfq_providers.dart';
import 'rfq_state.dart';

final rfqControllerProvider =
    StateNotifierProvider.autoDispose<RfqController, RfqState>((ref) {
      return RfqController(ref.watch(rfqRepositoryProvider));
    });

class RfqController extends StateNotifier<RfqState> {
  RfqController(this._repository) : super(const RfqState());

  final RfqRepository _repository;

  Future<void> loadList([RfqFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getRfqs(nextFilters);
      state = state.copyWith(
        isLoading: false,
        rfqs: page.items,
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
      clearSelectedRfq: true,
    );
    try {
      final rfq = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedRfq: rfq);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadComparison(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearComparison: true,
    );
    try {
      final comparison = await _repository.getComparison(id);
      state = state.copyWith(isLoading: false, comparison: comparison);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadEligiblePurchaseRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final requests = await _repository.getEligiblePurchaseRequests();
      state = state.copyWith(
        isLoading: false,
        eligiblePurchaseRequests: requests,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<Rfq?> createRfq(CreateRfqPayload payload) {
    return _mutate(() => _repository.createRfq(payload));
  }

  Future<Rfq?> assignVendors(String id, AssignRfqVendorsPayload payload) {
    return _mutate(() => _repository.assignVendors(id, payload));
  }

  Future<Rfq?> openRfq(String id) {
    return _mutate(() => _repository.openRfq(id));
  }

  Future<Quotation?> createQuotation(
    String id,
    CreateQuotationPayload payload,
  ) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final quotation = await _repository.createQuotation(id, payload);
      final rfq = await _repository.getById(id);
      state = state.copyWith(isMutating: false, selectedRfq: rfq);
      return quotation;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<Rfq?> selectQuotation(
    String id,
    SelectedQuotationPayload payload,
  ) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final rfq = await _repository.selectQuotation(id, payload);
      final comparison = await _repository.getComparison(id);
      state = state.copyWith(
        isMutating: false,
        selectedRfq: rfq,
        comparison: comparison,
        rfqs: [
          for (final item in state.rfqs)
            if (item.localId == rfq.localId || item.serverId == rfq.serverId)
              rfq
            else
              item,
        ],
      );
      return rfq;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<Rfq?> _mutate(Future<Rfq> Function() action) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final rfq = await action();
      state = state.copyWith(isMutating: false, selectedRfq: rfq);
      return rfq;
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
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    return message;
  }
}
