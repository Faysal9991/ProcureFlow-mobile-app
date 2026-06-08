import '../../../core/domain/base_entity.dart';

class VendorEntity extends SyncableEntity {
  const VendorEntity({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final bool isActive;

  @override
  List<Object?> get props => [
    ...super.props,
    name,
    email,
    phone,
    address,
    isActive,
  ];
}
