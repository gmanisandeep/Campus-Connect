# Roadmap

## Milestones

| Phase | Outcome | Exit gate |
|---|---|---|
| 0 Foundation | Product, roles, architecture, data, security, design, offline, testing, decisions | Complete for this reconstruction checkpoint |
| 1 App foundation | Config, DI, routing, theme, session state, core adapters/widgets, gallery, CI | Source and Android build/launch gates pass; iOS remains unverified on Windows |
| 2 Identity | Invitation, login/reset, session restoration, institution/role selection, profile completion | Core and Docker-backed Auth/RLS integration pass; legal acknowledgement, preferences, and invitation administration remain open |
| 3 Academics | Departments, periods, courses, assignments, enrolments, timetable | Basic student-today/faculty-assigned vertical delivered; role Home composition, course lists/details, and day/week/agenda Calendar remain |
| 4 Attendance | Offline draft, server-confirmed submission, summaries, risk, audited corrections | Atomic capture, personal summary, and encrypted draft lifecycle pass the consolidated source/test/APK-build gate; exact-artifact physical persistence, history/risk, configurable policy, corrections, audit, and export remain |
| 5 Communication | Official Feed, targeted announcements, reads/saves, Notification Center, then course-scoped Chat | Audience/expiry and course-membership policies, unread semantics, retention boundaries, and offline tests pass |
| 6 Campus | Events, capacity-safe registration, clubs/membership | Atomic capacity and coordinator policies pass |
| 7 Mentorship | Assignments, private/shared notes, actions, reminders | Confidentiality and assignment tests pass |
| 8 Career | Student-owned Skills plus verified typed Opportunities for internships, jobs, and part-time work | Skill provenance and opportunity expiry/eligibility/tenant tests pass |
| 9 Offline hardening | Broader Drift reference cache, operation queue, conflict recovery, observability | Fault-injection sync tests pass beyond the scoped attendance-draft store |
| 10 Release | Security, accessibility, performance, CI/CD, backup/recovery | All release gates and staged rollout sign-off |

## Role-experience delivery order

The whiteboard-derived hierarchy and production exposure gate are canonical in
`FEATURE_ARCHITECTURE.md`. Capabilities are delivered as secure vertical slices,
not as placeholder tabs:

1. Finish the shared Purple Universe components and role-aware Home/shell over
   the already-proven academic and Attendance data.
2. Establish enrolled/assigned Courses and the timetable-first academic
   Calendar.
3. Deliver the official Feed and Notification Center together with an
   authorized publishing path.
4. Add course-scoped Chat only after membership, retention, moderation, unread,
   retry, and offline contracts pass.
5. Deliver Student Skills and one typed Opportunities system for Internships,
   Jobs, and Part-time.

## Immediate next milestone

Implement the first production-facing role-experience slice without weakening
the existing Attendance contracts:

1. Complete the Purple Universe gallery primitives required by the role shell
   and role Home.
2. Compose Student Home and Faculty Teaching Overview from the real timetable
   and Attendance controllers; omit unavailable Feed, Chat, and Career cards.
3. Add Home semantics, narrow-phone, large-text, reduced-motion, and tablet
   tests.
4. Rebuild and validate the backend-connected Android artifact on the Galaxy
   A35.
5. Continue the exact-artifact encrypted-draft restart/offline/reconnect
   evidence in parallel.
