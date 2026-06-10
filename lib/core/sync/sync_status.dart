enum SyncStatus {
  pendingCreate('pending_create', 'Pending create'),
  pendingUpdate('pending_update', 'Pending update'),
  pendingDelete('pending_delete', 'Pending delete'),
  synced('synced', 'Synced'),
  syncFailed('sync_failed', 'Sync failed'),
  conflict('conflict', 'Conflict');

  const SyncStatus(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static SyncStatus fromStorage(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => SyncStatus.syncFailed,
    );
  }
}
