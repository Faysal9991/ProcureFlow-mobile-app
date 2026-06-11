import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/infrastructure_providers.dart';
import '../../../core/sync/sync_summary.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../purchase_request/presentation/purchase_request_providers.dart';

final onlineStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return connectivity.onStatusChanged;
});

final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) {
    return 0;
  }
  ref.watch(purchaseRequestsProvider);
  return ref.watch(procurementDaoProvider).countPendingSync(session.companyId);
});

final syncLogsProvider = StreamProvider.autoDispose<List<SyncLog>>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) {
    return const Stream.empty();
  }
  return ref.watch(procurementDaoProvider).watchSyncLogs(session.companyId);
});

final syncControllerProvider =
    StateNotifierProvider.autoDispose<SyncController, AsyncValue<SyncSummary?>>(
      (ref) => SyncController(ref),
    );

class SyncController extends StateNotifier<AsyncValue<SyncSummary?>> {
  SyncController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<SyncSummary?> syncNow() async {
    final session = _ref.read(authControllerProvider).session;
    if (session == null) {
      return null;
    }
    state = const AsyncLoading();
    try {
      final summary = await _ref
          .read(syncServiceProvider)
          .syncPendingPurchaseRequests(session.companyId);
      if (!mounted) return summary;
      _ref.invalidate(pendingSyncCountProvider);
      state = AsyncData(summary);
      return summary;
    } on Exception catch (error, stackTrace) {
      if (!mounted) return null;
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
