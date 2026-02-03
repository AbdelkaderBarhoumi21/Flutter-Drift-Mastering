import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class GetPendingSyncUseCase
    implements UseCase<List<TransactionEntity>, NoParams> {
  const GetPendingSyncUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<List<TransactionEntity>> call(NoParams params) =>
      repository.getPendingSync();
}
