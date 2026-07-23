# CampusConnect Purple Universe motion system

## Status and scope

This document is the implementation contract for motion in CampusConnect. It
defines how motion communicates hierarchy, causality, state, and the calm
energy of the Purple Universe visual language.

Motion is a presentation concern. It must not change authentication,
authorization, navigation guards, repository calls, attendance idempotency,
encrypted-draft behavior, or any server contract. An animation callback must
never commit, retry, delay, or infer a business operation.

The current Flutter application provides a sound base:

- `lib/core/theme` owns Material 3 theme and design tokens.
- `GoRouter` owns public and protected routes, with a `ShellRoute` for Home,
  Academics, and Profile.
- `RoleAwareShell` switches between `NavigationBar` and `NavigationRail` at
  the existing 720 logical-pixel breakpoint.
- Riverpod exposes session, connectivity, academic dashboard, draft, and
  submission state.
- Home and Academics use `CustomScrollView` and large sliver app bars.
- Faculty classes use `ExpansionTile`; async feedback uses skeletons,
  progress indicators, banners, snackbars, and a destructive confirmation
  dialog.
- There is no third-party animation dependency. Flutter's animation,
  rendering, physics, services, and routing APIs are sufficient for the first
  implementation.

This specification applies to dark and light themes. Color, glow, and glass
may differ by theme, but timing and interaction meaning do not.

## Principles

1. **Truth precedes motion.** The authoritative state changes first; motion
   explains that change. A transition must never make a locally saved draft
   look server-submitted.
2. **Calm, not restless.** Interactive motion is brief. Ambient motion is slow,
   low-amplitude, sparse, and limited to selected high-value surfaces.
3. **Spatial meaning is consistent.** Peer destinations use fade-through;
   parent/child journeys use a shared axis; overlays use depth; continuous
   objects alone qualify for a hero transition.
4. **Input response is immediate.** Press feedback starts within the next
   rendered frame and never waits for network or storage.
5. **Interruption is normal.** Animations must reverse or settle cleanly after
   a canceled gesture, route change, rebuild, lifecycle pause, or authority
   change.
6. **Accessibility is a first-class mode.** Reduced motion is a deliberate,
   tested presentation, not every duration divided by an arbitrary factor.
7. **Motion is optional; state feedback is not.** Text, icons, semantics,
   focus, and disabled states remain sufficient when every nonessential
   animation is removed.
8. **One visual event per state change.** Do not combine a scale, bounce,
   parallax, shimmer, glow sweep, and haptic for an ordinary action.

## Architecture and ownership

Keep motion beside the existing theme rather than creating a second design
system hierarchy:

```text
lib/core/theme/
  app_tokens.dart             existing spacing, radius, color, breakpoints
  app_motion.dart             durations, curves, springs, resolved policy
  app_theme.dart              theme animation and component defaults

lib/core/routing/
  app_router.dart             existing routes and redirects
  app_transition_page.dart    reusable route transition page

lib/core/widgets/
  motion/                     reusable press, switch, reveal helpers
```

The exact helper filenames may be consolidated, but ownership must remain:

| Concern | Owner |
|---|---|
| Durations, curves, spring descriptions | `core/theme` |
| Reduced-motion resolution | one `core/theme` policy |
| Route hierarchy and transitions | `core/routing` |
| Press, reveal, and state-switch behavior | reusable `core/widgets` |
| When a domain state changed | existing Riverpod controllers |
| Screen-specific composition | feature presentation layer |
| Ambient quality and pause state | visible screen/effect owner |

Do not add animation timers to Riverpod domain or data providers. A widget may
observe a provider transition and animate from the previous rendered value to
the new value, but the provider remains unaware of that animation.

### Proposed centralized API

`app_motion.dart` should expose one vocabulary:

```dart
abstract final class AppMotionDurations {
  static const instant = Duration(milliseconds: 80);
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const comfortable = Duration(milliseconds: 320);
  static const expressive = Duration(milliseconds: 450);

  static const shortLoop = Duration(milliseconds: 1600);
  static const ambient = Duration(seconds: 12);
  static const ambientLong = Duration(seconds: 20);
}

abstract final class AppMotionCurves {
  static const standard = Cubic(0.20, 0.00, 0.00, 1.00);
  static const decelerate = Cubic(0.00, 0.00, 0.00, 1.00);
  static const accelerate = Cubic(0.30, 0.00, 1.00, 1.00);
  static const ambient = Curves.easeInOutSine;
}

abstract final class AppMotionSprings {
  static final spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 0.82,
  );

  static final softSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.95,
  );
}
```

`spring` and `softSpring` are physical simulations, not decorative cubic
curves. Use `SpringSimulation` where release velocity and interruption matter.
Do not approximate them with a large elastic overshoot. The interactive spring
may produce one restrained return; the soft spring should appear almost
critically damped.

A single resolver must derive a full or reduced profile from
`MediaQuery.disableAnimationsOf(context)`. If CampusConnect later adds an
explicit in-app motion preference, the effective reduced setting is the
logical OR of the app preference and the platform value. Individual widgets
must not read unrelated platform flags or invent local duration multipliers.

### Token meaning

| Token | Use | Never use for |
|---|---|---|
| `instant`, 80 ms | icon swap, pressed-state onset, focus accent | page travel |
| `quick`, 140 ms | button content, badge state, small opacity | ambient effects |
| `standard`, 220 ms | async state swap, shell peer transition, banner | celebration |
| `comfortable`, 320 ms | shared-axis route, expansion, large surface reveal | routine tap feedback |
| `expressive`, 450 ms | one-time confirmed success or hero morph | loading or blocking |
| `shortLoop`, 1600 ms | bounded branded loader or skeleton cycle | permanent ambient background |
| `ambient`, 12 s | primary Campus Flow drift | interaction feedback |
| `ambientLong`, 20 s | secondary glow phase | independent per-card loops |

Staggering is 40 ms between items, capped at five items and 160 ms total
onset. Never stagger a roster, timetable, feed, search result, or any
unbounded list. Long lists reveal as a group and rely on scroll motion.

### Distances and amplitudes

| Behavior | Limit |
|---|---|
| Press compression | scale `1.0` to `0.975` |
| Selected navigation icon | scale no higher than `1.06` |
| Shared-axis route travel | at most 16 logical pixels |
| Depth route travel | at most 8 logical pixels and scale `0.985` to `1.0` |
| Header parallax | at most 6 logical pixels |
| Touch-following highlight | remains inside the clipped focal surface |
| Spring overshoot | less than 3% of the animated property range |

The gesture and semantics hit region never scales down with the visual child.
All targets retain the existing minimum 44 logical-pixel size, preferably 48.

## Reduced-motion semantics

Reduced motion is active whenever
`MediaQuery.disableAnimationsOf(context)` is true. The reduced profile is:

| Full behavior | Reduced behavior |
|---|---|
| Page translation, depth, or hero morph | no spatial travel; destination replaces immediately |
| Press scale or spring | no scale; immediate color, border, or elevation state |
| Expansion spring | content appears without animated size |
| Ambient Campus Flow | static, intentionally composed frame |
| Parallax, touch-following light, gyro | disabled |
| Skeleton shimmer | static skeleton |
| Branded looping loader | static progress mark plus visible loading text |
| One-time celebration | 80 ms opacity change only |
| Badge/icon state change | up to 80 ms crossfade |
| Offline/error banner | immediate layout; up to 80 ms opacity |

Reduced motion does not mean reduced information:

- Update labels, status icons, enabled state, and semantic values immediately.
- Keep progress and loading text present.
- Keep live-region announcements for errors, draft persistence, offline state,
  and confirmed submission.
- Do not leave invisible delays in place after removing an animation.
- Do not rely on direction, scale, color, or glow to explain a state change.
- Do not run a zero-visible-motion ticker.

Opacity transitions must not leave duplicate outgoing content in the semantic
tree. Exclude the outgoing layer from semantics as soon as the new state is
authoritative.

## Security and authority boundaries

Some changes are not eligible for a graceful outgoing animation. Sign-out,
password recovery, authenticated-user replacement, active membership or
institution changes, permission loss, and access blocking are authority
boundaries.

At an authority boundary:

1. Stop and dispose screen-specific motion.
2. Remove previously scoped names, rosters, metrics, and drafts from the
   painted and semantic trees synchronously.
3. Let existing router redirects choose the safe destination.
4. Animate only the safe destination background or placeholder, if full motion
   is enabled.

Never hero-morph or crossfade tenant-scoped content across a user, institution,
membership, or role switch. Never retain sensitive widget snapshots solely to
finish an exit transition. Existing redirect rules remain unchanged and are
never delayed to complete an animation.

## Interaction recipes

### Buttons and focal cards

For a reusable premium pressable:

1. Pointer down: visual child scales from `1.0` to `0.975` over `instant` using
   `accelerate`; border or glow opacity may increase by no more than 12%.
2. Pointer up inside: dispatch the action immediately and return to `1.0`
   using `spring`.
3. Pointer cancel or drag outside: return using `softSpring` with no haptic and
   no action.
4. Disabled: no compression, glow, or haptic.
5. Keyboard activation: show focus/pressed color feedback without requiring a
   scale transform.

Only focal action cards may use a clipped touch-following light. Update its
position through a narrow `ValueNotifier`/paint path, not a full-page
`setState`. Remove it on cancel, route loss, reduced motion, or lifecycle
pause.

Ordinary list tiles, text buttons, and every roster row do not need custom
spring wrappers. Material ink, focus, and selected states remain valid.

### State changes

- Button label to progress: 140 ms crossfade, with constant button dimensions.
- Badge icon and label: 140 ms crossfade; semantic label changes immediately.
- Error insertion: 220 ms opacity plus restrained size reveal; never shake a
  form or screen.
- Success: at most one 450 ms border/light sweep on the affected surface.
- Disabled/enabled: color transition no longer than 140 ms; enabled state
  changes immediately.
- Numeric data: initially render the authoritative value. On a later
  authoritative update, interpolate only the visual indicator from its
  previous value; expose the final semantic value immediately.

Animations must be keyed to stable identity and changed values. A Riverpod
rebuild with the same state must not replay a reveal, haptic, or celebration.

## Navigation motion

Retain every existing route, redirect, permission check, and shell
destination. Centralize the visual transition through a reusable GoRouter
`CustomTransitionPage` or equivalent page factory. Do not duplicate transition
builders in each route.

| Navigation relationship | Current examples | Full motion | Reduced |
|---|---|---|---|
| Session resolution | Splash to sign-in/onboarding/home | 220 ms fade-through; no artificial hold | immediate replace |
| Shell peers | Home, Academics, Profile | 220 ms fade-through, no horizontal push | immediate replace |
| Parent to child | Sign-in to forgot password | 320 ms shared axis, max 16 px | immediate replace |
| Child to parent | Forgot password to sign-in | inverse shared axis | immediate replace |
| Setup progression | Profile, invitation, access selection states | 320 ms shared axis in logical reading direction | immediate replace |
| Dialog | Discard attendance draft | Material depth fade/scale, 220 ms | immediate open/close |
| Future entity detail | Event, class, opportunity detail | hero only for the same stable entity | fade/replace |
| Authority redirect | sign-out, role/tenant/permission change | old scoped content removed immediately | immediate replace |

Fade-through is preferable to generic platform left/right transitions for
bottom-navigation peers because they occupy the same hierarchy level.

Navigation rules:

- Selecting the already active destination performs no route call, animation,
  or haptic.
- Rapid destination changes cancel the outgoing transition and continue toward
  the latest destination.
- The bottom bar/rail selection responds immediately; page content may finish
  its transition afterward.
- Crossing the 720-pixel responsive breakpoint may crossfade the navigation
  chrome over 140 ms, but must preserve the destination and page scroll state.
- Route motion never blocks Android back, predictive back where supported,
  keyboard dismissal, or screen-reader focus.
- The destination page heading is the only active heading in semantics during
  transition.

## Authentication and onboarding

### Splash and session restoration

The splash represents `SessionStatus.unknown`; it is not a cinematic gate.
Session restoration decides when it ends.

- The future Campus Flow startup sequence may run while restoration is
  unresolved, with a target visual length of 1.5 to 2.2 seconds.
- If restoration resolves earlier for a returning user, transition promptly.
  Never add a minimum-delay timer.
- If restoration takes longer, continue a lightweight 1600 ms loop and expose
  the existing "Restoring your session" semantics.
- Full motion may draw a violet point into one or two converging strands.
  Reduced motion displays the final static mark and loading label.
- Pause the painter when the app is not active.

### Sign-in and password flows

- Reveal the authentication card as one surface over 320 ms; do not stagger
  individual fields.
- Keep keyboard and `viewInsets` layout changes native. Ambient/header motion
  must not fight the keyboard animation or move the focused field.
- Password visibility icon swaps over 80 ms. The field value and obscure state
  change immediately.
- Validation errors appear without shake. Focus and semantics identify the
  invalid field.
- Sign-in and password-update buttons crossfade to their 20-pixel progress
  indicator over 140 ms without changing size.
- Sign-in success uses a restrained 320 ms depth/fade into Home only after the
  authenticated session is authoritative.
- Sign-in error uses the existing safe error text and no haptic.
- Forgot-password form to "Check your email" uses a 220 ms fade-through within
  the card. Do not imply whether an account exists.
- Password fields and user-entered values never participate in hero
  transitions.

### Onboarding and access selection

- Progress between profile completion, invitation acceptance, access
  selection, and the authenticated shell using shared-axis motion.
- Access cards compress only if promoted to the reusable focal pressable;
  their tap continues to call the existing `selectAccess` method once.
- Completing a profile or invitation may use one 450 ms spectral confirmation
  after the server-backed action succeeds. It must not delay the session
  transition.
- Canceling invitation acceptance uses the inverse shared axis and no
  celebration.
- An access-blocked screen is calm and static. "Try again" may show ordinary
  progress; never pulse the entire error surface.

## Application shell

### Navigation bar and rail

- Move the selected indicator between destinations over 220 ms with
  `decelerate`.
- Crossfade or subtly translate the selected label by at most 4 pixels over
  140 ms.
- Scale the selected icon no higher than `1.06`; do not bounce.
- Use the same state model for `NavigationBar` and `NavigationRail`.
- When destinations change because permissions change, remove an unauthorized
  item immediately. Animate the remaining indicator only if the active
  authority remains valid.
- The offline `MaterialBanner` enters/exits with a 220 ms fade/size transition,
  announces the changed network state once, and never pulses.

### Theme changes

Light, dark, and system theme changes may use a 320 ms theme interpolation with
the standard curve. Reduced motion applies the new theme immediately. Theme
motion must not animate large blur radii or restart every ambient controller;
ambient colors may converge to the new palette using the same shared phase.

## Home motion

The current Home screen has a large sliver app bar, identity status, role-aware
copy, and cards linking to Academics. The first premium redesign should keep
that behavior and use:

- Native sliver collapse as the primary scroll motion. Greeting and large
  visual header settle into a compact title without a second independent
  scroll controller.
- Header parallax of at most 6 pixels and only while the header is visible.
- One ambient controller shared by all header glow layers; 12- and 20-second
  phases may be derived from that controller.
- Home action cards use the focal press recipe only when they are visually
  promoted. The route transition remains the shell fade-through.
- A future next-class card may expose a clipped touch light. It must not
  continuously animate every card in the list.
- Attendance indicators render their real value on first paint. Later
  authoritative changes may animate the arc/line over 450 ms.
- Timeline illumination may fade between current/next states over 220 ms. It
  does not slide or reorder schedule entries unless the actual data order
  changes.
- A one-time greeting or section reveal is allowed on first entry to Home, not
  on every Riverpod refresh or return from Academics.

When Home is covered by another shell route, its ambient and header tickers
stop. Scroll position and authoritative content remain intact.

## Academics motion

### Dashboard and refresh

- Loading, data, empty, and error states use a 220 ms fade-through keyed by
  state kind. Refresh keeps existing content visible until the controller
  exposes its explicit loading state; the motion layer must not invent stale
  data.
- A branded pull-to-refresh indicator may replace the generic spinner. Its
  displacement follows the user's drag directly, then settles with
  `softSpring`. The network refresh begins at the existing threshold and is
  not coupled to the settle animation.
- A skeleton shimmer, if introduced, uses one 1600 ms controller for the page,
  a low-contrast spectral sweep, and no more than two cycles before settling
  to a static skeleton during a long wait.
- Student schedule cards appear as a group. Do not stagger an entire schedule.
- Attendance summary cards reveal at their final value. Subsequent confirmed
  percentage changes may interpolate over 450 ms.
- "Back to today" and historical-date transitions use a 220 ms content
  fade-through. They do not imply a horizontal calendar that is not present.
- Recovery cards and historical server checks never animate into a submitted
  state unless exact server confirmation has been received.

### Faculty class expansion

The current `ExpansionTile` is the correct semantic container and may remain.
Centralize its expansion duration at 320 ms with `softSpring` behavior or the
nearest supported expansion animation style.

- Expand from the header anchor; roster rows appear as one clipped body.
- Do not stagger student names or instantiate a controller per roster row.
- The chevron rotates with expansion. The card itself does not bounce.
- Collapsing a class during submission must not cancel, retry, or hide the
  authoritative operation state.
- A rebuilt class with the same timetable-entry identity retains its expansion
  state where the existing widget lifecycle allows.

### Attendance marking

The current control is a `DropdownButton<AttendanceStatus>`. Motion must work
with it now and with a future segmented P/A/L/E control:

- A selected status updates immediately, then crossfades its label/status
  accent over 140 ms.
- Give one selection haptic for an actual value change, never for reopening the
  menu or reselecting the same value.
- Marking does not reorder, bounce, or flash the roster row.
- Dirty, saved, pending confirmation, needs review, and submitted badges use
  the same 140 ms state change while retaining explicit text and icon.
- "Saved on this device" remains visually and semantically distinct from
  "Submitted".

### Secure draft save

1. Press feedback occurs immediately.
2. The existing encrypted save runs once.
3. On successful persistence, the draft badge changes to "saved on this
   device", the existing snackbar appears, and a light haptic may fire once.
4. On failure, show the existing safe error message without success motion or
   haptic.

Never animate the save action as a server submission.

### Attendance submission

1. On tap, apply normal press feedback and dispatch the existing submission
   controller once.
2. Crossfade the fixed-size button content to its progress indicator over
   140 ms. Disable relevant controls immediately.
3. Do not animate roster marks toward a submitted style while the request is
   in flight.
4. Only after exact server confirmation, crossfade the badge to "Submitted",
   run one restrained 450 ms spectral edge sweep, announce "Attendance
   submitted", and issue one success haptic.
5. For a rejected or definite failure, show the inline error over 220 ms with
   no shake and no success haptic.
6. For `submissionUncertain`, transition once to the explicit pending
   confirmation badge. Do not pulse it, retry automatically, or celebrate.
7. For `needsReview`, transition once to the danger status while retaining the
   explanatory text and review controls.

Rapid taps must not create multiple visual successes or calls. The existing
submission mutex/idempotency behavior remains the source of truth.

### Offline and recovery behavior

- Connectivity changes may animate the shell banner and affected labels once.
- Reconnect never starts a submission, spinner, celebration, or haptic.
- "Retry exact submission" animates only after a deliberate tap.
- Opening a saved historical draft uses content fade-through; past dates remain
  read-only for new submissions.
- Discard confirmation uses the dialog motion. A stronger warning haptic may
  occur on the confirmed destructive tap, before dispatch; the snackbar or
  remaining draft state is still the completion signal.

## Haptics and sound

Centralize haptics behind a small presentation helper using Flutter
`HapticFeedback`. It must be a no-op on unsupported platforms and must never
gate the action it accompanies.

| Event | Feedback |
|---|---|
| Select a different navigation destination | `selectionClick` |
| Change an attendance status | `selectionClick` |
| Persist an encrypted local draft successfully | `lightImpact` |
| Confirm exact server attendance submission | `mediumImpact` |
| Confirm destructive draft discard | `heavyImpact` at dispatch |
| Ordinary button, scroll, expansion, refresh | none |
| Validation, connectivity, timeout, server error | none |
| Automatic session or data transition | none |

Fire feedback once per semantic event, not once per rebuild. Haptics augment
visible and semantic feedback; they never indicate an outcome by themselves.

Do not call `SystemSound.play` and do not add bundled UI audio. CampusConnect
must remain appropriate in classrooms. Operating-system accessibility
feedback remains untouched.

## Pause, visibility, and lifecycle rules

Continuous motion is allowed only while it can be seen:

- Use `AppLifecycleListener` or the equivalent binding observer to stop
  controllers when the application becomes inactive, hidden, paused, or
  detached.
- Resume only after the application is active and the owning route is current.
- Use route visibility (`ModalRoute.isCurrent` or a centralized
  `RouteObserver`) for top-level screens.
- Wrap inactive route/effect subtrees in `TickerMode(enabled: false)`.
  `Offstage` alone does not stop tickers.
- Stop a collapsed ambient header when its painted region is no longer
  visible. Do not add a visibility package solely for static list cards.
- Preserve the normalized ambient phase while paused and resume from that
  phase without simulating elapsed hidden time.
- Cancel pointer-following highlights on pointer cancel, route loss, app pause,
  or widget disposal.
- Dispose every screen-owned `AnimationController`; no controller lives in a
  global singleton.
- Reduced-motion and low-quality modes create no dormant repeating controller.

Ambient layers on one route share one controller. There are no continuous
controllers per card, roster row, navigation item, skeleton line, or status
badge.

## Performance limits

Motion is accepted only when it remains smooth on the Galaxy A35 reference
device in profile mode.

### Frame and duration budgets

- Meet the 16.67 ms frame budget at 60 Hz; naturally target 8.33 ms at 120 Hz.
- After shader warm-up, the 95th-percentile build plus raster work for the
  tested interaction stays within the active display's frame budget.
- No interaction frame may exceed twice the 60 Hz budget without a recorded,
  investigated reason.
- Direct interaction completes within 450 ms. No navigation or confirmation
  waits for ambient motion.
- First useful content and input readiness are never delayed for animation.

### Rendering limits

- At most one repeating ambient controller on a visible route.
- No full-screen `BackdropFilter` or full-screen continuously repainting blur.
- Put procedural ambient painting behind a `RepaintBoundary`; keep foreground
  lists and text outside that repaint boundary.
- A custom painter implements precise `shouldRepaint` checks and reuses paths,
  gradients, and immutable geometry where practical.
- Do not allocate collections, decode images, read providers, or perform
  database/network work in a per-frame callback.
- Avoid animating layout for large lists. Prefer transform, opacity, and
  bounded clip animation.
- Do not wrap every row in `Opacity`, `ShaderMask`, `BackdropFilter`, or
  `saveLayer` effects.
- Warm any required shader through a representative profile/release run before
  accepting a route transition.
- Use `const` children and narrow repaint/rebuild boundaries. A moving glow
  must not rebuild the dashboard.

An animation package requires a demonstrated capability gap, size/performance
review, accessibility review, and tests. The first motion layer uses Flutter
SDK primitives.

## Testing contract

### Token and policy tests

- Assert every named duration and curve is stable.
- Assert reduced policy disables spatial, spring, parallax, hero, and ambient
  motion.
- Assert reduced visibility feedback is no longer than 80 ms.
- Assert a full profile cannot accidentally resolve when platform
  `disableAnimations` is true.

### Widget tests

- Test every transition in both full and reduced profiles.
- Use explicit `pump` intervals at start, midpoint, and completion. Do not use
  `pumpAndSettle` around an enabled ambient loop.
- Verify press cancel returns to the resting transform and dispatches no
  action.
- Verify disabled controls do not animate or emit haptics.
- Verify a repeated Riverpod state/rebuild does not replay a reveal,
  celebration, or haptic.
- Verify outgoing `AnimatedSwitcher` content is excluded from semantics.
- Verify focus order, page heading, status labels, and live regions during and
  after a transition.
- Mock the platform haptic channel and assert the documented event fires
  exactly once.

### Routing and authority tests

Keep all existing router redirect tests, then add:

- shell peer transitions preserve the active destination;
- selecting the active destination is a no-op;
- rapid destination changes finish on the latest route;
- reduced motion replaces routes without spatial travel;
- sign-out during an animation removes the previous user's visible and
  semantic content on the next frame;
- role, institution, membership, or permission change never crossfades stale
  scoped content;
- Android back works during an interrupted transition.

### Attendance safety tests

- Status selection emits at most one selection haptic and does not submit.
- Draft-save motion starts only after secure persistence succeeds.
- Submission progress does not display "Submitted".
- Exact server confirmation produces one submitted transition and one success
  haptic.
- Definite failure, uncertainty, and needs-review states produce no success
  motion.
- Double-tap still invokes one operation.
- Reconnect produces no submit call, progress transition, or haptic.
- Collapsing or navigating away does not cancel or duplicate an in-flight
  operation.

### Golden tests

Golden tests use a deterministic motion harness:

- fixed viewport, device pixel ratio, text scale, brightness, locale, and font;
- fixed ambient phase rather than a repeating ticker;
- reduced motion for static component goldens;
- separately captured full-motion keyframes at 0%, 50%, and 100% for the small
  number of components whose motion is itself under review;
- light and dark coverage for navigation, authentication, Home, Student
  Academics, and Faculty attendance states.

### Performance tests

Profile, not debug, builds on the reference device:

1. cold session restoration into sign-in and authenticated Home;
2. five rapid shell destination changes;
3. Home header collapse and a long scroll;
4. Academics pull-to-refresh and state swap;
5. faculty class expansion with a representative roster;
6. repeated attendance status changes;
7. submit progress to exact confirmation;
8. background/resume with ambient motion.

Record `FrameTiming`, raster jank, UI-thread jank, memory growth, and whether
tickers stop off-route and in the background. Reject or simplify an effect that
cannot meet the frame budget.

## Implementation order

1. Add centralized tokens, spring descriptions, reduced policy, and tests.
2. Apply theme animation and reusable route transition pages without changing
   redirect logic.
3. Add reusable press/state-switch helpers and haptic wrapper.
4. Migrate shell navigation and offline banner.
5. Migrate splash, sign-in, password, onboarding, and access-blocked states.
6. Add Home header/card motion with lifecycle pause behavior.
7. Migrate Academics async states, refresh, summary, and class expansion.
8. Add attendance status, save, submit, uncertainty, review, and discard
   feedback.
9. Profile on Galaxy A35, test reduced motion and large text, then remove or
   simplify any failing effect.

Each step is independently reviewable. No step requires a backend migration,
new permission, data-model change, fake data, or modification to the existing
attendance state machine.

## Definition of done

The Purple Universe motion layer is complete for a migrated screen only when:

- it uses centralized tokens and no ad hoc durations;
- full and reduced profiles are both intentional;
- auth and tenant boundaries remove stale content immediately;
- motion never controls a business operation;
- all interaction outcomes remain explicit in text, icon, semantics, and
  state;
- off-route and background tickers stop;
- widget, routing, attendance-safety, semantics, and golden tests pass;
- profile-mode measurements meet the frame budget on the reference device;
- no sound effect, unbounded loop, per-row controller, or unnecessary
  dependency was introduced.
