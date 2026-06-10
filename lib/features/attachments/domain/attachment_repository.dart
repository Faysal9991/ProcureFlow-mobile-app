import 'dart:io';

import 'attachment_entity.dart';

abstract class AttachmentRepository {
  Future<AttachmentPage> getAttachments({
    required String entityType,
    required String entityId,
    int page = 1,
    int limit = 10,
  });

  Future<AttachmentFile> uploadAttachment({
    required String entityType,
    required String entityId,
    required File file,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<String> downloadAttachment({
    required String id,
    required String fileName,
    void Function(int received, int total)? onReceiveProgress,
  });

  Future<void> deleteAttachment(String id);
}
