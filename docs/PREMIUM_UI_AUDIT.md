# CampusConnect Premium UI Audit

Updated: 2026-07-23

## Audit boundary

This is a code-evidenced audit of every implemented production route, its
important conditional states, the role-aware shell, the current theme, and the
shared visual primitives. The primary evidence is:

- `lib/core/routing/app_router.dart`
- `lib/core/routing/role_aware_shell.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_tokens.dart`
- `lib/core/widgets/`
- `lib/features/**/presentation/pages/`
- the session, academic-dashboard, attendance-submission, and encrypted-draft
  controllers that determine what those pages may show or do

This audit does not treat requested mockups as implemented product. It also
does not claim pixel-level device review, animation profiling, large-text
testing, screen-reader testing, or measured frame performance; those remain
validation gates after implementation.

## Executive finding

CampusConnect has a sound functional shell and unusually careful state copy
around authentication, role authority, attendance submission, and encrypted
offline drafts. Its visual layer is still a restrained Material 3 foundation:
one seed-generated color scheme, default typography, standard cards and
navigation, a generic spinner, and static feedback components. The gap to
“Purple Universe” is therefore large visually but does not require replacing
the application architecture.

The strongest elements to preserve are server-derived role and institution
scope, fail-closed routing, explicit local-versus-server attendance language,
exact retry behavior, safe responsive widths, form validation, and the
development-only gallery boundary. The highest-priority UX issues are the
generic and low-information Home pages, inefficient Faculty roster controls,
weak visibility of the active institution/role, an easily missed draft
recovery area, no distinct historical-review treatment, and shared feedback
components that need stronger accessibility behavior.

## Screen and component records

### 1. Cross-application theme and visual foundations

**SCREEN:** Shared light/dark theme, tokens, cards, inputs, and Material
surfaces used by every route.

**CURRENT PURPOSE:** `AppTheme` generates Material 3 light and dark
`ColorScheme`s from one indigo seed per brightness. `AppTokens` supplies six
spacing values, three radii, a navigation-rail breakpoint, and a maximum
content width. Cards are flat `surfaceContainerLow` shapes and inputs are
filled outlined controls.

**CURRENT UX PROBLEMS:** The foundations do not encode interaction states,
content density, semantic elevation, motion, reduced motion, haptics, or
quality tiers. Feature widgets therefore make local decisions and cannot yet
express a consistent premium hierarchy. The theme selected in Profile is
memory-only and returns to system mode after an app restart.

**CURRENT VISUAL PROBLEMS:** Default Material typography and seed-derived
colors make the product look like a competent starter application rather than
a recognizable campus product. There are no named Purple Universe colors,
gradients, glass roles, light roles, spectral borders, branded focus states,
or signature Campus Flow motif. Light mode is standard generated Material
rather than pearl/lavender art direction.

**COMPONENTS TO PRESERVE:** Material 3 semantics and platform behavior, the
existing light/dark/system contract, centralized spacing/radius/breakpoint
files, zero hardcoded feature-specific brand colors, and the content-width
constraint.

**REDESIGN DIRECTION:** Expand the existing token layer rather than bypassing
it. Add semantic color, gradient, typography, elevation, lighting, motion, and
surface roles; map them into `ThemeData`; and keep feature code dependent on
semantic tokens. Establish deep-space dark foundations and a genuinely
designed pearl/lavender light theme. Use solid readable content surfaces by
default and bounded glass only for selected hierarchy.

**MOTION OPPORTUNITIES:** Centralize instant, quick, standard, comfortable,
expressive, and ambient durations plus reduced-motion equivalents. Define
shared press, selection, expansion, route, and state-transition behavior
before adding page-specific animation.

**ACCESSIBILITY RISKS:** Seed generation alone does not prove contrast for
proposed spectral colors. New typography must survive large text without
fixed-height clipping. Focus, hover, pressed, disabled, high-contrast, and
reduced-motion states need token-level definitions so accessibility does not
depend on each feature team.

**PERFORMANCE RISKS:** The current theme is inexpensive. The redesign becomes
risky if gradients, blur, shadows, or animated painters are applied globally.
Theme extensions should hold immutable values; expensive effects should be
bounded, quality-aware, paused offscreen, and isolated with repaint
boundaries.

### 2. Shared feedback, status, skeleton, and search components

**SCREEN:** `AppEmptyState`, `AppErrorState`, `AppSkeleton`,
`AppSearchField`, and `StatusBadge`.

**CURRENT PURPOSE:** These widgets standardize empty/error messaging, retry
actions, a static loading placeholder, a labeled search field, and
icon-plus-label status chips used by Home, Academics, and the gallery.

**CURRENT UX PROBLEMS:** Error presentation always uses “Something went
wrong,” even when a section-specific explanation would be more useful. The
skeleton is a stack of identical bars rather than a preview of the destination
layout. `AppSearchField` always displays a clear action, but when no controller
is supplied it calls `onChanged('')` without clearing the visible field text.
The status vocabulary is useful but not yet a full state system with
timestamps, next actions, or inline help.

**CURRENT VISUAL PROBLEMS:** Empty and error states are generic icon/text
columns; loading bars are static gray blocks; status chips use standard
Material containers. None carries the Campus Flow identity or premium
hierarchy, and the error and empty states can occupy substantial blank space
without contextual illustration or section framing.

**COMPONENTS TO PRESERVE:** Reusable APIs, optional empty-state actions,
retry affordance, status icons plus text rather than color alone, compact
badge density, and the single “Loading” semantic label with excluded
individual skeleton bars.

**REDESIGN DIRECTION:** Introduce branded but quiet empty/error illustrations,
layout-specific skeleton variants, a controlled spectral shimmer, contextual
error titles, and status components with semantic severity. Fix search
ownership so the clear action always clears what the user sees. Keep technical
backend details out of production copy.

**MOTION OPPORTUNITIES:** Use one low-amplitude shimmer, a short retry
transition, subtle badge state interpolation, and an optional Campus Flow
pull-to-refresh mark. Reduced motion should replace shimmer and movement with
static tonal changes.

**ACCESSIBILITY RISKS:** `AppEmptyState` applies `header: true` to the entire
container, which may cause message and action descendants to be exposed as a
single header rather than making only the title a heading. Error and status
changes need live-region behavior only when they change, without duplicate
announcements from nested chip semantics. Clear-search state, focus order, and
large-text wrapping require explicit tests.

**PERFORMANCE RISKS:** Current components are cheap. Continuous shimmer across
many placeholders, animated empty-state painters, or multiple glowing chips
could create needless repaints. Animate one bounded layer and stop it when the
route is inactive.

### 3. Splash and session restoration

**SCREEN:** `/splash` while session status is unknown.

**CURRENT PURPOSE:** Hold a fail-closed route while the app restores and
classifies the session. It shows a centered `CircularProgressIndicator` with
the semantic label “Restoring your session.”

**CURRENT UX PROBLEMS:** There is no branded reassurance, progress context,
slow-restore state, or actionable recovery if restoration takes unusually
long. First launch and a returning-user restore look identical. The current
implementation correctly avoids delaying routing for a cosmetic animation.

**CURRENT VISUAL PROBLEMS:** A spinner on a blank scaffold creates the weakest
possible first impression and does not establish CampusConnect identity.

**COMPONENTS TO PRESERVE:** Immediate session restoration, fail-closed routing,
the restoration semantic label, and no mandatory cinematic delay for
returning users.

**REDESIGN DIRECTION:** Place a lightweight Campus Flow identity animation on
a deep-space or pearl foundation. Let the visual resolve into the wordmark
while restoration runs, then transition immediately when authority is known.
After the short intro finishes, hold a calm branded loading state rather than
restarting the animation.

**MOTION OPPORTUNITIES:** A violet point can become converging spectral strands
and then the CampusConnect mark in roughly 1.5–2.2 seconds on true cold launch.
Returning restores should use a much shorter continuity transition. Reduced
motion should show a static mark and tonal progress.

**ACCESSIBILITY RISKS:** Ambient motion must honor
`MediaQuery.disableAnimations`; the loading state needs a useful announcement
without repeating on every frame. The mark cannot be the only source of the
CampusConnect name.

**PERFORMANCE RISKS:** Avoid a continuously running full-screen shader during
network restoration. Prewarm or simplify any painter, bound glow layers,
isolate them from the progress label, and stop painting as soon as the route
leaves.

### 4. Sign in

**SCREEN:** `/sign-in`, including validation, submitting, backend error, and
development-gallery actions.

**CURRENT PURPOSE:** Authenticate with campus email and password; navigate to
password recovery; and, only in an enabled non-production gallery build, enter
the developer gallery or preview session.

**CURRENT UX PROBLEMS:** The form is clear but institution-agnostic and gives
little confidence about what the user is signing into. Errors appear inline
but focus is not moved to them and they are not announced as a live region.
The developer actions add density when enabled, although the production gate
is correct. There is no distinct slow-network explanation beyond the disabled
button spinner.

**CURRENT VISUAL PROBLEMS:** The centered card, school icon, title, and standard
controls are generic. Large screens produce considerable unused space, and
there is no branded visual area, dimensional lighting, or connection between
the auth surface and Campus Flow.

**COMPONENTS TO PRESERVE:** The 440-pixel readable form constraint,
`SafeArea`, scrolling keyboard-safe layout, autofill group, email/password
validation, password visibility tooltip, submit-on-keyboard behavior, disabled
loading state, forgot-password path, and strict development-only gallery gate.

**REDESIGN DIRECTION:** Use a composed authentication scaffold: a bounded
Campus Flow hero in the upper region and a solid or lightly frosted readable
form panel in the lower region. Keep the form short, make “Welcome back” and
trust copy feel campus-specific without inventing institution data, and retain
all existing controller calls.

**MOTION OPPORTUNITIES:** Allow a restrained hero drift, a short form entrance,
spring-soft button press, and fade-through to reset or Home. Pause or simplify
ambient motion when the keyboard is open and honor reduced motion.

**ACCESSIBILITY RISKS:** Add live error announcement and deterministic focus to
the first invalid field or action error. Validate large text and keyboard
insets, preserve password show/hide semantics, maintain visible focus, and do
not place neon text over moving gradients.

**PERFORMANCE RISKS:** Keyboard appearance must not keep a blurred or
shader-heavy header repainting behind the form. Avoid large `BackdropFilter`
regions and stop ambient animation when the route is obscured.

### 5. Forgot password and reset-instruction confirmation

**SCREEN:** `/forgot-password` before and after a reset request succeeds.

**CURRENT PURPOSE:** Collect a campus email, request recovery without account
enumeration, then show a generic “Check your email” confirmation and a path
back to sign in.

**CURRENT UX PROBLEMS:** The non-enumerating response is correct, but the page
does not help with delayed email, spam folders, resend timing, or changing the
address. Submission errors are inline without live announcement. The email
field does not submit from an explicit keyboard action.

**CURRENT VISUAL PROBLEMS:** Both request and confirmation states are plain
card layouts with standard icons. The success state has no branded continuity
with Sign in and no premium confirmation treatment.

**COMPONENTS TO PRESERVE:** Enumeration-safe copy, email validation, loading
disablement, back behavior, scroll-safe constrained layout, and the explicit
post-success state.

**REDESIGN DIRECTION:** Keep one compact recovery journey inside the premium
auth scaffold. Use a calm mail/flow confirmation visual, show the entered
address in a privacy-conscious way if product approves it, and add clear
resend/change-address affordances only when supported by rate-limited logic.

**MOTION OPPORTUNITIES:** Morph the form panel into confirmation content with a
short shared-axis or fade-through transition; use a brief spectral check, not
confetti.

**ACCESSIBILITY RISKS:** Announce request success and failures once, move focus
to the confirmation heading, support large text, and ensure any resend timer
is not communicated by color or animation alone.

**PERFORMANCE RISKS:** This page needs no continuous expensive animation. Reuse
the authentication background and pause it when the app is inactive or the
keyboard is open.

### 6. Password recovery update

**SCREEN:** `/reset-password` during a classified recovery session.

**CURRENT PURPOSE:** Set and confirm a new password, enforce the current
eight-character client rule, finish recovery, and let session restoration
route the user onward.

**CURRENT UX PROBLEMS:** Both fields share one visibility toggle controlled
from the first field, so the confirm field cannot be inspected independently.
There is no strength/help text beyond the eight-character error, no explicit
completion state in this page, and errors are not live-announced.

**CURRENT VISUAL PROBLEMS:** The page repeats the same generic centered-card
formula and uses a static password icon. It does not visually communicate that
this is a secure, temporary recovery context.

**COMPONENTS TO PRESERVE:** Recovery-only routing, autofill hints, password
confirmation, existing validation contract, disabled submit spinner, and
keyboard-safe constrained form.

**REDESIGN DIRECTION:** Reuse the authentication shell with a distinct secure
recovery header, concise requirements, independent visibility behavior, and a
short server-confirmed completion transition. Do not add client requirements
that disagree with the backend policy.

**MOTION OPPORTUNITIES:** Animate requirement satisfaction subtly and use a
short secure-success transition after confirmation. Avoid attention-seeking
loops on a sensitive form.

**ACCESSIBILITY RISKS:** Independently label visibility controls, announce
validation and server failures, test password-manager/autofill behavior,
preserve focus through loading, and keep requirement text readable at large
scale.

**PERFORMANCE RISKS:** Very low in the current implementation. A premium
background should remain bounded and static under reduced motion and while
typing.

### 7. Onboarding access selection

**SCREEN:** `/onboarding` when multiple active institution/role grants require
selection.

**CURRENT PURPOSE:** Present only server-derived active grants and let the user
choose an institution and role. Selection is then revalidated and persisted as
context, not authority.

**CURRENT UX PROBLEMS:** Every grant is a similar outlined list tile, with no
current/recent context, descriptive permission summary, or visible in-flight
state. Taps are not disabled while `selectAccess` revalidates the session, so
rapid repeated selections can feel ambiguous. A long grant list is rendered as
one eager column.

**CURRENT VISUAL PROBLEMS:** Institution and role choices lack visual
personality, hierarchy, avatars/monograms, or an active-context preview. The
generic card-in-card treatment feels administrative.

**COMPONENTS TO PRESERVE:** The exact server-derived grant list, institution
and role labels, stable selection keys, revalidation before authority changes,
scrollable constrained width, and no client-authored permissions.

**REDESIGN DIRECTION:** Present compact campus identity cards with clear role
badges and an explicit “Continue as …” selection state. Make the active choice
obvious, show progress during revalidation, and keep this critical identity
step distinct from any optional cinematic first-run introduction.

**MOTION OPPORTUNITIES:** Use a small selected-card lift/edge light and
shared-axis transition into the role-aware shell. The context change should be
calm and interruptible only before selection begins.

**ACCESSIBILITY RISKS:** Announce institution and role together, expose
selected and busy states, preserve logical focus after a failed selection, and
test long/duplicate institution names and large text.

**PERFORMANCE RISKS:** Current grant counts are likely small, but an unbounded
eager column does not scale. Use a lazily built list if product limits do not
guarantee a small set; do not animate every card continuously.

### 8. Onboarding profile completion

**SCREEN:** `/onboarding` for an authenticated active member whose profile is
not completed.

**CURRENT PURPOSE:** Confirm a server-stored display name and complete the
minimum profile required before campus access.

**CURRENT UX PROBLEMS:** The task is intentionally minimal but has no step
context, explanation of where the name appears, retry guidance, or alternate
exit. The action error is inline but not a live region. Terms/privacy
acknowledgement and notification preferences are not implemented and must not
be represented as complete.

**CURRENT VISUAL PROBLEMS:** A heading, sentence, field, and button inside the
same generic onboarding card provide no identity preview or sense of
completion.

**COMPONENTS TO PRESERVE:** The existing display-name normalization boundary,
120-character client limit, autofill, loading lock, server action, and
single-task simplicity.

**REDESIGN DIRECTION:** Show a lightweight campus-identity preview using only
available real data, explain display-name use, and make this feel like the last
required setup step. Keep any optional three-screen marketing introduction
separate so it cannot block or alter identity classification.

**MOTION OPPORTUNITIES:** Let the identity preview update gently as the user
types and use a brief completion glow only after the server confirms success.

**ACCESSIBILITY RISKS:** Announce action failures, associate supporting copy
with the field, avoid animating every keystroke under reduced motion, and test
long names, bidirectional text, and large font sizes.

**PERFORMANCE RISKS:** Current cost is negligible. A live identity preview
should update only the small name region, not repaint an ambient full-screen
effect on each keystroke.

### 9. Invitation acceptance states

**SCREEN:** `/onboarding` for initial invitation activation or adding an
invited membership to an already active account.

**CURRENT PURPOSE:** Select an acceptable invitation, confirm a display name,
optionally create and confirm a password for an initial account, accept the
server-issued membership, and allow “Not now” only when existing active access
is available.

**CURRENT UX PROBLEMS:** With multiple invitations, dropdown rows show only
institution name even though role information is important and duplicate
institution names may be ambiguous. Invitation expiry is available in the
domain model but not shown. The initial-password and existing-account variants
share one dense form without a clear step summary. Errors are not
live-announced.

**CURRENT VISUAL PROBLEMS:** The single-invitation summary is a plain
`ListTile`; multiple invitations use a standard dropdown. Neither feels like
receiving verified campus access, and role grants are visually secondary.

**COMPONENTS TO PRESERVE:** Server-filtered acceptable invitations,
membership-ID submission, role information, conditional password requirement,
confirmation validation, loading lock, safe “Not now” rule, and no client-side
membership invention.

**REDESIGN DIRECTION:** Use an invitation card that clearly groups institution,
roles, expiry when known, and the account action required. For multiple
invitations, provide accessible choice cards or a rich selector with unique
labels. Keep initial password creation secure and existing-account acceptance
short.

**MOTION OPPORTUNITIES:** A selected invitation can gain a restrained spectral
edge; accepted access can resolve into the active campus identity card after
server confirmation.

**ACCESSIBILITY RISKS:** Ensure every option has a unique spoken institution,
role, and expiry label; make password visibility independent and explicit;
announce failures and success; and preserve focus when switching invitations.

**PERFORMANCE RISKS:** Invitation sets should be small, so rich cards are safe.
Do not run separate looping effects on every option or repaint the whole form
when only selection changes.

### 10. Onboarding unavailable fallback

**SCREEN:** `/onboarding` when the identity exists but no active setup branch,
acceptable invitation, or selection state can be rendered.

**CURRENT PURPOSE:** Fail honestly with a message instructing the user to
restore the session or contact an authorized administrator.

**CURRENT UX PROBLEMS:** This is a dead end: unlike Access unavailable, it has
no “Try again” or “Sign out” action. The text tells the user to restore but
provides no control to do so.

**CURRENT VISUAL PROBLEMS:** A generic info icon and centered paragraph look
like an unfinished fallback and do not communicate whether the state is
temporary or administrative.

**COMPONENTS TO PRESERVE:** Honest fail-closed behavior and the instruction to
contact an authorized campus administrator rather than implying self-service
access.

**REDESIGN DIRECTION:** Convert this to the same intentional access-status
family as Access unavailable, with safe restore and sign-out actions and
reason-specific copy if the session model can provide it.

**MOTION OPPORTUNITIES:** Only a subtle status entrance or retry progress is
needed; do not animate a blocked state continuously.

**ACCESSIBILITY RISKS:** The current fallback has no semantic heading and no
actionable focus target. A redesigned state needs a heading, ordered actions,
busy feedback, and a live result after retry.

**PERFORMANCE RISKS:** Negligible. Keep blocked and fallback states static.

### 11. Access unavailable

**SCREEN:** `/access-unavailable` for no membership, suspension, inactive
institution, expired invitation, missing role, or unverifiable access.

**CURRENT PURPOSE:** Explain the server-derived block reason, retry session
restoration, or sign out without granting partial access.

**CURRENT UX PROBLEMS:** Reason-specific copy is strong, but there is no
institution/contact context or support path. The “Try again” button is disabled
from `identityActionController.isLoading` even though it invokes
`SessionController.restore`; that unrelated loading flag does not guarantee
that repeated restore taps are blocked or that restore progress is shown.

**CURRENT VISUAL PROBLEMS:** Every cause receives the same admin-panel icon and
generic card, so temporary connectivity failure looks almost identical to
suspension or inactive-institution status.

**COMPONENTS TO PRESERVE:** Fail-closed routing, reason-specific nontechnical
copy, safe restore, sign out, constrained scrolling layout, and no bypass
around membership authority.

**REDESIGN DIRECTION:** Create a clear access-status panel with semantic
severity and distinct temporary versus administrative treatment. Connect retry
busy state to the actual restore operation and offer support details only when
real institution data or an approved channel exists.

**MOTION OPPORTUNITIES:** Use a short retry progress transition and a calm
state change if access is restored. Administrative blocks should remain still.

**ACCESSIBILITY RISKS:** Make the reason a semantic heading/status, announce
retry outcome, expose the true busy state, preserve focus after failure, and
keep warning colors supplementary to text and iconography.

**PERFORMANCE RISKS:** Current cost is negligible. This state does not justify
an always-running ambient scene.

### 12. Student Home

**SCREEN:** `/home` with an active Student grant and eligible academics.

**CURRENT PURPOSE:** Confirm that identity is connected and provide two entry
cards to today’s timetable and attendance summary, both of which navigate to
Academics.

**CURRENT UX PROBLEMS:** The page does not use the available display name,
institution, date, next class, schedule, or attendance metrics. The two cards
are duplicate route shortcuts rather than distinct tasks. “Identity connected”
is system-oriented language with little daily value. There is no dashboard
loading or error state because no academic data is loaded here.

**CURRENT VISUAL PROBLEMS:** A standard large app bar, one status chip, text,
and two list tiles do not form a meaningful student dashboard. There is no
hero, temporal hierarchy, timetable rhythm, attendance visualization, or
CampusConnect signature.

**COMPONENTS TO PRESERVE:** Role-aware copy, permission/configuration gating,
honest navigation to implemented data, accessible standard controls, and no
fake announcements, events, career items, or metrics.

**REDESIGN DIRECTION:** Make Student Home the first complete Purple Universe
showcase using real academic repository data: personalized greeting, campus
date, next-class hero when available, a compact attendance overview without
invented thresholds, and a short today timeline. Keep unimplemented For You,
events, announcements, and career sections absent or explicitly labelled as
development-only—not mocked as production data.

**MOTION OPPORTUNITIES:** Compress a bounded spectral header on scroll, add
subtle next-class edge light, animate attendance values only on first data
arrival, and use coherent hero/fade-through navigation into Academics.

**ACCESSIBILITY RISKS:** Time-sensitive content needs complete spoken labels,
not visual position alone. Radial attendance visuals must include exact text,
large text must reflow the hero/timeline, and ambient/parallax movement must
have a reduced-motion path.

**PERFORMANCE RISKS:** Do not duplicate uncontrolled dashboard fetches between
Home and Academics. Share or deliberately cache authoritative data, bound the
hero painter, pause it offscreen, and avoid animating every timetable row.

### 13. Faculty Home

**SCREEN:** `/home` with an active Faculty grant and eligible academics.

**CURRENT PURPOSE:** Confirm identity and link to today’s assigned classes and
either fast attendance or read-only rosters based on
`attendanceRecord` permission.

**CURRENT UX PROBLEMS:** It does not show the next assigned class, class count,
submission status, unresolved local drafts, or roster workload. Both action
cards navigate to the same destination. Read-only versus record authority is
only explained in a subtitle, and urgent draft states remain hidden until
Academics is opened.

**CURRENT VISUAL PROBLEMS:** The Faculty experience is the Student baseline
with different copy. It has no professional workflow hierarchy, live status,
or distinct faculty identity beyond the app-bar title.

**COMPONENTS TO PRESERVE:** Permission-aware read-only wording,
configuration/role gating, one safe Academics destination, and no attempt to
submit from Home without the existing durable preflight.

**REDESIGN DIRECTION:** Use real assigned-class and local-draft data for a
faculty command view: next class, attendance-to-record count, submitted count,
and explicit unresolved local state. Route all actual marking through the
existing Faculty Academics workflow; Home should summarize, not bypass,
authority checks.

**MOTION OPPORTUNITIES:** Animate class-state changes and unresolved-draft
attention with restrained edge lighting; transition the selected class into
its roster. Celebrate only confirmed server submission.

**ACCESSIBILITY RISKS:** Urgency cannot rely on glow or color. Counts need clear
labels, role/read-only state must be spoken, and moving background treatment
must not compete with time-critical workflow content.

**PERFORMANCE RISKS:** Avoid a second independent polling/fetch pipeline and
multiple live countdown timers. Update time labels at a sensible cadence and
keep draft status observation lightweight.

### 14. Multi-role and unsupported-role Home behavior

**SCREEN:** `/home` for users with multiple grants or roles other than Student
and Faculty.

**CURRENT PURPOSE:** Show the currently selected role in the title; expose
Academics only for an eligible Student or Faculty grant; and honestly show “No
additional modules enabled” for unsupported or unconfigured experiences.
Role/institution switching is available later in Profile.

**CURRENT UX PROBLEMS:** The active institution is not visible on Home or in
the shell, and the role switcher is buried in Profile. A user who works across
campuses or roles can lose context, while the generic locked-module card does
not explain which future capabilities apply. Initial multi-grant selection is
handled, but subsequent switching lacks global discoverability.

**CURRENT VISUAL PROBLEMS:** Unsupported roles receive an almost empty generic
page, and multiple personas have no visual identity or active-context marker.

**COMPONENTS TO PRESERVE:** Fail-closed destination gating, server-derived
selection, honest hidden product areas, and identity invalidation when context
changes.

**REDESIGN DIRECTION:** Add a compact active campus/role identity control to
the top-level shell or header, with a safe context sheet for users who have
multiple grants. Give unsupported roles an intentional “available to you”
state without exposing dead navigation. Never use a visual role switch to
manufacture permissions.

**MOTION OPPORTUNITIES:** The active-context pill can morph into a role sheet;
on confirmed selection, use a short content fade-through and reset scoped
visual data.

**ACCESSIBILITY RISKS:** Always announce the active institution and role
together, expose selection state, return focus after switching, and ensure
role icons are supplementary rather than the only discriminator.

**PERFORMANCE RISKS:** Context changes must cancel or ignore stale animated and
data work just as the controllers already ignore stale authority. Do not keep
off-role dashboards alive behind a visual transition.

### 15. Student Academics

**SCREEN:** `/academics` for an eligible Student, including today’s schedule
and subject attendance summary.

**CURRENT PURPOSE:** Load the institution-local server date, show today’s
timetable with time/subject/section/room and recorded status, and display exact
attendance counts and percentages per subject.

**CURRENT UX PROBLEMS:** The content is reliable but flat: there is no next
class emphasis, week/history navigation, subject detail, or calendar view.
Attendance summaries are intentionally neutral because risk thresholds are
not implemented, so the screen cannot honestly say “on track” or “at risk.”
Schedule and summary are one long eager column.

**CURRENT VISUAL PROBLEMS:** Time is a small two-line block, each class is a
plain card, and attendance is a neutral chip plus default linear progress bar.
The layout does not express time progression or make percentage relationships
easy to scan.

**COMPONENTS TO PRESERVE:** Server-derived date and scope, exact schedule data,
the time semantic label, explicit recorded/scheduled status, exact attendance
counts, neutral percentage policy, loading/error/empty handling, and
pull-to-refresh.

**REDESIGN DIRECTION:** Build a legible illuminated day timeline, visually
promote the next real class when it can be derived safely, and use accessible
attendance rings or bars tied to exact counts. Do not introduce risk language
until configurable attendance policy exists. Leave unimplemented detail and
week controls absent or visibly disabled only in development prototypes.

**MOTION OPPORTUNITIES:** Reveal the current/next timeline marker, interpolate
summary progress once when data arrives, and use a card-to-detail hero only
after a real detail route exists.

**ACCESSIBILITY RISKS:** Progress visuals need exact percentage and count
labels; current horizontal rows may overflow with large text or long subject
names. Time/current-class status cannot depend on position, cyan, or glow.
Respect reduced motion for progress animation.

**PERFORMANCE RISKS:** The current `SliverToBoxAdapter` contains an eager
`Column`; this is acceptable for small daily schedules but should not be
extended into unbounded history. Cache static painters, avoid per-card blur,
and virtualize longer lists.

### 16. Faculty Academics and attendance capture

**SCREEN:** `/academics` for an eligible Faculty grant, with expandable
assigned classes, exact rosters, read-only or record authority, and submission.

**CURRENT PURPOSE:** Show server-authoritative assigned classes, expand an
exact roster, set Present/Absent/Late/Excused per student, save locally, and
submit one atomic server-confirmed attendance request when authorized.

**CURRENT UX PROBLEMS:** Every roster row uses a dropdown, making rapid marking
slow. There are no bulk controls, live Present/Absent/Late/Excused totals,
sticky submission summary, or final confirmation step. Unmarked server rows
default visually to Present, so a Faculty user can submit the default roster
without an explicit review gesture. A global submission loading flag affects
all class cards, which can make it unclear which class is submitting.

**CURRENT VISUAL PROBLEMS:** A standard `ExpansionTile`, repeated generic
avatars, dense list tiles, dropdowns, and stacked full-width buttons read like
an administrative form. Submission state and counts are buried inside each
expanded card.

**COMPONENTS TO PRESERVE:** Exact roster identity, four existing statuses,
permission-aware read-only mode, server-derived class/date, durable write
before RPC, explicit submission, idempotent exact retry, server-confirmed
success, safe disabled states, and no automatic submission.

**REDESIGN DIRECTION:** Introduce a focused roster workspace with fast
segmented P/A/L/E controls, carefully designed bulk actions, live totals, a
class-specific sticky review/submit surface, and a confirmation summary.
Retain the same status map and submission controller boundaries. Make local,
submitting, confirmed, and read-only authority unmistakable.

**MOTION OPPORTUNITIES:** Use spring-soft class expansion, immediate selection
feedback, small count transitions, optional selection haptics, and a brief
spectral confirmation only after the server confirms. Avoid animation while a
user is rapidly marking rows.

**ACCESSIBILITY RISKS:** Every compact status control must retain the student
name in its accessible label, expose selected state, meet touch targets, and
work without color. A confirmation step should receive focus and summarize
counts. Large names/text must not collide with controls, and read-only state
must be explicit.

**PERFORMANCE RISKS:** The current widget tree constructs every roster
`ListTile` inside each class card, even though content is presented through
expansion. Large classes or many classes can create a heavy eager tree.
Virtualize long rosters, isolate only the changing row/count regions, avoid
blur per student, and prevent ambient animation from repainting the roster.

### 17. Faculty encrypted draft state inside a class

**SCREEN:** Faculty class card in no-draft, unsaved-changes, saved,
submission-uncertain, needs-review, and submitted states.

**CURRENT PURPOSE:** Distinguish in-memory edits, encrypted device-local saves,
requests that may have reached the server, stale/mismatched drafts requiring
review, and confirmed server submission. It freezes uncertain payloads and
does not equate a local save with server submission.

**CURRENT UX PROBLEMS:** The safety copy is excellent but creates a dense stack
of badges, explanatory text, disabled buttons, and connection notes. “Needs
review” tells the user to refresh but offers no focused resolution flow.
Saved-at time is available in draft data but not shown. Some disabled actions
communicate the reason only in nearby body text.

**CURRENT VISUAL PROBLEMS:** State is primarily one standard status chip inside
the expanded class, so important local-only or uncertain work can be visually
subordinate to the roster. Warning, review, and submission controls share the
same generic card surface.

**COMPONENTS TO PRESERVE:** The exact state machine and vocabulary,
write-before-submit behavior, frozen uncertain retry, roster/class mismatch
detection, no auto-submit on reconnect, explicit discard, server-confirmed
deletion only, and local display-name exclusion.

**REDESIGN DIRECTION:** Create a persistent class-state rail or compact banner
with icon, semantic label, last-saved time, and one clear next action. Make
“Saved on this device” visually different from “Submitted to campus.” Give
uncertain state a focused exact-retry/status explanation and needs-review a
guided refresh-and-compare path without changing controller guarantees.

**MOTION OPPORTUNITIES:** Crossfade state labels, animate the local-save icon
briefly, and transition to confirmed only when authoritative data arrives.
Uncertain and danger states should not pulse continuously.

**ACCESSIBILITY RISKS:** The existing live region around the status badge is a
good start, but snackbar-only save/discard confirmation may be missed. Announce
meaningful state transitions once, expose why controls are disabled, and do
not communicate local/server distinction through color or glow alone.

**PERFORMANCE RISKS:** State changes are small and should repaint only their
banner, counts, and affected controls. Avoid connectivity-driven restart of
ambient or card-wide animations.

### 18. Encrypted draft recovery list

**SCREEN:** “Saved on this device” recovery cards for drafts not matched to
the currently visible server schedule/date.

**CURRENT PURPOSE:** Keep older or changed-class drafts visible, sorted by
update time, without persisting or displaying Student names. Allow online
server-status review or historical-date opening, allow safe discard except
for uncertain submissions, and never auto-submit.

**CURRENT UX PROBLEMS:** Recovery appears after all current schedule cards, so
urgent unresolved work can be missed. There is no unresolved count near the
page title, no last-saved timestamp, and no explanation of why a class changed.
Opening/review is disabled offline; the button label explains this visually
but there is no alternative summary view.

**CURRENT VISUAL PROBLEMS:** Recovery cards look like ordinary content cards,
despite representing durable local work with distinct risk. Date, time, roster
count, status, action, and explanatory copy form a tall repetitive stack.

**COMPONENTS TO PRESERVE:** User/membership/institution/selection scoping,
no Student display names at rest or in the recovery card, server-authoritative
checking, no auto-submit, frozen uncertain behavior, state-specific discard
rules, date sorting, and discard confirmation.

**REDESIGN DIRECTION:** Add an unresolved-work summary near the Faculty header
and a compact recovery inbox grouped by state/date. Use a clear local-vault
motif, show last-saved time, explain safe next actions, and keep uncertain
items non-discardable. The UI must remain a view over the existing scoped draft
book, not a new sync queue.

**MOTION OPPORTUNITIES:** Reveal the recovery panel when unresolved work first
appears, morph a selected item into its class/date review, and collapse it
after authoritative resolution. Do not use alarm-like looping motion.

**ACCESSIBILITY RISKS:** Disabled online-only actions need a spoken reason;
status/date/class context should be one concise card label; discard dialog
focus must remain contained; and local-vault iconography cannot replace the
explicit “not submitted” text.

**PERFORMANCE RISKS:** The list is eager and uncertain/review drafts may outlive
normal saved-draft retention. Use lazy rendering if volume grows, avoid one
animated effect per card, and keep decryption/loading outside paint work.

### 19. Historical draft review

**SCREEN:** Faculty Academics after opening a recovery draft whose date differs
from server “today.”

**CURRENT PURPOSE:** Load authoritative dashboard data for the saved date,
disable new past-date attendance submission, reconcile saved work with server
results, check uncertain work without resubmitting it, and provide “Back to
today.”

**CURRENT UX PROBLEMS:** The only strong historical cue is the date plus “Back
to today.” The section still says “Today’s assigned classes,” which is
incorrect on a historical date. There is no date picker, breadcrumb, reason
for entering review mode, or focused comparison/resolution view. Disabled
submit controls remain visible with “Past date — check status,” adding
ambiguity.

**CURRENT VISUAL PROBLEMS:** Historical review is visually almost identical to
today’s capture screen, so users can miss the mode change. The back action
floats above otherwise unchanged content rather than establishing a distinct
review header.

**COMPONENTS TO PRESERVE:** Authoritative date-specific load, clearly displayed
server date, read-only past behavior, exact server reconciliation, no past
auto-submit or resubmit, and always-available return to today even when the
historical dashboard errors.

**REDESIGN DIRECTION:** Introduce an explicit “Reviewing saved work” header
with date, local state, server state, and a clear return action. Replace
“Today’s” copy with date-aware language. Present differences and allowed
resolution actions directly; do not imply general attendance history, because
that product area is not implemented.

**MOTION OPPORTUNITIES:** Use a short date/content crossfade and selected-card
continuity from recovery. Keep review controls static and predictable.

**ACCESSIBILITY RISKS:** Announce entry into historical read-only mode and the
selected date, move focus to the review heading after load, preserve access to
“Back to today” on errors, and make unavailable submission explicit rather
than relying on disabled styling.

**PERFORMANCE RISKS:** Date changes trigger a new authoritative fetch. Avoid
retaining multiple animated dashboards or presenting stale cached authority;
cache only if it preserves the existing scope and freshness rules.

### 20. Offline and connection-checking states

**SCREEN:** Global shell offline banner plus Faculty Academics offline,
unknown-connection, save-local, and retry-when-online states.

**CURRENT PURPOSE:** Warn globally when connectivity reports offline, allow
Faculty encrypted draft saves, disable server submission without a known
online state, and explicitly avoid automatic submission on reconnect.

**CURRENT UX PROBLEMS:** The global banner says some information “may be out of
date” even though broad academic reference/data caching is not implemented;
depending on prior load, the user may instead have no data. It has no
last-updated time or action. Faculty cards repeat connection copy, while
Student Academics has no contextual offline-cache explanation. Unknown status
and offline status can produce several simultaneous messages.

**CURRENT VISUAL PROBLEMS:** A standard `MaterialBanner` and centered text under
each Faculty action interrupt the page hierarchy. Offline is visually
disconnected from the secure-local-draft state it most affects.

**COMPONENTS TO PRESERVE:** Submission disabled unless online, local saving
while offline, explicit local-versus-submitted language, no auto-submit on
reconnect, and one shell-level indication that applies across destinations.

**REDESIGN DIRECTION:** Use a compact accessible connection indicator in the
shell and one contextual Faculty draft panel that says exactly what remains
available. Show last-updated information only when real cached data and a real
timestamp exist. Do not claim the whole app works offline until broader cache
and sync architecture is delivered.

**MOTION OPPORTUNITIES:** Gently transition the connectivity indicator and
announce restored connection without automatically moving or submitting
anything. Avoid pulsing offline warnings.

**ACCESSIBILITY RISKS:** Network changes should be announced once without
repeated interruption, online-only disabled controls need a spoken reason, and
warning state cannot rely on amber. Verify banner/action focus with bottom
navigation and large text.

**PERFORMANCE RISKS:** Connectivity is watched by both the shell and Academics,
so changes rebuild significant widget regions. New ambient and navigation
animations must not restart on every status update; isolate stable visual
layers and animate only the indicator.

### 21. Academics loading, refresh, empty, and error states

**SCREEN:** Academic dashboard initial load/refresh, no classes, no Student
attendance, full load error, and inline attendance/draft action error.

**CURRENT PURPOSE:** Show eight skeleton lines while loading, retryable typed
errors, contextual empty states, pull-to-refresh, and live inline attendance
action errors.

**CURRENT UX PROBLEMS:** Refresh deliberately replaces all data with the full
skeleton, losing visual context and scroll continuity. The generic error title
does not distinguish timetable, roster, or attendance failure. There is no
safe stale-data fallback, per-section retry, or last-success timestamp.
Pull-to-refresh uses the platform-generic indicator.

**CURRENT VISUAL PROBLEMS:** Identical horizontal skeleton bars do not resemble
the destination layout. Empty and error states use stock icons and large blank
areas. Inline errors are clearer but still standard error-container cards.

**COMPONENTS TO PRESERVE:** Explicit loading/error/data states, typed
user-facing failure mapping, retry, contextual class/attendance empty copy,
always-scrollable refresh, live region for action errors, and no raw technical
exception display.

**REDESIGN DIRECTION:** Add layout-aware class and attendance skeletons,
section-specific error titles, premium Campus Flow refresh, and compact inline
recovery. Retain stale content during refresh only if architecture can prove it
belongs to the same current authority; otherwise preserve the existing
fail-closed replacement.

**MOTION OPPORTUNITIES:** One restrained spectral shimmer, a compact pull
animation, and short error-to-content fade are sufficient. Reduced motion uses
static placeholders and immediate replacement.

**ACCESSIBILITY RISKS:** Ensure only one useful loading announcement, move
focus to a full-page error when appropriate, keep retry discoverable, and
avoid shimmer for reduced-motion users. Correct the shared empty-state heading
semantics before reuse expands.

**PERFORMANCE RISKS:** Do not animate every skeleton line independently or
keep shimmer active after data arrives. A full replacement can also trigger
large rebuilds; isolate header/background from dashboard state.

### 22. Profile and campus identity

**SCREEN:** `/profile`, including identity summary, theme selection,
institution/role switching, pending invitation review, action error, and sign
out.

**CURRENT PURPOSE:** Display the available name and active institution/role,
change system/light/dark mode, switch among validated grants, enter pending
invitation acceptance, and sign out.

**CURRENT UX PROBLEMS:** The page cannot yet provide student ID, department,
semester, email, privacy, security, devices, help, or notification preferences
because those data/contracts are absent. Theme choice is not persisted.
Grant switching has no visible revalidation progress. Sign out clears
encrypted drafts by design, but the UI does not warn a Faculty user who may
have unresolved local drafts before they sign out.

**CURRENT VISUAL PROBLEMS:** A generic avatar list tile, divider, dropdowns,
outlined invitation card, and sign-out button do not feel like a digital
campus identity. The active campus/role has little prominence.

**COMPONENTS TO PRESERVE:** Real display name only, active server-derived grant,
validated context switching, theme modes, invitation review/cancel flow,
action error, sign-out behavior, and the rule against inventing unavailable
profile fields.

**REDESIGN DIRECTION:** Build a premium Campus ID card using only fields
currently available, followed by grouped Appearance, Campus access,
Invitations, and Account sections. Surface unresolved local-draft consequences
before sign-out. Add future identity fields only after their server contracts
exist.

**MOTION OPPORTUNITIES:** Use a subtle spectral ID edge, smooth theme preview,
and a short context-switch transition. Sign-out should be deliberate and
static, with no celebratory motion.

**ACCESSIBILITY RISKS:** Long institution/role labels can overflow dropdown
items; role changes and theme changes need announcements; the Campus ID must
have a concise semantic reading order; and any sign-out warning must clearly
explain local draft deletion without alarmist language.

**PERFORMANCE RISKS:** The current page is inexpensive. Keep any ID-card
lighting bounded and noncontinuous, avoid live blur behind settings lists, and
do not load future profile modules until their section is requested.

### 23. Role-aware shell and responsive navigation

**SCREEN:** Shared authenticated shell containing Home, eligible Academics,
Profile, offline messaging, bottom navigation below 720 pixels, and navigation
rail at wider widths.

**CURRENT PURPOSE:** Build destinations from current configuration and active
grant, hide Academics unless authorized, center content to 1200 pixels, switch
between Material navigation bar and rail, and keep an offline notice above the
active route.

**CURRENT UX PROBLEMS:** Active institution/role is absent from navigation.
Bottom and rail destinations change after role selection without an explicit
context explanation. The shell has no top-level notification or context
actions, and unsupported product modules are correctly absent but make the
experience feel sparse. The offline banner has no action or timestamp.

**CURRENT VISUAL PROBLEMS:** Standard `NavigationBar`/`NavigationRail`, a
one-pixel divider, and a wide single-column content region lack a branded shell
or premium active indicator. At tablet/desktop widths, content can remain
visually sparse despite the safe maximum width.

**COMPONENTS TO PRESERVE:** Dynamic permission/configuration gating, only
implemented destinations, responsive rail breakpoint, Material navigation
semantics, route-derived selection, max content width, and the separation
between shell and feature business logic.

**REDESIGN DIRECTION:** Create `CcNavigationGlass` or an equivalent integrated
navigation surface with a thin spectral edge, clear active item, safe-area
awareness, and a compact institution/role context control. Keep the current
destination source of truth and do not add Campus, Career, or other tabs until
their real routes and contracts exist.

**MOTION OPPORTUNITIES:** Glide a small active indicator, transition icon/label
states, use restrained fade-through between peer destinations, and morph the
context control into a selector sheet. All must have reduced-motion
equivalents.

**ACCESSIBILITY RISKS:** Preserve Material destination names, selected states,
logical focus order, keyboard navigation on wide screens, Android gesture/nav
insets, and 44-pixel targets. Active context must be spoken. Moving or glowing
indicators cannot be the sole selected-state cue.

**PERFORMANCE RISKS:** A full-width blurred bottom bar or rail can be expensive
over animated content. Bound and cache blur, prevent the ambient background
from repainting navigation, and avoid rebuilding/restarting shell effects when
only connectivity or feature data changes.

### 24. Design-system gallery

**SCREEN:** Development-only `/design-system`.

**CURRENT PURPOSE:** Preview four Material button types, search, four status
badges, the skeleton, an empty state, and an error state. The route is exposed
only when the non-production gallery flag is enabled.

**CURRENT UX PROBLEMS:** The gallery is a sample list rather than a design
system workbench. It has no light/dark toggle, quality/reduced-motion controls,
viewport/text-scale matrix, state selectors, token documentation, or copyable
component guidance. The buttons are inert and the uncontrolled search clear
behavior is misleading.

**CURRENT VISUAL PROBLEMS:** It demonstrates the same generic Material
foundation under review and omits colors, gradients, type, glass, lighting,
navigation, charts, forms, attendance states, and motion.

**COMPONENTS TO PRESERVE:** Strict development-only route gating, direct return
to Sign in, a scrollable catalog, and live reuse of production components
rather than screenshots.

**REDESIGN DIRECTION:** Turn this into the authoritative Purple Universe
catalog: foundations, semantic colors, gradients, typography, spacing,
surfaces, buttons, inputs, status, feedback, navigation, Campus Flow,
attendance controls/rings, motion, light/dark, quality, and accessibility
states. Use the same components production screens import.

**MOTION OPPORTUNITIES:** Provide opt-in isolated motion demos with replay and
reduced-motion comparison. Do not let every gallery specimen animate
simultaneously.

**ACCESSIBILITY RISKS:** The gallery should expose contrast notes, focus/hover
states, semantics, text scaling, and reduced-motion previews. It must remain
keyboard navigable and should make accessibility failures visible during
development.

**PERFORMANCE RISKS:** Rendering all shaders, blurs, charts, loaders, and
ambient effects at once would make the gallery a misleading worst case. Lazy
build sections, pause offscreen demos, and show performance/quality controls.

### 25. Product areas with no current screen

**SCREEN:** Announcements, notification center/preferences, Events, Clubs,
Career, Mentorship, academic week/detail/calendar, attendance history/risk,
attendance adjustments/export, and institution academic/invitation
administration.

**CURRENT PURPOSE:** None in the present Flutter route tree. These areas are
roadmap work and are deliberately hidden rather than exposed as dead
production controls.

**CURRENT UX PROBLEMS:** The implemented app currently covers identity,
Home/Profile, Student today/summary, Faculty assigned classes/attendance, and
encrypted local drafts—not the full campus operating-system promise. There are
no current screens to visually audit or validate for these product areas.

**CURRENT VISUAL PROBLEMS:** No implementation exists. Requested mockups,
proposed navigation labels, and future golden-test names must not be mistaken
for finished surfaces.

**COMPONENTS TO PRESERVE:** The honest fail-closed route boundary, absence of
fake production records, existing roadmap sequencing, tenant/role permissions,
and the rule that visual work must consume real repository contracts.

**REDESIGN DIRECTION:** Build these areas only after their domain, backend,
authorization, offline, empty/error, and test contracts exist. Reuse Purple
Universe foundations, but give each product area controlled personality rather
than cloning one dashboard card. Do not add their navigation destinations as
visual placeholders in production.

**MOTION OPPORTUNITIES:** Not applicable until real user journeys exist. Define
motion from task hierarchy after those flows are specified, not from concept
art.

**ACCESSIBILITY RISKS:** Future screens require independent keyboard,
screen-reader, contrast, text-scale, reduced-motion, and state-language audits.
No accessibility claim can be made for an unimplemented mockup.

**PERFORMANCE RISKS:** Future media feeds, event artwork, long opportunity
lists, calendars, notifications, and admin tables will need separate budgets,
virtualization, caching, and image policies. They must not inherit an
unbounded full-screen effects engine by default.

## Redesign sequencing implied by the audit

The current architecture supports a conservative implementation order:

1. Expand semantic foundations and build the reduced-motion/performance
   controls.
2. Replace shared feedback and establish one bounded Campus Flow engine.
3. Redesign the role-aware shell without changing route/destination authority.
4. Migrate Splash and authentication/account-setup states.
5. Build Student Home as the real-data showcase.
6. Migrate Student Academics, then the more interaction-heavy Faculty
   attendance and encrypted-draft states.
7. Migrate Profile and expand the development gallery/golden matrix.
8. Add later product areas only when their real business contracts exist.

At every step, visual state must continue to distinguish “saved locally” from
“submitted to the server,” and no animation, navigation element, or cached
view may outlive the active user, membership, institution, role, or permission
scope.
