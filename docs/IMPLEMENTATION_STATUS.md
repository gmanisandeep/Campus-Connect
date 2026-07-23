# Implementation status

Updated: 2026-07-23

## Reconstruction boundary

- The input workspace contained no application repository or recoverable source; the project was built from the attached requirements into `outputs/CampusConnect`.
- The original CampusConnect source, schema, exact stack, Git history, live deployment, and measurable outcomes remain unknown. This repository is a new implementation and does not claim production parity.
- A new Git repository was initialized for the reconstruction. No commit was created because neither repository-local nor global `user.name`/`user.email` is configured; no identity was invented.
- No real backend configuration, production data, or credentials were recovered or added.

## Delivered checkpoint

### Phase 0 specification

Product scope, role/permission matrix, architecture, data model, design system, security/privacy, offline/sync, testing, roadmap, decisions, and this evidence ledger are present and mutually scoped to a reconstruction.

### Phase 1 app foundation

- Flutter Material 3 with Riverpod, GoRouter, typed failures, environment validation, theme preferences, connectivity state, secure/key-value storage abstractions, logging/analytics boundaries, feature flags, reusable states/widgets, and a development-only design-system gallery.
- Android and iOS projects, custom `campusconnect://auth-callback` handling, Android release internet permission, disabled Android application backup, Android debug cleartext allowance, and an iOS Debug-only local-network plist.
- Home and Profile remain the baseline destinations. Academics is exposed only when the fresh backend identity snapshot contains an eligible active Student or Faculty grant; unsupported, unconfigured, and demo states remain fail-closed. Communication, Campus, Career, Notifications, and unfinished attendance destinations remain hidden rather than shipping dead controls.
- CI source pins Flutter 3.44.6 and Supabase CLI 2.109.1 by immutable action commits, runs format/analyze/tests/coverage/release APK, performs a fail-closed heuristic credential scan, and defines a Docker-backed database reset, schema-lint, pgTAP, and real local-backend verification job.

### Partial Phase 2 identity vertical slice

- Supabase initialization uses secure OS-backed auth storage, fail-closed session classification bound to the authenticated session, and refuses placeholder, arbitrary, `sb_secret_`, service-role, or non-`anon` legacy client keys.
- Email/password sign-in, reset request, recovery password update followed by a fresh password sign-in, auth-event/session restoration, sign-out, profile completion, initial and additional invitation acceptance, pending-invitation review/cancel, active institution/role selection, and blocked-access states are implemented.
- Identity context, roles, and permissions are server-derived. A persisted selection contains no permissions and is revalidated against every fresh server snapshot.
- Two migrations implement tenant/profile/membership/role/permission primitives, private RLS helpers, password-AMR enforcement across RLS and identity RPCs, explicit ACLs, Auth profile provisioning, identity-context/profile/invitation RPCs, row locking, mandatory invitation expiry/replay protection, display-name normalization plus a curated common blank/control/invisible defense, and deterministic fictional fixtures.
- Local Auth enforces an eight-character minimum password. SQL test sources define 81 identity/RLS assertions plus 46 onboarding/RPC assertions (127 total).

Phase 2 is not complete: approved terms/privacy acknowledgement, notification preferences, and invitation issuance/admin tooling are still missing. The full identity flow is verified on the local Android emulator, and install/sign-in/session restoration are verified on a physical Galaxy A35 5G. Physical recovery-callback, accessibility, performance, and iOS gates remain.

### Partial Phase 3 academic and timetable slice

- Departments, programmes, academic periods, sections, subjects, course offerings, faculty assignments, student enrolments, and timetable entries are implemented with tenant/period/resource integrity and RLS.
- `get_my_academic_dashboard` derives institution-local today on the server, returns the Student timetable and attendance summary or Faculty assigned classes and exact rosters, and rejects unsupported role/tenant access. The client trusts the returned institution, role, and date and discards stale responses after a role or tenant change.
- Flutter includes loading, empty, error, offline, Student, and Faculty states. Academics routing and navigation are enabled only for configured eligible grants; direct unsupported routes are guarded.

This is not the complete Phase 3 experience: full profile work, week/detail/calendar views, academic administration, and broader timetable workflows remain open.

### Partial Phase 4 attendance capture slice

- Faculty can select exact-roster statuses and submit one atomic confirmation after the scheduled start on the institution's current local date. Password AMR, active tenant, Faculty role, permission, current assignment, timetable, and complete roster are rechecked and locked server-side.
- A canonical payload fingerprint and request UUID make an exact uncertain retry idempotent while rejecting changed-content reuse. Authenticated clients cannot directly insert, update, or delete confirmed attendance.
- Faculty marks can be saved as encrypted device-local drafts in Drift over SQLite3MultipleCiphers. A random 256-bit database key is held separately in OS secure storage, and the local schema stores no Student display names.
- Drafts move through saved, submission-uncertain, and needs-review states. The exact payload and UUID are durable before the RPC; an uncertain retry is frozen to that payload/UUID, reconnect never auto-submits, and deletion requires an exact confirmed class/session/marks response. Sign-out, password recovery, and authenticated-user changes clear drafts, while role/tenant switches hide out-of-scope rows.
- Student summaries count `present` and `late` as attended over all confirmed statuses and return a neutral percentage without inventing threshold or risk labels.

This is not the complete Phase 4 experience: reference-data caching, attendance history, risk evaluation, configurable thresholds, adjustments, audit-event persistence, export, and general synchronization observability are not implemented.

## Validation evidence

The table records the fully consolidated encrypted-draft source/build gate and
the prior physical-device evidence. The current increment includes real
encrypted-store, key-destruction, controller state-machine/lifecycle-race,
repository exact-confirmation, and recovery-page widget coverage.

| Gate | Result |
|---|---|
| Flutter/Dart toolchain | Flutter 3.44.6 stable; Dart 3.12.2, invoked from the downloaded toolchain because it is not on `PATH`. |
| Android toolchain | Passed: Microsoft OpenJDK 17.0.19, Android Platforms 34/35/36, Build Tools 36.0.0, Platform Tools 37.0.0, NDK 28.2.13676358, and all SDK licenses are installed. Flutter Doctor recognizes the Android toolchain through persistent no-space junctions, and a fresh-daemon APK build passes after the temporary drive aliases are removed. |
| `flutter pub get` | Passed; `pubspec.lock` generated and dependencies resolved. |
| `dart format --output=none --set-exit-if-changed lib test` | Passed across all 70 Dart files after applying the current Dart formatter; the verification rerun required zero further changes. |
| `flutter analyze` | Passed with zero issues. |
| `flutter test --coverage` | Passed all 141 tests. Raw LCOV: 2,286/3,886 lines, 58.83%. Excluding generated Drift `.g.dart` code: 1,983/2,869 lines, 69.12%. |
| `flutter create . --platforms=android,ios ...` | Passed; platform scaffolding generated and auth callback configuration reviewed. |
| YAML/TOML/XML/plist parse checks | Passed: 3 YAML files, 1 TOML file, and 12 Android/iOS XML/plist files. |
| PostgreSQL-compatible migration/runtime smoke checks | Passed for all four migrations and the identity, onboarding, academic/timetable, and attendance behavior, including the targeted Unicode White_Space/common-invisible display-name cases. The real Supabase reset and pgTAP gates subsequently passed as well. |
| pgTAP | Passed in the current local Supabase stack: 4 files, 276 assertions (81 identity/RLS, 46 onboarding/RPC, 93 academic foundation, and 56 attendance capture), including direct OTP/recovery-token denial, mandatory invitation expiry, tenant/resource isolation, exact-roster enforcement, and idempotent attendance replay. During the 2026-07-23 recheck, the four files were run directly through `psql` in the healthy database container because Windows Application Control blocked the cached CLI executable; all 276 reported `ok` and none reported `not ok`. |
| Supabase CLI | Version 2.109.1 is pinned and was previously confirmed. Windows Application Control currently blocks the cached local executable, so the latest database-contract recheck used the running database container directly. |
| Docker Desktop / WSL 2 | Passed after the host restart: Docker Desktop 4.82.0 and Docker CLI 29.6.1 are installed, WSL 2 is healthy, and the Linux container engine is running. |
| `supabase db reset --local` | Most recent full CLI gate passed: all four migrations applied and deterministic identity/academic data loaded in the real local stack. The current containers remain healthy and the database was reset after the prior physical walkthrough; the 2026-07-23 CLI rerun is blocked by host Application Control, not a migration failure. |
| `supabase test db --local` | Most recent CLI gate passed. The current equivalent container-level recheck also passed all 4 files and 276 pgTAP assertions. |
| `supabase db lint --local --schema public,private --level warning --fail-on error` | Most recent CLI gate passed with no schema errors. No backend source changed in the encrypted-draft increment; the current host-policy block prevents a fresh CLI invocation. |
| Local backend verifier | Most recent full run passed under Windows PowerShell 5.1: 228 assertions, including 69 academic/timetable/attendance checks, across all seven seeded identities plus invalid login, anonymous/expired/revoked access, OTP recovery-token RPC/RLS denial, cross-tenant RLS, suspended/inactive access, invitation validity/expiry/replay, direct seven-character password rejection, disposable banned-user behavior, refresh-token revocation, and Mailpit recovery-email/redirect-URL checks. The script resets the database after every run by default; CI invokes the same script with PowerShell 7. No backend source changed afterward, but a fresh local rerun currently stops at its CLI status/reset dependency because Windows Application Control blocks that executable. |
| Local Supabase exposure | Core services remain healthy with optional analytics disabled. A host-scoped Windows Firewall inbound block covers TCP ports 54321-54329 while localhost access remains healthy; this machine-level rule is not enforced by the repository. |
| Credential-pattern scan | Passed; no credential-shaped value found outside documentation/workflow definitions. This remains a heuristic, not a history scan. |
| Android release-mode compilation | Passed with `flutter build apk --release --no-tree-shake-icons`; the standard local command reached AOT compilation but Windows Application Control blocked Flutter's `font-subset.exe`. Hosted Linux CI retains the standard tree-shaken command. The generated artifact is unconfigured and debug-signed, so this is a compilation gate, not a releasable APK. |
| `flutter build apk --debug` | Passed. The preserved backend-unconfigured artifact, `build/app/outputs/flutter-apk/CampusConnect-unconfigured-debug.apk`, is 159,473,710 bytes (152.1 MiB), verifies with APK Signature Scheme v2 and the standard Android debug certificate, and has SHA-256 `8817AAC1DB8793DFAD1D9662006DCA2E3A042CF36100B64D2BC13F7B8C2CBBBC`. It contains no Supabase URL/key and is not a backend-connected release. |
| Development demo APK | Passed. `build/app/outputs/flutter-apk/CampusConnect-demo-debug.apk` was built with the explicit non-production demo/gallery flags, is 183,607,807 bytes (175.1 MiB), uses package `com.campusconnect.campus_connect`, min SDK 24/target SDK 36, verifies with APK Signature Scheme v2, and has SHA-256 `71B8E75A427E76B515A190E3D1B5AAF0B1581E31CC39D9E7723657BB6F9653B8`. It is a UI preview, not a backend-connected or release-signed build. |
| Backend-connected local debug APKs | Passed. `CampusConnect-local-device-debug.apk` is 183,607,120 bytes with SHA-256 `B59663081453CAA043AF4671C2D7D08CD6970058D74419F90A0BCD91CFF87D6B`; `CampusConnect-local-emulator-debug.apk` is 183,607,142 bytes with SHA-256 `6AEB4F7F013F92CE0606A9B0878CCCDAF342D9295EB016B00AA6FD107DEE01AE`. Both verify with APK Signature Scheme v2. They contain local development configuration and are debug-signed test artifacts, not production releases. |
| Android emulator end-to-end identity flow | Passed with the exact final emulator APK against the real local Supabase stack: sign-in, password-session restore after process force-stop, Mailpit recovery deep-link launch that immediately removes Home authority, fail-closed recovery restoration after process force-stop, password update, sign-out of the recovery session, fresh password authentication accepted by the backend AMR guard, and post-update process restore. The backend was then reset to the original deterministic seed and the installed app was cleared back to sign-in. |
| Physical Android smoke flow | Passed with the prior academics device APK on a Samsung Galaxy A35 5G (`SM-A356E`), Android 16/API 36, at 1080x2340: secure wireless ADB pairing, APK installation, `tcp:54321` port reversal, cold launch, real seeded Student and Faculty sign-in, Student authenticated-session restoration after process force-stop, Student academics rendering, Faculty roster/status interaction, successful attendance confirmation, and cleanup. The physical recovery-callback and newer encrypted-draft artifact remain separate gates. |
| Current verified academics/attendance Android slice | Passed on the local Android emulator with the backend-connected `CampusConnect-academics-local-device-debug.apk`: Student sign-in, server-derived campus date, both timetable entries, 66.7%/50.0% summaries, Faculty sign-in, exact two-student roster, status selection, and successful attendance confirmation. The same byte-identical APK passed Student and Faculty end-to-end checks on the Galaxy A35, including successful server-confirmed Faculty submission. The 183,751,296-byte APK uses package `com.campusconnect.campus_connect`, version `0.1.0` (`versionCode` 1), min SDK 24/target SDK 36, verifies with APK Signature Scheme v2, and has SHA-256 `7EDF085CD1FD1C6981DE5896DEB454FED1660F1CA1D2F592583F6752DCA0D5AC`. It is the prior local debug artifact, not a release or validation of the newer encrypted-draft increment. |
| Current encrypted-draft local-device APK | Build/signature gate passed. `build/app/outputs/flutter-apk/CampusConnect-encrypted-offline-drafts-local-device-debug.apk` is 198,317,469 bytes with SHA-256 `348483207CE347B6ABEF10DF3E5DD2E5DEC6EF64F9932E3A7C04DCB89C74517E`. It uses package `com.campusconnect.campus_connect`, version `0.1.0` (`versionCode` 1), min SDK 24/target SDK 36, and verifies with APK Signature Scheme v2 and one Android debug signer. It contains local loopback development configuration and is not a production release. Physical restart/offline/reconnect validation of this exact artifact is pending because ADB currently sees no device. |
| iOS build/launch | Not run; this Windows host has no macOS/Xcode environment. |
| `git diff --cached --check` | Passed against the final staged tree. |
| Hosted CI | Workflow source exists but no GitHub Actions run is claimed. |
| Conventional Git commit | Blocked only by missing Git author identity; all deliverable files are staged on the feature branch. |

## Known limitations and blockers

1. The prior backend-connected academics APK passes Student and Faculty end-to-end flows on the Android emulator and physical Galaxy A35. The encrypted-draft increment now passes its consolidated source, test, security-review, and APK-build gates; physical restart persistence, offline save, reconnect-without-auto-submit, and cleanup remain to be run on the exact new artifact once ADB can see the phone. Physical recovery-callback behavior, accessibility QA, performance measurement, and iOS validation remain unverified; iOS requires macOS/Xcode.
2. `campusconnect://` is a custom scheme that another installed app could claim. Production recovery must use verified Android App Links and iOS Universal Links before release.
3. Android release builds still use the debug signing configuration, and CI's release compilation has no production Dart defines. Production signing, environment configuration, and distribution hardening remain blockers.
4. Terms/privacy acknowledgement and notification-preference contracts are intentionally absent until approved content and retention rules exist.
5. Invitation issuance/admin tooling and later product modules remain unimplemented and hidden. The partial academic/timetable slice still lacks complete profile, week/detail/calendar, and academic-administration workflows.
6. Drift with SQLite3MultipleCiphers is integrated only for encrypted Faculty attendance drafts. Broader offline caching/queue observability, FCM, Sentry, Edge Functions, storage/upload policy, rate limiting, audit-event persistence, and release observability remain planned boundaries rather than claimed integrations.
7. Optional local Supabase analytics is intentionally disabled because it is not required by this checkpoint. The scoped Windows Firewall protection is host setup, not repository-managed policy.
8. Display-name validation covers Unicode White_Space and a curated set of common invisible/filler characters; a full Unicode default-ignorable/confusable policy and normalization review remains release work.
9. Attendance submission remains explicit and server-confirmed; drafts can be saved offline, but the app still lacks reference-data caching, history, risk evaluation, configurable thresholds, audited adjustments, persisted audit events, exports, and a broad synchronization queue.
10. Course offering/catalog identity must be versioned or frozen before authenticated academic administration is added so historical attendance does not silently dereference renamed or repurposed current catalog rows.
11. Configure a real Git author identity before creating the initial conventional commit.

## Exact next milestone

Reconnect the Galaxy A35 and run the exact encrypted-draft APK through restart
persistence, offline save, reconnect-without-auto-submit, exact uncertain retry,
and sign-out cleanup. Next, add the missing Phase 3 week/detail/calendar
experience and design catalog versioning before academic admin CRUD, then
implement audited adjustment/history without weakening server authority.
Physical recovery callbacks, accessibility/performance QA, iOS, legal
acknowledgement, notification preferences, and invitation issuance/admin
tooling remain parallel release work.
