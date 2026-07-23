# Architecture decisions

## ADR-001: New reconstruction

Accepted. No original repository, schema, exact stack, deployment, or verified outcomes were recovered. Build a new implementation and preserve the evidence boundary in documentation and marketing copy.

## ADR-002: Flutter app and Supabase backend

Accepted for the reconstruction brief. Flutter/Material 3 targets Android/iOS; Supabase supplies PostgreSQL/Auth/Storage. This does not claim the historical project used these technologies.

## ADR-003: Feature-first clean boundaries

Accepted. Domain rules remain framework-independent, presentation uses Riverpod, GoRouter handles navigation, and Supabase stays behind interfaces.

## ADR-004: Multi-role RBAC plus resource checks

Accepted. A single role string cannot model real assignments. Membership roles grant permissions; policies additionally verify enrolment, assignment, audience, ownership, and state.

## ADR-005: Tenant isolation in RLS

Accepted. Client filtering is insufficient. Every exposed table enables RLS and must pass cross-institution negative tests.

## ADR-006: Introduce Drift with first real cached feature

Accepted and now applied to Faculty attendance drafts. Phase 1 defines
cache/sync interfaces and lightweight preference metadata; the first concrete
offline schema is deliberately limited to attendance draft headers and marks.
It uses Drift over SQLite3MultipleCiphers, with a random 256-bit database key
stored separately in OS secure storage. Student display names are not persisted.

The local state machine is `saved`, `submissionUncertain`, or `needsReview`.
The request UUID and exact marks become durable before the RPC, and an uncertain
operation may retry only that frozen payload with the same UUID. Reconnect is
never an automatic-submit signal, and server confirmation must exactly match
the class, session, and marks before deletion. This scoped implementation avoids
pretending that the broader reference cache and general synchronization queue
already exist.

Editable drafts use a 30-day limit measured only from an authoritative current
server date. Uncertain/review rows are not silently removed using local wall
time because a clock jump could erase the UUID and marks needed to reconcile a
request that the server may already have committed. Identity transitions hide
rows synchronously, purge revoked Faculty scopes from authoritative snapshots,
and reject destructive work from a superseded session load.

## ADR-007: Future administration clients use Next.js by default

Accepted. Flutter Web is not the default for data-dense administration/public SEO experiences; all clients share backend policy/contracts.

## ADR-008: Attendance confirmation is atomic and idempotent

Accepted for the first attendance slice. The app submits the exact active
roster with a tenant-scoped request UUID. PostgreSQL locks the authoritative
class and roster, creates one session plus all records atomically, and returns
server-confirmed state. Replaying the same UUID and canonical payload returns
the prior result; changing the payload or targeting an already-confirmed class
fails. Authenticated clients cannot edit confirmed records in place. Audited,
append-only corrections remain a later Phase 4 capability.

For the interim summary, `present` and `late` count as attended and every
confirmed record, including `excused`, remains in the denominator. No risk
label or low-attendance threshold is inferred until institution-configurable
policy exists. Institution time zone plus timetable-local time produces the
canonical session timestamp. The app asks the server for institution-local
today rather than trusting the device clock. Until audited backfill exists,
faculty can confirm only today's class and only after its scheduled start.
