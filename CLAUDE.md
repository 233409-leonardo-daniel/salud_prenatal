# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter mobile app "Salud Prenatal" (package name `salud_prenatal`, app name `mama_segura` in pubspec `name:` history) — prenatal health tracking connecting patients, doctors, and receptionists. Consumes a remote REST API at `https://saludprenatal.sytes.net/api/v1` (see [lib/core/config/api_config.dart](lib/core/config/api_config.dart)); there is no backend code in this repo.

## Commands

```
flutter pub get                        # install dependencies
flutter run                            # run on connected device/emulator
flutter analyze                        # static analysis (flutter_lints)
flutter test                           # run all tests
flutter test test/widget_test.dart     # run a single test file
flutter build apk / flutter build windows   # platform builds
```

No CI config, no custom lint overrides beyond `package:flutter_lints/flutter.yaml` ([analysis_options.yaml](analysis_options.yaml)).

## Architecture

Feature-first clean architecture. Each feature under `lib/features/<name>/` follows the same four-folder shape:

```
data/
  datasources/   # *RemoteDataSource — raw http calls via ApiClient, decodes JSON, throws Exception on non-2xx
  models/        # DTOs (fromJson/toJson)
  mappers/       # DTO <-> domain entity conversion (where present)
  repositories/  # *RepositoryImpl implementing the domain repository interface
domain/
  entities/      # plain domain objects
  repositories/  # abstract repository interfaces
  usecases/      # one class per use case, exposes `execute(...)`
di/
  <feature>_module.dart   # manually wires datasource -> repository -> usecases (no code-gen DI)
presentation/
  pages/         # widgets/screens, often paired with a *_state.dart enum/status file
  providers/     # ChangeNotifier providers consumed via package:provider
  widgets/       # feature-local widgets
```

Features present: `appointments`, `chat`, `dashboard`, `forums`, `login`, `patient_diaries`, `patients`, `privacy_policy`, `profile`, `register`, `subscriptions`, `users`.

Note: naming is inconsistent across features/older code — some usecases are suffixed `UseCase`, others `Usecase` (e.g. `appointments` has both `get_appointments_use_case.dart` and `get_appointments_usecase.dart` as distinct classes). Check the actual class name before assuming which one a provider uses.

### Wiring (composition root)

There is no DI framework. [lib/app.dart](lib/app.dart) is the composition root:
1. Instantiates `CoreModule` (holds the single `ApiClient` and `QrService`, see [lib/core/di/core_module.dart](lib/core/di/core_module.dart)).
2. Instantiates every feature's `*Module(apiClient)`, which builds its own datasource → repository → usecases chain.
3. Registers a `Provider`/`ChangeNotifierProvider` per feature provider inside a `MultiProvider`, passing usecases from the modules into the provider constructors.
4. Declares named routes (`/login`, `/register`, `/dashboard`, `/home`, `/patient-diaries`, `/forums`, `/subscription`) — many pages are still pushed via `Navigator.push` directly rather than named routes.

When adding a feature, follow this same pattern: datasource → repository → usecase → module → provider registration in `app.dart`.

### Networking

[lib/core/network/api_client.dart](lib/core/network/api_client.dart) is a thin `http` wrapper (get/post/put/delete + `getById`). Key behaviors:
- Auth token is stored in a **static** field (`ApiClient._authToken`), so it's shared across all `ApiClient()` instances app-wide — set via `setAuthToken`/`clearAuthToken` from `LoginProvider`.
- Emits a static broadcast stream `ApiClient.onPaymentRequired` whenever any request returns HTTP 402 (doctor subscription inactive). `SubscriptionGateListener` ([lib/core/widgets/subscription_gate_listener.dart](lib/core/widgets/subscription_gate_listener.dart)) listens globally and redirects to `/subscription`.
- Data sources throw plain `Exception('...: Status: <code>')` on non-2xx responses (in Spanish); providers catch these and strip the `Exception: ` prefix for display.

### Cross-cutting app behavior

- `SessionTimeoutListener` ([lib/core/widgets/session_timeout_listener.dart](lib/core/widgets/session_timeout_listener.dart)) wraps the whole app, logs the user out after 20 minutes of inactivity (tracked via `shared_preferences` timestamp + app lifecycle events), and force-navigates to `/login` using the static `MyApp.navigatorKey`.
- Both `SessionTimeoutListener` and `SubscriptionGateListener` rely on `MyApp.navigatorKey` (a `GlobalKey<NavigatorState>`) to navigate without a `BuildContext`, since they sit outside any single page's widget tree.
- Theming is centralized in [lib/core/theme/theme.dart](lib/core/theme/theme.dart) (`AppTheme.lightTheme`/`darkTheme`); `AppColors.isDarkMode` is set manually in `MaterialApp.builder` from `MediaQuery` platform brightness rather than relying on `Theme.of(context)` everywhere.
- Roles are strings from the backend (`'doctor'`/`'doctor(a)'`, `'paciente'`, `'recepcionista'`, `'admin'`) — `LoginProvider.isDoctor` normalizes the doctor check; other role checks are done ad hoc against these string values.

## UI/UX conventions

- Never block a user-triggered action (button tap, opening a dialog/sheet) on an `await` before showing anything. Kick off the fetch, show the UI immediately, and render a loading state inline while it resolves — e.g. open the `showModalBottomSheet`/page right away and use a `FutureBuilder` (or provider loading flag) inside it to switch between skeleton and content, instead of `await`-ing the fetch before calling `showModalBottomSheet`/`Navigator.push`.
- Prefer a skeleton (placeholder shapes matching the eventual layout, e.g. `_ContactsSkeletonList` in [chat_list_page.dart](lib/features/chat/presentation/pages/chat_list_page.dart)) over a bare spinner when the loading area has a known list/card shape. Fall back to a spinner only for opaque/full-page loads where a skeleton shape doesn't make sense.
- Skeleton placeholder blocks must use `AppColors.skeletonBase` ([theme.dart](lib/core/theme/theme.dart)), never a hardcoded hex pair. It's derived from the current theme (`textDark` blended over `cardBackground`) so it always contrasts with the surrounding card/sheet — a fixed hex per light/dark variant WILL eventually match `cardBackground` exactly and render an invisible skeleton (happened once already in the contacts dialog).
- When a screen needs data from more than one provider/usecase, fire the independent ones concurrently with `Future.wait(...)` rather than sequential `await`s — don't serialize requests that don't depend on each other.

## Design reference

`stitch_prompt_*.md` files at the repo root are design-system prompts (color palette, component shapes, typography) used with Google Stitch to generate new screens matching the existing visual language — not app documentation. Consult them if asked to design new screens/roles in the same style.
