import 'package:equatable/equatable.dart';

import '../../../core/domain/base_entity.dart';

abstract final class AttachmentEntityType {
  static const purchaseRequest = 'PURCHASE_REQUEST';
  static const purchaseOrder = 'PURCHASE_ORDER';
  static const invoice = 'INVOICE';
  static const payment = 'PAYMENT';
  static const vendor = 'VENDOR';
  static const rfq = 'RFQ';
}

class AttachmentFile extends SyncableEntity {
  const AttachmentFile({
    required super.localId,
    required super.serverId,
    required super.companyId,
    required super.syncStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.lastSyncedAt,
    required super.isDeleted,
    required this.entityType,
    required this.entityId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedByName,
  });

  final String entityType;
  final String entityId;
  final String fileName;
  final String? mimeType;
  final int fileSize;
  final String uploadedByName;

  @override
  List<Object?> get props => [
    ...super.props,
    entityType,
    entityId,
    fileName,
    mimeType,
    fileSize,
    uploadedByName,
  ];
}

class AttachmentPage extends Equatable {
  const AttachmentPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<AttachmentFile> items;
  final int page;
  final int limit;
  final int total;

  @override
  List<Object?> get props => [items, page, limit, total];
}
