import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransactionParams {
  const DeleteTransactionParams({required this.id});
  final String id;
}

class DeleteTransactionUseCase
    implements UseCase<void, DeleteTransactionParams> {
  const DeleteTransactionUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<void> call(DeleteTransactionParams params) =>
      repository.deleteTransaction(params.id);
}
