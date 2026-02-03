import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class GetTransactionByIdParams {
  const GetTransactionByIdParams({required this.id});
  final String id;
}

class GetTransactionByIdUseCase
    implements UseCase<TransactionEntity, GetTransactionByIdParams> {
  const GetTransactionByIdUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<TransactionEntity> call(GetTransactionByIdParams params) =>
      repository.getTransactionsById(params.id);
}
