# TransactionRemoteDataSource — The Bridge to the Server

This class handles **all HTTP communications** with the backend API. Each method corresponds to a CRUD operation on the server.

---

## 1. getTransactions() — Fetch All Transactions from Server

```dart
Future<List<TransactionModel>> getTransactions() async {
  try {
    final response = await apiClient.get(ApiEndpoints.transactions);
    // GET https://api.yourbackend.com/v1/transactions
    
    final List<dynamic> data = response['data'] as List;
    return data.map((json) => TransactionModel.fromJson(json)).toList();
  } catch (e) {
    throw ServerException(e.toString());
  }
}
```

### Usage Example

```
User opens the app for the first time
        ↓
Repository calls getTransactions()
        ↓
GET https://api.yourbackend.com/v1/transactions
        ↓
Server responds:
{
  "data": [
    {"id": "abc-123", "description": "Taxi", "amount": 25.0, ...},
    {"id": "def-456", "description": "Café", "amount": 5.5, ...}
  ]
}
        ↓
Converts each JSON to TransactionModel
        ↓
Returns [TransactionModel, TransactionModel]
        ↓
Repository saves them to Drift (local DB)
```

**Role**: Synchronize initial data from the server to local storage.

---

## 2. createTransaction() — Create a New Transaction on Server

```dart
Future<TransactionModel> createTransaction(TransactionModel transaction) async {
  try {
    final response = await apiClient.post(
      ApiEndpoints.transactions,
      body: transaction.toJson(),
    );
    // POST https://api.yourbackend.com/v1/transactions
    
    return TransactionModel.fromJson(response['data']);
  } catch (e) {
    throw ServerException(e.toString());
  }
}
```

### Usage Example

```
User adds "Taxi 25 DT" offline
        ↓
Saved locally with isPendingSync = true
        ↓
15 minutes later, WorkManager triggers
        ↓
Sync Engine retrieves pending via getPendingSync()
        ↓
For each pending, calls createTransaction()
        ↓
POST https://api.yourbackend.com/v1/transactions
Body: {
  "id": "abc-123",
  "description": "Taxi",
  "amount": 25.0,
  "date": "2024-02-03T10:00:00Z",
  "category_id": "cat_transport",
  ...
}
        ↓
Server creates the transaction and responds:
{
  "data": {
    "id": "abc-123",
    "description": "Taxi",
    "amount": 25.0,
    "updated_at": "2024-02-03T10:15:00Z",  ← server timestamp
    ...
  }
}
        ↓
Repository updates local record:
  - isPendingSync = false
  - syncStatus = synced
  - serverUpdatedAt = "2024-02-03T10:15:00Z"
```

**Role**: Send newly created offline transactions to the server.

---

## 3. updateTransaction() — Update an Existing Transaction

```dart
Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
  try {
    final response = await apiClient.put(
      '${ApiEndpoints.transactions}/${transaction.id}',
      body: transaction.toJson(),
    );
    // PUT https://api.yourbackend.com/v1/transactions/abc-123
    
    return TransactionModel.fromJson(response['data']);
  } on SyncConflictException {
    rethrow;  // Let the Conflict Resolver handle this
  } catch (e) {
    throw ServerException(e.toString());
  }
}
```

### Usage Example

```
User modifies "Taxi 25 DT" → "Taxi 30 DT" offline
        ↓
Updated locally with isPendingSync = true
        ↓
Sync Engine calls updateTransaction()
        ↓
PUT https://api.yourbackend.com/v1/transactions/abc-123
Body: {
  "id": "abc-123",
  "description": "Taxi",
  "amount": 30.0,  ← changed
  "updated_at": "2024-02-03T10:05:00Z",
  ...
}
        ↓
TWO POSSIBLE SCENARIOS:
```

### Scenario 1: No Conflict

```
Server responds 200 OK:
{
  "data": {
    "id": "abc-123",
    "amount": 30.0,
    "updated_at": "2024-02-03T10:20:00Z",
    ...
  }
}
        ↓
Update successful, markAsSynced()
```

### Scenario 2: Conflict Detected

```
Server responds 409 Conflict:
{
  "local": {"amount": 30.0, "updated_at": "2024-02-03T10:05:00Z"},
  "remote": {"amount": 35.0, "updated_at": "2024-02-03T10:15:00Z"}
}
        ↓
SyncConflictException is thrown
        ↓
rethrow → Repository catches the exception
        ↓
Conflict Resolver decides what to do
```

**Role**: Synchronize local modifications to the server and detect conflicts.

---

## 4. deleteTransaction() — Delete a Transaction on Server

```dart
Future<void> deleteTransaction(String id) async {
  try {
    await apiClient.delete('${ApiEndpoints.transactions}/$id');
    // DELETE https://api.yourbackend.com/v1/transactions/abc-123
  } catch (e) {
    throw ServerException(e.toString());
  }
}
```

### Usage Example

```
User deletes "Taxi 25 DT" offline
        ↓
Soft delete locally:
  - isDeleted = true
  - isPendingSync = true
        ↓
Sync Engine calls deleteTransaction()
        ↓
DELETE https://api.yourbackend.com/v1/transactions/abc-123
        ↓
Server deletes and responds 204 No Content
        ↓
Local can now permanently remove the row
(or keep it with isDeleted=true for history)
```

**Role**: Propagate local deletions to the server.

---

## 5. syncTransactions() — Batch Sync (Multiple Transactions at Once)

```dart
Future<void> syncTransactions(List<TransactionModel> transactions) async {
  try {
    final body = {
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    await apiClient.post(ApiEndpoints.sync, body: body);
    // POST https://api.yourbackend.com/v1/sync
  } catch (e) {
    throw ServerException(e.toString());
  }
}
```

### Usage Example

```
User creates 10 transactions offline
        ↓
All marked isPendingSync = true
        ↓
Sync Engine retrieves the 10 via getPendingSync()
        ↓
Instead of sending 10 separate requests (slow)
        ↓
Calls syncTransactions() with the complete list
        ↓
POST https://api.yourbackend.com/v1/sync
Body: {
  "transactions": [
    {"id": "abc-1", "description": "Taxi", ...},
    {"id": "abc-2", "description": "Café", ...},
    {"id": "abc-3", "description": "Bus", ...},
    ...10 transactions
  ]
}
        ↓
Server processes all in a single request (much faster)
        ↓
Responds with results for each
        ↓
Repository updates the status of each transaction
```

**Role**: Optimize sync by sending multiple transactions at once instead of one by one.

---

## Exception Handling — Why `rethrow`?

```dart
} on ServerException {
  rethrow;  // Re-throw the exception without modifying it
} on NetworkException {
  rethrow;
} catch (e) {
  throw ServerException(e.toString());  // Convert unknown errors
}
```

### Why not just let the error propagate?

Because the Repository (the layer above) needs to know **what type of error** occurred to decide what to do:

```dart
// In the Repository
try {
  await remoteDataSource.updateTransaction(transaction);
} on NetworkException {
  // No network → keep isPendingSync=true, will retry later
} on SyncConflictException catch (e) {
  // Conflict → call the Conflict Resolver
} on ServerException {
  // Server error → mark as failed
}
```

Without `rethrow`, all errors would be transformed into `ServerException`, and the Repository couldn't differentiate between them.

---

## Visual Summary

```
Local DB (Drift)              Remote DataSource              API Server
─────────────────             ──────────────────             ──────────
isPendingSync=true    →       createTransaction()     →      POST /transactions
                              
Transaction modified   →       updateTransaction()     →      PUT /transactions/:id
                              
isDeleted=true        →       deleteTransaction()     →      DELETE /transactions/:id
                              
First app open        ←       getTransactions()       ←      GET /transactions
                              
10 pending            →       syncTransactions()      →      POST /sync (batch)
```

Each method has a precise role in the offline-first synchronization lifecycle.