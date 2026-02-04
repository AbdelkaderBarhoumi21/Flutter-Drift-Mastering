# TransactionBloc — The Business Logic Component

The BLoC (Business Logic Component) is the **brain** of the feature. It receives events from the UI, processes them using use cases, and emits states back to the UI.

---

## Architecture Position

```
┌─────────────────────────────────────────────┐
│                 UI Layer                     │
│  (Widgets, Screens, Buttons)                │
└──────────────┬──────────────────────────────┘
               │ Dispatches Events
               │ Listens to States
┌──────────────▼──────────────────────────────┐
│           TransactionBloc                    │
│  • Receives events                           │
│  • Calls use cases                           │
│  • Emits states                              │
└──────────────┬──────────────────────────────┘
               │ Calls
┌──────────────▼──────────────────────────────┐
│            Use Cases                         │
│  (GetTransactions, AddTransaction, etc.)    │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│           Repository                         │
│  (Local + Remote data sources)              │
└──────────────────────────────────────────────┘
```

---

## Class Structure

```dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  // Use cases (business logic)
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final UpdateTransaction updateTransaction;
  final DeleteTransaction deleteTransaction;
  final SyncTransactions syncTransactions;

  // Stream subscription for real-time updates
  StreamSubscription? _transactionsSubscription;

  TransactionBloc({...}) : super(TransactionInitial()) {
    // Register event handlers
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<SyncRequested>(_onSyncRequested);
  }
}
```

### Dependencies (Use Cases)

The BLoC depends on **5 use cases** — each handles one specific operation:

| Use Case | Purpose |
|----------|---------|
| `GetTransactions` | Load all transactions from local DB |
| `AddTransaction` | Create a new transaction |
| `UpdateTransaction` | Modify an existing transaction |
| `DeleteTransaction` | Delete a transaction |
| `SyncTransactions` | Sync pending transactions with server |

**Why use cases?** They separate business logic from the BLoC, making each operation testable independently.

---

## Constructor and Initial State

```dart
TransactionBloc({
  required this.getTransactions,
  required this.addTransaction,
  required this.updateTransaction,
  required this.deleteTransaction,
  required this.syncTransactions,
}) : super(TransactionInitial()) {
  on<LoadTransactions>(_onLoadTransactions);
  on<AddTransactionEvent>(_onAddTransaction);
  on<UpdateTransactionEvent>(_onUpdateTransaction);
  on<DeleteTransactionEvent>(_onDeleteTransaction);
  on<SyncRequested>(_onSyncRequested);
}
```

### `super(TransactionInitial())`

Sets the **initial state** of the BLoC. When the BLoC is first created, it starts in the `TransactionInitial` state.

```
App starts → BLoC created → State = TransactionInitial
```

### Event Handlers Registration

```dart
on<LoadTransactions>(_onLoadTransactions);
```

This tells the BLoC: **"When you receive a `LoadTransactions` event, call the `_onLoadTransactions` method."**

Each `on<Event>()` call registers a handler for that specific event type.

---

## Event Handler 1: Load Transactions

```dart
Future<void> _onLoadTransactions(
  LoadTransactions event,
  Emitter<TransactionState> emit,
) async {
  // 1. Emit loading state
  emit(TransactionLoading());

  // 2. Cancel previous subscription if exists
  await _transactionsSubscription?.cancel();
  
  // 3. Watch for real-time updates
  _transactionsSubscription = getTransactions.watch().listen(
    (transactions) {
      emit(TransactionLoaded(transactions));
    },
    onError: (error) {
      emit(TransactionError(error.toString()));
    },
  );
}
```

### How It Works

**Step 1: Emit Loading State**

```dart
emit(TransactionLoading());
```

Immediately tells the UI "I'm working on it, show a loading spinner."

**Step 2: Cancel Previous Subscription**

```dart
await _transactionsSubscription?.cancel();
```

If there's already a stream listening to transactions, cancel it first to avoid memory leaks and duplicate subscriptions.

**Step 3: Start Watching for Changes**

```dart
_transactionsSubscription = getTransactions.watch().listen(...)
```

Creates a **reactive stream** that automatically emits new states whenever the database changes.

### The Flow

```
User opens transactions screen
        ↓
Widget: bloc.add(LoadTransactions())
        ↓
BLoC: emit(TransactionLoading())
        ↓
UI: Shows loading spinner
        ↓
BLoC: getTransactions.watch() starts listening
        ↓
Repository: Returns Stream<List<Transaction>>
        ↓
Drift: SELECT * FROM transactions WHERE isDeleted = false
        ↓
Stream emits: [Transaction1, Transaction2, ...]
        ↓
BLoC: emit(TransactionLoaded(transactions))
        ↓
UI: Displays the list

        ↓ (Later, user adds a transaction in another screen)

Drift: INSERT INTO transactions
        ↓
Stream automatically detects change
        ↓
Stream emits updated list: [Transaction1, Transaction2, NewTransaction]
        ↓
BLoC: emit(TransactionLoaded(updatedList))
        ↓
UI: Automatically updates without needing to refresh
```

### Why Use `.watch()` Instead of `.call()`?

```dart
// ❌ Without watch (manual)
final result = await getTransactions();
// Returns data once, then you're done
// To see new data, you'd have to call it again manually

// ✅ With watch (reactive)
getTransactions.watch().listen(...)
// Returns a stream that keeps emitting new data automatically
// UI updates in real-time when database changes
```

---

## Event Handler 2: Add Transaction

```dart
Future<void> _onAddTransaction(
  AddTransactionEvent event,
  Emitter<TransactionState> emit,
) async {
  // Call the use case
  final result = await addTransaction(event.transaction);

  // Handle the result
  result.fold(
    (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
    (_) => emit(const TransactionOperationSuccess('Transaction added successfully')),
  );
}
```

### How It Works

**Step 1: Call the Use Case**

```dart
final result = await addTransaction(event.transaction);
```

The use case calls the repository, which:
1. Saves to local DB instantly
2. Tries to sync with server if online
3. Returns `Either<Failure, Transaction>`

**Step 2: Handle Success or Failure**

```dart
result.fold(
  (failure) => emit(TransactionError(...)),  // Left = Error
  (_) => emit(TransactionOperationSuccess(...)),  // Right = Success
);
```

`.fold()` is from the `dartz` package (`Either` type):
- **Left side** = Failure occurred
- **Right side** = Success

### The Flow

```
User fills form and taps "Save"
        ↓
Widget: bloc.add(AddTransactionEvent(transaction))
        ↓
BLoC: Calls addTransaction.call(event.transaction)
        ↓
Use Case: Calls repository.addTransaction()
        ↓
Repository: 
  1. Saves to local DB (instant)
  2. Checks network
  3. If online, tries to sync
        ↓
SCENARIO A: Success
  Repository returns: Right(transaction)
        ↓
  BLoC: emit(TransactionOperationSuccess('Transaction added successfully'))
        ↓
  UI: Shows success snackbar, closes form

SCENARIO B: Failure (e.g., database error)
  Repository returns: Left(CacheFailure('DB error'))
        ↓
  BLoC: emit(TransactionError('Database Error: DB error'))
        ↓
  UI: Shows error snackbar, keeps form open
```

### Why `(_)` Instead of Named Variable?

```dart
(_) => emit(TransactionOperationSuccess(...))
```

The `_` means **"I don't care about this value."** 

When adding succeeds, the repository returns `Right(transaction)`, but the BLoC doesn't need the transaction object here — it just needs to know it succeeded. The list will update automatically via the `.watch()` stream.

---

## Event Handler 3: Update Transaction (with Conflict Detection)

```dart
Future<void> _onUpdateTransaction(
  UpdateTransactionEvent event,
  Emitter<TransactionState> emit,
) async {
  final result = await updateTransaction(event.transaction);

  result.fold(
    (failure) {
      if (failure is SyncConflictFailure) {
        emit(SyncConflict(
          localData: failure.localData,
          remoteData: failure.remoteData,
        ));
      } else {
        emit(TransactionError(_mapFailureToMessage(failure)));
      }
    },
    (_) => emit(const TransactionOperationSuccess('Transaction updated successfully')),
  );
}
```

### The Special Case: Conflict Detection

This handler has **extra logic** to detect sync conflicts:

```dart
if (failure is SyncConflictFailure) {
  emit(SyncConflict(
    localData: failure.localData,
    remoteData: failure.remoteData,
  ));
}
```

### The Flow with Conflict

```
User edits transaction offline
        ↓
Widget: bloc.add(UpdateTransactionEvent(modifiedTransaction))
        ↓
BLoC: Calls updateTransaction.call(event.transaction)
        ↓
Repository: Updates local DB, tries to sync
        ↓
Remote DataSource: PUT /transactions/abc-123
        ↓
Server responds: 409 Conflict
{
  "local": {amount: 30, updatedAt: "10:05:00"},
  "remote": {amount: 35, updatedAt: "10:15:00"}
}
        ↓
Repository throws: SyncConflictException
        ↓
Repository returns: Left(SyncConflictFailure(...))
        ↓
BLoC checks: if (failure is SyncConflictFailure)
        ↓
BLoC emits: SyncConflict(localData, remoteData)
        ↓
UI: Shows conflict resolution dialog
        ↓
User chooses which version to keep
        ↓
Widget: bloc.add(UpdateTransactionEvent(chosenVersion))
        ↓
Process repeats with chosen version
```

---

## Event Handler 4: Delete Transaction

```dart
Future<void> _onDeleteTransaction(
  DeleteTransactionEvent event,
  Emitter<TransactionState> emit,
) async {
  final result = await deleteTransaction(event.id);

  result.fold(
    (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
    (_) => emit(const TransactionOperationSuccess('Transaction deleted successfully')),
  );
}
```

### Simple and Straightforward

Delete is simpler than update — no conflict detection needed because:

```
If transaction exists locally  → Soft delete (isDeleted = true)
If transaction exists on server → DELETE request
If conflict → Server handles it (can't conflict on deletion)
```

### The Flow

```
User swipes to delete
        ↓
Widget: bloc.add(DeleteTransactionEvent(transaction.id))
        ↓
BLoC: Calls deleteTransaction.call(event.id)
        ↓
Repository: 
  1. Soft deletes locally (UPDATE isDeleted = true)
  2. If online, sends DELETE to server
        ↓
Repository returns: Right(null)
        ↓
BLoC: emit(TransactionOperationSuccess('Transaction deleted successfully'))
        ↓
UI: Shows snackbar with "Undo" option
        ↓
.watch() stream detects change, removes item from list automatically
```

---

## Event Handler 5: Manual Sync

```dart
Future<void> _onSyncRequested(
  SyncRequested event,
  Emitter<TransactionState> emit,
) async {
  final result = await syncTransactions();

  result.fold(
    (failure) {
      if (failure is SyncConflictFailure) {
        emit(SyncConflict(
          localData: failure.localData,
          remoteData: failure.remoteData,
        ));
      } else {
        emit(TransactionError(_mapFailureToMessage(failure)));
      }
    },
    (_) => emit(const TransactionOperationSuccess('Sync completed successfully')),
  );
}
```

### When It's Used

```
User taps "Sync Now" button
        ↓
Widget: bloc.add(SyncRequested())
        ↓
BLoC: Calls syncTransactions.call()
        ↓
Repository:
  1. Checks network
  2. Gets pending transactions (isPendingSync = true)
  3. Sends batch to server
  4. Marks all as synced
        ↓
SUCCESS:
  BLoC emits: TransactionOperationSuccess('Sync completed successfully')
        ↓
  UI: Shows "3 transactions synced" snackbar

FAILURE (offline):
  BLoC emits: TransactionError('Network Error: No internet connection')
        ↓
  UI: Shows error snackbar

CONFLICT:
  BLoC emits: SyncConflict(localData, remoteData)
        ↓
  UI: Shows conflict dialog
```

---

## Helper Method: Failure to Message Mapping

```dart
String _mapFailureToMessage(Failure failure) {
  if (failure is ServerFailure) {
    return 'Server Error: ${failure.message}';
  } else if (failure is NetworkFailure) {
    return 'Network Error: ${failure.message}';
  } else if (failure is CacheFailure) {
    return 'Database Error: ${failure.message}';
  } else if (failure is ValidationFailure) {
    return 'Validation Error: ${failure.message}';
  } else {
    return 'Unexpected Error: ${failure.message}';
  }
}
```

### Purpose

Converts technical `Failure` objects into **user-friendly error messages**.

### Example

```dart
// Repository returns
Left(NetworkFailure('No internet connection'))

// BLoC converts it to
'Network Error: No internet connection'

// UI shows in a snackbar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Network Error: No internet connection'))
);
```

Without this mapping, the UI would have to check `if (failure is NetworkFailure)` everywhere. This centralizes the logic.

---

## Cleanup: Closing the BLoC

```dart
@override
Future<void> close() {
  _transactionsSubscription?.cancel();
  return super.close();
}
```

### Why This Matters

When the BLoC is disposed (e.g., user navigates away from the screen), we must **cancel the stream subscription** to avoid memory leaks.

```
Widget disposed
        ↓
BLoC.close() called
        ↓
Cancel stream subscription
        ↓
Stop listening to database changes
        ↓
Free up memory
```

Without this, the stream would keep running even though nobody is listening, wasting resources.

---

## Complete Flow Example: Add Transaction

```
┌─────────────────────────────────────────────────────────┐
│ 1. USER ACTION                                           │
│    User fills form and taps "Save"                       │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 2. WIDGET (Presentation Layer)                           │
│    Creates event and adds to BLoC                        │
│                                                           │
│    final event = AddTransactionEvent(transaction);       │
│    context.read<TransactionBloc>().add(event);           │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 3. BLOC (Business Logic)                                 │
│    _onAddTransaction called                              │
│                                                           │
│    final result = await addTransaction(event.transaction);│
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 4. USE CASE (Domain Layer)                               │
│    AddTransaction.call()                                 │
│                                                           │
│    return repository.addTransaction(transaction);        │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 5. REPOSITORY (Data Layer)                               │
│    - Save to local DB (instant)                          │
│    - Try to sync with server if online                   │
│    - Return Either<Failure, Transaction>                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ├─── SUCCESS ───┐
                     │                │
┌────────────────────▼────────────────▼───────────────────┐
│ 6. BLOC HANDLES RESULT                                   │
│    result.fold(                                           │
│      (failure) => emit(TransactionError(...)),           │
│      (_) => emit(TransactionOperationSuccess(...))       │
│    );                                                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 7. UI LISTENS TO STATE                                   │
│    BlocListener<TransactionBloc, TransactionState> {     │
│      if (state is TransactionOperationSuccess) {         │
│        ScaffoldMessenger.showSnackBar(...);              │
│        Navigator.pop();                                  │
│      }                                                    │
│    }                                                      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ 8. AUTO-UPDATE VIA STREAM                                │
│    .watch() stream detects INSERT                        │
│    Stream emits new list                                 │
│    BLoC emits TransactionLoaded(updatedList)             │
│    UI rebuilds with new transaction in list              │
└──────────────────────────────────────────────────────────┘
```

---

## Key Takeaways

1. **BLoC is a mediator** — It connects UI events to business logic
2. **Use cases keep BLoC clean** — Each operation is encapsulated
3. **`.fold()` handles errors elegantly** — Type-safe error handling with `Either`
4. **`.watch()` enables reactive UI** — Automatic updates without manual refresh
5. **Conflict detection is built-in** — Special handling for `SyncConflictFailure`
6. **Cleanup prevents memory leaks** — Always cancel stream subscriptions
7. **User-friendly error messages** — Technical failures converted to readable text

This architecture ensures a clean separation of concerns while maintaining a responsive, offline-first user experience.