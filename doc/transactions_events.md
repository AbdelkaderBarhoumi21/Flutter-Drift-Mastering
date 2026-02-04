# TransactionEvent — BLoC Events Explained

In the BLoC pattern, **Events** represent user actions or system triggers that cause state changes in the application. These events are dispatched to the BLoC, which processes them and emits new states.

---

## What Are Events?

Events are **immutable objects** that describe something that happened. They're the "input" to the BLoC.

```
User taps a button  →  Event is created  →  BLoC receives event  →  BLoC processes  →  New state emitted
```

---

## Base Class: TransactionEvent

```dart
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  
  @override
  List<Object?> get props => [];
}
```

### Why `abstract`?

This is the **base class** that all transaction events inherit from. You never create a `TransactionEvent` directly — you create one of its concrete subclasses like `LoadTransactions` or `AddTransactionEvent`.

### Why `extends Equatable`?

`Equatable` allows events to be compared by their values instead of by reference. This is crucial for BLoC's internal optimization:

```dart
// Without Equatable
final event1 = AddTransactionEvent(transaction);
final event2 = AddTransactionEvent(transaction);
event1 == event2  // ❌ false (different objects in memory)

// With Equatable
final event1 = AddTransactionEvent(transaction);
final event2 = AddTransactionEvent(transaction);
event1 == event2  // ✅ true (same values in props)
```

BLoC uses this to avoid processing duplicate events.

### Why `const`?

Events are **immutable** — once created, they can never change. The `const` constructor enforces this and allows compile-time constants for better performance.

### What is `props`?

`props` is a getter that returns a list of properties used for equality comparison. If two events have the same `props`, they're considered equal.

```dart
@override
List<Object?> get props => [];  // Base class has no properties
```

---

## Event 1: LoadTransactions

```dart
class LoadTransactions extends TransactionEvent {}
```

### Purpose

Triggers the loading of all transactions from the local database.

### When It's Used

- App startup (load initial data)
- User pulls to refresh
- User navigates to the transactions screen

### Example Usage

```dart
// In a widget
@override
void initState() {
  super.initState();
  context.read<TransactionBloc>().add(LoadTransactions());
}

// Or with a refresh button
onPressed: () {
  context.read<TransactionBloc>().add(LoadTransactions());
}
```

### Flow

```
User opens transactions screen
        ↓
Widget calls: bloc.add(LoadTransactions())
        ↓
BLoC receives LoadTransactions event
        ↓
BLoC calls: getTransactionsUseCase()
        ↓
Repository → localDataSource.getTransactions()
        ↓
Drift query: SELECT * FROM transactions
        ↓
BLoC emits: TransactionsLoaded(transactions)
        ↓
UI displays the list
```

### Why No Properties?

It doesn't need any data — it's just a trigger to "load everything".

```dart
@override
List<Object?> get props => [];  // No properties to compare
```

---

## Event 2: AddTransactionEvent

```dart
class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  
  const AddTransactionEvent(this.transaction);
  
  @override
  List<Object?> get props => [transaction];
}
```

### Purpose

Tells the BLoC to add a new transaction to the database.

### When It's Used

- User taps "Save" on the add transaction form
- Importing transactions from a file
- Creating a recurring transaction automatically

### Example Usage

```dart
// In the add transaction form
onPressed: () {
  final transaction = Transaction(
    id: uuid.v4(),
    description: descriptionController.text,
    amount: double.parse(amountController.text),
    date: selectedDate,
    categoryId: selectedCategory.id,
    // ... other fields
  );
  
  context.read<TransactionBloc>().add(
    AddTransactionEvent(transaction)
  );
}
```

### Flow

```
User fills form and taps "Save"
        ↓
Widget creates: AddTransactionEvent(newTransaction)
        ↓
Widget calls: bloc.add(event)
        ↓
BLoC receives AddTransactionEvent
        ↓
BLoC calls: addTransactionUseCase(transaction)
        ↓
Repository saves to local DB + tries to sync
        ↓
BLoC emits: TransactionAdded(transaction)
        ↓
UI shows success message
        ↓
UI navigates back or updates list
```

### Why `transaction` in `props`?

```dart
@override
List<Object?> get props => [transaction];
```

This ensures two events with the same transaction data are considered equal:

```dart
final tx = Transaction(id: '123', amount: 25.0, ...);

final event1 = AddTransactionEvent(tx);
final event2 = AddTransactionEvent(tx);

event1 == event2  // ✅ true (same transaction)
```

BLoC can use this to deduplicate events if the user accidentally taps "Save" twice.

---

## Event 3: UpdateTransactionEvent

```dart
class UpdateTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  
  const UpdateTransactionEvent(this.transaction);
  
  @override
  List<Object?> get props => [transaction];
}
```

### Purpose

Tells the BLoC to update an existing transaction.

### When It's Used

- User edits a transaction and taps "Save"
- Conflict resolution (user chooses a version to keep)
- Background sync updates local data with server changes

### Example Usage

```dart
// In the edit transaction screen
onPressed: () {
  final updated = originalTransaction.copyWith(
    amount: double.parse(amountController.text),
    description: descriptionController.text,
    updatedAt: DateTime.now(),
  );
  
  context.read<TransactionBloc>().add(
    UpdateTransactionEvent(updated)
  );
}
```

### Flow

```
User edits transaction and taps "Save"
        ↓
Widget creates: UpdateTransactionEvent(modifiedTransaction)
        ↓
Widget calls: bloc.add(event)
        ↓
BLoC receives UpdateTransactionEvent
        ↓
BLoC calls: updateTransactionUseCase(transaction)
        ↓
Repository updates local DB + tries to sync
        ↓
IF sync succeeds:
  BLoC emits: TransactionUpdated(transaction)
IF conflict detected:
  BLoC emits: TransactionConflict(local, remote)
        ↓
UI updates accordingly
```

### Difference from AddTransactionEvent

```
AddTransactionEvent    →  Creates a NEW transaction (id doesn't exist yet)
UpdateTransactionEvent →  Modifies an EXISTING transaction (id already exists)
```

Both carry a `Transaction` object, but the BLoC handles them differently:

```dart
// In BLoC
on<AddTransactionEvent>((event, emit) async {
  final result = await addTransactionUseCase(event.transaction);
  // Calls repository.addTransaction() → INSERT
});

on<UpdateTransactionEvent>((event, emit) async {
  final result = await updateTransactionUseCase(event.transaction);
  // Calls repository.updateTransaction() → UPDATE
});
```

---

## Event 4: DeleteTransactionEvent

```dart
class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  
  const DeleteTransactionEvent(this.id);
  
  @override
  List<Object?> get props => [id];
}
```

### Purpose

Tells the BLoC to delete a transaction (soft delete).

### When It's Used

- User swipes to delete a transaction
- User taps delete button in transaction details
- Bulk delete operation

### Example Usage

```dart
// In a transaction list item
onDismissed: (direction) {
  context.read<TransactionBloc>().add(
    DeleteTransactionEvent(transaction.id)
  );
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Transaction deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Re-add the transaction
          context.read<TransactionBloc>().add(
            AddTransactionEvent(transaction)
          );
        },
      ),
    ),
  );
}
```

### Flow

```
User swipes to delete
        ↓
Widget creates: DeleteTransactionEvent(transaction.id)
        ↓
Widget calls: bloc.add(event)
        ↓
BLoC receives DeleteTransactionEvent
        ↓
BLoC calls: deleteTransactionUseCase(id)
        ↓
Repository soft deletes (UPDATE isDeleted = true)
        ↓
If online, tries to DELETE on server
        ↓
BLoC emits: TransactionDeleted(id)
        ↓
UI removes item from list
```

### Why Only `id` Instead of Full Transaction?

```dart
final String id;  // ← Just the ID
```

To delete a transaction, we only need its ID. Passing the entire transaction would be wasteful:

```dart
// ❌ Unnecessary
DeleteTransactionEvent(entireTransaction)

// ✅ Efficient
DeleteTransactionEvent(transaction.id)
```

The BLoC and repository don't need the description, amount, etc. — just the ID to find and delete it.

---

## Event 5: SyncRequested

```dart
class SyncRequested extends TransactionEvent {}
```

### Purpose

Manually triggers a sync operation to push pending transactions to the server.

### When It's Used

- User taps a "Sync Now" button
- Pull-to-refresh triggers a sync
- App comes back online and user wants to force sync

### Example Usage

```dart
// In a sync button
IconButton(
  icon: Icon(Icons.sync),
  onPressed: () {
    context.read<TransactionBloc>().add(SyncRequested());
  },
)

// Or in a pull-to-refresh
onRefresh: () async {
  context.read<TransactionBloc>().add(SyncRequested());
  await Future.delayed(Duration(seconds: 2));  // Wait for sync
}
```

### Flow

```
User taps "Sync Now" button
        ↓
Widget calls: bloc.add(SyncRequested())
        ↓
BLoC receives SyncRequested event
        ↓
BLoC calls: syncTransactionsUseCase()
        ↓
Repository checks network
        ↓
IF ONLINE:
  Gets pending transactions
  Syncs them with server
  Marks as synced
  BLoC emits: SyncCompleted(successCount)
IF OFFLINE:
  BLoC emits: SyncFailed('No internet')
        ↓
UI shows result (success/failure)
```

### Why No Properties?

Like `LoadTransactions`, it's just a trigger — no data needed.

```dart
@override
List<Object?> get props => [];
```

### Difference from Automatic Sync

```
SyncRequested (Manual)     →  User explicitly requests sync
                               Happens immediately

WorkManager (Automatic)    →  Background sync every 15 minutes
                               Happens without user action
```

Both call the same `syncTransactions()` method in the repository, but `SyncRequested` gives users control when they want to force a sync.

---

## Event Comparison Table

| Event | Properties | Purpose | Triggered By |
|-------|-----------|---------|--------------|
| `LoadTransactions` | None | Load all transactions | App startup, refresh |
| `AddTransactionEvent` | `Transaction` | Create new transaction | Save button on add form |
| `UpdateTransactionEvent` | `Transaction` | Modify existing transaction | Save button on edit form |
| `DeleteTransactionEvent` | `String id` | Delete transaction | Swipe to delete, delete button |
| `SyncRequested` | None | Manual sync trigger | Sync button, pull-to-refresh |

---

## Why Equatable Matters — Practical Example

```dart
// User rapidly taps "Save" button twice
final transaction = Transaction(id: '123', amount: 25.0, ...);

bloc.add(AddTransactionEvent(transaction));  // First tap
bloc.add(AddTransactionEvent(transaction));  // Second tap (0.1s later)

// WITHOUT Equatable:
// BLoC processes both events
// Transaction added twice ❌

// WITH Equatable:
// BLoC sees: event1.props == event2.props
// Second event is deduplicated
// Transaction added once ✅
```

This prevents duplicate database entries from accidental double-taps.

---

## Complete Flow Example: Add Transaction

```
1. USER INTERACTION
   User fills form:
     Description: "Taxi"
     Amount: 25 DT
     Category: Transport
   User taps "Save"
        ↓
2. EVENT CREATION
   final transaction = Transaction(
     id: uuid.v4(),
     description: 'Taxi',
     amount: 25.0,
     categoryId: 'cat_transport',
     ...
   );
   final event = AddTransactionEvent(transaction);
        ↓
3. EVENT DISPATCH
   bloc.add(event);
        ↓
4. BLOC RECEIVES EVENT
   on<AddTransactionEvent>((event, emit) async {
     emit(TransactionLoading());
     final result = await addTransactionUseCase(event.transaction);
     result.fold(
       (failure) => emit(TransactionError(failure.message)),
       (transaction) => emit(TransactionAdded(transaction)),
     );
   });
        ↓
5. STATE EMITTED
   TransactionAdded(transaction)
        ↓
6. UI UPDATES
   - Shows success message
   - Closes add form
   - List automatically updates via watchTransactions() stream
```

---

## Key Takeaways

1. **Events are immutable** — Once created, they never change
2. **Equatable enables value comparison** — Prevents duplicate processing
3. **props defines equality** — Events with same props are considered equal
4. **Each event has a clear purpose** — Load, Add, Update, Delete, Sync
5. **Events carry only necessary data** — ID for delete, full object for add/update
6. **BLoC processes events asynchronously** — UI doesn't block

This event-driven architecture keeps the code organized, testable, and makes the flow of data through the app very clear.