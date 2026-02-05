import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartSyncEvent extends SyncEvent {}

class StopSyncEvent extends SyncEvent {}

class CheckConnectivityEvent extends SyncEvent {}

class SyncStatusUpdatedEvent extends SyncEvent {
  SyncStatusUpdatedEvent({required this.pendingCount});
  final int pendingCount;
  @override
  List<Object?> get props => [pendingCount];
}
