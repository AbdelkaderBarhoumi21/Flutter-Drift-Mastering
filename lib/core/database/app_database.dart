import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_drift_advanced_project/core/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ============================================================================
// TABLES
// ============================================================================

@DataClassName('TransactionTable')
class Transactions extends Table {
  // In this app, each device can create offline transactions without communicating with the server.
  // Phone A creates a transaction → id: 1
  // Phone B creates a transaction → id: 1 ← SAME ID! that why we haven't use auto increment
  // ✅ UUID — un id unique généré partout dans le monde
  // Primary key
  TextColumn get id => text()();

  // Transaction data
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();

  // Category(foreign key)
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();
  // User notes
  TextColumn get notes => text().nullable()();

  // Sync metadata
  IntColumn get syncStatus => integer().withDefault(
    const Constant(0),
  )(); // Sync status enums (SQL understand 0 , 1 not enums pending synced)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  // Server timestamp (for conflict resolution)
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  // Is this a local-only change? => isPendingSync — is this transaction waiting to be sent?
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
  // Soft delete we keep the row but mark it UPDATE transactions SET isDeleted = true WHERE id = 'abc-123'; =>
  // The Sync Engine sees isDeleted = true => It sends a DELETE request to the server => // After a successful sync, the row can be permanently removed
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>>? get primaryKey => {id}; // Id is unique and id is a TextColumn  so drift doesn't know it's a primary key so we need to precise it manually
}

// Category Table
@DataClassName('CategoryTable')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()(); // Emoji or icon name
  IntColumn get color => integer()(); // Color value

  // Sync metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Sync Queue Table (tracks operations to sync)
@DataClassName('SyncQueueTable')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()(); // 'transaction', 'category'
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'

  TextColumn get data => text()(); // JSON data

  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [Transactions, Categories, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertDefaultCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // Insert default categories
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'cat_food',
        name: 'Food & Dining',
        icon: '🍔',
        color: 0xFFFF5722,
      ),
      CategoriesCompanion.insert(
        id: 'cat_transport',
        name: 'Transportation',
        icon: '🚗',
        color: 0xFF2196F3,
      ),
      CategoriesCompanion.insert(
        id: 'cat_shopping',
        name: 'Shopping',
        icon: '🛍️',
        color: 0xFF9C27B0,
      ),
      CategoriesCompanion.insert(
        id: 'cat_entertainment',
        name: 'Entertainment',
        icon: '🎬',
        color: 0xFFE91E63,
      ),
      CategoriesCompanion.insert(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        icon: '📄',
        color: 0xFF795548,
      ),
    ];

    await batch((batch) {
      batch.insertAll(
        categories,
        defaultCategories,
        mode: InsertMode.insertOrIgnore,
      );
    });
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, AppConstants.databaseName));
  return NativeDatabase(file);
});
