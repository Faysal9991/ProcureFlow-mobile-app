# Procurement Management

Offline-first Flutter MVP for a SaaS procurement workflow.

## Stack

- Flutter + Material 3
- Riverpod for dependency injection and state
- GoRouter for navigation
- Drift/SQLite for local offline storage
- Dio + Retrofit for typed backend clients
- Equatable for value-based domain models

## Mobile Architecture

The mobile app uses a feature-first structure with shared infrastructure in
`core/`:

```text
lib/
 |-- app/
 |   |-- procurement_app.dart
 |   |-- router/
 |   `-- theme/
 |-- core/
 |   |-- api/
 |   |-- config/
 |   |-- providers/
 |   |-- storage/
 |   |-- database/
 |   |-- network/
 |   |-- sync/
 |   `-- widgets/
 `-- features/
     |-- auth/
     |-- dashboard/
     |-- notifications/
     |-- purchase_request/
     |-- purchase_order/
     |-- approval/
     `-- vendor/
```

Core package responsibilities:

- `flutter_riverpod`: dependency injection and app state
- `go_router`: guarded navigation and auth redirects
- `dio` + `retrofit`: HTTP client and typed API definitions
- `flutter_secure_storage`: access-token and session persistence
- `drift`: local database/cache for offline-first workflows
- `connectivity_plus`: online/offline checks
- `lucide_icons_flutter`: app icon set

## Phase 1 Auth Startup

Implemented startup flow:

```text
Open app
 -> SplashScreen
 -> Read secure access token
 -> If no token: LoginScreen
 -> If token exists: GET /auth/me
 -> If invalid: clear token and LoginScreen
 -> If mustChangePassword == true: ChangePasswordScreen
 -> Else: GET /auth/permissions
 -> Store permissions in AuthSession
 -> DashboardScreen
```

`API_BASE_URL` should include the API version prefix, for example
`https://your-api.example/api/v1`. Retrofit paths are declared as `/auth/...`,
so the full backend URLs resolve to `/api/v1/auth/...`.

## Phase 2 Home Shell

Implemented post-login scope:

```text
/dashboard
/notifications
/profile
/change-password
/login
```

The mobile bottom navigation contains only:

```text
Home
Notifications
Profile
```

Phase 2 is not module development. Purchase Requests, Approvals, Vendors, RFQ,
Purchase Orders, Invoices, Budgets, and Reports are permission-gated dashboard
menu items. If the user has permission, the item is visible as disabled
`Coming Soon`; without permission, it is hidden.

Phase 2 API paths:

```text
GET  /dashboard/summary
GET  /notifications/unread-count
GET  /notifications?page=1&limit=10
POST /notifications/{id}/read
POST /notifications/read-all
```

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
flutter run --dart-define-from-file=.env
```

The local `.env` file uses the same compile-time values read by
`String.fromEnvironment`:

```dotenv
USE_MOCK_API=false
API_BASE_URL=https://your-api.example/api/v1
```

## Verification

```sh
dart run build_runner build
flutter analyze
flutter test
```
# ProcureFlow-mobile-app
