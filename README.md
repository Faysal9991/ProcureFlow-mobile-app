# Procurement Management

Offline-first Flutter MVP for a SaaS procurement workflow.

## Stack

- Flutter + Material 3
- Riverpod for dependency injection and state
- GoRouter for navigation
- Drift/SQLite for local offline storage
- Dio + Retrofit for typed backend clients
- Equatable for value-based domain models

## MVP Flow

Employee creates a purchase request with items. Requests can be saved online or queued offline as `pending_create`. The sync service pushes pending requests when sync is triggered and marks successful rows as `synced`. Managers can approve or reject requests, and procurement users can create purchase orders from approved requests.

## Demo Login

Any email/password works in mock mode. The role is inferred from the email:

- `employee@demo.com`
- `manager@demo.com`
- `procurement@demo.com`
- `finance@demo.com`

Mock mode is enabled by default. To point Retrofit clients at a backend, run with:

```sh
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your-api.example/api
```

## Verification

```sh
dart run build_runner build
flutter analyze
flutter test
```
# ProcureFlow-mobile-app
