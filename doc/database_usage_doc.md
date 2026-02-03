Full Concrete Example
Below is a complete scenario showing how every field behaves.

Step 1 — Ahmed creates “Taxi — 25 DT” offline
id: "abc-123"
description: "Taxi"
amount: 25.0
syncStatus: 0                    ← pending
isPendingSync: true             ← waiting for sync
createdAt: 2024-02-03 10:00:00
updatedAt: 2024-02-03 10:00:00
syncedAt: null                  
serverUpdatedAt: null           
isDeleted: false


Step 2 — Ahmed edits the transaction (still offline)
id: "abc-123"
description: "Taxi"
amount: 30.0                     ← updated
syncStatus: 0
isPendingSync: true
createdAt: 2024-02-03 10:00:00
updatedAt: 2024-02-03 10:05:00   ← updated timestamp
syncedAt: null
serverUpdatedAt: null
isDeleted: false


Step 3 — Network returns → Sync Engine pushes data
Server replies:

“OK, transaction created. Here is my timestamp.”

Then Drift updates:
id: "abc-123"
amount: 30.0
syncStatus: 2                    ← synced
isPendingSync: false
createdAt: 2024-02-03 10:00:00
updatedAt: 2024-02-03 10:05:00
syncedAt: 2024-02-03 10:10:00
serverUpdatedAt: 2024-02-03 10:10:00  ← server timestamp
isDeleted: false


Step 4 — Another device edits the same transaction
Remote server now has:
amount: 35.0
serverUpdatedAt: 2024-02-03 10:15:00

When Ahmed's device pulls data:

Local updatedAt = 10:05
Remote serverUpdatedAt = 10:15

Result → Conflict detected
syncStatus: 4   ← conflict

UI shows a conflict resolution dialog.

📦 Why each sync field exists


FieldRolesyncStatusTracks state: pending, syncing, synced, failed, conflictisPendingSyncFast filter to get all unsynced itemscreatedAtWhen the user created the item locallyupdatedAtLast local modification timesyncedAtLast successful sync timeserverUpdatedAtLast server modification timestamp (for conflict detection)isDeletedSoft delete: ensures offline deletes sync later

🎨 Categories Table — Simpler Structure
Categories rarely change and rarely cause conflicts, so they do not include sync fields.
Example:
Dartid: "cat_food"name: "Food & Dining"icon: "🍔"color: 0xFFFF5722createdAt: 2024-02-03 10:00:00updatedAt: 2024-02-03 10:00:00isDeleted: falseShow more lines
No syncStatus or isPendingSync.

🔄 SyncQueue Table — The Sync Job Queue
This table stores operations that must be executed on the server:
Dartid: 1entityType: "transaction"entityId: "abc-123"operation: "update"data: '{"amount": 30, ...}'retryCount: 0createdAt: 2024-02-03 10:05:00lastAttemptAt: nullShow more lines
How Sync Engine uses it:
Every 15 minutes (WorkManager)
         ↓
Read SyncQueue WHERE retryCount < 3
         ↓
Send operations to server
         ↓
If success → delete row
If failed → retryCount++


🏛️ AppDatabase Configuration
Dart@DriftDatabase(tables: [Transactions, Categories, SyncQueue])class AppDatabase extends _$AppDatabase {  @override  int get schemaVersion => 1;}Show more lines

🛠️ Migration Strategy
onCreate
Dartawait m.createAll();await _insertDefaultCategories();Show more lines
Creates tables and inserts default categories once.
beforeOpen
Dartawait customStatement('PRAGMA foreign_keys = ON');Show more lines
Enables foreign key enforcement (SQLite does not enable it by default).

📁 Database File Location
The _openConnection function defines the DB path:
Dartfinal dbFolder = await getApplicationDocumentsDirectory();final file = File(p.join(dbFolder.path, AppConstants.databaseName));return NativeDatabase(file);Show more lines
Paths

Android: /data/data/com.yourapp/files/drift_sync_app.db
iOS: ~/Documents/drift_sync_app.db

LazyDatabase ensures the DB opens only when first needed, improving startup performance.

🧩 Full Summary of the Example Flow
1. Ahmed creates "Taxi 25 DT" offline
   → syncStatus = pending  
   → SyncQueue: create

2. He modifies it to 30 DT (offline)
   → updatedAt changes  
   → SyncQueue: update

3. Sync Engine runs
   → Sends to server  
   → Server returns timestamps  
   → syncStatus = synced  
   → SyncQueue row removed

4. Another device changes it to 35 DT
   → serverUpdatedAt updated  
   → Local vs remote timestamps mismatch  
   → Conflict detected

Each field has a precise role in the offline-first lifecycle.

If you'd like, I can also generate:
✅ A UML diagram
✅ A Markdown table of all fields
✅ A color‑coded infographic version
✅ DRY summary for documentation