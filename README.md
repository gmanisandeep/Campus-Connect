# CampusConnect

CampusConnect is a new, app-first reconstruction of a unified campus operating platform. The recovered material established the product problem and Student/Faculty feature intent, but did not include the original source, database, stack, deployment, Git history, or measurable outcomes. This repository therefore makes no originality or production-readiness claim.

## Current checkpoint

This repository contains the reviewed Phase 0 specification, a green Phase 1 Flutter foundation, the core of the Phase 2 identity vertical slice, and a first partial Phase 3/4 academics and attendance vertical slice:

- Flutter Material 3 app with Riverpod, GoRouter, responsive Home/Profile/eligible-Academics navigation, secure session persistence, environment validation, typed failures, connectivity state, theme preferences, and a development-only design-system gallery.
- Supabase sign-in, password reset/recovery, crash-safe fail-closed session classification/restoration, profile completion, invitation acceptance, pending-invitation review, and server-derived institution/role selection. Recovery/OTP sessions are denied campus identity data by both the app and backend until a fresh password-authenticated session exists.
- Fail-closed route and permission handling. Academics navigation is enabled only for a backend-configured active Student or Faculty grant; unfinished Campus, Career, Notifications, and the remaining academic/attendance surfaces are not exposed as dead production controls.
- Server-derived institution-local today timetable, Student attendance summaries, Faculty assigned-class rosters, and atomic, idempotent attendance confirmation.
- Encrypted, device-local Faculty attendance drafts backed by Drift and SQLite3MultipleCiphers. A random 256-bit database key is held separately in OS secure storage; drafts contain roster identifiers and marks but no Student display names. Saved, submission-uncertain, and needs-review states preserve server authority, and reconnect never submits automatically.
- Multi-tenant identity, academic, timetable, and attendance schema with RLS, explicit grants, password-AMR authorization helpers, atomic invitation/profile/attendance RPCs, required invitation expiry, deterministic fictional seed fixtures, and 276 pgTAP assertions across four SQL test files.
- A running local Supabase gate: database reset/seed, all 276 pgTAP assertions, schema lint, and a 228-assertion GoTrue/PostgREST/Mailpit verifier. Sixty-nine verifier assertions exercise the academics/attendance path in addition to the seeded identity matrix, recovery-token isolation, password policy, and negative security cases.
- A green hosted GitHub Actions baseline on commit `bc7cc51`: Flutter format, analysis, tests/coverage, release APK compilation, credential scan, Supabase reset, all database contracts, schema lint, and the real-backend verifier passed.
- A verified Android-emulator identity flow using the final emulator APK: real sign-in, process-level session restore, Mailpit recovery deep link, fail-closed recovery across force-stop, password update followed by fresh password authentication, backend-authorized Home, and post-update restore. The backend was reset to its original deterministic seed and the installed app was cleared back to sign-in afterward.
- A verified Android-emulator academics/attendance flow using the current backend-connected APK: Student sign-in and server-dated timetable/summary rendering, Faculty sign-in and exact-roster expansion, status editing, and successful attendance confirmation against local Supabase.
- A verified physical-device flow on a Samsung Galaxy A35 5G running Android 16/API 36 using the prior academics APK: wireless ADB pairing, APK installation, backend port reversal, cold launch, real seeded Student and Faculty sign-in, process-level Student session restore, Student timetable/summary rendering, Faculty exact-roster expansion and status editing, and successful server-confirmed attendance submission.
- A fresh local-device encrypted-draft APK built from the consolidated source gate. It verifies with APK Signature Scheme v2; physical restart/offline/reconnect validation of this exact artifact remains pending until the phone is visible to ADB again.
- Android/iOS scaffolding, custom auth callback scheme, release network permission, development-only local-network allowances, and Flutter/database CI jobs.

This is a **partial Phase 2/3/4 checkpoint**, not a completed release. The preserved device-loopback and emulator-host APKs are local debug builds, not production releases. The prior academics APK passes Student and Faculty end-to-end validation on both the Android emulator and physical device. The encrypted-draft increment now passes its consolidated format, analysis, 141-test, coverage, security-review, and signed-debug-APK gates. Physical persistence/offline/reconnect validation of that exact APK, physical recovery-callback, accessibility, performance, and iOS validation remain open, as do terms/privacy acknowledgement, notification preferences, invitation issuance/admin tooling, the rest of the academic experience, and later product verticals.

## Prerequisites

- Flutter 3.44.6 stable (Dart 3.12.2 was used for this checkpoint)
- Android SDK for Android builds, or macOS/Xcode for iOS builds
- Docker Desktop and Supabase CLI 2.109.1 for the local backend test gate
- PowerShell 7 for the cross-platform verifier/CI, or Windows PowerShell 5.1 on Windows

## Run locally

Copy `.env.example` to an ignored development file, replace only its public values, then run:

```sh
flutter pub get
flutter run --dart-define-from-file=.env.development
```

`SUPABASE_ANON_KEY` accepts a modern `sb_publishable_...` key or a legacy JWT whose role is `anon`. Never place a service-role, `sb_secret_...`, signing, or other privileged credential in the app.

For deterministic local backend fixtures:

```sh
supabase start
supabase db reset --local
supabase test db --local
supabase db lint --local --schema public,private --level warning --fail-on error
pwsh ./tool/verify_local_backend.ps1
```

On a Windows host without PowerShell 7, replace the last command with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\verify_local_backend.ps1
```

See `docs/DEVELOPMENT_USERS.md` before using the seed. It is disposable local data; the verifier exercises all seven seeded identity scenarios plus the academic/timetable/attendance path against the running local GoTrue/PostgREST stack and restores deterministic seed state afterward.

## Validate

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build apk --release
supabase db reset --local
supabase test db --local
supabase db lint --local --schema public,private --level warning --fail-on error
pwsh ./tool/verify_local_backend.ps1
```

The same Windows PowerShell 5.1 alternative shown above is supported.

On the validated Windows host, Application Control blocks Flutter's
`font-subset.exe`. The equivalent local AOT compilation passes with
`flutter build apk --release --no-tree-shake-icons`; hosted Linux CI keeps the
normal tree-shaken release command.

The source and local-backend gates pass. The completed identity emulator and physical-device evidence, current academics/attendance Android status, remaining platform/product blockers, and exact counts are recorded in `docs/IMPLEMENTATION_STATUS.md`.
