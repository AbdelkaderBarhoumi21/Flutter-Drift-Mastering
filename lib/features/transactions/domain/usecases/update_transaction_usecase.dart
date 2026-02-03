import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransactionParams {
  const UpdateTransactionParams({required this.transaction});
  final TransactionEntity transaction;
}

class UpdateTransactionUseCase
    implements UseCase<TransactionEntity, UpdateTransactionParams> {
  const UpdateTransactionUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<TransactionEntity> call(UpdateTransactionParams params) =>
      repository.updateTransaction(params.transaction);
}
