import 'package:dartz/dartz.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';
import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransactionParams {
  AddTransactionParams({required this.transaction});
  final TransactionEntity transaction;
}

class AddTransactionUseCase
    implements UseCase<TransactionEntity, AddTransactionParams> {
  AddTransactionUseCase({required this.repository});
  final TransactionRepository repository;
  @override
  ResultFuture<TransactionEntity> call(AddTransactionParams params) async {
    // Validation
    if (params.transaction.description.trim().isEmpty) {
      return const Left(ValidationFailure('Description cannot be empty'));
    }
    if (params.transaction.amount <= 0) {
      return const Left(ValidationFailure('Amount must be greater than 0'));
    }

    return repository.addTransaction(params.transaction);
  }
}
