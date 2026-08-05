# Security and privacy model

## Threat model

Primary risks are cross-institution disclosure, role escalation, insecure direct object access, exposed service credentials, malicious files, session theft, brute force, unsafe offline data, notification leakage, and overbroad administrator/support access.

## Trust boundaries

The Flutter client is untrusted. It may present an institution or role selection, but the backend resolves it from `auth.uid()`, active memberships, roles, permissions, and resource relationships. The public anon key is not authorization. RLS applies to every exposed table and Storage bucket.

## Implemented in this checkpoint

- Deny by default with RLS; explicit institution membership plus permission/resource checks.
- No service-role key, private signing secret, or real credentials in mobile source/config.
- Client configuration accepts only `sb_publishable_...` or legacy `anon` JWT keys and rejects privileged/placeholder/arbitrary values.
- Supabase session material uses secure OS storage, while saved institution/role selection is revalidated against a fresh server-derived identity snapshot.
- Faculty attendance drafts use a separate encrypted Drift database backed by
  SQLite3MultipleCiphers. A random 256-bit database key is stored separately in
  OS secure storage; the draft schema excludes Student display names and keeps
  only scoped identifiers, class labels, statuses, state, and timestamps needed
  for recovery.
- Identity RLS and RPCs require a password method in the signed JWT `amr` claim in addition to deriving the actor from `auth.uid()`. OTP/recovery tokens cannot read campus identity data, accept invitations, or complete profiles.
- State-changing identity RPCs lock relevant rows, enforce active tenant/preassigned role/mandatory invitation expiry, and prevent replay. Local Auth enforces the same eight-character password floor as the app.
- Academic and attendance tables carry tenant scope through composite foreign
  keys, enable RLS in their creating migrations, and expose authenticated reads
  only through active-membership plus enrolment/assignment checks. Roster names
  are returned only by the checked faculty dashboard RPC; ordinary profile RLS
  remains self-only.
- Attendance submission requires password AMR, an active Faculty role, the
  `attendance_record` permission, and an assignment to the exact offering. The
  backend locks the authoritative timetable and active roster, rejects partial,
  duplicate, or foreign-student payloads, writes the session and all records in
  one transaction, and uses a request UUID plus payload fingerprint for safe
  retry. Authenticated clients have no direct attendance write privileges.
- Before an attendance RPC leaves the device, the exact marks and idempotency
  UUID are written durably. An uncertain draft is immutable and can retry only
  the frozen payload with the same UUID. Reconnect never submits automatically,
  and local deletion requires exact server confirmation of the class, session,
  roster, and marks. Scope switches hide drafts; revoked Faculty grants are
  purged after an authoritative identity snapshot, and stale session loads
  cannot destructively filter newer authority. Sign-out, password recovery,
  authenticated-user changes, and foreign-user rows clear them fail-closed.
- Editable saved drafts expire only against a fresh authoritative server date.
  Uncertain/review rows are not deleted from the local wall clock because their
  durable UUID and marks may still be needed to reconcile a committed request.
- Android release networking is explicit, Android application backup is disabled, and cleartext/local-network allowances are limited to development platform configuration, while production app configuration requires HTTPS.
- The production console logger and Flutter framework error presenter are disabled. Non-production structured fields are recursively filtered by sensitive key fragments and raw error values are reduced to their type; stack traces can still contain development paths.

## Required before release

- Trusted Edge Functions for invitation issuance, capacity enforcement, audited corrections, notification dispatch, exports, and support access.
- Signed file URLs, MIME sniffing, extension allowlists, size caps, malware scanning strategy, and tenant-prefixed storage paths.
- Rate limiting for authentication, invitations, password reset, exports, uploads, and high-impact mutations.
- A reviewed crash-reporting/analytics integration with consent, redaction, retention, access, and deletion controls. The current interfaces are not that implementation.
- Session/device-token revocation, secure account deletion/export, legal acknowledgement, notification privacy, and incident response exercises.
- Verified Android App Links/iOS Universal Links for recovery callbacks, production signing, and environment-specific release configuration. The development custom scheme and debug-signed artifacts are not release controls.

## Social and college-onboarding controls

- Social clients receive only server-projected feed, profile, comment, inbox,
  and thread data. Direct authenticated reads and writes on the underlying
  social tables are revoked.
- College visibility is resolved from an active membership or pending Student
  affiliation. Official publishing requires `announcements_publish` or
  `institution_manage` for the same institution.
- A message request is required before a new pair can exchange messages.
  Either participant may block the other; blocking terminates follows and
  pending requests and prevents new messaging.
- Saves are private. Claim documents use a private bucket with user-prefixed
  upload paths and platform-administrator review access. Public social media
  uses a separate capped, allowlisted bucket.
- College and Faculty forms grant no authority by themselves. College claims
  require platform review; Faculty applications require an already verified
  college and college-administrator review. Self-approval is not an exposed
  path.
- Production still requires upload malware scanning, abuse/rate limits,
  moderation operations, retention/deletion jobs, legal policies, verified
  directory-source ingestion, and an append-only administrative audit trail.

## Authorization order

1. Valid authenticated identity.
2. Active institution membership.
3. Required permission/role.
4. Resource assignment, ownership, audience, or enrolment.
5. Record state constraints such as deadline, capacity, or archive status.

## Secret scanning

CI performs a heuristic tracked-file scan for service-role assignments, modern `sb_secret_` keys, JWT-shaped values, and private-key headers. `.env*` is ignored except `.env.example`. This is not a comprehensive secret scanner or history scan; production release still requires a dedicated repository/history scan. A detected privileged client credential must be rotated, not only deleted from the latest commit.

## Audit events

Record actor, tenant, action, resource type/id, timestamp, correlation ID, safe diff, and trusted request metadata for role changes, attendance submissions/adjustments, exports, private mentorship access, opportunity publication, support access, and destructive administration. Audit data is append-only and access-restricted.

## Migration limitations

The first two migrations establish tenant identity, membership,
role/permission, onboarding, and profile primitives. The two follow-up migrations
implement academic/timetable reads and basic immutable attendance confirmation.
The encrypted attendance draft is a client-local recovery mechanism and adds no
server table or authorization path. The migrations do not implement academic
administration, audited corrections, exports, risk policy, or persisted audit
events. Every later exposed table must enable RLS in the same migration and
include positive and negative policy tests before merge.

The four current pgTAP files contain 276 assertions, and the real-backend
verifier contains 228 assertions, including 69 for academic/timetable/attendance
behavior. These are checkpoint controls, not a substitute for a formal security
review, production rate limits, or an append-only audit implementation.
