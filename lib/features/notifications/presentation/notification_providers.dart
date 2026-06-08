import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/infrastructure_providers.dart';
import '../../auth/presentation/auth_controller.dart';

final notificationsProvider =
    StreamProvider.autoDispose<List<LocalNotification>>((ref) {
      final session = ref.watch(authControllerProvider).session;
      if (session == null) {
        return const Stream.empty();
      }
      return ref
          .watch(procurementDaoProvider)
          .watchNotifications(session.companyId);
    });

final markNotificationsReadProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final session = ref.read(authControllerProvider).session;
    if (session == null) {
      return;
    }
    await ref
        .read(procurementDaoProvider)
        .markAllNotificationsRead(session.companyId);
  };
});
