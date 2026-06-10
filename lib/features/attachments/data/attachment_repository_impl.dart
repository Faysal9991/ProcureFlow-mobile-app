import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_dtos.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/procurement_api.dart';
import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/procurement_dao.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/attachment_entity.dart';
import '../domain/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  AttachmentRepositoryImpl({
    required ProcurementApi api,
    required Dio dio,
    required ProcurementDao dao,
    required AppConfig config,
  }) : _api = api,
       _dio = dio,
       _dao = dao,
       _config = config;

  final ProcurementApi _api;
  final Dio _dio;
  final ProcurementDao _dao;
  final AppConfig _config;
  final Uuid _uuid = const Uuid();

  static const maxFileSize = 10 * 1024 * 1024;
  static const allowedExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
  };

  @override
  Future<AttachmentPage> getAttachments({
    required String entityType,
    required String entityId,
    int page = 1,
    int limit = 10,
  }) async {
    if (_config.useMockApi) {
      final offset = (page - 1) * limit;
      final rows = await _dao.getAttachments(
        entityType: entityType,
        entityId: entityId,
        limit: limit,
        offset: offset,
      );
      final total = await _dao.countAttachments(
        entityType: entityType,
        entityId: entityId,
      );
      return AttachmentPage(
        items: rows.map(_fromRow).toList(),
        page: page,
        limit: limit,
        total: total,
      );
    }
    final response = await _api.getAttachments(
      entityType,
      entityId,
      page,
      limit,
    );
    return AttachmentPage(
      items: response.items.map(_fromDto).toList(),
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  @override
  Future<AttachmentFile> uploadAttachment({
    required String entityType,
    required String entityId,
    required File file,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    await _validateFile(file);
    final now = DateTime.now();
    if (_config.useMockApi) {
      final localId = _uuid.v4();
      await _dao.insertAttachment(
        db.AttachmentsCompanion.insert(
          localId: localId,
          serverId: Value('mock-attachment-$localId'),
          companyId: 'company-demo',
          ownerType: entityType,
          ownerLocalId: entityId,
          entityType: Value(entityType),
          entityId: Value(entityId),
          fileName: p.basename(file.path),
          localPath: Value(file.path),
          mimeType: Value(_mimeType(file.path)),
          fileSize: Value(await file.length()),
          syncStatus: Value(SyncStatus.synced.storageValue),
          createdAt: now,
          updatedAt: now,
          lastSyncedAt: Value(now),
        ),
      );
      return (await getAttachments(
        entityType: entityType,
        entityId: entityId,
      )).items.firstWhere((item) => item.localId == localId);
    }

    final form = FormData.fromMap({
      'entityType': entityType,
      'entityId': entityId,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.attachmentUpload,
      data: form,
      onSendProgress: onSendProgress,
    );
    return _fromDto(AttachmentDto.fromJson(response.data ?? const {}));
  }

  @override
  Future<String> downloadAttachment({
    required String id,
    required String fileName,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
    final path = p.join(dir.path, safeName);

    if (_config.useMockApi) {
      final row = await _dao.getAttachment(id);
      final localPath = row?.localPath;
      if (localPath != null && await File(localPath).exists()) {
        return localPath;
      }
      await File(path).writeAsString('Mock attachment: $fileName');
      return path;
    }

    final url = (await _api.getAttachmentDownloadUrl(id)).url;
    if (url.isEmpty) throw StateError('Download URL is not available.');
    await _dio.download(url, path, onReceiveProgress: onReceiveProgress);
    return path;
  }

  @override
  Future<void> deleteAttachment(String id) async {
    if (_config.useMockApi) {
      await _dao.deleteAttachment(id);
      return;
    }
    await _api.deleteAttachment(id);
  }

  Future<void> _validateFile(File file) async {
    if (!await file.exists()) {
      throw ArgumentError('Selected file does not exist.');
    }
    final size = await file.length();
    if (size > maxFileSize) {
      throw ArgumentError('File must be 10MB or smaller.');
    }
    final extension = p
        .extension(file.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError('Unsupported file type.');
    }
  }

  AttachmentFile _fromDto(AttachmentDto dto) {
    return AttachmentFile(
      localId: dto.id,
      serverId: dto.id,
      companyId: dto.companyId,
      syncStatus: SyncStatus.synced,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      lastSyncedAt: dto.updatedAt,
      isDeleted: false,
      entityType: dto.entityType,
      entityId: dto.entityId,
      fileName: dto.fileName,
      mimeType: dto.mimeType,
      fileSize: dto.fileSize,
      uploadedByName: dto.uploadedByName,
    );
  }

  AttachmentFile _fromRow(db.Attachment row) {
    return AttachmentFile(
      localId: row.localId,
      serverId: row.serverId,
      companyId: row.companyId,
      syncStatus: SyncStatus.fromStorage(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncedAt: row.lastSyncedAt,
      isDeleted: row.isDeleted,
      entityType: row.entityType ?? row.ownerType,
      entityId: row.entityId ?? row.ownerLocalId,
      fileName: row.fileName,
      mimeType: row.mimeType,
      fileSize: row.fileSize ?? 0,
      uploadedByName: row.uploadedByName ?? '',
    );
  }

  String? _mimeType(String path) {
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'csv' => 'text/csv',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => null,
    };
  }
}
