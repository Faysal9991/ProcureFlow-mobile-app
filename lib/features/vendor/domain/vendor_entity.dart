import 'package:equatable/equatable.dart';

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
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
  });

  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String status;

  String get normalizedStatus => normalizeVendorStatus(status);

  bool get isActive => normalizedStatus == VendorStatus.active;

  @override
  List<Object?> get props => [
    ...super.props,
    name,
    contactPerson,
    email,
    phone,
    address,
    status,
  ];
}

class VendorPayload {
  const VendorPayload({
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.status,
  });

  final String name;
  final String? contactPerson;
  final String phone;
  final String? email;
  final String? address;
  final String status;
}

class VendorFilters extends Equatable {
  const VendorFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 10,
  });

  final String? search;
  final String? status;
  final int page;
  final int limit;

  VendorFilters copyWith({
    String? search,
    String? status,
    int? page,
    int? limit,
    bool clearSearch = false,
    bool clearStatus = false,
  }) {
    return VendorFilters(
      search: clearSearch ? null : search ?? this.search,
      status: clearStatus ? null : status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [search, status, page, limit];
}

class VendorPage extends Equatable {
  const VendorPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<VendorEntity> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}

abstract final class VendorStatus {
  static const active = 'ACTIVE';
  static const inactive = 'INACTIVE';
}

String normalizeVendorStatus(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('-', '_');
  return normalized == VendorStatus.inactive
      ? VendorStatus.inactive
      : VendorStatus.active;
}
