import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class SyncTransactionsUseCase implements UseCase<void, NoParams> {
  const SyncTransactionsUseCase({required this.repository});
  final TransactionRepository repository;
  @override
  ResultFuture<void> call(NoParams params) => repository.syncTransactions();
}
