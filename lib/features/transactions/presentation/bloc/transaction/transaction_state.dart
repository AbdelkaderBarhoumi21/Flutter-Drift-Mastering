import 'package:equatable/equatable.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  const TransactionLoaded({required this.transactions});
  final List<TransactionEntity> transactions;
  @override
  List<Object?> get props => [transactions];
}

class TransactionOperationSuccess extends TransactionState {
  const TransactionOperationSuccess({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class TransactionError extends TransactionState {
  const TransactionError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class SyncConflictState extends TransactionState {
  const SyncConflictState({required this.localData, required this.remoteData});
  final dynamic localData;
  final dynamic remoteData;

  @override
  List<Object?> get props => [localData, remoteData];
}
