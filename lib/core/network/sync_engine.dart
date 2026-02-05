import 'dart:async';

import 'package:flutter_drift_advanced_project/core/network/network_info.dart';
import 'package:flutter_drift_advanced_project/core/utils/app_logger.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/datasources/transaction_remote_datasource.dart';

class SyncEngine {
  SyncEngine({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.logger,
  });
  final TransactionRemoteDatasource remoteDataSource;
  final TransactionLocalDatasource localDataSource;
  final NetworkInfo networkInfo;
  final AppLogger logger;

  Timer? _syncTimer; // Start sync every 15 min for exp
  StreamSubscription?
  _connectivitySubscription; // Listen to connectivity changes
  bool _isSyncing = false; // Prevent 2 sync at the same time

  /// Start automatic sync
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    logger.info('Starting automatic sync every ${interval.inMinutes} minutes');

    // Periodic sync
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => sync());

    // Sync on connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((
      isConnected,
    ) {
      if (isConnected) {
        logger.info('Network connected - triggering sync');
        sync();
      }
    });

    // Initial sync when ap start instead of waiting for the first timer tick(15 min)
    sync();
  }

  /// Stop automatic sync
  void stopAutoSync() {
    logger.info('Stopping automatic sync');
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Manual sync
  Future<void> sync() async {
    if (_isSyncing) {
      logger.warn('Sync already in progress, skipping');
      return;
    }

    if (!await networkInfo.isConnected) {
      logger.warn('No network connection, skipping sync');
      return;
    }
    _isSyncing = true;
    logger.info('Starting sync process.......');

    try {
      // Get pending transactions
      final pendingTransactions = await localDataSource.getPendingSync();

      if (pendingTransactions.isEmpty) {
        logger.info('No pending transactions to sync');
        return;
      }

      logger.info('Syncing ${pendingTransactions.length} transactions');

      // Sync each transaction
      for (final transaction in pendingTransactions) {
        try {
          if (transaction.isDeleted) {
            // Delete on server
            await remoteDataSource.deleteTransaction(transaction.id);
          } else if (transaction.syncedAt == null) {
            // New transaction - create on server
            await remoteDataSource.createTransaction(transaction);
          } else {
            // Existing transaction - update on server
            await remoteDataSource.updateTransaction(transaction);
          }

          // Mark as synced locally
          await localDataSource.markAsSynced(transaction.id, DateTime.now());
          logger.info('Successfully synced transaction: ${transaction.id}');
        } catch (e) {
          logger.error('Failed to sync transaction: ${transaction.id}', e);
          await localDataSource.markAsFailed(transaction.id);
        }
      }
      logger.info('Sync completed successfully');
    } catch (e) {
      logger.error('Sync failed', e);
    } finally {
      // Execute even success or failure
      _isSyncing = false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}
