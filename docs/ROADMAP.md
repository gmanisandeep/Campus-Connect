# Roadmap

## Milestones

| Phase | Outcome | Exit gate |
|---|---|---|
| 0 Foundation | Product, roles, architecture, data, security, design, offline, testing, decisions | Complete for this reconstruction checkpoint |
| 1 App foundation | Config, DI, routing, theme, session state, core adapters/widgets, gallery, CI | Source and Android build/launch gates pass; iOS remains unverified on Windows |
| 2 Identity | Invitation, login/reset, session restoration, institution/role selection, profile completion | Core and Docker-backed Auth/RLS integration pass; legal acknowledgement, preferences, and invitation administration remain open |
| 3 Academics | Departments, periods, courses, assignments, enrolments, timetable | Basic student-today/faculty-assigned vertical delivered; profiles, week view, details, and calendar remain |
| 4 Attendance | Offline draft, server-confirmed submission, summaries, risk, audited corrections | Atomic capture, personal summary, and encrypted draft lifecycle pass the consolidated source/test/APK-build gate; exact-artifact physical persistence, history/risk, configurable policy, corrections, audit, and export remain |
| 5 Communication | Targeted announcements, read/save, notification center/preferences | Audience and expiry policies pass |
| 6 Campus | Events, capacity-safe registration, clubs/membership | Atomic capacity and coordinator policies pass |
| 7 Mentorship | Assignments, private/shared notes, actions, reminders | Confidentiality and assignment tests pass |
| 8 Career | Verified opportunities, eligibility, saves/applications | Expiry/eligibility/tenant tests pass |
| 9 Offline hardening | Broader Drift reference cache, operation queue, conflict recovery, observability | Fault-injection sync tests pass beyond the scoped attendance-draft store |
| 10 Release | Security, accessibility, performance, CI/CD, backup/recovery | All release gates and staged rollout sign-off |

## Immediate next milestone

Harden the delivered academic/attendance vertical without claiming the full
Attendance phase:

1. Reconnect the physical Android device and complete exact-artifact evidence
   for the encrypted Faculty draft lifecycle: restart persistence, offline save,
   reconnect without auto-submit, exact uncertain retry, and cleanup.
2. Define institution-configurable attendance math and threshold policy,
   including explicit treatment of late and excused states.
3. Add student history/week views, faculty recent sessions, and an append-only
   adjustment workflow with reason, actor, and audit event.
4. Complete the Phase 2 legal acknowledgement, notification preferences, and
   invitation-administration gaps.
5. Run physical accessibility/performance and recovery-callback gates, then the
   iOS build/launch gate on macOS before release work.
