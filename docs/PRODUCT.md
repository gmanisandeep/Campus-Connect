# Product requirements

## Status and evidence boundary

CampusConnect is a new reconstruction. Confirmed historical facts are limited to a final-year, full-stack campus platform concept or implementation with Student and Faculty dashboards, shared authentication/RBAC, attendance, announcements, events, mentorship, clubs, career content, a mobile-first dark UI, and scalability intent. The original code, exact stack, schema, deployment, screenshots, adoption, and outcomes were not recovered.

## Vision

Create a trustworthy campus operating platform that routes timely academic and campus information to the correct people, replaces fragmented notice boards/messages/spreadsheets, and stays useful on budget phones and unreliable networks.

## Product principles

1. Make frequent work fast: today's classes, attendance, urgent notices, and deadlines surface first.
2. Enforce permissions and institution isolation at the backend.
3. Make state explicit: loading, empty, error, offline, pending sync, and confirmed.
4. Never claim a capacity-sensitive or authoritative mutation succeeded before server confirmation.
5. Support accessibility, localization, long names, large text, and reduced motion.
6. Keep unfinished capabilities behind flags; never ship dead controls.

## Users and primary outcomes

| User | Primary outcome |
|---|---|
| Student | Understand today's schedule, attendance health, notices, events, mentorship actions, and career deadlines. |
| Faculty | See assigned classes and record attendance quickly and safely. |
| Mentor | Manage assigned mentees, private notes, shared summaries, and follow-ups. |
| Club coordinator | Manage assigned clubs, activities, memberships, and events. |
| Placement officer | Publish verified opportunities and manage eligible audiences. |
| Department administrator | Configure and report within an authorized department. |
| Institution administrator | Configure one institution and its memberships, academics, permissions, and audits. |
| Platform administrator | Operate the platform without implicit access to private tenant data. |

Users may hold multiple roles. Active institution and active role are session context, not trusted client claims.

## Information architecture

The canonical hierarchy, exposure gate, and per-feature contracts are defined
in `FEATURE_ARCHITECTURE.md`.

- Student navigation: Home, Academics, Community, Career, Profile.
- Faculty navigation: Home, Teaching, Community, Students, Profile.
- Feed and course Chat are children of Community.
- Calendar, Courses, and Attendance are children of Academics or Teaching.
- Skills plus typed Internships, Jobs, and Part-time Opportunities are children
  of Student Career.
- The Notification Center is a global bell action rather than another primary
  destination.

Administrative web experiences are future Next.js applications sharing backend policy and contracts; they are not part of the mobile MVP.

## First vertical slice acceptance

- A valid invited member can sign in, restore a session, select an institution and role, and sign out.
- A Student sees today's timetable and personal subject attendance summary.
- A Faculty member sees assigned classes and can submit a non-duplicate attendance session.
- The server derives identity, institution membership, and authorization.
- Cross-institution reads and writes fail in automated policy tests.
- Attendance calculations are domain-tested.
- All screens include loading, empty, error, offline, and accessible semantics where relevant.

## Non-goals for the first release

Payments, results, assignments, transport, hostel, parent portal, alumni, marketplace, generative AI advice, full administration web, and public marketing web.

## Definition of Done

A feature needs a coherent flow, validation, authorization, tenant isolation, accessibility review, observable errors, offline behavior, tests, documentation, realistic fixtures, responsive QA, and no secrets or debug placeholders. A rendered screen alone is not complete.

## Analytics naming

Use `area.object.action` (for example `attendance.session.submitted`). Never include names, email, student IDs, private notes, or free-form content in analytics properties.
