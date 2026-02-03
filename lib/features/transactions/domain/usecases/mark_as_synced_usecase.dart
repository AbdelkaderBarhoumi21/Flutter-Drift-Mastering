import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class MarkAsSyncedParams {
  const MarkAsSyncedParams({required this.id});
  final String id;
}

class MarkAsSyncedUseCase implements UseCase<void, MarkAsSyncedParams> {
  const MarkAsSyncedUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<void> call(MarkAsSyncedParams params) =>
      repository.markAsSynced(params.id);
}
