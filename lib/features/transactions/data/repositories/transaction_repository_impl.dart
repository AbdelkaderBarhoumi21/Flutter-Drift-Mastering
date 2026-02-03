import 'package:dartz/dartz.dart';
import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';
import 'package:flutter_drift_advanced_project/core/network/network_info.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });
  final TransactionLocalDatasource localDataSource;
  final TransactionRemoteDatasource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  ResultFuture<List<TransactionEntity>> getTransactions() async {
    try {
      // The list is always read from the local Drift database, and a background sync process
      // (e.g., WorkManager) periodically fetches the latest server changes and writes them into the local DB
      // Always read from local database (offline-first)
      final models = await localDataSource.getTransactions();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TransactionEntity> getTransactionsById(String id) async {
    try {
      final model = await localDataSource.getTransactionById(id);
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TransactionEntity> addTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final model = await TransactionModel.fromEntity(transaction);
      final savedModel = await localDataSource.addTransaction(model);
      try {
        // Try to sync with server if online
        if (await networkInfo.isConnected) {
          final serverModel = await remoteDataSource.createTransaction(model);
          // UPDATE transactions SET isPendingSync = false,   syncStatus = synced,    serverUpdatedAt = .
          await localDataSource.markAsSynced(
            serverModel.id,
            serverModel.serverUpdatedAt!,
          );
          return Right(serverModel.toEntity());
        }
      } catch (e) {
        // Sync failed, but local save succeeded
        // Will sync later
        return Right(savedModel.toEntity());
      }
      return Right(savedModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TransactionEntity> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      // Update local database first
      final model = TransactionModel.fromEntity(
        transaction,
      ).copyWith(updatedAt: DateTime.now(), isPendingSync: true);

      final updatedModel = await localDataSource.updateTransaction(model);

      // Try to sync with server if online
      if (await networkInfo.isConnected) {
        try {
          final serverModel = await remoteDataSource.updateTransaction(model);
          await localDataSource.markAsSynced(
            serverModel.id,
            serverModel.serverUpdatedAt!,
          );
          return Right(serverModel.toEntity());
        } on SyncConflictException catch (e) {
          // Conflict detected - return conflict failure
          return Left(
            SyncConflictFailure(
              message: e.message,
              localData: e.localData,
              remoteData: e.remoteData,
            ),
          );
        } catch (e) {
          // Sync failed, but local update succeeded
          return Right(updatedModel.toEntity());
        }
      }

      return Right(updatedModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> deleteTransaction(String id) async {
    try {
      // Soft delete in local database
      await localDataSource.deleteTransaction(id);

      // Try to sync deletion with server if online
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.deleteTransaction(id);
        } catch (e) {
          // Sync failed, but local delete succeeded
          // Will sync later
        }
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // performs a sync action. It sends pending local changes to the server, marks them as synced,
  @override
  ResultFuture<void> syncTransactions() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Get pending transactions
      final pendingModels = await localDataSource.getPendingSync();

      if (pendingModels.isEmpty) {
        return const Right(null);
      }

      // Sync with server
      try {
        await remoteDataSource.syncTransactions(pendingModels);

        // Mark all as synced
        for (final model in pendingModels) {
          await localDataSource.markAsSynced(model.id, DateTime.now());
        }

        return const Right(null);
      } on SyncConflictException catch (e) {
        return Left(
          SyncConflictFailure(
            message: e.message,
            localData: e.localData,
            remoteData: e.remoteData,
          ),
        );
      }
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // reads data only. It returns the list of transactions that are still pending sync from the local DB
  @override
  ResultFuture<List<TransactionEntity>> getPendingSync() async {
    try {
      final models = await localDataSource.getPendingSync();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> markAsSynced(String id) async {
    try {
      await localDataSource.markAsSynced(id, DateTime.now());
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> markAsFailed(String id) async {
    try {
      await localDataSource.markAsFailed(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() => localDataSource
      .watchTransactions()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Stream<int> watchPendingSyncCount() =>
      localDataSource.watchPendingSyncCount();
}
