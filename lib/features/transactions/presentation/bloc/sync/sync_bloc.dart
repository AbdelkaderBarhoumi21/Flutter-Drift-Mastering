import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_drift_advanced_project/core/network/network_info.dart';
import 'package:flutter_drift_advanced_project/core/network/sync_engine.dart';
import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/watch_pending_sync_count_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/sync/sync_event.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/sync/sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required this.syncEngine,
    required this.networkInfo,
    required this.watchPendingSyncCountUseCase,
  }) : super(SyncInitial()) {
    on<StartSyncEvent>(_onStartSync);

    // Start watching pending sync count changes
    _startWatching();
  }

  void _startWatching() {
    // Watch pending sync count
    _pendingSubscription = watchPendingSyncCountUseCase
        .watch(const NoParams())
        .listen((pendingCount) {
          add(SyncStatusUpdatedEvent(pendingCount: pendingCount));
        });
    // Watch connectivity
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      isOnline,
    ) {
      add(CheckConnectivityEvent());
    });
  }

  final SyncEngine syncEngine;
  final NetworkInfo networkInfo;
  final WatchPendingSyncCountUseCase watchPendingSyncCountUseCase;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _connectivitySubscription;

  Future<void> _onStartSync(
    StartSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    if (!await networkInfo.isConnected) {
      final currentState = state;
      if (currentState is SyncInProgress) {
        emit(Offline(currentState.pendingCount));
      }
      return;
    }

    emit(const Syncing(totalItems: 0, syncedItems: 0));

    try {
      await syncEngine.sync();
      emit(const SyncSuccess(syncedCount: 0));
    } catch (e) {
      print(e);
    }
  }
}
