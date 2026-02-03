enum SyncStatus {
  pending(0),
  syncing(1),
  synced(2),
  failed(3),
  conflict(4);

  const SyncStatus(this.value);
  final int value;
  static SyncStatus fromValue(int value) =>
      SyncStatus.values.firstWhere((e) => e.value == value);
}
