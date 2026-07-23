# Architecture

## Context

The mobile app is Flutter. Supabase provides Auth, PostgreSQL, Storage, and selected Realtime use. Edge Functions own privileged operations. Future Next.js clients use the same policy model and API contracts.

```text
Flutter presentation -> application controllers/use cases -> domain interfaces
        -> data repositories -> Supabase gateway / local cache / sync queue
        -> PostgreSQL with RLS, Storage policies, Edge Functions
```

## Boundaries

- Presentation never calls Supabase directly.
- Domain entities and rules import no Flutter or Supabase types.
- Data implementations map transport/database DTOs into domain entities.
- Identity, institution scope, and permissions are server-derived.
- RLS is the final authorization boundary; UI gating is only usability.
- Offline writes are queued with idempotency keys only when the operation is safe.

## Flutter structure

`lib/core` holds configuration, auth/session primitives, errors, logging, analytics, network, routing, storage, sync, theme, flags, and shared widgets. `lib/features/<feature>` uses `domain`, `data`, and `presentation` boundaries. New features must not become top-level service singletons.

## State and dependency injection

Riverpod providers construct replaceable interfaces. Async UI uses `AsyncValue` or a feature-specific sealed state and renders loading, empty, data, and failure explicitly. Identity uses explicit `unknown`, `signedOut`, `passwordRecovery`, `onboarding`, `selectionRequired`, `authenticated`, and `accessBlocked` states. A demo session is allowed only behind an explicit non-production flag.

## Routing

GoRouter owns public, protected, and developer routes. Redirects depend on
session state. Authenticated Student and Faculty grants with the required
permissions receive Home/Academics/Profile navigation; unsupported roles and
backend-unconfigured demo sessions do not receive the Academics destination.
Direct navigation is guarded as well as hidden. Future permission-sensitive
routes remain absent until their server authorization and vertical slice are
complete.

## Academic and attendance request path

The academics feature maps one security-definer dashboard RPC into immutable
domain models. Production requests leave the date null so PostgreSQL derives
institution-local today; explicit dates remain available for read-only test and
future calendar flows. Riverpod state is guarded by the active institution,
active role, user, generation, and server-returned date so a role/tenant switch
cannot reuse stale authority. Faculty submission uses a separate mutation controller and refreshes
the server snapshot only after confirmation; roster choices are never treated
as confirmed merely because they changed in local widget state.

## Encrypted Faculty draft path

The first real offline vertical uses Drift over SQLite3MultipleCiphers rather
than the preference-backed metadata store. Each environment/backend namespace
has a random 256-bit database key stored separately through OS secure storage.
The encrypted database stores class snapshots, opaque roster identifiers,
marks, state, timestamps, and an optional request UUID; Student display names
are deliberately excluded.

An attendance draft moves through `saved`, `submissionUncertain`, and
`needsReview`. Before the attendance RPC can leave the device, the controller
freezes the exact marks and durably writes the request UUID. An uncertain
operation can retry only that frozen payload with the same UUID; editing is
disabled until the server confirms it or the draft requires explicit review.
The repository accepts confirmation only when the returned class, session, and
marks exactly match the submitted operation, after which the local draft may be
deleted. Connectivity is a presentation hint: reconnect never triggers a
submission.

Draft visibility remains bound to the authenticated user, membership,
institution, role, class, and server date. Role or tenant navigation hides
out-of-scope rows rather than presenting stale authority. Identity-bearing
onboarding, selection-required, and access-blocked transitions keep rows for
still-authorized Faculty grants hidden while purging rows whose grant or
attendance permission was revoked. A superseded session load cannot perform
that destructive filtering. Sign-out, password recovery, an authenticated-user
change, or a foreign-user row triggers fail-closed cleanup; an identity-less
transient state keeps rows hidden until authority is known.

## Error model

Infrastructure errors are mapped to typed `AppFailure` values: validation, authentication, authorization, not found, conflict, connectivity, timeout, server, and unexpected. UI receives a safe user message plus a correlation ID; logs retain technical context without secrets.

## Configuration

Values arrive through `--dart-define`/`--dart-define-from-file`. Startup validates the environment and any supplied URL/key pair. Missing backend configuration leaves the app signed out; placeholder, arbitrary, secret, and service-role-shaped keys prevent backend initialization. Service-role credentials are prohibited in every client environment.

## Performance conventions

Paginate datasets, debounce search, constrain image size, avoid broad Realtime subscriptions, use selectors to limit rebuilds, and measure cold start/render/API latency before adding animation packages.

## Naming and folders

- Dart files: `snake_case.dart`; types: `UpperCamelCase`; members/providers: `lowerCamelCase`.
- SQL tables/columns/functions: `snake_case`; primary keys: UUID; timestamps: `timestamptz`.
- Analytics: `area.object.action`; flags: `area_capability`.
- Tests mirror source paths and end in `_test.dart`.

## Logging

Structured levels are debug/info/warning/error/fatal. The checkpoint console logger is disabled in production, recursively filters common sensitive key fragments in non-production fields, and records error types rather than raw error values. Stack traces remain development-only technical context. A production crash/analytics provider requires a separate privacy and redaction review.

## Release strategy

Use development, staging, and production Supabase projects. Merge only after format/analyze/test/migration/RLS gates. Promote immutable migrations through staging, use phased mobile rollout and remotely disable risky unfinished features. Rollback application versions; fix shared migrations with follow-up migrations.
