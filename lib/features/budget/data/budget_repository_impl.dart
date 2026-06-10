import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({
    required ProcurementDao dao,
    required ProcurementApi api,
    required AppConfig config,
  }) : _dao = dao,
       _api = api,
       _config = config;

  final ProcurementDao _dao;
  final ProcurementApi _api;
  final AppConfig _config;
  final Uuid _uuid = const Uuid();

  @override
  Future<BudgetPage> getBudgets(BudgetFilters filters) async {
    if (_config.useMockApi) {
      final rows = await _dao.getBudgets('company-demo');
      final filtered = rows
          .map(_fromRow)
          .where((budget) => _matches(budget, filters))
          .toList();
      final start = (filters.page - 1) * filters.limit;
      final items = start >= filtered.length
          ? <Budget>[]
          : filtered.skip(start).take(filters.limit).toList();
      return BudgetPage(
        items: items,
        page: filters.page,
        limit: filters.limit,
        total: filtered.length,
      );
    }

    final response = await _api.getBudgets(
      _searchQuery(filters.search),
      _statusQuery(filters.status),
      _stringQuery(filters.departmentId),
      _dateQuery(filters.dateFrom),
      _dateQuery(filters.dateTo),
      filters.page,
      filters.limit,
    );
    return BudgetPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<Budget?> getById(String id) async {
    if (_config.useMockApi) {
      final row = await _dao.getBudget(id);
      return row == null ? null : _fromRow(row);
    }
    return _fromDto(await _api.getBudget(id));
  }

  @override
  Future<Budget> create(BudgetPayload payload) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      final now = DateTime.now();
      final localId = _uuid.v4();
      await _dao.insertBudget(
        db.BudgetsCompanion.insert(
          localId: localId,
          serverId: Value('mock-budget-$localId'),
          companyId: 'company-demo',
          departmentId: payload.departmentId.trim(),
          departmentName: Value(payload.departmentId.trim()),
          name: payload.name.trim(),
          periodType: Value(normalizeBudgetPeriodType(payload.periodType)),
          periodStartDate: payload.periodStartDate!,
          periodEndDate: payload.periodEndDate!,
          allocatedAmount: payload.allocatedAmount,
          availableAmount: payload.allocatedAmount,
          notes: Value(_blankToNull(payload.notes)),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
      );
      return (await getById(localId))!;
    }

    return _fromDto(await _api.createBudget(_toDto(payload)));
  }

  @override
  Future<Budget> update(String id, BudgetPayload payload) async {
    _validatePayload(payload);
    if (_config.useMockApi) {
      await _dao.updateBudget(
        id,
        db.BudgetsCompanion(
          departmentId: Value(payload.departmentId.trim()),
          departmentName: Value(payload.departmentId.trim()),
          name: Value(payload.name.trim()),
          periodType: Value(normalizeBudgetPeriodType(payload.periodType)),
          periodStartDate: Value(payload.periodStartDate!),
          periodEndDate: Value(payload.periodEndDate!),
          allocatedAmount: Value(payload.allocatedAmount),
          availableAmount: Value(payload.allocatedAmount),
          notes: Value(_blankToNull(payload.notes)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await getById(id))!;
    }
    return _fromDto(await _api.updateBudget(id, _toDto(payload)));
  }

  @override
  Future<Budget> activate(String id) async {
    if (_config.useMockApi) {
      await _dao.activateBudget(id);
      return (await getById(id))!;
    }
    return _fromDto(await _api.activateBudget(id));
  }

  @override
  Future<Budget> close(String id) async {
    if (_config.useMockApi) {
      await _dao.closeBudget(id);
      return (await getById(id))!;
    }
    return _fromDto(await _api.closeBudget(id));
  }

  @override
  Future<Budget> addAdjustment(
    String id,
    BudgetAdjustmentPayload payload,
  ) async {
    if (payload.amount == 0) {
      throw ArgumentError('Adjustment amount cannot be zero.');
    }
    if (payload.description.trim().isEmpty) {
      throw ArgumentError('Adjustment description is required.');
    }
    if (_config.useMockApi) {
      await _dao.addBudgetAdjustment(
        id: id,
        amount: payload.amount,
        description: payload.description.trim(),
      );
      return (await getById(id))!;
    }
    return _fromDto(
      await _api.addBudgetAdjustment(
        id,
        BudgetAdjustmentPayloadDto(
          amount: payload.amount,
          description: payload.description.trim(),
        ),
      ),
    );
  }

  @override
  Future<List<BudgetTransaction>> getTransactions(String id) async {
    if (_config.useMockApi) {
      return (await _dao.getBudgetTransactions(
        id,
      )).map(_transactionRow).toList();
    }
    final response = await _api.getBudgetTransactions(id, 1, 50);
    return response.items.map(_transactionDto).toList();
  }

  @override
  Future<BudgetAvailability> checkAvailability({
    required String departmentId,
    required double amount,
    required DateTime date,
  }) async {
    if (_config.useMockApi) {
      final budget = await _dao.getActiveBudgetForAvailability(
        companyId: 'company-demo',
        departmentId: departmentId,
        date: date,
      );
      if (budget == null) {
        return const BudgetAvailability(
          available: false,
          availableAmount: 0,
          message: 'No active budget found.',
        );
      }
      return BudgetAvailability(
        available: budget.availableAmount >= amount,
        availableAmount: budget.availableAmount,
        message: budget.availableAmount >= amount
            ? 'Budget is available.'
            : 'Budget is insufficient.',
      );
    }
    final response = await _api.getBudgetAvailability(
      departmentId,
      amount,
      _dateQuery(date)!,
    );
    return BudgetAvailability(
      available: response.available,
      availableAmount: response.availableAmount,
      message: response.message,
    );
  }

  BudgetPayloadDto _toDto(BudgetPayload payload) {
    return BudgetPayloadDto(
      departmentId: payload.departmentId.trim(),
      name: payload.name.trim(),
      periodType: normalizeBudgetPeriodType(payload.periodType),
      periodStartDate: payload.periodStartDate!,
      periodEndDate: payload.periodEndDate!,
      allocatedAmount: payload.allocatedAmount,
      notes: _blankToNull(payload.notes),
    );
  }

  void _validatePayload(BudgetPayload payload) {
    if (payload.departmentId.trim().isEmpty) {
      throw ArgumentError('Department is required.');
    }
    if (payload.name.trim().isEmpty) {
      throw ArgumentError('Budget name is required.');
    }
    if (payload.periodStartDate == null) {
      throw ArgumentError('Period start date is required.');
    }
    if (payload.periodEndDate == null) {
      throw ArgumentError('Period end date is required.');
    }
    if (payload.periodEndDate!.isBefore(payload.periodStartDate!)) {
      throw ArgumentError('Period end must be on or after period start.');
    }
    if (payload.allocatedAmount <= 0) {
      throw ArgumentError('Allocated amount must be greater than zero.');
    }
  }

  bool _matches(Budget budget, BudgetFilters filters) {
    final search = _searchQuery(filters.search)?.toLowerCase();
    if (search != null &&
        !budget.name.toLowerCase().contains(search) &&
        !budget.departmentName.toLowerCase().contains(search)) {
      return false;
    }
    if (filters.status != null &&
        filters.status!.trim().isNotEmpty &&
        budget.normalizedStatus != normalizeBudgetStatus(filters.status!)) {
      return false;
    }
    if (filters.departmentId != null &&
        filters.departmentId!.trim().isNotEmpty &&
        budget.departmentId != filters.departmentId!.trim()) {
      return false;
    }
    return true;
  }

  Budget _fromDto(BudgetDto dto) {
    return Budget(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId.isEmpty ? 'remote' : dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      departmentId: dto.departmentId,
      departmentName: dto.departmentName,
      name: dto.name,
      periodType: dto.periodType,
      periodStartDate: dto.periodStartDate,
      periodEndDate: dto.periodEndDate,
      allocatedAmount: dto.allocatedAmount,
      spentAmount: dto.spentAmount,
      availableAmount: dto.availableAmount,
      status: dto.status,
      notes: dto.notes,
      activatedAt: dto.activatedAt,
      closedAt: dto.closedAt,
    );
  }

  Budget _fromRow(db.Budget row) {
    return Budget(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      departmentId: row.departmentId,
      departmentName: row.departmentName ?? row.departmentId,
      name: row.name,
      periodType: row.periodType,
      periodStartDate: row.periodStartDate,
      periodEndDate: row.periodEndDate,
      allocatedAmount: row.allocatedAmount,
      spentAmount: row.spentAmount,
      availableAmount: row.availableAmount,
      status: row.status,
      notes: row.notes,
      activatedAt: row.activatedAt,
      closedAt: row.closedAt,
    );
  }

  BudgetTransaction _transactionDto(BudgetTransactionDto dto) {
    return BudgetTransaction(
      id: dto.id,
      budgetId: dto.budgetId,
      transactionType: dto.transactionType,
      amount: dto.amount,
      description: dto.description,
      referenceType: dto.referenceType,
      referenceId: dto.referenceId,
      createdByName: dto.createdByName,
      createdAt: dto.createdAt,
    );
  }

  BudgetTransaction _transactionRow(db.BudgetTransaction row) {
    return BudgetTransaction(
      id: row.localId,
      budgetId: row.budgetId,
      transactionType: row.transactionType,
      amount: row.amount,
      description: row.description,
      referenceType: row.referenceType,
      referenceId: row.referenceId,
      createdByName: row.createdByName ?? '',
      createdAt: row.createdAt,
    );
  }

  String? _stringQuery(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _searchQuery(String? value) {
    final trimmed = _stringQuery(value);
    if (trimmed == null || trimmed.length < 2) return null;
    return trimmed;
  }

  String? _statusQuery(String? value) {
    final trimmed = _stringQuery(value);
    return trimmed == null ? null : normalizeBudgetStatus(trimmed);
  }

  String? _dateQuery(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
