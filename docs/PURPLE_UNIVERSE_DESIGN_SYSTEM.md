# CampusConnect Purple Universe design system

## Purpose

Purple Universe is CampusConnect's original visual language: calm futuristic
intelligence for a campus operating system. It combines midnight depth,
selective spectral light, tactile surfaces, and clear information hierarchy
without weakening the existing authorization, attendance, or offline-state
contracts.

The system must feel distinctive on first use and remain comfortable after
months of daily use. Visual drama belongs at entry points, top-level heroes,
selected navigation, and moments of confirmation. Dense forms, rosters, error
recovery, and long reading surfaces favor clarity.

## Principles

1. **Authority remains visible.** Local, pending, needs-review, offline, and
   server-confirmed states always use explicit language and icons.
2. **Light creates hierarchy.** Violet and cyan identify focus and energy; they
   are not body-text colors or decoration on every surface.
3. **One signature, many quiet screens.** Campus Flow is the recognizable
   motif. Supporting screens should not invent competing visual effects.
4. **Solid first, glass second.** Most content sits on stable opaque or nearly
   opaque surfaces. Glass is reserved for navigation, floating controls, and
   selected hero layers.
5. **Motion has a reason.** Motion explains state, hierarchy, navigation, or
   spatial continuity and always has a reduced-motion equivalent.
6. **Real content shapes the layout.** Components support actual long names,
   schedules, roles, errors, offline states, and text scaling.
7. **Premium is measured.** Effects that miss the performance budget are
   simplified or removed.

## Integration with the current architecture

The existing `lib/core/theme` boundary remains the migration anchor. The P1
foundation is now implemented there without bypassing current feature
architecture.

Implemented foundation and planned component structure:

```text
lib/core/theme/
  app_tokens.dart                 implemented compatibility exports
  app_theme.dart                  implemented ThemeData composition
  purple_universe/
    cc_colors.dart                implemented
    cc_gradients.dart             implemented
    cc_spacing.dart               implemented
    cc_radius.dart                implemented
    cc_typography.dart            implemented
    cc_motion.dart                implemented
    cc_elevation.dart             implemented
    cc_theme_extension.dart       implemented

lib/core/widgets/
  purple_universe/
    cc_scaffold.dart              planned
    cc_surface.dart               planned
    cc_button.dart                planned
    cc_navigation.dart            planned
    cc_feedback.dart              planned
    cc_data_display.dart          planned
    cc_ambient_background.dart    planned
```

Existing `AppSpacing`, `AppRadius`, and shared state widgets remain supported
during migration. New features consume semantic `Cc*` tokens. Compatibility
aliases are removed only after every production screen and test has migrated.
P1 also installs typed semantic status roles and accessible Material component
defaults. It does not yet implement ambient rendering, custom glass/spectral
components, gallery migration, or redesigned production screens.

## Color foundations

### Dark scheme

| Token | Value | Intended use |
|---|---:|---|
| `voidDark` | `#05030B` | deepest canvas and system-edge continuity |
| `spaceBlack` | `#080611` | default app background |
| `deepNight` | `#0D0920` | quiet section background |
| `midnightPurple` | `#120B2D` | hero depth and elevated backdrop |
| `nebulaSurface` | `#17102F` | standard content surface |
| `raisedSurface` | `#1D153A` | raised cards and controls |
| `electricPurple` | `#8B5CF6` | primary action and selected state |
| `ultraViolet` | `#7C3AED` | primary depth and gradient anchor |
| `hyperViolet` | `#9333EA` | restrained luminous accent |
| `royalBlue` | `#315CFF` | informational energy |
| `electricBlue` | `#1E7BFF` | link/info focus |
| `neonCyan` | `#36E4FF` | tiny highlight, current/next marker |
| `spectralPink` | `#F252FF` | rare celebration or spectral edge |
| `nebulaPink` | `#D946EF` | rare gradient transition |
| `softLavender` | `#C7B8FF` | emphasized text/icon on dark |
| `starWhite` | `#F8F7FF` | primary text |
| `moonWhite` | `#EAE7F5` | strong secondary text |
| `secondaryText` | `#B5AEC9` | normal secondary text |
| `mutedText` | `#827A99` | metadata only when contrast passes |

Dark semantic colors use accessible, desaturated values on tinted containers:

| Semantic role | Foreground | Container |
|---|---:|---:|
| success | `#7DE2B8` | `#123B31` |
| warning | `#FFD37A` | `#422F12` |
| danger | `#FF9B91` | `#481E24` |
| info | `#8DC8FF` | `#152E52` |

### Light scheme

Purple Universe Light is pearl and lavender rather than plain white.

| Token | Value | Intended use |
|---|---:|---|
| `pearlCanvas` | `#F7F5FC` | default app background |
| `lavenderMist` | `#F0ECFA` | quiet section background |
| `cloudSurface` | `#FCFAFF` | content surface |
| `raisedPearl` | `#FFFFFF` | selected raised content |
| `paleViolet` | `#E7DEFF` | selected/tonal container |
| `paleBlue` | `#E6F1FF` | informational container |
| `inkIndigo` | `#17102F` | primary text |
| `secondaryInk` | `#4F4765` | secondary text |
| `mutedInk` | `#716982` | metadata |
| `lightPrimary` | `#6D35D7` | primary action |
| `lightLink` | `#165FCC` | links and information |

Theme construction maps these tokens into a complete Material `ColorScheme`.
Features use semantic theme roles or a typed theme extension, never brightness
checks with local color literals.

## Gradient tokens

Gradients are named resources with fixed intent.

| Token | Stops | Use |
|---|---|---|
| `purpleCore` | `#5B21B6 → #7C3AED → #A855F7` | primary CTA, compact focal metric |
| `electricHorizon` | `#243CFF → #6D28D9 → #D946EF` | top-level hero only |
| `cyanViolet` | `#22D3EE → #3B82F6 → #8B5CF6` | next/current state and Campus Flow |
| `deepSpace` | `#05030B → #0F0824 → #160B36` | dark background depth |
| `nebula` | `#090512 → #22104F → #4C1D95 → #1310A1` | sparse splash/auth artwork |
| `pearlHorizon` | `#FCFAFF → #F0ECFA → #E6F1FF` | light-mode hero depth |

Rules:

- A viewport normally has at most one prominent gradient.
- Forms, long lists, body copy, danger controls, and disabled controls remain
  solid.
- Semantic danger/warning never inherits a decorative spectral gradient.
- Gradients must not reduce text contrast; use an opaque scrim when content
  overlays artwork.

## Campus Flow signature

Campus Flow represents people, schedules, and communities moving through one
campus network. It consists of two to four long spectral ribbons with related
control points, not independent generic blobs.

- Hue path: indigo → cobalt → violet → cyan, with magenta used only at a rare
  crossing highlight.
- Shape: broad magnetic arcs and narrow connecting filaments; no logo or
  proprietary-art resemblance.
- Pace: one subtle ambient cycle over 12–20 seconds.
- Depth: a sharp low-opacity core plus one bounded soft halo.
- Placement: splash, authentication hero, compressed dashboard header,
  selected empty states, and the development gallery.
- Exclusions: long roster bodies, every list row, dialogs, keyboard forms, and
  full-screen repainting behind a scrolling list.

The planned painter/shader must accept a stable seed, progress, palette,
quality, and reduced-motion flag. In reduced motion it renders a static,
balanced frame. It is isolated in a `RepaintBoundary`, pauses offscreen, and
never owns business state.

## Ambient background quality

The planned `CcAmbientBackground` composes:

1. an opaque theme canvas;
2. at most three bounded radial glows;
3. an optional Campus Flow layer;
4. optional low-opacity procedural grain that is cached, not animated;
5. readable foreground content.

| Quality | Behavior |
|---|---|
| low | static two-glow background; no blur animation or flowing painter |
| medium | slow translated glows plus low-detail Campus Flow in hero bounds |
| high | medium behavior plus higher-detail ribbon and subtle parallax |

Low is mandatory for reduced motion. Medium is the default until profiling
proves high mode on the target device. Quality changes must not change layout,
meaning, contrast, or available actions.

## Surface and light system

### Surface hierarchy

| Level | Treatment |
|---|---|
| canvas | opaque midnight/pearl foundation |
| section | opaque or 96% surface, no blur |
| card | 94–98% surface, one-pixel tonal border, quiet shadow |
| glass | 72–88% surface, bounded 8–16 sigma blur, inner highlight |
| floating focal | glass/raised surface with one restrained spectral edge |

The planned `CcGlassSurface` is not a default card. It requires a bounded clip
and exposes surface strength, border emphasis, and optional active glow.
Full-screen `BackdropFilter` is prohibited.

Contextual lighting:

- next class: cyan-to-violet edge;
- attendance overview: quiet violet bloom;
- selected navigation: compact spectral aura;
- primary press/focus: short purple energy response;
- warning/danger: semantic container and icon, with only a restrained halo.

## Typography

Start with the platform/system sans stack to avoid network fetching and license
risk. A bundled open font may replace it only with its license committed and
Android/iOS rendering, APK size, and golden baselines reviewed.

| Style | Size | Weight | Line height | Use |
|---|---:|---:|---:|---|
| display | 44 | 700 | 1.08 | rare onboarding statement |
| hero | 34 | 700 | 1.12 | dashboard greeting/metric |
| page title | 28 | 700 | 1.18 | page heading |
| section | 22 | 600 | 1.22 | section heading |
| card title | 17 | 600 | 1.28 | card identity |
| body large | 16 | 400 | 1.50 | primary reading |
| body | 14 | 400 | 1.48 | normal content |
| supporting | 13 | 500 | 1.40 | metadata/support |
| micro | 11 | 600 | 1.35 | short label, never long copy |

Type remains scalable and may wrap. Components do not use fixed text heights.
Large display/hero styles step down on narrow widths and at high text scale.
Neon colors are excluded from paragraphs.

## Spacing, radius, and layout

Spacing follows a four-point base:

`4, 8, 12, 16, 20, 24, 32, 40, 48, 64`.

Default phone page gutters are 16–20; tablet gutters are 24–32. Touch targets
are at least 44 logical pixels, with 48 preferred for primary controls.

Radius:

| Token | Value | Use |
|---|---:|---|
| `compact` | 8 | small chips and inner controls |
| `control` | 12 | fields and buttons |
| `card` | 18 | normal cards |
| `prominent` | 24 | hero cards and sheets |
| `capsule` | 999 | pills and status indicators |

Breakpoints retain the existing navigation-rail threshold as a compatibility
baseline, then validate `compact < 600`, `medium 600–839`, and
`expanded ≥ 840` layouts. Content width remains constrained; tablets should not
stretch phone cards edge to edge.

## Core component contract

The next component slice will introduce:

- `CcScaffold`: theme canvas, ambient quality, safe areas, and foreground slot;
- `CcSurface` / `CcGlassSurface`: controlled hierarchy and bounded effects;
- `CcSpectralCard`: optional focal edge and touch-responsive highlight;
- `CcButton`: primary, tonal, outline, text, destructive, loading, and disabled;
- `CcNavigationBar` / rail: role-derived destinations with animated indicator;
- `CcAttendanceRing`: semantic percentage/status visualization;
- `CcSectionHeader`, `CcStatusBadge`, `CcSkeleton`, `CcEmptyState`,
  `CcErrorState`, and `CcOfflineBanner`.

Every component must:

- consume semantic tokens;
- support dark and light themes;
- remain correct at 200% text scale where practical;
- expose semantics and focus;
- provide loading/disabled states when applicable;
- avoid color-only meaning;
- render a reduced-motion path;
- avoid owning repository or authorization logic.

## Screen composition rules

- **Authentication:** visual hero occupies at most 40% and yields cleanly to
  keyboard/insets; the form remains a stable, mostly opaque surface.
- **Student Home:** one compressible hero, one next-class focal card, then
  attendance and timeline hierarchy backed by actual available data. Missing
  repositories produce honest unavailable/empty states, not invented content.
- **Faculty Home:** operational density over spectacle: next class/action,
  today's classes, submission state, and recovery clarity.
- **Academics/attendance:** class and draft state language remains exact.
  Expandable roster motion cannot delay marking or submission.
- **Profile/onboarding:** campus identity may receive a subtle spectral edge;
  legal, invitation, role, and security actions stay explicit and readable.

Unimplemented Campus, Career, Events, Clubs, Announcements, and Notifications
remain absent from production navigation until their real vertical slices and
authorization exist. The gallery may preview components with clearly labeled
fictional fixtures.

## Gallery and governance

The development-only `/design-system` route becomes the canonical review
surface for:

- dark/light palettes and contrast pairs;
- gradients and Campus Flow quality modes;
- typography and text scaling;
- buttons, fields, cards, glass, navigation, badges, loaders, and feedback;
- online/offline/pending/needs-review/confirmed attendance states;
- reduced motion and narrow/tablet layouts.

Production navigation never exposes the gallery. New token literals require a
design-system change, not a one-off feature override.

## Migration sequence

1. Add token/theme extensions with compatibility aliases. **Implemented and
   locally validated in P1.**
2. Add ambient, surface, button, navigation, feedback, and attendance
   primitives to the gallery.
3. Migrate shell/navigation and loading/error/offline presentation.
4. Migrate authentication without changing session behavior.
5. Build the Student Home showcase only from available authoritative data.
6. Migrate Student and Faculty Academics/attendance states.
7. Migrate profile and remaining implemented identity screens.
8. Finish light mode, performance/accessibility profiling, goldens, and
   physical-device validation.

Each stage is independently formatted, analyzed, tested, committed, and pushed.
