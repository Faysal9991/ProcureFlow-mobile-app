import 'budget_entity.dart';

abstract class BudgetRepository {
  Future<BudgetPage> getBudgets(BudgetFilters filters);

  Future<Budget?> getById(String id);

  Future<Budget> create(BudgetPayload payload);

  Future<Budget> update(String id, BudgetPayload payload);

  Future<Budget> activate(String id);

  Future<Budget> close(String id);

  Future<Budget> addAdjustment(String id, BudgetAdjustmentPayload payload);

  Future<List<BudgetTransaction>> getTransactions(String id);

  Future<BudgetAvailability> checkAvailability({
    required String departmentId,
    required double amount,
    required DateTime date,
  });
}
