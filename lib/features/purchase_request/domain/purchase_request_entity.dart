import '../../../core/domain/base_entity.dart';

class PurchaseRequestItemEntity extends SyncableEntity {
  const PurchaseRequestItemEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.requestLocalId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String requestLocalId;
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  @override
  List<Object?> get props => [
    ...super.props,
    requestLocalId,
    name,
    description,
    quantity,
    unitPrice,
    lineTotal,
  ];
}

class PurchaseRequestEntity extends SyncableEntity {
  const PurchaseRequestEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.requestNumber,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.departmentId,
    required this.priority,
    required this.neededDate,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  final String requestNumber;
  final String title;
  final String? description;
  final String requesterId;
  final String? departmentId;
  final String priority;
  final DateTime? neededDate;
  final String status;
  final double totalAmount;
  final List<PurchaseRequestItemEntity> items;

  bool get isApproved => status == 'approved';

  bool get hasPurchaseOrder => status == 'po_created';

  @override
  List<Object?> get props => [
    ...super.props,
    requestNumber,
    title,
    description,
    requesterId,
    departmentId,
    priority,
    neededDate,
    status,
    totalAmount,
    items,
  ];
}

class PurchaseRequestItemInput {
  const PurchaseRequestItemInput({
    required this.name,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

class CreatePurchaseRequestInput {
  const CreatePurchaseRequestInput({
    required this.companyId,
    required this.requesterId,
    required this.title,
    required this.description,
    required this.priority,
    required this.neededDate,
    required this.items,
    required this.forceOffline,
  });

  final String companyId;
  final String requesterId;
  final String title;
  final String? description;
  final String priority;
  final DateTime? neededDate;
  final List<PurchaseRequestItemInput> items;
  final bool forceOffline;

  double get totalAmount {
    return items.fold(0, (total, item) => total + item.lineTotal);
  }
}
