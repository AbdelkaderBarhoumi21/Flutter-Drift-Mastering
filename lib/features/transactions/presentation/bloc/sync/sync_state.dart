import 'package:equatable/equatable.dart';

// App start => state : initial
// Check network => if offline State: Offline(pendingCount: X) (or SyncIdle(... isOnline: false)) , State: SyncIdle(pendingCount: X, isOnline: true)
// User trigger sync or auto sync => State: SyncInProgress(pendingCount: X, isOnline: true)
// During sync => Update progress: Syncing(totalItems: X, syncedItems: 1) , Syncing(totalItems: X, syncedItems: 2) ....
// Sync Done State: SyncSuccess(syncedCount: X) => Return to stable status SyncInProgress(pendingCount: 0, isOnline: true)
abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

// Not syncing right now” (stable/rest state) => I’m ready; here’s current status.
class SyncInProgress extends SyncState {
  const SyncInProgress({required this.pendingCount, required this.isOnline});
  final int pendingCount;
  final bool isOnline;
  @override
  List<Object?> get props => [pendingCount, isOnline];
}

class Syncing extends SyncState {
  const Syncing({required this.totalItems, required this.syncedItems});
  final int totalItems;
  final int syncedItems;

  double get progress => totalItems > 0 ? syncedItems / totalItems : 0.0;
  @override
  List<Object?> get props => [totalItems, syncedItems];
}

class SyncSuccess extends SyncState {
  const SyncSuccess({required this.syncedCount});
  final int syncedCount;
  @override
  List<Object?> get props => [syncedCount];
}

class SyncError extends SyncState {
  const SyncError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class Offline extends SyncState {
  const Offline(this.pendingCount);
  final int pendingCount;

  @override
  List<Object?> get props => [pendingCount];
}
