import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartSyncEvent extends SyncEvent {}
class StopSyncEvent extends SyncEvent {}