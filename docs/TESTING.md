# Testing strategy

## Test pyramid

- Domain unit tests: calculations, validation, permissions, state transitions, conflict rules.
- Repository/mapper tests: DTO mapping, failure translation, cache/server behavior.
- Widget tests: semantics, large text, loading/empty/error/success/offline states and role navigation.
- Integration tests: authentication, session restore, multi-role selection, timetable, attendance capture/refresh.
- SQL policy tests: positive same-tenant access and negative cross-tenant/resource access for every policy.
- Golden tests: stable, critical phone/tablet states in light/dark themes; not a substitute for semantics tests.

## Required critical flows

Sign in/session expiry; today's timetable; subject attendance; faculty submission; target announcement; event capacity; mentor shared action; verified opportunity; tenant denial; offline retry/idempotency.

## Quality gates

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
supabase db reset --local
supabase test db --local
supabase db lint --local --schema public,private --level warning --fail-on error
pwsh ./tool/verify_local_backend.ps1
```

CI uses PowerShell 7 (`pwsh`). Windows PowerShell 5.1 is also supported locally via
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\verify_local_backend.ps1`.

Release also requires dependency/secret scans, successful supported-target launch, migration rehearsal, accessibility QA, and performance measurements on a budget Android profile.

## Fixtures

Fixtures and development seed data must be explicit, fictional, and deterministic. No production exports or real student data. Demo mode cannot compile into production by default.

## Current checkpoint evidence

- The consolidated `dart format` and `flutter analyze` gates pass on Flutter
  3.44.6/Dart 3.12.2 with zero analyzer issues.
- The full Flutter gate passes all 141 unit/widget tests. Raw LCOV records 2,286
  of 3,886 lines hit (58.83%). Excluding generated Drift `.g.dart` code, it
  records 1,983 of 2,869 lines hit (69.12%). These are checkpoint measurements,
  not a release-quality target.
- The encrypted-draft increment includes 19 focused real-store/key-destruction
  cases, 35 controller/state-machine/lifecycle-race cases, 12 Academics page
  widget cases, and exact-confirmation repository coverage. It covers
  ciphertext inspection, wrong/missing keys, write-before-RPC, frozen UUID
  retry, cross-account and revoked-grant cleanup, stale-session races,
  historical recovery, and reconnect-without-auto-submit.
- The Android toolchain gate passes with OpenJDK 17, Android API 36, Build Tools 36, and NDK 28.2. The backend-connected device-loopback and emulator-host debug APKs both verify with APK Signature Scheme v2. They are local debug test artifacts, not production releases.
- The exact final emulator APK passed real sign-in, password-session restore, Mailpit recovery deep-link launch that removed Home authority, fail-closed recovery restoration across force-stop, password update followed by fresh password authentication accepted by the backend, and post-update process restore. After verification, the backend was reset to its original deterministic seed and the installed app was cleared back to sign-in.
- The prior backend-connected academics APK passed an Android-emulator Student/Faculty walkthrough: server-derived campus date, two live timetable entries, 66.7%/50.0% Student summaries, exact two-student Faculty roster, status editing, and successful attendance confirmation.
- The same prior APK passed secure wireless installation and backend-connected Student/Faculty validation on a Samsung Galaxy A35 5G running Android 16/API 36: cold launch, seeded sign-in, Student authenticated-session restoration after force-stop, server-derived campus date, both timetable entries and summary, Faculty exact-roster expansion and status editing, and successful server-confirmed attendance submission. The physical recovery-callback flow remains unverified on that phone. This does not validate the newer encrypted-draft APK increment.
- The fresh encrypted-draft local-device debug artifact is
  `CampusConnect-encrypted-offline-drafts-local-device-debug.apk`, 198,317,469
  bytes, SHA-256
  `348483207CE347B6ABEF10DF3E5DD2E5DEC6EF64F9932E3A7C04DCB89C74517E`.
  It uses package `com.campusconnect.campus_connect`, version `0.1.0`,
  min SDK 24/target SDK 36, and verifies with APK Signature Scheme v2 and the
  Android debug certificate. Its physical persistence/offline/reconnect test is
  pending because no device is currently visible to ADB.
- The real local Supabase gate passes: all four migrations apply, deterministic identity/academic seed data loads, all 276 pgTAP assertions pass across four files (81 identity/RLS, 46 onboarding/RPC, 93 academic foundation, and 56 attendance capture), and schema lint reports no errors.
- The verifier passes 228 assertions through GoTrue, PostgREST, and Mailpit, including 69 academic/timetable/attendance checks, then resets the database to deterministic seed state. It covers all seven seeded identities plus server-derived institution-local dates, Student/Faculty/multi-role dashboards, exact rosters, atomic/idempotent submission and refresh, invalid login, anonymous/expired/revoked access, OTP recovery-token RPC/RLS denial, cross-tenant RLS, suspended/inactive access, invitation validity/expiry/replay, direct weak-password rejection, disposable banned-user behavior, refresh-token revocation, and recovery-email/redirect-URL shape. The local evidence used Windows PowerShell 5.1; CI is configured to use PowerShell 7.
- On the 2026-07-23 hard recheck, all Supabase containers were healthy and all
  276 pgTAP assertions passed again by running the four SQL files directly
  through `psql` in the database container. Windows Application Control now
  blocks the cached Supabase CLI executable, so the unchanged schema's CLI lint
  and 228-assertion verifier retain their most recent passing evidence rather
  than being claimed as fresh reruns.
- CI now contains the Flutter source/coverage/release-APK gates, a heuristic secret scan, and a Docker-backed Supabase reset, schema-lint, pgTAP, and local-backend verification job. No hosted workflow run is claimed.
- Local release-mode AOT compilation passes with `--no-tree-shake-icons`; Windows Application Control blocks Flutter's `font-subset.exe` in the default tree-shaken command. Linux CI retains the standard command. This is not release-readiness evidence because production signing and Dart defines are still absent.

Docker Desktop 4.82.0, Docker CLI 29.6.1, WSL 2, and the Linux container engine are operational. Optional Supabase analytics is intentionally disabled; core services and localhost Auth health remain available. A host-scoped Windows Firewall rule blocks inbound TCP ports 54321-54329, but that machine-level protection is not enforced by the repository.

The local backend verification script exercises the seeded users through GoTrue and PostgREST, including valid/invalid login, expired and revoked sessions, recovery-token isolation, a disposable banned Auth user, server password policy, password-recovery delivery and redirect-URL shape, invitation expiry/replay, direct cross-tenant RLS denial, role-specific academic dashboards, exact-roster attendance, idempotent replay, and Student summary refresh. It restores full deterministic database seed state after every run by default, including early failures. The prior academics/attendance Android build and Student/Faculty emulator and physical-device walkthroughs pass. The encrypted-draft increment has completed its consolidated Flutter and APK-build gates; the exact new artifact still requires its physical-device persistence/offline/reconnect gate. Physical-device callback behavior, accessibility QA, performance measurement, verified production links, release signing/configuration, and iOS remain separate release gates, along with the unfinished Phase 3/4 work and later product verticals.
