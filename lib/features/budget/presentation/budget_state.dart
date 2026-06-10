import 'package:equatable/equatable.dart';

import '../domain/budget_entity.dart';

class BudgetState extends Equatable {
  const BudgetState({
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.filters = const BudgetFilters(),
    this.budgets = const [],
    this.selectedBudget,
    this.transactions = const [],
    this.total = 0,
  });

  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final BudgetFilters filters;
  final List<Budget> budgets;
  final Budget? selectedBudget;
  final List<BudgetTransaction> transactions;
  final int total;

  BudgetState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
    BudgetFilters? filters,
    List<Budget>? budgets,
    Budget? selectedBudget,
    bool clearSelectedBudget = false,
    List<BudgetTransaction>? transactions,
    int? total,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      budgets: budgets ?? this.budgets,
      selectedBudget: clearSelectedBudget
          ? null
          : selectedBudget ?? this.selectedBudget,
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    errorMessage,
    filters,
    budgets,
    selectedBudget,
    transactions,
    total,
  ];
}
