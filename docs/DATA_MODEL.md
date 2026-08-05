# Data model

## Multi-tenant rules

Every institution-owned root record contains `institution_id`; children either repeat it for efficient policy/index enforcement or inherit it through a non-bypassable foreign-key relationship. UUID keys avoid cross-tenant sequence leakage. All mutable records use `created_at`, `updated_at`, and actor fields where audit value exists.

## Entity groups

| Area | Entities |
|---|---|
| Tenant/identity | institutions, institution_settings, campuses, profiles, institution_memberships, roles, permissions, membership_roles, role_permissions |
| Academic | departments, programmes, academic_periods, sections, subjects, course_offerings, faculty_assignments, student_enrolments, timetable_entries |
| Attendance | attendance_sessions, attendance_records; attendance_adjustments is reserved for the audited-corrections slice |
| Communication | announcements, announcement_audiences, announcement_reads, announcement_saves, conversations, conversation_members, messages, conversation_read_state, notifications, notification_preferences, device_tokens |
| Campus | events, event_registrations, event_attendance, clubs, club_memberships, club_activities |
| Mentorship | mentor_assignments, mentorship_sessions, mentorship_action_items |
| Career | skills, student_skills, career_opportunities, opportunity_eligibility_rules, opportunity_applications, saved_opportunities |
| Platform | files, feature_flags, audit_logs, domain_event_outbox, sync_operations |

Communication, Campus, Mentorship, Career, and the additional Platform entities
in this table are planned unless an implemented migration is named below. A
reserved entity name is not evidence of a table, grant, RLS policy, RPC, or
working Flutter feature.

## Planned whiteboard feature contracts

- **Feed** starts with announcements and typed audience rows. Reads and saves
  are per-user state; publication and expiry remain server-enforced.
- **Course Chat** binds conversations to a tenant-scoped course offering.
  Current enrolment or Faculty assignment is rechecked dynamically rather than
  trusting a stale member row. Message retry uses a client UUID, and unread
  state uses a monotonic per-conversation cursor.
- **Calendar** is initially an authorized projection of timetable entries over
  a bounded date range. Later events and Opportunity deadlines remain typed
  source records instead of copied calendar truth.
- **Skills** separates a curated institution skill from a Student's assertion.
  Self-declared and institution-verified provenance are distinct fields and
  permissions.
- **Internships, Jobs, and Part-time** are values of one Opportunity type, not
  separate table families. Saves are low-risk user state; eligibility and
  application transitions require current server confirmation.
- **Dashboard/Home** is a role-aware projection and has no standalone business
  table. It returns compact previews and counts from authorized source
  features.

## Device-local attendance draft model

The Flutter client now has two device-local Drift tables,
`attendance_draft_rows` and `attendance_draft_mark_rows`. They are not Supabase
tables and confer no server authority. A header binds one draft to the
authenticated user, membership, institution, selected role, course offering,
timetable entry, and server-derived date; it also carries a class-label
snapshot, lifecycle state, timestamps, and an optional idempotency UUID. Child
rows hold only the roster enrolment/user identifiers and selected status.
Student display names are intentionally absent.

The entire database is encrypted with SQLite3MultipleCiphers. Its random
256-bit key is kept separately in OS secure storage. A `saved` draft remains
editable. `submissionUncertain` freezes the exact marks and durable UUID for
same-payload retry. `needsReview` prevents blind retry when roster, scope,
authority, validation, conflict, or confirmation no longer matches. Confirmed
server data is not cached as draft truth: deletion requires an exact confirmed
class/session/marks response from the attendance RPC.

## Critical invariants

- A profile may have multiple institution memberships and roles.
- Only active memberships authorize tenant access.
- Academic assignments and enrolments must share institution and academic period.
- Attendance session uniqueness is institution + course offering + start time.
- Attendance record uniqueness is session + student; enrolled student and assigned faculty checks are server enforced.
- Confirmed attendance records are immutable to authenticated clients. The future adjustment model is append-only and references the prior and new state plus reason/actor.
- Event registration capacity and deadline are enforced atomically server-side.
- Private mentor notes and student-visible summaries are separate columns with separate access paths.
- Expired/archived content is filtered server-side; it is not merely hidden by the client.
- Chat access ends immediately when the underlying enrolment or assignment is
  no longer authorized; Realtime subscription state never outlives RLS.
- A self-declared skill never silently satisfies a verified-skill eligibility
  rule.
- Opportunity type, publication state, deadline, audience, and eligibility are
  rechecked under the same server-confirmed application transaction.
- One social profile belongs to one Auth user; usernames are unique and are not
  authorization identities.
- Social post visibility is enforced by server projection. College posts bind
  to the college resolved from active membership or pending affiliation.
- A social thread is created only by accepting a message request and contains
  exactly the accepted participants. Blocks override follows, requests, post
  visibility, and messaging.
- Institution directory publication is distinct from platform registration:
  an institution may be prelisted and unclaimed, claim-pending, or verified.
  Only verified institutions can accept Faculty authority applications.

## Index strategy

Lead composite indexes with `institution_id`, then frequent filters: `(institution_id, user_id)`, `(institution_id, starts_at)`, `(institution_id, published_at desc)`, `(institution_id, deadline)`, and attendance session/student keys. Add partial indexes for active memberships, unread notifications, published announcements, and open opportunities after query measurement.

## Retention and deletion

Use hard deletion for safe transient data. Use archival/soft deletion only for records requiring recovery or audits. Attendance adjustments and audit events are append-only with institution-configured retention. Account deletion is a backend workflow that preserves legally required anonymized academic records while removing unnecessary profile data.

For the device-local attendance store, editable `saved` drafts expire after 30
calendar days only when compared with an authoritative current server date.
`submissionUncertain` and `needsReview` rows are retained until server
reconciliation or explicit discard; the device wall clock is not trusted to
erase unresolved UUID/mark evidence. Sign-out, password recovery, an
authenticated-user change, or a foreign-user row triggers fail-closed local
cleanup. Revoked Faculty scopes are purged from an authoritative identity
snapshot.

## Implemented academic and attendance slice

Migrations `20260720000100_academic_foundation.sql` and
`20260720000200_attendance_capture.sql` implement the academic entities listed
above plus `attendance_sessions` and `attendance_records`. Composite foreign
keys carry institution and academic-period scope through offerings,
assignments, enrolments, timetable entries, sessions, and records, preventing a
service-side write from joining records across tenants or periods. Faculty and
student user references also require a membership in the same institution.

`institutions.time_zone` is validated against PostgreSQL time-zone names and
defines server-authoritative "today" plus how a timetable date and local class
time map to the session's canonical `scheduled_starts_at` timestamp. Sessions are unique
by institution, offering, and that timestamp. A tenant-scoped request UUID plus
a canonical payload fingerprint makes exact retries idempotent while rejecting
key reuse with changed content.

The current student summary counts `present` and `late` as attended and divides
by all confirmed session records, including `excused`. That deterministic rule
is intentionally labeled interim until an institution-configurable attendance
policy and threshold model is approved. Confirmed records have no authenticated
update/delete path; audited corrections and `attendance_adjustments` remain
part of the unfinished full Attendance phase.

The basic capture RPC confirms only a class occurring today in the institution
time zone and only after its scheduled start. This intentionally prevents the
unaudited historical/future backfill that would otherwise be possible before
effective-dated enrolments and the adjustment/audit workflow exist.

The current catalog and offering rows are suitable for read-only seeded data,
but their displayed subject/section identity is not yet historical-versioned.
Before authenticated academic administration or edit CRUD is exposed, catalog
identity must be frozen once referenced or represented by effective-dated,
versioned snapshots so a rename or repurpose cannot silently change historical
timetable and attendance meaning.
