import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/infrastructure_providers.dart';
import '../data/attachment_repository_impl.dart';
import '../domain/attachment_repository.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepositoryImpl(
    api: ref.watch(procurementApiProvider),
    dio: ref.watch(dioProvider),
    dao: ref.watch(procurementDaoProvider),
    config: ref.watch(appConfigProvider),
  );
});
