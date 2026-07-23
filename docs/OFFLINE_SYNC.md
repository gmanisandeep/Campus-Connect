# Offline and synchronization

## Goals

Keep reference information readable during poor connectivity while preserving server authority for attendance, eligibility, capacity, permissions, and other consequential state.

## Cache classes

- Cache with TTL: profile, timetable, attendance summary, announcements, events, saved opportunities, memberships, shared action items.
- Local drafts: attendance draft and profile edit draft, clearly labeled and encrypted where sensitive.
- Queued low-risk actions: read state, saves, notification preferences.
- Server-confirmed only: attendance submission, event capacity registration, role/permission changes, eligibility/application transitions.

## Operation envelope

Queued mutations contain an opaque UUID idempotency key, authenticated user/tenant context derived again by the server, operation type, schema version, created time, dependency IDs, safe payload, attempt count, and state (`pending`, `syncing`, `confirmed`, `failed`, `needsReview`).

## Conflict policy

Server wins for permissions, membership, attendance truth, capacity, deadlines, and eligibility. Last-write-wins is allowed only for user-owned preferences. Profile conflicts prompt review when both sides changed. Attendance drafts are merged only before any server submission; corrections use audited adjustment workflows.

## Retry and visibility

Retry network/5xx failures with capped exponential backoff and jitter. Do not retry validation, authorization, or conflict failures automatically. UI exposes offline state, last successful sync, pending count, and a recovery action. Optimistic presentation must never use confirmed language before acknowledgement.

## Storage

Phase 1 still uses the preference-backed store only for lightweight metadata.
The first real offline vertical now uses Drift over
SQLite3MultipleCiphers for Faculty attendance drafts. A cryptographically
random 256-bit database key is generated per environment/backend namespace and
stored separately in OS secure storage. If that key is unavailable, stale
encrypted database files are discarded rather than opened under a replacement
key.

The encrypted rows store the active authority and class scope, a class-label
snapshot, roster enrolment/user identifiers, selected statuses, timestamps,
state, and the idempotency UUID when present. Student display names are never
written to the local database. This is a narrow draft store, not a completed
timetable cache or general-purpose mutation queue.

## Current attendance slice

The Faculty path supports three durable local states:

- `saved`: editable marks saved on this device and explicitly not submitted.
- `submissionUncertain`: the exact marks and request UUID were durably frozen
  before the RPC, but no exact server confirmation has been observed. Editing is
  disabled and only the identical payload may be retried with the same UUID.
- `needsReview`: authority, class, roster, validation, conflict, or confirmation
  evidence no longer supports a safe blind retry; the user must review or
  discard the draft.

Network availability is only a hint. Reconnect does not submit, retry, or mark
anything confirmed automatically. A submission starts only from an explicit
Faculty action after the durable UUID write succeeds. The server remains
authoritative and a local row is removed only after its response proves the
same institution/class, confirmed session, exact roster, and exact marks.

Drafts survive process restarts and transient connectivity loss. A role or
tenant switch hides drafts outside the exact active user/membership/institution
scope; it does not reinterpret them under new authority. Sign-out, password
recovery, authenticated-user changes, and foreign-user rows clear attendance
draft data fail-closed. Identity-bearing onboarding, selection-required, and
access-blocked states keep still-authorized Faculty scopes hidden but delete
rows whose grant or attendance permission was revoked. Identity-less transient
states keep rows hidden until authority is known, and a superseded session load
cannot delete against stale authority.

Editable `saved` rows older than 30 calendar days are deleted only when a
fresh, non-historical dashboard supplies the authoritative server date.
`submissionUncertain` and `needsReview` rows are not silently age-deleted from
the device wall clock because that could erase the durable UUID/evidence needed
to reconcile a server-committed request. They require authoritative resolution
or explicit discard. UI copy distinguishes “Draft — saved on this device,”
“Not submitted,” and “Pending confirmation — not confirmed” from
server-confirmed attendance.
