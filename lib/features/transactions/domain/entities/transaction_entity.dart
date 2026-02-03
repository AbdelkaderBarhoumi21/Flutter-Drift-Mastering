import 'package:equatable/equatable.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/sync_status_enum.dart';

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.isPendingSync,
    required this.isDeleted,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.serverUpdatedAt,
    this.notes,
  });
  TransactionEntity copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? notes,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    DateTime? serverUpdatedAt,
    bool? isPendingSync,
    bool? isDeleted,
  }) => TransactionEntity(
    id: id ?? this.id,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    notes: notes ?? this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt ?? this.syncedAt,
    serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    isPendingSync: isPendingSync ?? this.isPendingSync,
    isDeleted: isDeleted ?? this.isDeleted,
  );

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? serverUpdatedAt;
  final bool isPendingSync;
  final bool isDeleted;
  @override
  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    date,
    categoryId,
    notes,
    syncStatus,
    createdAt,
    updatedAt,
    syncedAt,
    serverUpdatedAt,
    isPendingSync,
    isDeleted,
  ];
}
