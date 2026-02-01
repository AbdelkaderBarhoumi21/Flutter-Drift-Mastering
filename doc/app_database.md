# Database Tables Explanation

## The Three Tables and Their Roles

---

## Transactions — Stores the Data

This is the main table. Each row represents a single expense created by the user.

| Field | Description |
|---|---|
| `id` | Unique identifier (UUID) |
| `description` | Text of the expense (e.g., "Airport Taxi") |
| `amount` | The amount (e.g., 25.0) |
| `date` | When the expense was made |
| `categoryId` | Link to a category (foreign key) |
| `notes` | Optional user notes (nullable — can be empty) |

---

## Categories — Stores Expense Types

Each row represents an available category.

| Field | Description |
|---|---|
| `id` | Unique identifier |
| `name` | Displayed name (e.g., "Food & Dining") |
| `icon` | An emoji (e.g., 🍔) |
| `color` | A color as an integer value (e.g., `0xFFFF5722` = orange) |

A transaction references a category through `categoryId`:

```
Transactions                    Categories
┌─────────────────┐            ┌──────────────────┐
│ id: abc-123     │            │ id: cat_food     │
│ description: Taxi│            │ name: Food       │
│ categoryId ─────┼────────►   │ icon: 🍔         │
│ amount: 25      │            │ color: 0xFFFF5722│
└─────────────────┘            └──────────────────┘
```

---

## SyncQueue — Stores Pending Operations

This is where the app differs from a normal app. When the user performs an action offline, we don't just store the data — we also store **the operation to execute on the server**.

| Field | Description |
|---|---|
| `id` | Auto-increment (local queue only, no sync needed, so no UUID required) |
| `entityType` | What it targets (`"transaction"` or `"category"`) |
| `entityId` | The ID of the targeted transaction or category |
| `operation` | What to do (`"create"`, `"update"`, `"delete"`) |
| `data` | The data as a JSON string |
| `retryCount` | How many times the sync has already been retried |
| `lastAttemptAt` | When the last sync attempt was made |

---

## Why Transactions Has So Many Fields

You'll notice that Transactions has significantly more fields than Categories. That's because it serves **two roles at the same time**: storing the data **and** managing the sync.

---

### Sync Fields in Transactions

```dart
// 1. syncStatus — the current sync state
IntColumn get syncStatus => integer().withDefault(const Constant(0))();
// 0 = pending, 1 = syncing, 2 = synced, 3 = failed, 4 = conflict

// 2. isPendingSync — is this transaction waiting to be sent?
BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
// true = not yet sent to the server
```

---

### The Timestamps — Why Are There Four?

```dart
createdAt         →  When the user created the transaction on their phone
updatedAt         →  When the user last modified it locally
syncedAt          →  When the last successful sync happened
serverUpdatedAt   →  When the SERVER last updated this transaction
```

Each one has a specific role:

```
User creates "Taxi 25 DT"
        ↓
createdAt = now
updatedAt = now
syncedAt = null          ← not synced yet
serverUpdatedAt = null   ← the server doesn't know about it yet

        ↓ sync succeeds

syncedAt = now           ← now it does
serverUpdatedAt = value from server  ← the server confirms

        ↓ another device modifies the same transaction

serverUpdatedAt changes  ← the server has a new version
updatedAt (local) stays  ← the local version hasn't changed

        ↓ Conflict Resolver compares these two timestamps
          to decide which version to keep
```

This is exactly why `serverUpdatedAt` is needed in addition to `updatedAt` — to compare **the local version vs the server version** and detect conflicts.

---

### `isDeleted` — Soft Delete

```dart
BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
```

Instead of actually deleting the row from the database:

```
// ❌ Hard delete — the row disappears
DELETE FROM transactions WHERE id = 'abc-123';
// The server will never know this transaction was deleted

// ✅ Soft delete — we keep the row but mark it
UPDATE transactions SET isDeleted = true WHERE id = 'abc-123';
// The Sync Engine sees isDeleted = true
// It sends a DELETE request to the server
// After a successful sync, the row can be permanently removed
```

Without soft delete, if the user deletes a transaction while offline, the Sync Engine would have no way of knowing it needs to be deleted on the server as well.