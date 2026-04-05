# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Nathemni (نظمني) is a personal organization and productivity Flutter app supporting Arabic (RTL) as the primary language. It uses an offline-first architecture with SQLite for local storage and syncs with a Laravel backend at `https://nathemni.ly`.

## Development Commands

```powershell
# Install dependencies
flutter pub get

# Run app (development - uses production API by default)
flutter run

# Run with specific environment
flutter run --dart-define=ENV=prod
flutter run --dart-define=ENV=staging

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release APK
flutter build apk --release --dart-define=ENV=prod

# Build App Bundle (Play Store)
flutter build appbundle --release --dart-define=ENV=prod

# Generate launcher icons (after modifying pubspec.yaml flutter_launcher_icons config)
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

## Architecture

### Directory Structure

The codebase follows a feature-based architecture:

- `lib/core/` - Shared infrastructure (config, theme, navigation, utils, widgets)
- `lib/data/` - Global data layer (API client, database helper, shared models)
- `lib/features/` - Feature modules, each containing:
  - `data/` - Models, repositories, and DAOs
  - `presentation/` - Screens and widgets
  - `providers/` - Riverpod state management
- `lib/l10n/` - Internationalization

### Key Patterns

**Offline-First with Repository Pattern**:
- `*_repository.dart` - Abstracts data access, handles offline-first logic
- `*_local_dao.dart` - SQLite database operations
- `*_local_model.dart` - Local database models with sync fields (`sync_status`, `sync_id`, `server_id`)

**State Management (Riverpod)**:
- `StateNotifierProvider` with `AsyncValue<T>` for async data
- Providers load data in constructor via `Future.microtask()`
- Use `ref.invalidate()` to refresh dependent providers

**Database Schema**:
- All tables include sync-related columns: `server_id`, `is_synced`, `sync_id`, `sync_status`, `last_modified`
- Foreign keys enabled via `PRAGMA foreign_keys = ON`
- Schema versioning with `_upgradeDB()` for migrations

**API Client**:
- Dio-based with interceptors for auth token injection
- Tokens stored in `flutter_secure_storage`
- Environment-based URLs via `EnvConfig` (uses `--dart-define=ENV=xxx`)

### Feature Module Structure Example

```
features/tasks/
├── data/
│   ├── task_local_model.dart    # SQLite model with toMap/fromMap
│   ├── tasks_local_dao.dart     # Database CRUD operations
│   └── tasks_repository.dart    # Business logic, offline-first
├── presentation/
│   ├── tasks_screen.dart        # List screen
│   ├── add_task_screen.dart     # Create/edit form
│   └── task_details_screen.dart
└── providers/
    └── tasks_providers.dart     # StateNotifierProvider + notifier class
```

### Navigation

Uses named routes via `MaterialApp.routes` with `AppRoutes` class. Navigate with:
```dart
Navigator.pushNamed(context, AppRoutes.tasks);
```

### Theming

Brand colors and theme defined in `lib/core/theme/app_theme.dart`:
- Primary: `#146084` / `#6D99A0`
- Accent: `#F4B860`
- Success: `#3FA796`
- Error: `#D64545`
- Font: Cairo (bundled in `fonts/`)

## Conventions

- Arabic is the default locale; all user-facing strings should support RTL
- Currency defaults to LYD (Libyan Dinar)
- User ID defaults to `1` for local-only mode (see `currentUserIdProvider`)
- Models use `copyWith()` pattern for immutability
- Database operations return affected row counts for verification
