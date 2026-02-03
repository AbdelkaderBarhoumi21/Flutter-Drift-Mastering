import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  // Local operations
  ResultFuture<List<TransactionEntity>> getTransactions();
  ResultFuture<TransactionEntity> getTransactionsById(String id);
  ResultFuture<TransactionEntity> addTransaction(TransactionEntity transaction);
  ResultFuture<TransactionEntity> updateTransaction(
    TransactionEntity transaction,
  );
  ResultFuture<void> deleteTransaction(String id);

  // Sync operations
  ResultFuture<void> syncTransactions();
  ResultFuture<List<TransactionEntity>> getPendingSync();
  ResultFuture<void> markAsSynced(String id);
  ResultFuture<void> markAsFailed(String id);

  // Stream operations
  Stream<List<TransactionEntity>> watchTransactions();
  Stream<int> watchPendingSyncCount();
}
