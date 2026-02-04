import 'package:dartz/dartz.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';
import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/sync_status_enum.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class ResolveConflictUseCase
    implements UseCase<TransactionEntity, ResolveConflictsParams> {
  const ResolveConflictUseCase({required this.repository});
  final TransactionRepository repository;
  @override
  ResultFuture<TransactionEntity> call(ResolveConflictsParams params) async {
    try {
      TransactionEntity resolvedTransaction;
      switch (params.resolution) {
        case ConflictResolution.keepLocal:
          // keep local version mark for re-sync
          resolvedTransaction = params.localTransaction.copyWith(
            isPendingSync: true,
            syncStatus: SyncStatus.pending,
          );
          break;
        case ConflictResolution.acceptRemote:
          // keep server version, update local
          resolvedTransaction = params.remoteTransaction.copyWith(
            isPendingSync: false,
            syncStatus: SyncStatus.synced,
          );
          break;
        case ConflictResolution.merge:
          // Merge: keep local description/notes, use remote amount/date
          resolvedTransaction = TransactionEntity(
            id: params.localTransaction.id,
            description: params.localTransaction.id,
            amount: params.remoteTransaction.amount,
            date: params.remoteTransaction.date,
            categoryId: params.remoteTransaction.categoryId,
            notes: params.localTransaction.notes,
            isPendingSync: true,
            isDeleted: false,
            syncStatus: SyncStatus.pending,
            createdAt: params.localTransaction.createdAt,
            updatedAt: DateTime.now(),
            serverUpdatedAt: params.remoteTransaction.serverUpdatedAt,
            // syncedAt: null,
          );
          break;
      }
      return repository.updateTransaction(resolvedTransaction);
    } catch (e) {
      return Left(CacheFailure('Failed to resolve conflict: ${e.toString()}'));
    }
  }
}

enum ConflictResolution { keepLocal, acceptRemote, merge }

class ResolveConflictsParams {
  const ResolveConflictsParams({
    required this.localTransaction,
    required this.remoteTransaction,
    required this.resolution,
  });
  final TransactionEntity localTransaction;
  final TransactionEntity remoteTransaction;
  final ConflictResolution resolution;
}
