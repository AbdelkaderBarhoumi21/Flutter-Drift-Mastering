import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/repositories/transaction_repository.dart';

class WatchPendingSyncCountUseCase {
  const WatchPendingSyncCountUseCase({required this.repository});
  final TransactionRepository repository;

  Stream<int> watch(NoParams params) => repository.watchPendingSyncCount();
}
