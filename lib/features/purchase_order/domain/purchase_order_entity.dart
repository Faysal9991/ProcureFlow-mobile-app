import '../../../core/domain/base_entity.dart';

class PurchaseOrderEntity extends SyncableEntity {
  const PurchaseOrderEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.poNumber,
    required this.requestLocalId,
    required this.vendorId,
    required this.createdById,
    required this.status,
    required this.totalAmount,
  });

  final String poNumber;
  final String? requestLocalId;
  final String? vendorId;
  final String createdById;
  final String status;
  final double totalAmount;

  @override
  List<Object?> get props => [
    ...super.props,
    poNumber,
    requestLocalId,
    vendorId,
    createdById,
    status,
    totalAmount,
  ];
}
