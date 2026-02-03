import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  // Local operations
  ResultFuture<List<TransactionEntity>> getTransactions();
}
