import '../sync/sync_summary.dart';
import 'base_entity.dart';

abstract interface class Repository<T extends BaseEntity> {
  Future<List<T>> getAll();

  Future<T?> getById(String localId);
}

abstract interface class SyncableRepository<T extends SyncableEntity>
    implements Repository<T> {
  Future<SyncSummary> syncPending();
}
