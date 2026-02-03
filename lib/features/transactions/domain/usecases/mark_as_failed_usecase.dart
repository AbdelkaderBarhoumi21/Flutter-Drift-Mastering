import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class MarkAsFailedParams {
  const MarkAsFailedParams({required this.id});
  final String id;
}

class MarkAsFailedUseCase implements UseCase<void, MarkAsFailedParams> {
  const MarkAsFailedUseCase({required this.repository});
  final TransactionRepository repository;

  @override
  ResultFuture<void> call(MarkAsFailedParams params) =>
      repository.markAsFailed(params.id);
}
