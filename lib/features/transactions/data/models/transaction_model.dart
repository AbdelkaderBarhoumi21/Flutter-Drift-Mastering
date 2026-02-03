import 'package:drift/drift.dart';
import 'package:flutter_drift_advanced_project/core/database/app_database.dart';
import 'package:flutter_drift_advanced_project/core/utils/typedef.dart';
import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/sync_status_enum.dart';

import 'package:flutter_drift_advanced_project/features/transactions/domain/entities/transaction_entity.dart';

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.isPendingSync,
    required this.isDeleted,
    this.notes,
    this.syncedAt,
    this.serverUpdatedAt,
  });

  // From Drift table to Model
  factory TransactionModel.fromTable(TransactionTable table) =>
      TransactionModel(
        id: table.id,
        description: table.description,
        amount: table.amount,
        date: table.date,
        categoryId: table.categoryId,
        notes: table.notes,
        syncStatus: table.syncStatus,
        createdAt: table.createdAt,
        updatedAt: table.updatedAt,
        syncedAt: table.syncedAt,
        serverUpdatedAt: table.serverUpdatedAt,
        isPendingSync: table.isPendingSync,
        isDeleted: table.isDeleted,
      );

  // From JSON (API response) to Model
  factory TransactionModel.fromJson(DataMap json) => TransactionModel(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    categoryId: json['category_id'] as String,
    notes: json['notes'] as String?,
    syncStatus: SyncStatus.synced.value,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    syncedAt: DateTime.now(),
    serverUpdatedAt: DateTime.parse(json['updated_at'] as String),
    isPendingSync: false,
    isDeleted: json['is_deleted'] as bool? ?? false,
  );
  // From Domain Entity to Model
  factory TransactionModel.fromEntity(TransactionEntity entity) =>
      TransactionModel(
        id: entity.id,
        description: entity.description,
        amount: entity.amount,
        date: entity.date,
        categoryId: entity.categoryId,
        notes: entity.notes,
        syncStatus: entity.syncStatus.value,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncedAt: entity.syncedAt,
        serverUpdatedAt: entity.serverUpdatedAt,
        isPendingSync: entity.isPendingSync,
        isDeleted: entity.isDeleted,
      );

  // To Domain Entity
  TransactionEntity toEntity() => TransactionEntity(
    id: id,
    description: description,
    amount: amount,
    date: date,
    categoryId: categoryId,
    notes: notes,
    syncStatus: SyncStatus.fromValue(syncStatus),
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncedAt: syncedAt,
    serverUpdatedAt: serverUpdatedAt,
    isPendingSync: isPendingSync,
    isDeleted: isDeleted,
  );

  // To JSON (for API request)
  DataMap toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category_id': categoryId,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
  };

  TransactionModel copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? notes,
    int? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    DateTime? serverUpdatedAt,
    bool? isPendingSync,
    bool? isDeleted,
  }) =>
      TransactionModel(
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
  // To Drift Companion (for insert/update)
  TransactionsCompanion toCompanion() => TransactionsCompanion.insert(
    id: id,
    description: description,
    amount: amount,
    date: date,
    categoryId: categoryId,
    notes: Value(notes),
    syncStatus: Value(syncStatus),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    syncedAt: Value(syncedAt),
    serverUpdatedAt: Value(serverUpdatedAt),
    isPendingSync: Value(isPendingSync),
    isDeleted: Value(isDeleted),
  );

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? notes;
  final int syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final DateTime? serverUpdatedAt;
  final bool isPendingSync;
  final bool isDeleted;
}
