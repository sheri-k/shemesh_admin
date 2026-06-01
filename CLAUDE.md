# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
```bash
# Build for production database
./build.sh prod

# Build for default (dev) database
./build.sh dev
```
Both scripts run `flutter build web --dart-define=DATABASE_ID=<value>` and output to `build/web/`.

### Run locally
```bash
flutter run -d chrome --dart-define=DATABASE_ID=production
flutter run -d chrome --dart-define=DATABASE_ID='(default)'
```

### Deploy
```bash
./admin_deploy.sh          # Deploy to production Firebase Hosting (target: admin)
./admin_test_deploy.sh     # Deploy to preview channel (shemesh-admin)
```

### No tests
The only test file (`test/widget_test.dart`) is an unmodified generated template and is not maintained. There is no test suite to run.

## Architecture

**Single-page web admin dashboard** for monitoring Shemesh Begivon app statistics. Firebase project: `shemesh-test`.

### Data flow
1. `main.dart` initializes the `FirebaseService` singleton, then renders `AdminLoginPage`
2. Login uses Firebase Auth (email/password) + custom JWT admin claim check
3. On success, navigates to `DashboardPage` via `Navigator.pushReplacement()`
4. Dashboard calls `DashboardStats.loadStats()` which fans out parallel Firestore queries via `Future.wait()`

### Firebase / multi-database
`FirebaseService` (singleton) reads the database via:
```dart
const databaseId = String.fromEnvironment('DATABASE_ID', defaultValue: '(default)');
```
- `'production'` — production Firestore database
- `'(default)'` — development Firestore database

All Firestore access goes through `FirebaseService().firestore` — never instantiate `FirebaseFirestore.instance` directly, as it would bypass the selected database.

### State management
No framework. All state is vanilla `StatefulWidget` + `setState()`. Async data is loaded with `FutureBuilder`. Charts receive pre-computed data from `DashboardStats.loadStats()`.

### Firestore collections queried
- `users` — total count, active (last 7 days via `last_login`), new registrations (last 30 days via `date_of_registration`)
- `collectionGroup('test_data')` — quiz submissions by date
- `analytics/guest_stats` — guest login and quiz submission counts

### UI conventions
- All UI is **RTL** (Hebrew). Wrap new layouts in `Directionality(textDirection: TextDirection.rtl, ...)` or rely on the app-level RTL setting.
- Color palette and time-period constants are in `lib/config/common_consts.dart`.
- Cross-platform logging via `debugLog()` in `lib/utilities/debug_log.dart` — use this instead of `print()`.
