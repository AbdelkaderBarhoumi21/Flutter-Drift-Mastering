import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_drift_advanced_project/core/errors/failures.dart';
import 'package:flutter_drift_advanced_project/core/usecase/usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/sync_transactions_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_event.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required this.getTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.syncTransactionsUseCase,
  }) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<SyncRequestedEvent>(_onSyncRequested);
  }
  final GetTransactionsUseCase getTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final SyncTransactionsUseCase syncTransactionsUseCase;

  StreamSubscription? _transactionsSubscription;

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    //  Watch for real-time transactions
    // .watch() => Returns Stream<List<Transaction>>
    await _transactionsSubscription?.cancel();
    _transactionsSubscription = getTransactionsUseCase
        .watch(const NoParams())
        .listen(
          (transactions) {
            emit(TransactionLoaded(transactions: transactions));
          },
          onError: (error) {
            emit(TransactionError(message: error.toString()));
          },
          onDone: () {
            // optional: handle stream completion
          },
        );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await addTransactionUseCase(
      AddTransactionParams(transaction: event.transaction),
    );

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction added successfully',
        ),
      ),
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await updateTransactionUseCase(
      UpdateTransactionParams(transaction: event.transaction),
    );
    result.fold(
      (failure) {
        if (failure is SyncConflictFailure) {
          emit(
            SyncConflictState(
              localData: failure.localData,
              remoteData: failure.remoteData,
            ),
          );
        } else {
          emit(TransactionError(message: _mapFailureToMessage(failure)));
        }
      },
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction updated successfully',
        ),
      ),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await deleteTransactionUseCase(
      DeleteTransactionParams(id: event.id),
    );

    result.fold(
      (failure) =>
          emit(TransactionError(message: _mapFailureToMessage(failure))),
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Transaction deleted successfully',
        ),
      ),
    );
  }

  Future<void> _onSyncRequested(
    SyncRequestedEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await syncTransactionsUseCase(const NoParams());

    result.fold(
      (failure) {
        if (failure is SyncConflictFailure) {
          emit(
            SyncConflictState(
              localData: failure.localData,
              remoteData: failure.remoteData,
            ),
          );
        } else {
          emit(TransactionError(message: _mapFailureToMessage(failure)));
        }
      },
      (_) => emit(
        const TransactionOperationSuccess(
          message: 'Sync completed successfully',
        ),
      ),
    );
  }

  // ServerFailure() (Object Pattern): This tells Dart: "Check if failure is an instance of the class ServerFailure."
  // It is the equivalent of writing if (failure is ServerFailure).
  String _mapFailureToMessage(Failure failure) => switch (failure) {
    ServerFailure() => 'Server Error: ${failure.message}',
    NetworkFailure() => 'Network Error: ${failure.message}',
    CacheFailure() => 'Database Error: ${failure.message}',
    ValidationFailure() => 'Validation Error: ${failure.message}',
    _ => 'Unexpected Error: ${failure.message}', // Default case
  };

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
