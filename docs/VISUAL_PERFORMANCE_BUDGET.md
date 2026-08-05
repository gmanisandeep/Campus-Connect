# Purple Universe visual performance budget

## Purpose

This document is the admission gate for every CampusConnect Purple Universe
visual. It applies to the ambient background, Campus Flow painter, glass
surfaces, glow, touch light, hero transitions, navigation motion, charts,
loading states, and image-led cards.

The product requirement is a reliable 60 frames per second minimum on the
Galaxy A35, while allowing 90 Hz and 120 Hz devices to present at their native
refresh rate when the active quality mode can meet the corresponding budget.
Visual quality must fall back before interaction quality does.

These are release gates, not aspirations. A metric that was not measured is
`unknown`, not `pass`.

## Audited baseline

At baseline commit `bc7cc51`, the app:

- uses Material 3 themes generated from two seed colors;
- declares no bundled image, font, or shader assets in `pubspec.yaml`;
- contains no `CustomPainter`, `BackdropFilter`, fragment shader,
  `AnimationController`, or perpetual ticker in `lib/`;
- uses the platform font and conventional Material surfaces; and
- already has data-heavy Student and Faculty attendance routes that future
  effects must not make slower.

Existing APKs are useful only as context. The available debug artifact is
198,317,469 bytes and an older release artifact is 54,490,972 bytes, but they
were produced at different times and with different build characteristics.
They are not a valid before/after size comparison. Before the visual work is
merged, rebuild the baseline and candidate from the same Flutter SDK, build
mode, ABI set, Dart defines, and dependency lockfile.

## How the frame budget is interpreted

Flutter's UI/build and raster threads operate as a pipeline. Their durations
must each fit the relevant budget; they must not be added together and compared
with one frame interval.

Collect `FrameTiming.buildDuration` and `FrameTiming.rasterDuration` in a
profile or release build. Exclude a documented warm-up pass from steady-state
statistics, but run the cold-start and first-use shader gate separately.

| Display rate | Vsync interval | UI/build p95 | Raster p95 | p99 for either thread | Frames missing the interval |
|---|---:|---:|---:|---:|---:|
| 60 Hz | 16.67 ms | <= 8.0 ms | <= 10.0 ms | <= 16.67 ms | <= 1.0% |
| 90 Hz | 11.11 ms | <= 5.5 ms | <= 7.0 ms | <= 11.11 ms | <= 1.5% |
| 120 Hz | 8.33 ms | <= 4.0 ms | <= 5.5 ms | <= 8.33 ms | <= 2.0% |

Additional frame gates:

- Zero steady-state frames over 50 ms in each recorded scenario.
- No cluster of three consecutive missed frames after warm-up.
- At least three repeat runs and at least 1,000 scheduled frames per
  steady-state scenario.
- A touch must show its first visual response by the next presented frame.
  End-to-end response to an ordinary tap must remain under 100 ms.
- Scrolling and direct-manipulation content target the display's native rate.
  An intentionally slower ambient animation does not authorize slow scrolling.
- The 60 Hz row is mandatory for the Galaxy A35. The 90 Hz row must be tested
  on hardware that actually exposes 90 Hz; do not claim a Galaxy A35 90 Hz
  result if the device offers only Standard 60 Hz and Adaptive/up-to-120 Hz.
- A high-refresh mode may be enabled only on a device/configuration that meets
  its row. Otherwise the visual engine must downgrade without changing the
  display rate or blocking the UI.

Network latency, Supabase response time, and database work are reported
separately. They must not be used to excuse a blocked UI thread.

## Visual-effect budgets

### Backdrop blur and glass

Blur is the most expensive part of the proposed glass system. Prefer a
translucent, pre-tinted surface with a border and inner highlight. Add a
backdrop blur only when it materially communicates elevation.

| Constraint | High | Medium | Low |
|---|---:|---:|---:|
| Simultaneously visible backdrop groups | 1 | 1 | 0 |
| Total blurred viewport area | <= 25% | <= 15% | 0% |
| Maximum blur sigma | 14 | 8 | 0 |
| Blur inside a scrolling list item | Never | Never | Never |
| Nested or full-screen backdrop filters | Never | Never | Never |

Two disjoint glass regions are allowed only when they share one grouped
backdrop input and still pass the raster budget. A large sheet should use an
opaque or pre-blended surface rather than a full-screen blur. Do not use
`Clip.antiAliasWithSaveLayer`, an animated `ShaderMask`, or an `Opacity` layer
over a large region merely to simulate glass.

The splash is the only route that may temporarily cover the viewport with a
visual effect, and its complete branded sequence must finish within 2.2
seconds. It still has to pass the cold-start frame gate.

### Campus Flow, shaders, and custom painting

- At most one continuously animated custom-paint region may be active on a
  route.
- Its repaint bounds may cover at most 40% of the viewport in High, 25% in
  Medium, and 0% in Low. The Low treatment is a static gradient or image.
- High may draw at most three ribbons and 96 total curve/mesh segments.
  Medium may draw at most two ribbons and 48 segments. These are ceilings,
  not targets.
- Use no more than two paint passes per ribbon in High and one in Medium.
  A soft precomputed gradient is preferable to repeated mask blurs.
- `Paint`, reusable `Path`, gradient inputs, and immutable geometry must be
  cached when their inputs do not change. Painting must not decode images,
  create a fragment program, grow collections, read storage, or perform
  network work.
- `shouldRepaint` must compare the smallest immutable visual state. It must not
  return `true` for unrelated page or repository changes.
- The animated painter and the content above it must be isolated into separate
  repaint regions. The content must not repaint merely because ambient time
  changed.
- One single-pass fragment shader is the maximum on an ordinary route. It must
  be bounded to the visual's region, have no data-dependent unbounded loops,
  and have a gradient/painter fallback.
- A full-screen fragment pass is allowed only for the bounded splash sequence.
  Multi-pass full-screen effects, unbounded particles, animated noise
  textures, and feedback buffers are prohibited.
- Shader compilation and pipeline creation must be exercised on a cold
  profile/release run. A candidate fails if its first visible use produces a
  frame over 100 ms or more than one frame over 50 ms.
- Campus Flow is decorative. Exclude it from semantics and never put required
  information inside the painter.

If any numeric ceiling above still misses the raster target, reduce the effect;
meeting the ceiling is not evidence that the effect is fast.

### Animation lifecycle

- Use time-based animation values, never frame counters, so motion speed does
  not change between 60 Hz and 120 Hz.
- Allow at most one perpetual ambient ticker per visible route. Transient
  interaction controllers may overlap, but a normal tested gesture must not
  leave more than four controllers ticking.
- Dispose every controller. Pause it when its route is covered, its subtree is
  under a disabled `TickerMode`, or the app is inactive, paused, detached, or
  hidden.
- No offscreen list item may own a looping animation. Starting a loop in every
  card, badge, avatar, or skeleton is prohibited.
- Reconnect, repository refresh, and Riverpod rebuilds must not create a second
  controller for the same visual.
- Use `AnimatedBuilder`/transition children and paint-only transforms to keep
  stable subtrees out of the rebuild. Never call `setState` on an entire
  `Scaffold` for an ambient frame.
- Interactive motion uses the centralized 80/140/220/320/450 ms motion
  durations. Ambient loops should normally take 8-24 seconds and must have no
  visible seam.
- Haptics are event-driven and never run from an animation tick or scroll
  listener.
- Gyroscope parallax is off by default. It may ship only after a separate
  battery and motion-accessibility review, and it must stop with reduced
  motion, route invisibility, and app backgrounding.

### Repaint boundaries and overdraw

`RepaintBoundary` is a measured optimization, not a decoration to add around
every component.

- Put a boundary around the independently animated ambient/header region and
  around a proven expensive static child only when DevTools shows that it
  prevents repeated work.
- Do not wrap every list tile. Remove a boundary if raster-cache memory rises
  without reducing repaint work.
- A route begins with one opaque foundation. Above it, allow at most two
  viewport-scale translucent ambient layers and at most three translucent
  layers at any point in the normal content path.
- In Android's GPU overdraw visualization, at least 90% of a representative
  screen must remain at 2x overdraw or less. 3x is limited to small glows and
  card intersections. Persistent 4x overdraw is a failure.
- Avoid an overlapping glow, shadow, gradient, opacity, clip, and blur on the
  same card. Collapse equivalent effects into one painter or pre-blended
  surface.
- Scrolling a list must not repaint a stationary full-screen background.
  Animating the background must not rebuild or repaint list children.
- Review raster-cache images in DevTools after navigation. Cache growth must
  stabilize; abandoned routes must release their layers.

## Resource and artifact budgets

Size gates compare a candidate against a freshly rebuilt non-visual baseline
using identical inputs. Both the absolute and delta gate apply once that
baseline exists.

| Resource | Gate |
|---|---:|
| Universal release APK | Provisional ceiling <= 72 MiB |
| Purple Universe compressed APK delta | <= 6 MiB |
| Per-device AAB estimated download | <= 40 MiB, then ratchet after first measured baseline |
| Purple Universe installed-size delta | <= 12 MiB |
| All bundled raster visuals | <= 4 MiB compressed |
| One routine bundled raster | <= 300 KiB |
| One exceptional hero/splash raster | <= 750 KiB |
| Bundled font files | <= 1.5 MiB compressed total; include only used weights |
| Shader assets | <= 256 KiB total |
| Routine decoded image | <= 12 MiB |
| Exceptional transient decoded image | <= 16 MiB |
| Visible decoded-image working set | <= 48 MiB |
| Flutter image cache | <= 64 MiB unless profiling justifies less |

Image rules:

- Request/decode images close to their rendered physical dimensions. Use
  `cacheWidth`/`cacheHeight` or a resized network variant; do not decode a
  poster at several times its display size.
- The decoded long edge should be no more than 1.25 times the displayed
  physical long edge, except on an explicit zoomable detail view.
- Provide size variants for feed thumbnails and hero images. Do not use the
  original event poster everywhere.
- Prefer an efficiently compressed still asset over GIF, video, or an image
  sequence. Ambient animation must not be delivered as a looping video.
- A repeated grain texture, if retained at all, must be a small seamless tile
  no larger than 128 x 128 pixels and 64 KiB compressed.
- Do not add several font files for visual experimentation. Prefer the current
  platform font or a licensed variable font with only the axes in use.

Measure memory with `dumpsys meminfo` and DevTools from the same profile build:

| State on Galaxy A35 | Absolute PSS gate | Maximum increase from rebuilt baseline |
|---|---:|---:|
| Warm idle on Student Home | <= 220 MiB | <= 35 MiB |
| Steady scroll/animation on the heaviest route | <= 280 MiB | <= 45 MiB |
| Transient peak during navigation/hero | <= 350 MiB | <= 60 MiB |

After a ten-minute dashboard/attendance/navigation loop and return to Student
Home, PSS must return to within 30 MiB or 15% (whichever is smaller) of the
post-warm-up idle value within two minutes. A monotonic increase over three
identical loops is a leak investigation, even if the absolute ceiling is not
yet crossed.

Debug APK size and debug-build memory are recorded for diagnosis but never
used to pass this gate.

## Accessibility is part of the performance budget

Performance fallback must never remove meaning, contrast, focus, or touch
feedback.

- Respect `MediaQuery.disableAnimations`. Reduced motion uses a static Campus
  Flow frame, zero parallax/gyro, no perpetual loops, no large hero movement,
  and no spring overshoot. Essential state changes may use an 80-140 ms
  cross-fade or happen immediately.
- Reduced motion is independent of visual quality: a capable device may keep
  sharp gradients and borders while movement is disabled.
- Test text at 1.0x, 1.3x, and 2.0x using Flutter's `TextScaler`. Do not clamp
  the user's scale. At 2.0x, content may reflow or scroll but must not clip,
  overlap, or hide an action.
- Interactive targets are at least 48 x 48 logical pixels, with at least 8
  logical pixels between adjacent destructive/selection targets where
  practical.
- Normal text contrast is at least 4.5:1; large text is at least 3:1; controls,
  focus indicators, and meaningful graphics are at least 3:1. Measure against
  the lowest-contrast point of an animated gradient, not a hand-picked still.
- Neon colors are accents, not body-copy colors. Glows do not count toward the
  contrast of the underlying foreground.
- No state is encoded by color or animation alone. Attendance, offline draft,
  submission, error, and selection states retain text and semantic labels.
- Decorative painters, grain, and glow are excluded from the semantics tree.
  Meaningful custom charts expose a text summary and semantic values.
- TalkBack order must remain logical while a visual header collapses. Focus
  must not jump when an animation finishes.
- Nothing flashes more than three times per second. The design should contain
  no strobe-like luminance or rapid spectral cycling.
- Disabling motion must reduce CPU/GPU work, not merely set animation opacity
  to zero while tickers continue.

## Quality modes and fallback policy

Quality controls visual complexity only. Business behavior, data, permissions,
offline state, hit targets, and content are identical in all modes.

| Feature | High | Medium (default until qualified) | Low |
|---|---|---|---|
| Campus Flow | Up to 3 ribbons, viewport-bounded | Up to 2 simpler ribbons | Static gradient/frame |
| Ambient update | Native vsync while visible | At most 30 visual updates/s | No ambient ticker |
| Backdrop glass | One bounded grouped blur | Smaller/lower-sigma grouped blur | Opaque pre-tinted surface |
| Glow | Bounded soft edge/bloom | Border and small edge light | Border/color only |
| Parallax | <= 4 logical px, opt-in | Off | Off |
| Touch light | Small clipped highlight | Simplified highlight | Tonal press state |
| Page transitions | Full centralized motion | Shorter/simpler motion | 80-140 ms fade or immediate |
| Skeleton | Lightweight moving highlight | Slower bounded highlight | Static placeholders |

Selection policy:

1. Start unqualified devices in Medium. Enable High only after that
   device-class/renderer combination has evidence for its active refresh rate.
2. `disableAnimations` immediately selects the reduced-motion behavior,
   regardless of quality.
3. App backgrounding, route coverage, or `TickerMode` disablement stops all
   ambient work in every quality mode.
4. If frame timings are monitored in production, use a rolling window of at
   least 120 scheduled frames. Downgrade after more than 5% of frames miss the
   active deadline in three consecutive windows, excluding a documented
   network-only wait.
5. A second three-window breach in Medium selects Low. Do not upgrade again on
   the same route visit. This hysteresis prevents visual oscillation.
6. Battery-saver, low-RAM, and thermal signals may force Medium or Low only if
   the platform exposes a reliable, tested signal. Do not guess from device
   model, battery percentage, or refresh rate.
7. Log only anonymous quality decisions and aggregate timings. Do not attach
   student identifiers, screen content, tokens, or attendance data.

The automatic timing observer itself must be profiled. If it materially
increases frame work, retain the static device qualification plus
accessibility/lifecycle fallback instead.

## Galaxy A35 profiling procedure

### 1. Freeze and record the build

Record:

- Git commit and clean/dirty state;
- Flutter and Dart versions;
- Android build type, ABI, app version, renderer, and all feature flags;
- Galaxy A35 model, Android build fingerprint, available RAM, and display
  mode;
- APK/AAB SHA-256 and byte size; and
- the selected Purple Universe quality and reduced-motion state.

Do not put Supabase keys, access tokens, user data, or raw authenticated API
payloads into logs or evidence.

Debug mode is invalid for performance acceptance. Use profile mode for Flutter
timeline analysis and repeat final frame/startup checks with the release
candidate.

If `adb` and Flutter are not on `PATH`, use the installed SDK executables
directly in PowerShell:

```powershell
$adbPath = Join-Path $env:USERPROFILE '.campusconnect-tools\android-sdk\platform-tools\adb.exe'
$flutterPath = Join-Path $env:USERPROFILE '.campusconnect-tools\flutter\bin\flutter.bat'
& $adbPath devices -l
& $flutterPath devices
```

Launch with the project's existing, non-secret configuration mechanism:

```powershell
& $flutterPath run --profile -d <device-id>
```

Add the required existing Dart defines without printing or committing their
values. Use the DevTools link emitted by Flutter.

### 2. Stabilize the device

- Test on the physical Galaxy A35, not an emulator.
- Disable Battery Saver for the primary run. Test Battery Saver separately as
  a fallback case.
- Set brightness to a fixed value, close screen recording and floating
  overlays, and record whether USB charging is active.
- Let the device cool until it reports no thermal throttling. Record battery
  temperature and thermal status before and after every run.
- Use Samsung **Settings > Display > Motion smoothness** to test Standard
  (60 Hz) and Adaptive/up-to-120 Hz. Reopen the app after changing it.
- Record the actual active display mode from Android diagnostics. Do not assume
  that selecting Adaptive means every frame was presented at 120 Hz.
- Do not force refresh settings with undocumented `adb settings put` commands
  on the user's device. If a controlled override is ever used, record and
  restore the original values.
- Test the 90 Hz row on a separate device or controlled environment that
  actually supports 90 Hz.

Useful read-only captures include:

```powershell
& $adbPath shell dumpsys display
& $adbPath shell dumpsys thermalservice
& $adbPath shell dumpsys battery
& $adbPath shell getprop ro.build.fingerprint
```

### 3. Warm up, then capture

Exercise every route and effect once. Do not record this pass as steady state.
Then perform three captures per refresh-rate/quality combination:

1. In DevTools Performance, record the exact scenario.
2. Export the timeline and frame chart.
3. Record build/raster p50, p95, p99, missed-frame percentage, longest frame,
   and any consecutive misses.
4. Repeat with enhanced widget-build/repaint diagnostics only when diagnosing;
   those overlays add overhead and are not acceptance measurements.
5. Reset and collect Android frame statistics as corroborating evidence:

```powershell
& $adbPath shell dumpsys gfxinfo com.campusconnect.campus_connect reset
```

Run the scenario, then:

```powershell
& $adbPath shell dumpsys gfxinfo com.campusconnect.campus_connect
& $adbPath shell dumpsys meminfo com.campusconnect.campus_connect
```

Use Perfetto or Android GPU tools in a separate diagnostic pass for unexplained
GPU/CPU stalls. Do not combine heavy instrumentation and call the result an
unperturbed acceptance run.

### 4. Required scenarios

Use a dedicated test tenant and representative seeded data; never add fake
records to a production tenant.

| ID | Scenario | Minimum exercise |
|---|---|---|
| C1 | Cold launch | Five force-stop launches; first splash, sign-in/home frame, first Campus Flow use |
| C2 | Student Home ambient idle | 60 seconds with no touch, then 10 complete slow/fast scroll cycles |
| C3 | Navigation | Ten cycles across all available primary destinations |
| C4 | Student attendance | Open summaries/details, scroll all subjects, background/resume |
| C5 | Faculty attendance | Representative 100-row roster; expand, mark rapidly, scroll, save locally, submit once |
| C6 | Offline drafts | Go offline, save encrypted draft, navigate/restart, reconnect; verify no auto-submit |
| C7 | Image feed | Scroll at least 50 mixed announcement/event/opportunity cards with cold and warm image cache |
| C8 | Keyboard and sheets | Sign-in fields, keyboard resize, bottom sheet open/drag/close ten times |
| C9 | Lifecycle | Background/resume ten times and cover/uncover each animated route |
| C10 | Accessibility | Reduced motion, TalkBack, 2.0x text, light/dark themes, and Low quality |

If a scenario's production screen does not exist yet, mark it `not applicable -
not implemented`; it becomes mandatory when that screen enters the checkpoint.
Do not replace it with a visual-only mock and call it passed.

### 5. Cold-start and memory passes

Cold launch is recorded separately from the warmed steady-state runs. Capture
five launches after force-stop and one after process eviction. Report median
and worst time to first useful interactive screen; do not hide a long auth or
network wait inside a splash animation.

For memory, capture:

1. process start;
2. post-warm Student Home idle;
3. the heaviest point in each scenario;
4. after ten minutes alternating Home, Academics, Faculty roster, and image
   feeds; and
5. two minutes after returning to Student Home.

Take a DevTools heap snapshot if PSS grows monotonically. Verify that disposed
routes do not retain animation controllers, decoded images, render layers, or
large paths.

### 6. Overdraw, contrast, and visual inspection

Run Android's GPU overdraw visualization as a separate pass and capture Student
Home, expanded Faculty attendance, a glass sheet, and navigation. Use Flutter's
repaint-rainbow and performance overlays only for diagnosis.

Capture still frames at the lowest-contrast points of every animated gradient.
Measure contrast from the actual rendered colors. Inspect for text shimmer,
banding, clipped bloom, blur leaking beyond bounds, touch-light artifacts, and
layout movement when network images resolve.

Do not screen-record during timing acceptance. Recording changes GPU and
thermal load.

## Pass/fail evidence matrix

Store sanitized evidence under a directory keyed by commit, device, and date.
The exact storage location may be local or CI-managed; secrets and user data
must never be included.

| Gate | Required evidence | Pass condition | Failure response |
|---|---|---|---|
| Provenance | Commit, toolchain, device fingerprint, variant, renderer, artifact hash | Candidate is reproducible and inputs match baseline | Rebuild and rerun |
| 60 Hz frame budget | Three exported timelines for C2-C6 | Entire 60 Hz row and stall rules pass | Optimize; Medium/Low is not allowed to miss 60 Hz |
| 90 Hz support | Three timelines on actual 90 Hz hardware | Entire 90 Hz row passes | Do not claim/enable qualified 90 Hz visual mode |
| 120 Hz support | Three Galaxy A35 Adaptive captures with actual mode evidence | Entire 120 Hz row passes for advertised mode | Downgrade visual quality and rerun |
| Cold shaders/startup | Five C1 traces, first-use effect trace | No frame > 100 ms; at most one > 50 ms; no blank/frozen frame | Pre-warm, simplify, or replace shader |
| Ambient idle | C2 CPU/frame trace with no interaction | No unnecessary content repaint; mode frame budget passes | Reduce update rate/region or make static |
| Blur/glass | Raster trace plus layer/overdraw capture | Blur bounds/sigma ceilings and raster row pass | Replace with pre-tinted opaque surface |
| Scroll/navigation | C2/C3 timelines | Frame row, response, and consecutive-miss gates pass | Reduce layers/rebuild scope |
| Attendance safety path | C4-C6 timeline and functional result | Performance passes and local/submitted states remain distinct | Block visual checkpoint; preserve business flow |
| Memory | Five PSS points and DevTools snapshot if growing | Absolute, delta, peak, and recovery gates pass | Find retention/cache issue; reduce assets |
| APK/assets | Baseline/candidate build report and size analysis | Absolute and delta size gates pass | Remove/compress/split assets |
| Image feed | Cold/warm C7 traces and cache measurement | Frame and decoded working-set gates pass; no layout jump | Resize, predeclare aspect ratio, cap cache |
| Overdraw | GPU-overdraw captures for representative routes | >= 90% at 2x or less; no persistent 4x | Flatten layers/effects |
| Lifecycle | C9 timeline and controller/ticker audit | Zero hidden-route ambient ticks; memory returns | Fix route/app lifecycle ownership |
| Reduced motion | C10 recording and timing trace | No parallax, loops, gyro, or overshoot; essential feedback remains | Block release |
| Large text | 1.0x/1.3x/2.0x screenshots and widget/golden tests | No clipping/overlap/hidden action | Reflow; remove fixed text heights |
| Touch/semantics | Inspector/TalkBack audit | 48 dp targets, logical focus/order, named states | Fix component before reuse |
| Contrast | Measured worst-gradient samples in both themes | 4.5:1 text, 3:1 large/non-text | Change token/scrim; glow is not credit |
| Automatic fallback | Forced timing breach and recovery log | High -> Medium -> Low uses thresholds and does not oscillate | Disable automatic promotion; default lower |
| Thermal repeatability | Before/after thermal and battery captures | No severe throttling; repeat runs stay within budget | Cool device, simplify effect, rerun |

## Checkpoint rule

A Purple Universe checkpoint may be called performance-verified only when:

1. all implemented-screen rows in the evidence matrix pass;
2. 60 Hz on the Galaxy A35 passes in Medium and Low;
3. any High/90/120 claim has its own matching evidence;
4. reduced motion and 2.0x text pass;
5. artifact and memory deltas are measured against a like-for-like baseline;
6. functional Student/Faculty and encrypted-draft tests still pass; and
7. regressions, unavailable hardware, and unimplemented scenarios are reported
   explicitly.

When a visual misses budget, the resolution order is: reduce repaint bounds,
flatten compositing, remove backdrop blur, reduce painter complexity, stop
offscreen animation, resize images, then select a lower quality mode. Raising
the budget is not an optimization.
