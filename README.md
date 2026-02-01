# flutter_drift_advanced_project

A production-ready **offline-first expense tracker** built with Flutter, demonstrating advanced patterns including Drift database, background API synchronization, Clean Architecture, and conflict resolution.

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-027DFD?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- **Offline-First**: Full functionality without internet — data is saved locally first, synced later automatically
- **Background Sync**: Transactions sync to the remote API even when the app is closed, powered by WorkManager
- **Conflict Resolution**: Handles data conflicts between local and server versions (client wins, server wins, manual, or field-level merge)
- **Clean Architecture**: Clearly separated Presentation, Domain, and Data layers for maintainability and testability
- **BLoC State Management**: Reactive state handling with flutter_bloc
- **Network Detection**: Automatic online/offline awareness — syncs only when connected
- **Real-time Updates**: UI updates instantly via Drift's reactive streams

---

## 🏗️ Architecture

This project follows **Clean Architecture** with dependencies pointing inward:

```
┌─────────────────────────────────────────────┐
│             PRESENTATION LAYER               │
│   Pages, Widgets, BLoC (Flutter UI)          │
└─────────────────┬───────────────────────────┘
                  │ depends on
┌─────────────────▼───────────────────────────┐
│               DOMAIN LAYER                   │
│   Entities, Use Cases, Repository Interfaces │
│   (Pure Dart — no Flutter dependencies)      │
└─────────────────▲───────────────────────────┘
                  │ implemented by
┌─────────────────┼───────────────────────────┐
│               DATA LAYER                     │
│   Drift (local), HTTP (remote), Models,      │
│   Sync Engine, Conflict Resolver             │
└──────────────────────────────────────────────┘
```

### How Sync Works

```
User adds a transaction
        ↓
Save instantly to local Drift DB   ← UI updates immediately
Mark as "pending sync"
        ↓
WorkManager triggers every 15 min  ← runs even if app is closed
        ↓
Sync Engine picks up pending items
        ↓
Push to remote API (if online)
        ↓
Update status to "synced" in local DB
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── database/          # Drift database definition & generated code
│   ├── di/                # Dependency injection (GetIt)
│   ├── network/           # HTTP client, endpoints, network detection
│   ├── errors/            # Exceptions & Failure types
│   ├── utils/             # Constants, typedefs, logger
│   └── sync/              # Sync engine, queue, conflict resolver, scheduler
└── features/
    └── transactions/
        ├── domain/        # Entities, repository interfaces, use cases
        ├── data/          # Models, local/remote datasources, repository impls
        └── presentation/  # BLoC, pages, widgets
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `drift` / `drift_dev` | Local SQLite database with type-safe queries and code generation |
| `flutter_bloc` / `bloc` | State management |
| `dartz` | Functional programming (`Either` for error handling) |
| `get_it` | Dependency injection container |
| `workmanager` | Background task scheduling (Android) |
| `connectivity_plus` | Online/offline network detection |
| `http` | REST API communication |
| `uuid` | Unique ID generation for local entities |
| `mocktail` / `bloc_test` | Unit & BLoC testing |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio or VS Code with Flutter plugin

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/your-username/flutter_drift_advanced_project.git
cd flutter_drift_advanced_project
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Generate code** (Drift requires code generation)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**4. Run the app**

```bash
flutter run
```

---

## 🔄 Sync States

Each transaction tracks its synchronization status:

| Status | Meaning |
|---|---|
| `pending` | Saved locally, waiting to be sent to the server |
| `syncing` | Currently being uploaded |
| `synced` | Successfully saved on the server |
| `failed` | Sync attempt failed — will retry automatically |
| `conflict` | Local and remote versions differ — needs resolution |

---

## ⚡ Conflict Resolution Strategies

When the local and server versions of a transaction diverge, the app supports four strategies:

- **Client Wins** — keeps the local version based on the most recent `updatedAt` timestamp
- **Server Wins** — overwrites local data with the server version
- **Manual** — shows a dialog letting the user choose which version to keep
- **Field-Level Merge** — merges non-conflicting fields from both versions

---

## 🧪 Testing

The project includes unit tests for every layer:

```bash
flutter test
```

- **Domain**: use case logic tested independently with mocked repositories
- **Data**: datasources and repository implementations tested with mocked dependencies
- **Presentation**: BLoC tested with `bloc_test`, widgets tested with `testWidgets`
- **Sync**: integration tests covering the full sync + conflict resolution flow

---

## ⚠️ Important Notes

- **WorkManager is Android-only.** For a production iOS release, you would need to add `background_fetch` and abstract the scheduling behind a platform-agnostic interface.
- **API base URL** is configured in `lib/core/utils/constants.dart`. Replace it with your actual backend URL before deploying.
- **Database encryption** is not enabled by default. For production, consider integrating `sqlcipher` for encrypting sensitive local data.

---

## 📚 Resources

- [Drift — Reactive SQLite for Dart & Flutter](https://drift.simonbinder.eu/)
- [BLoC Pattern — State Management](https://bloclibrary.dev/)
- [Clean Architecture — Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Dartz — Functional Programming in Dart](https://pub.dev/packages/dartz)

---

## 📝 License

This project is licensed under the MIT License.
