import 'package:equatable/equatable.dart';

import '../sync/sync_status.dart';

abstract class BaseEntity extends Equatable {
  const BaseEntity({
    required this.localId,
    required this.serverId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String localId;
  final String? serverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [localId, serverId, createdAt, updatedAt];
}

abstract class TenantScopedEntity extends BaseEntity {
  const TenantScopedEntity({
    required super.localId,
    required super.serverId,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
  });

  final String companyId;

  @override
  List<Object?> get props => [...super.props, companyId];
}

abstract class SyncableEntity extends TenantScopedEntity {
  const SyncableEntity({
    required super.localId,
    required super.serverId,
    required super.createdAt,
    required super.updatedAt,
    required super.companyId,
    required this.syncStatus,
    required this.lastSyncedAt,
    required this.isDeleted,
  });

  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool isDeleted;

  bool get needsSync => syncStatus != SyncStatus.synced;

  @override
  List<Object?> get props => [
    ...super.props,
    syncStatus,
    lastSyncedAt,
    isDeleted,
  ];
}
