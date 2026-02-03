# TransactionRepositoryImpl — The Orchestrator

This is the **heart of the offline-first architecture**. The Repository coordinates between local storage (Drift) and remote API, implementing the business logic for when to use which data source.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                  TransactionRepositoryImpl                │
│                                                           │
│  ┌─────────────────┐         ┌─────────────────┐        │
│  │ Local DataSource│         │Remote DataSource│        │
│  │    (Drift)      │         │   (HTTP API)    │        │
│  └────────┬────────┘         └────────┬────────┘        │
│           │                           │                  │
│           │    ┌──────────────┐       │                  │
│           └────│ NetworkInfo  │───────┘                  │
│                │ (Online?)    │                          │
│                └──────────────┘                          │
└──────────────────────────────────────────────────────────┘
```

---

## Core Principle: Offline-First

**Every operation follows this pattern:**

1. **Write to local database FIRST** (instant response)
2. **Check if online**
3. **If online**, try to sync with server
4. **If offline or sync fails**, queue for later sync

This ensures the UI never blocks waiting for network responses.

---

## Method-by-Method Breakdown

### 1. getTransactions() — Read Operations

```dart
@override
ResultFuture<List<Transaction>> getTransactions() async {
  try {
    // Always read from local database (offline-first)
    final models = await localDataSource.getTransactions();
    final entities = models.map((m) => m.toEntity()).toList();
    return Right(entities);
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

#### Key Points

- **ALWAYS reads from local** — never from the server
- Fast and works offline
- The server data gets pulled into local via background sync

#### Flow Example

```
User opens the app
        ↓
BLoC calls repository.getTransactions()
        ↓
Repository → localDataSource.getTransactions()
        ↓
Drift query: SELECT * FROM transactions WHERE isDeleted = false
        ↓
[TransactionModel, TransactionModel, ...]
        ↓
Convert to entities: models.map((m) => m.toEntity())
        ↓
Return Right([Transaction, Transaction, ...])
        ↓
BLoC emits state with transactions
        ↓
UI displays the list
```

---

### 2. addTransaction() — Create with Opportunistic Sync

```dart
@override
ResultFuture<Transaction> addTransaction(Transaction transaction) async {
  try {
    // 1. Save to local database FIRST
    final model = TransactionModel.fromEntity(transaction);
    final savedModel = await localDataSource.addTransaction(model);

    // 2. Try to sync with server if online
    if (await networkInfo.isConnected) {
      try {
        final serverModel = await remoteDataSource.createTransaction(model);
        // Update local with server timestamps
        await localDataSource.markAsSynced(
          serverModel.id,
          serverModel.serverUpdatedAt!,
        );
        return Right(serverModel.toEntity());
      } catch (e) {
        // 3. Sync failed, but local save succeeded
        // Will sync later via WorkManager
        return Right(savedModel.toEntity());
      }
    }

    // 4. Offline - return the locally saved transaction
    return Right(savedModel.toEntity());
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

#### The Two-Phase Approach

**Phase 1: Local Save (ALWAYS happens)**

```
User adds "Taxi 25 DT"
        ↓
repository.addTransaction(transaction)
        ↓
localDataSource.addTransaction(model)
        ↓
INSERT INTO transactions (...) VALUES (...)
        ↓
isPendingSync = true
syncStatus = pending
        ↓
✅ UI updates IMMEDIATELY (no waiting for network)
```

**Phase 2: Remote Sync (ONLY if online)**

```
Check networkInfo.isConnected
        ↓
IF ONLINE:
  ├─→ remoteDataSource.createTransaction(model)
  │   POST /transactions
  │   ↓
  │   Success:
  │   ├─→ Server responds with serverUpdatedAt
  │   └─→ markAsSynced(id, serverUpdatedAt)
  │       UPDATE transactions SET
  │         isPendingSync = false,
  │         syncStatus = synced,
  │         serverUpdatedAt = ...
  │
  │   Failure:
  │   └─→ Keep isPendingSync = true
  │       WorkManager will retry later
  │
IF OFFLINE:
  └─→ Transaction stays isPendingSync = true
      WorkManager will sync when online
```

---

### 3. updateTransaction() — Update with Conflict Detection

```dart
@override
ResultFuture<Transaction> updateTransaction(Transaction transaction) async {
  try {
    // 1. Update local database first
    final model = TransactionModel.fromEntity(transaction).copyWith(
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );
    
    final updatedModel = await localDataSource.updateTransaction(model);

    // 2. Try to sync with server if online
    if (await networkInfo.isConnected) {
      try {
        final serverModel = await remoteDataSource.updateTransaction(model);
        await localDataSource.markAsSynced(
          serverModel.id,
          serverModel.serverUpdatedAt!,
        );
        return Right(serverModel.toEntity());
      } on SyncConflictException catch (e) {
        // 3. CONFLICT DETECTED
        return Left(SyncConflictFailure(
          message: e.message,
          localData: e.localData,
          remoteData: e.remoteData,
        ));
      } catch (e) {
        // Sync failed, but local update succeeded
        return Right(updatedModel.toEntity());
      }
    }

    return Right(updatedModel.toEntity());
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

#### Conflict Detection Flow

```
User modifies "Taxi 25 DT" → "Taxi 30 DT"
        ↓
1. UPDATE LOCAL FIRST
   UPDATE transactions SET
     amount = 30.0,
     updatedAt = now,
     isPendingSync = true
        ↓
2. CHECK NETWORK
   networkInfo.isConnected → true
        ↓
3. TRY TO SYNC
   PUT /transactions/abc-123
   Body: {amount: 30.0, updatedAt: "10:05:00"}
        ↓
   SERVER CHECKS:
   - Local updatedAt:  10:05:00
   - Server updatedAt: 10:15:00  ← Another device changed it!
        ↓
   Server responds: 409 Conflict
   {
     "local": {amount: 30.0, updatedAt: "10:05:00"},
     "remote": {amount: 35.0, updatedAt: "10:15:00"}
   }
        ↓
4. HANDLE CONFLICT
   SyncConflictException thrown
        ↓
   Repository catches it
        ↓
   Return Left(SyncConflictFailure(...))
        ↓
   BLoC receives the failure
        ↓
   BLoC shows conflict resolution dialog to user
```

---

### 4. deleteTransaction() — Soft Delete with Background Sync

```dart
@override
ResultFuture<void> deleteTransaction(String id) async {
  try {
    // 1. Soft delete in local database
    await localDataSource.deleteTransaction(id);
    // UPDATE transactions SET isDeleted = true, isPendingSync = true

    // 2. Try to sync deletion with server if online
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTransaction(id);
        // DELETE /transactions/abc-123
      } catch (e) {
        // Sync failed, but local delete succeeded
        // Will sync later
      }
    }

    return const Right(null);
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

#### Why Soft Delete?

```
WITHOUT SOFT DELETE:
User deletes "Taxi 25 DT" offline
        ↓
DELETE FROM transactions WHERE id = 'abc-123'
        ↓
Row is gone from local DB
        ↓
WorkManager triggers sync later
        ↓
❌ No record that this transaction should be deleted on server
   Server still has the transaction
   Next sync will re-download it


WITH SOFT DELETE:
User deletes "Taxi 25 DT" offline
        ↓
UPDATE transactions SET isDeleted = true, isPendingSync = true
        ↓
Row still exists in DB (just marked)
        ↓
WorkManager triggers sync later
        ↓
✅ Sees isDeleted = true, isPendingSync = true
   Sends DELETE /transactions/abc-123 to server
   Then permanently removes from local DB
```

---

### 5. syncTransactions() — Batch Sync for Pending Items

```dart
@override
ResultFuture<void> syncTransactions() async {
  try {
    // 1. Check network
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    // 2. Get all pending transactions
    final pendingModels = await localDataSource.getPendingSync();

    if (pendingModels.isEmpty) {
      return const Right(null);
    }

    // 3. Sync with server (batch)
    try {
      await remoteDataSource.syncTransactions(pendingModels);
      
      // 4. Mark all as synced
      for (final model in pendingModels) {
        await localDataSource.markAsSynced(model.id, DateTime.now());
      }

      return const Right(null);
    } on SyncConflictException catch (e) {
      return Left(SyncConflictFailure(
        message: e.message,
        localData: e.localData,
        remoteData: e.remoteData,
      ));
    }
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  }
}
```

#### Batch Sync Flow

```
WorkManager triggers every 15 minutes
        ↓
Calls repository.syncTransactions()
        ↓
1. Check network
   networkInfo.isConnected → true ✅
        ↓
2. Get pending items
   localDataSource.getPendingSync()
   SELECT * FROM transactions WHERE isPendingSync = true
        ↓
   [Transaction A, Transaction B, Transaction C]  (3 pending)
        ↓
3. Send all in one request
   remoteDataSource.syncTransactions([A, B, C])
   POST /sync
   Body: {
     "transactions": [
       {id: "abc-1", amount: 25, ...},
       {id: "abc-2", amount: 30, ...},
       {id: "abc-3", amount: 15, ...}
     ]
   }
        ↓
4. Server processes all
   Server responds: 200 OK
        ↓
5. Mark all as synced
   FOR EACH transaction:
     UPDATE transactions SET
       isPendingSync = false,
       syncStatus = synced,
       syncedAt = now
```

---

## Error Handling with Either<Failure, Success>

### Why Use `Either`?

Traditional error handling:

```dart
// ❌ Exceptions force you to use try-catch everywhere
try {
  final transactions = await repository.getTransactions();
  // use transactions
} catch (e) {
  // handle error
}
```

With `Either`:

```dart
// ✅ Errors are part of the return type
final result = await repository.getTransactions();

result.fold(
  (failure) {
    // Left side = failure
    if (failure is NetworkFailure) {
      showSnackbar('No internet');
    } else if (failure is CacheFailure) {
      showSnackbar('Database error');
    }
  },
  (transactions) {
    // Right side = success
    displayTransactions(transactions);
  },
);
```

### The Pattern in Every Method

```dart
try {
  // Do the work
  final result = await localDataSource.getTransactions();
  return Right(result);  // ✅ Success
} on CacheException catch (e) {
  return Left(CacheFailure(e.message));  // ❌ Failure
} catch (e) {
  return Left(CacheFailure(e.toString()));  // ❌ Unknown failure
}
```

---

## Stream Methods — Real-time Updates

### watchTransactions()

```dart
@override
Stream<List<Transaction>> watchTransactions() {
  return localDataSource.watchTransactions().map(
    (models) => models.map((m) => m.toEntity()).toList(),
  );
}
```

Returns a **reactive stream** that emits every time the local database changes:

```
User adds a transaction in another screen
        ↓
localDataSource.addTransaction()
        ↓
INSERT INTO transactions
        ↓
Drift detects the change
        ↓
watchTransactions() stream emits new list
        ↓
StreamBuilder in UI rebuilds automatically
        ↓
New transaction appears in the list
```

---

## Complete Flow Example: Add Transaction Offline

```
1. USER ACTION
   User taps "Add Transaction" button
        ↓
2. BLoC LAYER
   TransactionBloc receives AddTransactionEvent
   Calls: usecase.addTransaction(transaction)
        ↓
3. USE CASE
   Forwards to: repository.addTransaction(transaction)
        ↓
4. REPOSITORY (Local Phase)
   - Convert entity to model
   - localDataSource.addTransaction(model)
   - INSERT INTO transactions with isPendingSync=true
   - ✅ UI updates IMMEDIATELY
        ↓
5. REPOSITORY (Network Check)
   networkInfo.isConnected → FALSE (offline)
   - Skip remote sync
   - Return Right(transaction)
        ↓
6. BLoC RECEIVES SUCCESS
   Emits TransactionAdded state
        ↓
7. UI UPDATES
   Shows success message
   List updates via watchTransactions() stream
        ↓
8. BACKGROUND (15 minutes later)
   WorkManager triggers
   - Calls repository.syncTransactions()
   - networkInfo.isConnected → TRUE (online now)
   - getPendingSync() finds the transaction
   - remoteDataSource.createTransaction()
   - POST /transactions
   - Server responds with serverUpdatedAt
   - markAsSynced() updates local DB
   - isPendingSync = false
   - ✅ Fully synced
```

---

## Key Takeaways

1. **Local-first**: Every write goes to local DB FIRST, ensuring instant UI updates
2. **Opportunistic sync**: Tries to sync immediately if online, queues for later if offline
3. **Conflict detection**: Server can reject updates if data changed elsewhere
4. **Type-safe errors**: `Either<Failure, Success>` makes error handling explicit
5. **Reactive streams**: UI automatically updates when data changes
6. **Background resilience**: WorkManager ensures pending items eventually sync

This architecture ensures the app works perfectly offline while maintaining data consistency across devices when online.