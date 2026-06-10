import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';
import 'budget_providers.dart';
import 'budget_state.dart';

final budgetControllerProvider =
    StateNotifierProvider.autoDispose<BudgetController, BudgetState>((ref) {
      return BudgetController(ref.watch(budgetRepositoryProvider));
    });

class BudgetController extends StateNotifier<BudgetState> {
  BudgetController(this._repository) : super(const BudgetState());

  final BudgetRepository _repository;

  Future<void> loadList([BudgetFilters? filters]) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      filters: nextFilters,
      clearError: true,
    );
    try {
      final page = await _repository.getBudgets(nextFilters);
      state = state.copyWith(
        isLoading: false,
        budgets: page.items,
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
      clearSelectedBudget: true,
    );
    try {
      final budget = await _repository.getById(id);
      state = state.copyWith(isLoading: false, selectedBudget: budget);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> loadTransactions(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final transactions = await _repository.getTransactions(id);
      state = state.copyWith(isLoading: false, transactions: transactions);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<Budget?> create(BudgetPayload payload) {
    return _mutate(() => _repository.create(payload));
  }

  Future<Budget?> update(String id, BudgetPayload payload) {
    return _mutate(() => _repository.update(id, payload));
  }

  Future<Budget?> activate(String id) {
    return _mutate(() => _repository.activate(id));
  }

  Future<Budget?> close(String id) {
    return _mutate(() => _repository.close(id));
  }

  Future<Budget?> addAdjustment(String id, BudgetAdjustmentPayload payload) {
    return _mutate(() => _repository.addAdjustment(id, payload));
  }

  Future<Budget?> _mutate(Future<Budget> Function() action) async {
    if (state.isMutating) return null;
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final budget = await action();
      final items = [
        for (final item in state.budgets)
          if (item.localId == budget.localId ||
              item.serverId == budget.serverId)
            budget
          else
            item,
      ];
      if (!items.any(
        (item) =>
            item.localId == budget.localId || item.serverId == budget.serverId,
      )) {
        items.insert(0, budget);
      }
      state = state.copyWith(
        isMutating: false,
        selectedBudget: budget,
        budgets: items,
      );
      return budget;
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
