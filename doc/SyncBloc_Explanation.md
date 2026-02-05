# SyncBloc — Background Synchronization Management

The SyncBloc manages the **synchronization status** between the local database and the remote server. Unlike TransactionBloc which handles user actions on transactions, SyncBloc handles the **background sync process** itself.

---

## Purpose


This BLoC answers three key questions for the UI:
1. **How many transactions are waiting to sync?** (pending count)
2. **Are we online or offline?** (connectivity status)
3. **What's happening with sync right now?** (idle, syncing, success, error)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                    SyncBloc                           │
│                                                       │
│  Watches:                                             │
│  • Pending sync count (from database)                │
│  • Network connectivity (online/offline)             │
│                                                       │
│  Controls:                                            │
│  • Manual sync trigger                                │
│  • Auto-sync start/stop                               │
└──────────────────────────────────────────────────────┘
           │                    │
           │                    │
    ┌──────▼──────┐      ┌─────▼──────┐
    │ SyncEngine  │      │NetworkInfo │
    │             │      │            │
    │ • sync()    │      │ • isOnline │
    │ • startAuto│      │ • onChange │
    │ • stopAuto │      └────────────┘
    └─────────────┘
```

---

## Events Explained

### 1. StartSync — Trigger Manual Sync

```dart
class StartSync extends SyncEvent {}
```

**Purpose**: User manually requests a sync (e.g., taps "Sync Now" button).

**When triggered**:
- User taps sync button
- App detects coming back online with pending items
- Pull-to-refresh on transactions screen

**Example**:
```dart
// In a sync button widget
IconButton(
  icon: Icon(Icons.sync),
  onPressed: () {
    context.read<SyncBloc>().add(StartSync());
  },
)
```

---

### 2. StopSync — Stop Automatic Sync

```dart
class StopSync extends SyncEvent {}
```

**Purpose**: Disable background automatic synchronization.

**When triggered**:
- User disables sync in settings
- Battery saver mode activated
- App enters background (optional)

**Example**:
```dart
// In settings screen
SwitchListTile(
  title: Text('Auto Sync'),
  value: autoSyncEnabled,
  onChanged: (value) {
    if (!value) {
      context.read<SyncBloc>().add(StopSync());
    }
  },
)
```

---

### 3. CheckConnectivity — Verify Network Status

```dart
class CheckConnectivity extends SyncEvent {}
```

**Purpose**: Check current network connectivity and update the state accordingly.

**When triggered**:
- App resumes from background
- Network state changes (WiFi → Mobile, Online → Offline)
- User manually requests connectivity check

**This event is automatically triggered** by the connectivity stream listener:

```dart
_connectivitySubscription = networkInfo.onConnectivityChanged.listen((isOnline) {
  add(CheckConnectivity());  // Auto-triggered when connectivity changes
});
```

---

### 4. SyncStatusUpdated — Pending Count Changed

```dart
class SyncStatusUpdated extends SyncEvent {
  final int pendingCount;
  const SyncStatusUpdated(this.pendingCount);
}
```

**Purpose**: Update the UI with the current number of pending transactions.

**When triggered**:
- Database detects new pending transaction
- Transaction is marked as synced
- Transaction is deleted

**This event is automatically triggered** by the pending count stream:

```dart
_pendingSubscription = watchPendingSyncCount().listen((count) {
  add(SyncStatusUpdated(count));  // Auto-triggered when count changes
});
```

---

## States Explained

### 1. SyncInitial — Starting State

```dart
class SyncInitial extends SyncState {}
```

**When**: BLoC is first created, before any checks run.

**UI should**: Show nothing or a placeholder.

---

### 2. SyncIdle — Ready and Waiting

```dart
class SyncIdle extends SyncState {
  final int pendingCount;
  final bool isOnline;
  
  const SyncIdle({
    required this.pendingCount,
    required this.isOnline,
  });
}
```

**When**: Everything is normal, no sync currently happening.

**Properties**:
- `pendingCount` — How many transactions need syncing
- `isOnline` — Whether device has internet

**UI should**: 
```dart
if (state is SyncIdle) {
  return Badge(
    label: Text('${state.pendingCount} pending'),
    child: Icon(
      state.isOnline ? Icons.cloud : Icons.cloud_off,
    ),
  );
}
```

---

### 3. Syncing — Sync in Progress

```dart
class Syncing extends SyncState {
  final int totalItems;
  final int syncedItems;
  
  const Syncing({
    required this.totalItems,
    required this.syncedItems,
  });
  
  double get progress => totalItems > 0 ? syncedItems / totalItems : 0;
}
```

**When**: Background sync is actively running.

**Properties**:
- `totalItems` — Total transactions to sync
- `syncedItems` — How many have synced so far
- `progress` — Calculated percentage (0.0 to 1.0)

**UI should**:
```dart
if (state is Syncing) {
  return LinearProgressIndicator(
    value: state.progress,
  );
}
```

---

### 4. SyncSuccess — Sync Completed

```dart
class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess(this.syncedCount);
}
```

**When**: Sync finished successfully.

**Properties**:
- `syncedCount` — How many transactions were synced

**UI should**:
```dart
BlocListener<SyncBloc, SyncState>(
  listener: (context, state) {
    if (state is SyncSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${state.syncedCount} transactions synced')),
      );
    }
  },
)
```

---

### 5. SyncError — Sync Failed

```dart
class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
}
```

**When**: Sync encountered an error.

**Properties**:
- `message` — Human-readable error description

**UI should**:
```dart
if (state is SyncError) {
  return Card(
    color: Colors.red,
    child: ListTile(
      leading: Icon(Icons.error),
      title: Text('Sync failed'),
      subtitle: Text(state.message),
      trailing: TextButton(
        child: Text('Retry'),
        onPressed: () => context.read<SyncBloc>().add(StartSync()),
      ),
    ),
  );
}
```

---

### 6. Offline — No Internet Connection

```dart
class Offline extends SyncState {
  final int pendingCount;
  const Offline(this.pendingCount);
}
```

**When**: Device has no internet, but there are pending transactions.

**Properties**:
- `pendingCount` — How many transactions waiting

**UI should**:
```dart
if (state is Offline) {
  return Banner(
    message: '${state.pendingCount} pending - Offline',
    color: Colors.orange,
    icon: Icons.cloud_off,
  );
}
```

---

## BLoC Initialization and Watchers

```dart
SyncBloc({
  required this.syncEngine,
  required this.networkInfo,
  required this.watchPendingSyncCount,
}) : super(SyncInitial()) {
  // Register event handlers
  on<StartSync>(_onStartSync);
  on<StopSync>(_onStopSync);
  on<CheckConnectivity>(_onCheckConnectivity);
  on<SyncStatusUpdated>(_onSyncStatusUpdated);
  
  // Start watching automatically
  _startWatching();
}
```

### _startWatching() — Auto-Monitoring

```dart
void _startWatching() {
  // 1. Watch pending sync count from database
  _pendingSubscription = watchPendingSyncCount().listen((count) {
    add(SyncStatusUpdated(count));
  });
  
  // 2. Watch network connectivity changes
  _connectivitySubscription = networkInfo.onConnectivityChanged.listen((isOnline) {
    add(CheckConnectivity());
  });
}
```

**What it does**:

```
Database changes (INSERT/UPDATE/DELETE)
        ↓
watchPendingSyncCount() stream emits new count
        ↓
BLoC adds SyncStatusUpdated(count) event
        ↓
State updates with new pending count
        ↓
UI badge updates automatically

Network changes (WiFi → Mobile, Online → Offline)
        ↓
networkInfo.onConnectivityChanged emits
        ↓
BLoC adds CheckConnectivity() event
        ↓
State updates with new online/offline status
        ↓
UI icon changes (cloud → cloud_off)
```

---

## Event Handler 1: _onStartSync

```dart
Future<void> _onStartSync(
  StartSync event,
  Emitter<SyncState> emit,
) async {
  // 1. Check if online
  if (!await networkInfo.isConnected) {
    final currentState = state;
    if (currentState is SyncIdle) {
      emit(Offline(currentState.pendingCount));
    }
    return;
  }
  
  // 2. Start syncing
  emit(const Syncing(totalItems: 0, syncedItems: 0));
  
  try {
    // 3. Call sync engine
    await syncEngine.sync();
    
    // 4. Success
    emit(const SyncSuccess(0));
  } catch (e) {
    // 5. Error
    emit(SyncError(e.toString()));
  }
}
```

### Flow

```
User taps "Sync Now"
        ↓
Widget: bloc.add(StartSync())
        ↓
BLoC: Check networkInfo.isConnected
        ↓
IF OFFLINE:
  emit(Offline(pendingCount))
  UI shows: "No internet connection"
  STOP HERE
        ↓
IF ONLINE:
  emit(Syncing(totalItems: 0, syncedItems: 0))
  UI shows: Progress indicator
        ↓
  Call: syncEngine.sync()
        ↓
  Sync Engine:
    1. Gets pending transactions from DB
    2. Sends batch to server
    3. Marks as synced
        ↓
  SUCCESS:
    emit(SyncSuccess(syncedCount))
    UI shows: "3 transactions synced" snackbar
        ↓
  ERROR:
    emit(SyncError('Server error'))
    UI shows: Error banner with retry button
```

---

## Event Handler 2: _onStopSync

```dart
Future<void> _onStopSync(
  StopSync event,
  Emitter<SyncState> emit,
) async {
  syncEngine.stopAutoSync();
}
```

**Simple**: Just tells the SyncEngine to stop its periodic WorkManager task.

```
User disables "Auto Sync" in settings
        ↓
Widget: bloc.add(StopSync())
        ↓
BLoC: syncEngine.stopAutoSync()
        ↓
WorkManager: Cancels periodic sync task
        ↓
No more background syncs until user re-enables
```

---

## Event Handler 3: _onCheckConnectivity

```dart
Future<void> _onCheckConnectivity(
  CheckConnectivity event,
  Emitter<SyncState> emit,
) async {
  // 1. Check current network status
  final isOnline = await networkInfo.isConnected;
  
  // 2. Get current pending count
  final currentState = state;
  int pendingCount = 0;
  
  if (currentState is SyncIdle) {
    pendingCount = currentState.pendingCount;
  } else if (currentState is Offline) {
    pendingCount = currentState.pendingCount;
  }
  
  // 3. Update state based on connectivity
  if (isOnline) {
    emit(SyncIdle(pendingCount: pendingCount, isOnline: true));
    
    // 4. Auto-trigger sync if there are pending items
    if (pendingCount > 0) {
      add(StartSync());
    }
  } else {
    emit(Offline(pendingCount));
  }
}
```

### Flow: Coming Back Online

```
Phone was offline
Current state: Offline(pendingCount: 5)
        ↓
WiFi reconnects
        ↓
networkInfo.onConnectivityChanged emits: true
        ↓
BLoC adds: CheckConnectivity()
        ↓
Handler checks: isOnline = true
        ↓
Handler emits: SyncIdle(pendingCount: 5, isOnline: true)
        ↓
Handler sees: pendingCount > 0
        ↓
Handler adds: StartSync()  ← Automatic sync!
        ↓
Sync begins automatically
        ↓
UI shows: "Syncing 5 transactions..."
```

### Flow: Going Offline

```
Phone online
Current state: SyncIdle(pendingCount: 3, isOnline: true)
        ↓
WiFi disconnects
        ↓
networkInfo.onConnectivityChanged emits: false
        ↓
BLoC adds: CheckConnectivity()
        ↓
Handler checks: isOnline = false
        ↓
Handler emits: Offline(pendingCount: 3)
        ↓
UI shows: "3 pending - Offline" banner
```

---

## Event Handler 4: _onSyncStatusUpdated

```dart
Future<void> _onSyncStatusUpdated(
  SyncStatusUpdated event,
  Emitter<SyncState> emit,
) async {
  final isOnline = await networkInfo.isConnected;
  emit(SyncIdle(pendingCount: event.pendingCount, isOnline: isOnline));
}
```

### Flow: User Adds Transaction

```
User adds "Taxi 25 DT"
        ↓
Transaction saved to local DB with isPendingSync = true
        ↓
Drift database changes
        ↓
watchPendingSyncCount() stream emits: 1
        ↓
BLoC adds: SyncStatusUpdated(1)
        ↓
Handler emits: SyncIdle(pendingCount: 1, isOnline: true)
        ↓
UI badge updates: Shows "1 pending"
```

### Flow: Transaction Syncs

```
Sync completes for one transaction
        ↓
markAsSynced() updates DB: isPendingSync = false
        ↓
Drift database changes
        ↓
watchPendingSyncCount() stream emits: 0
        ↓
BLoC adds: SyncStatusUpdated(0)
        ↓
Handler emits: SyncIdle(pendingCount: 0, isOnline: true)
        ↓
UI badge disappears (no pending items)
```

---

## Complete Example: User Journey

```
┌──────────────────────────────────────────────────────┐
│ SCENARIO: User creates transaction offline,          │
│ then comes back online                                │
└──────────────────────────────────────────────────────┘

1. INITIAL STATE
   State: SyncIdle(pendingCount: 0, isOnline: true)
   UI: ☁️ (cloud icon, no badge)

2. USER GOES OFFLINE
   WiFi disconnects
        ↓
   networkInfo.onConnectivityChanged → false
        ↓
   BLoC: CheckConnectivity event
        ↓
   State: Offline(pendingCount: 0)
   UI: ☁️❌ (cloud with slash)

3. USER ADDS TRANSACTION OFFLINE
   User adds "Taxi 25 DT"
        ↓
   Saved to DB with isPendingSync = true
        ↓
   watchPendingSyncCount() → 1
        ↓
   BLoC: SyncStatusUpdated(1)
        ↓
   State: Offline(pendingCount: 1)
   UI: ☁️❌ [1] (offline, 1 pending)

4. USER ADDS ANOTHER TRANSACTION
   User adds "Café 5 DT"
        ↓
   watchPendingSyncCount() → 2
        ↓
   State: Offline(pendingCount: 2)
   UI: ☁️❌ [2] (offline, 2 pending)

5. USER COMES BACK ONLINE
   WiFi reconnects
        ↓
   networkInfo.onConnectivityChanged → true
        ↓
   BLoC: CheckConnectivity event
        ↓
   Handler sees: isOnline = true, pendingCount = 2
        ↓
   State: SyncIdle(pendingCount: 2, isOnline: true)
   UI: ☁️ [2] (online, 2 pending)
        ↓
   Handler sees: pendingCount > 0
        ↓
   Handler adds: StartSync()  ← AUTO-SYNC

6. SYNC BEGINS
   State: Syncing(totalItems: 2, syncedItems: 0)
   UI: ⟳ Syncing... [████░░░░] 0%

7. FIRST TRANSACTION SYNCED
   markAsSynced("Taxi")
        ↓
   watchPendingSyncCount() → 1
        ↓
   State: Syncing(totalItems: 2, syncedItems: 1)
   UI: ⟳ Syncing... [████████] 50%

8. SECOND TRANSACTION SYNCED
   markAsSynced("Café")
        ↓
   watchPendingSyncCount() → 0
        ↓
   State: SyncSuccess(2)
   UI: ✓ "2 transactions synced" snackbar

9. BACK TO IDLE
   State: SyncIdle(pendingCount: 0, isOnline: true)
   UI: ☁️ (cloud, no badge)
```

---

## Cleanup

```dart
@override
Future<void> close() {
  _pendingSubscription?.cancel();
  _connectivitySubscription?.cancel();
  return super.close();
}
```

**Prevents memory leaks** by canceling both stream subscriptions when the BLoC is disposed.

---

## UI Integration Example

```dart
class SyncStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state is SyncIdle) {
          return IconButton(
            icon: Badge(
              label: state.pendingCount > 0 ? Text('${state.pendingCount}') : null,
              child: Icon(state.isOnline ? Icons.cloud : Icons.cloud_off),
            ),
            onPressed: state.pendingCount > 0
                ? () => context.read<SyncBloc>().add(StartSync())
                : null,
          );
        }
        
        if (state is Syncing) {
          return CircularProgressIndicator(value: state.progress);
        }
        
        if (state is Offline) {
          return Badge(
            label: Text('${state.pendingCount}'),
            backgroundColor: Colors.orange,
            child: Icon(Icons.cloud_off),
          );
        }
        
        return SizedBox();
      },
    );
  }
}
```

---

## Key Takeaways

1. **Two auto-watchers**: Pending count and connectivity status
2. **Auto-sync on reconnect**: When online + pending > 0 → auto StartSync
3. **Real-time UI updates**: Streams keep badge counts current
4. **Offline awareness**: Clear distinction between idle and offline states
5. **Progress tracking**: Syncing state shows sync progress
6. **Error handling**: SyncError state with retry capability
7. **Clean separation**: TransactionBloc handles CRUD, SyncBloc handles sync status

This architecture ensures the UI always shows accurate sync status and automatically triggers sync when appropriate, providing a seamless offline-first experience.
