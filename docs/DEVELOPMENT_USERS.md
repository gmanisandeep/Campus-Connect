# Local development users

These accounts are deterministic, explicitly fictional fixtures for the local
Supabase stack only. Their addresses use the reserved `.invalid` top-level
domain, and none represents a real person, institution, or production record.

Never apply `supabase/seed.sql` to a hosted or production project. Reset local
fixtures with `supabase db reset`; migrations run first and the seed then creates
the intended `auth.users` and email `auth.identities` rows. Database reset,
GoTrue login, PostgREST authorization, and deterministic cleanup are exercised
by `tool/verify_local_backend.ps1` against the local Docker-backed stack.

## Shared local password

Every account below uses `CampusConnectDevOnly!`. This deliberately shared
credential is safe only for disposable local development and must never be
reused for any real account or stored as a deployment secret. The seed also
uses a fixed bcrypt setting solely to keep these disposable rows reproducible.

## Fixture accounts

| Email | Membership scenario | Roles |
| --- | --- | --- |
| `student.active@campusconnect.local.invalid` | Active member; enrolled in both fictional CSE offerings | `student` |
| `faculty.active@campusconnect.local.invalid` | Active member; assigned to both fictional CSE offerings | `faculty` |
| `member.multi-role@campusconnect.local.invalid` | Active member; enrolled in both offerings and assigned to Distributed Systems | `student`, `faculty` |
| `member.invited@campusconnect.local.invalid` | Valid invitation to Fictional Active Campus; profile intentionally incomplete | `student` |
| `member.expired-invite@campusconnect.local.invalid` | Expired invitation to Fictional Active Campus; profile intentionally incomplete | `student` |
| `member.suspended@campusconnect.local.invalid` | Suspended member of Fictional Active Campus | `student` |
| `member.inactive-campus@campusconnect.local.invalid` | Active membership attached to Fictional Inactive Campus | `student` |

The active institution ID is
`20000000-0000-4000-8000-000000000001`; the inactive institution ID is
`20000000-0000-4000-8000-000000000002`.

The active campus uses `Asia/Kolkata`. Its long-lived local academic period has
two fictional offerings, `CS701 Distributed Systems` and `CS702 Mobile
Application Development`, with weekday timetable entries at 09:00 and 11:15.
Fixed historical sessions produce non-empty student summaries. Weekday and
weekend timetable rows keep the institution-local today view deterministic.
The verifier derives today's date and timetable identity from the RPC, inserts
a disposable already-started verification entry, exercises faculty
confirmation plus student refresh, and restores the original seed afterward.

For invitation RPC checks, use membership
`30000000-0000-4000-8000-000000000004` for the valid invitation and
`30000000-0000-4000-8000-000000000005` for the expired invitation. The valid
fixture expires at `2099-12-31T23:59:59Z`; the expired fixture elapsed at
`2026-01-16T09:00:00Z`.

The seed marks all Auth emails as pre-confirmed so the scenarios are intended to
sign in even when their application-level institution membership is invited,
suspended, or otherwise ineligible. Authentication success does not grant
campus access: identity, academic, and attendance RPCs still enforce password
AMR, active membership, role/permission, and resource assignment/enrolment.
