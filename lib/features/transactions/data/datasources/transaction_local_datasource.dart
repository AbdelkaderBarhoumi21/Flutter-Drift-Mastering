import 'package:drift/drift.dart';
import 'package:flutter_drift_advanced_project/core/database/app_database.dart';
import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/sync_status_enum.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> getTransactionById(String id);
  Future<TransactionModel> addTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionModel>>
  getPendingSync(); // SELECT * FROM transactions WHERE isPendingSync = true get all transaction that need to be synced with the sever => called with sync engine
  Future<void> markAsSynced(String id, DateTime serverUpdatedAt);
  Future<void> markAsFailed(String id);
  Stream<List<TransactionModel>> watchTransactions();
  Stream<int> watchPendingSyncCount();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDatasource {
  TransactionLocalDataSourceImpl({required this.database});
  final AppDatabase database;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final results =
          await (database.select(database.transactions)
                ..where((t) => t.isDeleted.equals(false))
                ..orderBy([(t) => OrderingTerm.desc(t.date)]))
              .get();

      return results.map((t) => TransactionModel.fromTable(t)).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final result = await (database.select(
        database.transactions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (result == null) {
        throw const CacheException('Transaction not found');
      }

      return TransactionModel.fromTable(result);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  // INSERT INTO transactions (..,...,...) => SQL
  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      await database
          .into(database.transactions)
          .insert(transaction.toCompanion());
      return transaction;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      await (database.update(database.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(transaction.toCompanion());
      return transaction;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      // Soft delete: mark as deleted and pending sync
      await (database.update(
        database.transactions,
      )..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          isDeleted: const Value(true),
          isPendingSync: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getPendingSync() async {
    try {
      final results = await (database.select(
        database.transactions,
      )..where((t) => t.isPendingSync.equals(true))).get();

      return results.map((t) => TransactionModel.fromTable(t)).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> markAsSynced(String id, DateTime serverUpdatedAt) async {
    try {
      await (database.update(
        database.transactions,
      )..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          syncStatus: Value(SyncStatus.synced.value),
          isPendingSync: const Value(false),
          syncedAt: Value(DateTime.now()),
          serverUpdatedAt: Value(serverUpdatedAt),
        ),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> markAsFailed(String id) async {
    try {
      await (database.update(
        database.transactions,
      )..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(syncStatus: Value(SyncStatus.failed.value)),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    try {
      final results =
          (database.select(database.transactions)
                ..where((t) => t.isDeleted.equals(false))
                ..orderBy([(t) => OrderingTerm.desc(t.date)]))
              .watch();

      return results.map(
        (rows) => rows.map(TransactionModel.fromTable).toList(),
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  // Builds a query that counts how many rows in transactions have is_pending_sync = true.
  // SELECT COUNT(id) AS count FROM transactions WHERE is_pending_sync = 1;
  // watchSingle() => Returns a stream that emits the count each time the result changes.
  // row.read(count) ?? 0 => Reads the count from the row, defaults to 0 if null.
  @override
  Stream<int> watchPendingSyncCount() {
    try {
      final count = database.transactions.id.count();
      return (database.selectOnly(database.transactions)
            ..addColumns([count])
            ..where(database.transactions.isPendingSync.equals(true)))
          .watchSingle()
          .map((row) => row.read(count) ?? 0);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
