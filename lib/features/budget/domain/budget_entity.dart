import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';

abstract final class BudgetStatus {
  static const draft = 'DRAFT';
  static const active = 'ACTIVE';
  static const closed = 'CLOSED';

  static const values = [draft, active, closed];
}

abstract final class BudgetPeriodType {
  static const monthly = 'MONTHLY';
  static const quarterly = 'QUARTERLY';
  static const yearly = 'YEARLY';
  static const custom = 'CUSTOM';

  static const values = [monthly, quarterly, yearly, custom];
}

String normalizeBudgetStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    BudgetStatus.active => BudgetStatus.active,
    BudgetStatus.closed => BudgetStatus.closed,
    _ => BudgetStatus.draft,
  };
}

String normalizeBudgetPeriodType(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return switch (normalized) {
    BudgetPeriodType.quarterly => BudgetPeriodType.quarterly,
    BudgetPeriodType.yearly || 'ANNUAL' => BudgetPeriodType.yearly,
    BudgetPeriodType.custom => BudgetPeriodType.custom,
    _ => BudgetPeriodType.monthly,
  };
}

class Budget extends SyncableEntity {
  const Budget({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.departmentId,
    required this.departmentName,
    required this.name,
    required this.periodType,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.availableAmount,
    required this.status,
    required this.notes,
    required this.activatedAt,
    required this.closedAt,
  });

  final String departmentId;
  final String departmentName;
  final String name;
  final String periodType;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final double allocatedAmount;
  final double spentAmount;
  final double availableAmount;
  final String status;
  final String? notes;
  final DateTime? activatedAt;
  final DateTime? closedAt;

  String get normalizedStatus => normalizeBudgetStatus(status);

  bool get isDraft => normalizedStatus == BudgetStatus.draft;

  bool get isActive => normalizedStatus == BudgetStatus.active;

  bool get isClosed => normalizedStatus == BudgetStatus.closed;

  @override
  List<Object?> get props => [
    ...super.props,
    departmentId,
    departmentName,
    name,
    periodType,
    periodStartDate,
    periodEndDate,
    allocatedAmount,
    spentAmount,
    availableAmount,
    status,
    notes,
    activatedAt,
    closedAt,
  ];
}

class BudgetPage extends Equatable {
  const BudgetPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Budget> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

class BudgetFilters extends Equatable {
  const BudgetFilters({
    this.search,
    this.status,
    this.departmentId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final String? departmentId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int limit;

  BudgetFilters copyWith({
    String? search,
    bool clearSearch = false,
    String? status,
    bool clearStatus = false,
    String? departmentId,
    bool clearDepartmentId = false,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    int? page,
    int? limit,
  }) {
    return BudgetFilters(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      departmentId: clearDepartmentId
          ? null
          : departmentId ?? this.departmentId,
      dateFrom: clearDateFrom ? null : dateFrom ?? this.dateFrom,
      dateTo: clearDateTo ? null : dateTo ?? this.dateTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    search,
    status,
    departmentId,
    dateFrom,
    dateTo,
    page,
    limit,
  ];
}

class BudgetPayload extends Equatable {
  const BudgetPayload({
    required this.departmentId,
    required this.name,
    required this.periodType,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.allocatedAmount,
    this.notes,
  });

  final String departmentId;
  final String name;
  final String periodType;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final double allocatedAmount;
  final String? notes;

  @override
  List<Object?> get props => [
    departmentId,
    name,
    periodType,
    periodStartDate,
    periodEndDate,
    allocatedAmount,
    notes,
  ];
}

class BudgetAdjustmentPayload extends Equatable {
  const BudgetAdjustmentPayload({
    required this.amount,
    required this.description,
  });

  final double amount;
  final String description;

  @override
  List<Object?> get props => [amount, description];
}

class BudgetTransaction extends Equatable {
  const BudgetTransaction({
    required this.id,
    required this.budgetId,
    required this.transactionType,
    required this.amount,
    required this.description,
    required this.referenceType,
    required this.referenceId,
    required this.createdByName,
    required this.createdAt,
  });

  final String id;
  final String budgetId;
  final String transactionType;
  final double amount;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final String createdByName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    budgetId,
    transactionType,
    amount,
    description,
    referenceType,
    referenceId,
    createdByName,
    createdAt,
  ];
}

class BudgetAvailability extends Equatable {
  const BudgetAvailability({
    required this.available,
    required this.availableAmount,
    required this.message,
  });

  final bool available;
  final double availableAmount;
  final String message;

  @override
  List<Object?> get props => [available, availableAmount, message];
}
