# CampusConnect feature architecture

## Purpose and evidence boundary

This document translates the Student and Faculty dashboard whiteboard into a
coherent, role-aware product architecture. It defines intended navigation,
feature contracts, exposure rules, and delivery order.

It is an architecture and delivery contract, not a claim that every feature
below is implemented. The implementation status table is authoritative for the
current evidence boundary. A planned route or data entity must not appear as a
working production capability until its complete vertical slice passes the
exposure gate in this document.

## Product interpretation

The whiteboard terms are grouped into product areas rather than rendered as a
large set of peer navigation tabs:

- **Feed** means an official, audience-targeted campus information feed for the
  MVP. It is not an unmoderated social network.
- **Chat** starts with institution-authorized course channels. Direct messages,
  attachments, and media are later extensions that require approved retention,
  moderation, storage, and abuse-handling policies.
- **Calendar** is a presentation of authoritative timetable, event, and
  deadline sources. It does not become a second source of schedule truth.
- **Courses** and **Attendance** belong to the Student **Academics** area and
  the Faculty **Teaching** area.
- **Student platform** becomes **Career**. Skills is a distinct subarea, while
  Internships, Jobs, and Part-time are filters over one typed Opportunities
  model rather than three disconnected implementations.
- The second **Dashboard** written under Faculty is resolved as Faculty
  **Home**, whose page title and purpose are **Teaching overview**. CampusConnect
  must not create two Faculty destinations both named Dashboard. If a later
  requirement calls for analytics, it becomes permission-gated
  **Teaching > Insights** only after authoritative aggregates and their
  interpretation are defined.

## Delivery-state vocabulary

| State | Meaning |
|---|---|
| **Available** | A secured, end-to-end vertical slice exists and may be exposed to eligible production users. |
| **Foundation** | A real supporting contract, permission, entity, or narrower slice exists, but the named product capability is not complete. Foundation does not authorize a production destination or control. |
| **Planned** | This document defines intent only; no working product capability is claimed. |

## Current feature evidence

| Area | State | Current evidence boundary |
|---|---|---|
| Identity, institution/role selection, route authorization, profile, and sign-out | **Available** | Server-derived grants and the existing role-aware shell support the authenticated app. |
| Student Dashboard and Faculty Teaching overview | **Foundation** | A small role-aware Home exists; the richer whiteboard dashboard composition is not yet delivered. |
| Student today timetable and personal subject attendance summary | **Available** | Backed by the current academic repository and tenant-scoped backend contracts. |
| Faculty assigned classes, exact roster, attendance capture, and encrypted local drafts | **Available** | This is the existing narrow Attendance vertical; history, risk, corrections, and exports remain outside it. |
| Purple Universe tokens and theme extension | **Foundation** | Semantic theme foundations exist; the shared ambient, surface, navigation, feedback, and data-display components are the next component slice. |
| Full Calendar and Course hub | **Foundation** | Today schedule and academic entities exist, but complete day/week/agenda, course list, and course-detail experiences do not. |
| Standalone Faculty Students area | **Foundation** | Assigned-course rosters exist inside Attendance; an independently complete, permission-safe Students area does not. |
| Feed and Notification Center | **Planned** | Permission vocabulary and product/data-model boundaries exist, but no production repository, RLS policy, or UI slice is implemented. |
| Course Chat | **Planned** | No production chat capability is claimed. |
| Skills | **Planned** | No production skill-profile capability is claimed. |
| Typed Opportunities and Career | **Planned** | Placement roles and permission vocabulary exist, but no complete publishing or consumption slice is implemented. |

## Target role-aware information architecture

### Student

```text
Student
├─ Home
│  ├─ Next class / today
│  ├─ Attendance snapshot
│  ├─ Latest official update
│  └─ Deadlines and action reminders
├─ Academics
│  ├─ Calendar
│  ├─ Courses
│  └─ Attendance
├─ Community
│  ├─ Feed
│  └─ Chat
├─ Career
│  ├─ Skills
│  ├─ Opportunities
│  │  ├─ Internships
│  │  ├─ Jobs
│  │  └─ Part-time
│  └─ Saved
└─ Profile
   ├─ Campus identity
   ├─ Institution and role switch
   ├─ Security
   └─ Preferences
```

The final compact Student navigation is:

`Home · Academics · Community · Career · Profile`

### Faculty

```text
Faculty
├─ Home — Teaching overview
│  ├─ Next class
│  ├─ Today's classes
│  ├─ Attendance requiring action
│  ├─ Latest official updates
│  └─ Unread communication
├─ Teaching
│  ├─ Calendar
│  ├─ Courses / assigned classes
│  └─ Attendance
├─ Community
│  ├─ Feed
│  └─ Chat
├─ Students
│  └─ Assigned-course rosters only
└─ Profile
   ├─ Campus identity
   ├─ Institution and role switch
   ├─ Security
   └─ Preferences
```

The final compact Faculty navigation is:

`Home · Teaching · Community · Students · Profile`

On medium and expanded layouts, the navigation rail uses the same destination
order. Feed and Chat remain children of Community. Calendar, Courses, and
Attendance remain children of Academics or Teaching. Internships, Jobs, and
Part-time remain typed filters inside Career. The Notification Center is a
global bell action in authenticated top-level headers, not a sixth navigation
destination.

The existing shared `/academics` route family may continue to back both the
Student **Academics** and Faculty **Teaching** labels during migration. Product
labels are role-aware; authorization and data scope remain shared backend
contracts rather than duplicated client trust.

## Production exposure gate

A destination, Home card, button, notification deep link, or other production
control is exposed only when all three conditions are true:

1. **Complete implementation:** its secured end-to-end vertical slice,
   including state handling, offline behavior, accessibility, tests, and
   documentation, is complete.
2. **Institution module enabled:** the active institution has enabled the
   module through an authoritative server-provided capability or rollout flag.
3. **Server grant:** the active server-derived membership and role grant the
   required capability for the requested resource.

Client feature flags improve rollout safety but never grant authority. Backend
RLS and RPC checks remain decisive.

Production navigation must contain no disabled “coming soon” tabs, dead cards,
fake counters, or controls backed only by demo data. Empty authoritative data
is a valid state and should display an honest empty view. An unfinished module
is absent. The development-only design-system gallery may use clearly labeled
fictional fixtures and must remain inaccessible in production.

## MVP feature contracts

### Home and Faculty Teaching overview

Home composes concise summaries from available authoritative modules; it does
not own parallel business data. Student Home prioritizes next class,
attendance health, official updates, and deadlines. Faculty Home prioritizes
next class, today's assigned classes, Attendance states requiring action, and
communication signals.

Unavailable modules are omitted. A temporarily unavailable enabled module uses
an explicit error or offline state. Home never invents schedules, percentages,
insights, performance scores, unread counts, or success states.

### Feed

The MVP Feed contains official institution or department announcements with
publisher identity, publication time, target audience, optional expiry, and a
stable source identifier. Reads are tenant- and audience-scoped, ordered and
paginated deterministically, and exclude expired or unauthorized content at
the server.

Eligible Student and Faculty users consume the Feed. A compose action appears
only for a grant with `announcementsPublish`, and publication still requires
backend policy enforcement. Read and save states are user-owned and
idempotent. Likes, public comments, anonymous posting, and algorithmic ranking
are outside the MVP.

### Course Chat

Chat begins with channels bound to a real course offering or assigned class.
Students may access only channels for current authorized enrolments; Faculty
may access only channels for current assignments. Membership revocation
removes subsequent read and write access.

Messages use server timestamps, stable ordering, opaque client idempotency
keys, and explicit `sending`, `sent`, and `failed` presentation. A locally
composed offline message is a draft, not a sent message. Direct messages,
attachments, reactions, edit/delete behavior, and push previews remain gated
until privacy, retention, moderation, storage, and notification policies are
approved.

### Calendar

Calendar is an agenda/day/week projection over authoritative sources. The
first complete slice uses institution-local academic timetable data. Later
event and opportunity deadlines enter through typed source adapters, preserving
their source identifiers and authorization.

Every item shows source, local date/time, status where relevant, and a deep
link to a real destination. The institution time zone and server-derived
academic date are authoritative. Device time cannot authorize attendance or
change deadlines. A text agenda remains available as an accessible alternative
to a visual grid.

### Courses

Students see only enrolled course offerings. Faculty see only assigned course
offerings. A course detail may show supported subject, section, period,
schedule, Faculty identity, Student-authorized Attendance summary, and
Faculty-authorized roster/action links.

Grades, assignments, files, discussion, and materials remain absent until
their own data, permission, storage, offline, and audit contracts exist.
Catalog identity must be versioned or frozen before authenticated editing can
alter historically referenced course meaning.

### Attendance

Student Attendance shows only the active user's server-confirmed records,
counts, percentage, relevant institution policy explanation, and last-updated
state. Status is expressed with text and icons as well as color.

Faculty Attendance remains limited to assigned classes and the exact
server-authorized roster. Editable local marks are explicitly device drafts.
Submission begins only after an explicit Faculty action and durable
idempotency write. Reconnect never auto-submits. The UI distinguishes
`saved`, `submissionUncertain`, `needsReview`, and server-confirmed states.
Duplicate sessions and changed-payload key reuse are rejected by the server.
Corrections require the later append-only adjustment and audit workflow.

### Skills

Skills are Student-owned profile statements with normalized labels and
optional evidence or verification provenance. Self-declared and
institution-verified skills are never presented as equivalent. The product
does not infer proficiency, rank Students, or generate employability scores
without an approved, explainable contract.

Editing supports a local draft and explicit save. Verification, endorsements,
evidence upload, recommendations, and public visibility require separate
permissions, privacy choices, and file-retention policies.

### Unified typed Opportunities

Internships, Jobs, and Part-time use one tenant-scoped Opportunity entity with
an explicit type: `internship`, `job`, or `part_time`. Common fields include a
verified publisher, title, organization, description, location/work mode,
publication and deadline times, status, eligibility explanation, and
application destination.

Students may browse authorized, current opportunities, filter by type, and
save items. Eligibility is determined and explained by authoritative backend
rules; the client does not silently hide a failure reason. An external link is
labeled external. An internal application is never presented as submitted
before exact server confirmation. Career is not exposed until an authorized
Placement or administrative publishing path can supply and maintain real
content.

## Notification and unread behavior

- Notification records are server-backed, scoped to the active user,
  institution, membership, audience, and resource authorization.
- The global bell badge counts unread Notification Center records. The
  Community destination may separately count unread Chat messages. Feed may
  show a textual “new updates” count; these counters must not be merged or
  double-counted ambiguously.
- Opening a list does not mark every item read. A specific item becomes read
  when its content is displayed. “Mark all as read” is a separate, explicit,
  idempotent action.
- Chat unread state uses a server-held last-read sequence or equivalent
  monotonic cursor per channel. A user's own messages do not increase that
  user's unread count.
- Read changes may update optimistically and queue offline because they are
  low-risk user-owned state. Failed synchronization remains visible and
  recoverable; the next server response reconciles counts across devices.
- Sign-out, authenticated-user change, institution switch, and role switch
  immediately clear or rescope local counters. A badge from one authority
  scope must never leak into another.
- Badges show `1` through `99`, then `99+`, and disappear at zero. Semantics
  announce meaningful text such as “3 unread messages”; color or a dot alone is
  insufficient.
- Push is a delivery channel, not the notification source of truth.
  Notification preferences govern delivery without widening access to the
  underlying record.

## Offline contract

| Area | MVP offline behavior |
|---|---|
| Home | Compose only available cached module summaries and show a global offline state plus each source's last successful sync. |
| Feed | Read cached authorized items with a stale timestamp; queue low-risk read/save state idempotently. Publishing requires the server. |
| Chat | Read an authorized local cache and preserve a local composition draft. MVP send requires reconnect and explicit action; offline content is never labeled sent. |
| Calendar and Courses | Read the last authorized cache with source and sync time. Calendar data never authorizes a consequential action. |
| Attendance | Preserve the existing encrypted, scope-bound Faculty draft lifecycle. Reconnect does not submit or confirm automatically. |
| Skills | Preserve an explicit local edit draft. Verification and server save require current authority. |
| Opportunities | Read cached current-at-last-sync items and queue saves. Eligibility and application transitions are server-confirmed only. |
| Notifications | Read the local cache and queue read state. Source access is revalidated before a deep link reveals content. |

All caches are namespaced by authenticated user, membership, institution, role,
environment/backend namespace, and schema version as appropriate. Server truth
wins for permissions, enrolment, assignment, Attendance, deadlines,
eligibility, capacity, and publication status. A queued action revalidates
current authority before replay. The UI always distinguishes stale, local,
pending, needs-review, and confirmed states.

## Accessibility and responsive behavior

- All interactive targets are at least 44 logical pixels, with 48 preferred
  for primary actions.
- Screens preserve logical focus order, keyboard navigation, visible focus,
  headings, control labels, and useful screen-reader announcements.
- Layout and content remain usable at 200% text scale where practical. Text may
  wrap; fixed-height text containers are avoided.
- Attendance rings, unread badges, calendar colors, status chips, and charts
  always provide equivalent text. No meaning is communicated by color alone.
- The Calendar provides an agenda representation. Chat announces new content
  without repeatedly interrupting assistive technology. Dynamic state
  announcements are reserved for meaningful submit, sync, error, and
  confirmation changes.
- `MediaQuery.disableAnimations` removes ambient loops, parallax, large
  transforms, and spring overshoot while preserving essential feedback.
- Compact navigation becomes a same-order navigation rail on wider layouts.
  Content width stays bounded rather than stretching phone cards across a
  tablet.
- Offline, error, empty, loading, disabled, pending, and confirmed states are
  accessible states, not decorative variants.

## Purple Universe composition

New screens reuse the shared Purple Universe component contracts after those
components are implemented:

- `CcScaffold` provides the semantic canvas and safe-area structure.
- One bounded Campus Flow or `CcSpectralCard` may emphasize Home's next class
  or primary action.
- `CcSurface` provides quiet, stable Feed, Chat, Course, Calendar, Opportunity,
  and roster rows.
- `CcNavigationBar` and its rail equivalent render the role-derived
  destinations in the exact order defined above.
- `CcAttendanceRing` always includes textual counts and percentage.
- `CcStatusBadge`, `CcSkeleton`, `CcEmptyState`, `CcErrorState`, and
  `CcOfflineBanner` express state consistently.

Dense lists, Chat bodies, rosters, forms, warning content, and long reading
surfaces remain solid or nearly opaque. A viewport normally has at most one
prominent gradient. Shared visual components do not own repositories,
permissions, unread counters, or business state.

## Security and data contract

- The backend derives authenticated user, active membership, institution,
  roles, permissions, and resource relationship. Client route state and labels
  are never trusted as authorization.
- Every institution-owned root record carries `institution_id`; child
  relationships preserve tenant scope through enforced foreign keys or
  equivalent non-bypassable relationships.
- RLS is enabled for every exposed table. Consequential mutations use narrow
  RPCs or equivalent server operations that recheck active membership,
  permission, resource assignment/enrolment, payload validity, and
  idempotency.
- Feed audience and expiry, Chat channel membership, Course
  enrolment/assignment, Attendance authority, Notification audience,
  Opportunity publication/eligibility, and Faculty roster scope are enforced
  server-side rather than filtered only by Flutter.
- Active institution and role changes rebuild navigation and data scope
  atomically. Cached or in-flight results from a superseded scope cannot render
  or mutate under the new scope.
- Sensitive local data uses the minimum necessary fields and appropriate
  encryption. Student display names remain absent from encrypted Attendance
  draft rows. Chat and skill evidence require a separate data-minimization and
  retention review before storage.
- Every new backend slice includes migrations, indexes justified by its query
  paths, grants, positive and negative tenant/resource policy tests, domain
  tests, and realistic fictional development fixtures.
- Analytics use `area.object.action` names and never include names, email
  addresses, Student identifiers, message content, private notes, skill
  evidence, or other free-form content.

## Ordered vertical slices

These are delivery slices within the repository roadmap, not permission to
expose all target navigation immediately.

1. **Purple components and gallery**
   Implement and validate ambient, surface, navigation, button, feedback,
   Attendance, loading, empty, error, and offline primitives in the
   development-only gallery.

2. **Role shell and proven academic Home**
   Migrate the shell to grouped, role-derived navigation. Build Student Home
   and Faculty Home — Teaching overview from the already-authoritative
   timetable and Attendance data. Preserve current route, authorization, and
   encrypted-draft behavior.

3. **Courses and academic Calendar**
   Deliver enrolled/assigned course lists, secured course detail, and
   institution-time-zone agenda/day/week views with reference caching and
   Student/Faculty policy tests.

4. **Official Feed and Notification Center**
   Deliver publishing and consumption together: audience and expiry policy,
   pagination, reads/saves, unread counts, preferences, source deep links, and
   an authorized real-content publishing path.

5. **Course Chat**
   Deliver course channels, membership lifecycle, real-time updates, stable
   ordering, unread cursors, local drafts, reconnect behavior, retention and
   moderation policy, and tenant/resource isolation tests. Direct messaging
   and attachments remain gated.

6. **Student Career**
   Deliver skill provenance plus the unified typed Opportunity model,
   authorized publishing, eligibility explanations, saves, deadlines, and
   server-confirmed application transitions before exposing Career.

7. **Hardening and expansion**
   Add broader offline observability, approved push delivery, Attendance
   history/risk/corrections, any approved Chat extensions, accessibility and
   performance profiling on the Galaxy A35, recovery validation, iOS gates,
   and release hardening.

Each slice is independently formatted, analyzed, tested, documented,
committed, pushed, and verified. A later slice does not weaken the security,
offline-authority, accessibility, or evidence boundary of an earlier one.
