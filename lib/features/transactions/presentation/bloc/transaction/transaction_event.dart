import 'package:equatable/equatable.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {}

class AddTransactionEvent extends TransactionEvent {
  const AddTransactionEvent({required this.transaction});
  final TransactionEntity transaction;
  @override
  List<Object?> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionEvent {
  const UpdateTransactionEvent({required this.transaction});
  final TransactionEntity transaction;
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  const DeleteTransactionEvent(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

// Gives users control when they want to force a sync. => call the same syncTransactions()
class SyncRequestedEvent extends TransactionEvent {}
