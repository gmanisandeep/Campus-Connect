# CampusConnect design contract

CampusConnect uses **Purple Universe**: a cinematic campus utility built from
deep ink or pearl foundations, one restrained violet-to-cyan light field, and
clear opaque task surfaces. It should feel polished and distinctive without
becoming a marketing mockup. Editorial scale is reserved for a small number of
hero moments; everyday academic work stays calm, legible, and direct.

This file is the short implementation contract. See
[`docs/PURPLE_UNIVERSE_DESIGN_SYSTEM.md`](docs/PURPLE_UNIVERSE_DESIGN_SYSTEM.md),
[`docs/MOTION_SYSTEM.md`](docs/MOTION_SYSTEM.md), and
[`docs/VISUAL_PERFORMANCE_BUDGET.md`](docs/VISUAL_PERFORMANCE_BUDGET.md) for the
complete token, motion, and profiling specifications.

## Source of truth

- `lib/core/theme/app_theme.dart` composes Material 3 light and dark themes.
- `lib/core/theme/purple_universe/cc_colors.dart` and
  `cc_theme_extension.dart` own semantic color and surface roles. Features use
  these roles instead of local brightness checks or color literals.
- `cc_typography.dart` owns the platform-sans type scale. Display styles are
  for heroes; page, section, title, body, supporting, and label styles carry
  application content.
- `cc_spacing.dart` owns the 4-point spacing sequence
  (`4, 8, 12, 16, 20, 24, 32, 40, 48, 64`), while `cc_radius.dart` owns
  compact, control, card, prominent, and capsule radii.
- `cc_motion.dart` owns shared durations and curves. Presentation motion must
  never own, infer, delay, or commit business state.

## Visual grammar

- Use at most one prominent violet/cyan gradient or light field per viewport.
- Put readable content above atmosphere on opaque or strongly pre-tinted
  surfaces. Glass is a restrained navigation or focal treatment, not the
  default card.
- Dark mode is ink, midnight purple, lavender text, and selective spectral
  accents. Light mode is pearl, lavender mist, indigo text, and a soft blue
  horizon, not plain white with purple controls.
- Use cyan, violet, glow, and gradients to express focus and hierarchy. Use
  semantic success, warning, danger, and info roles for state. Never encode
  state with color alone.
- Prefer one clear focal action and progressive hierarchy over grids of equal
  visual weight.

## Core Purple Universe components

Reusable primitives live in `lib/core/widgets/purple_universe/`:

- `CcAmbientBackground` paints the static aurora foundation inside a
  `RepaintBoundary` and excludes it from semantics.
- `CcScaffold` and `CcAuthScaffold` provide safe-area, keyboard-aware, and
  narrow/wide compositions.
- `CcSurface` provides base, raised, glass, and outlined hierarchy.
- `CcPrimaryButton` and `CcSecondaryButton` provide accessible action and
  loading states.
- `CcNavigationBar` and `CcNavigationRail` present the same role-derived
  destinations at phone and expanded widths.
- `CcBrandLockup`, `CcIconTile`, and `CcSectionHeader` establish identity and
  content hierarchy.
- `CcInlineMessage` presents named info, success, warning, and danger feedback.

Compose with these primitives before adding a feature-local visual pattern.
If a pattern is reusable, add it to this vocabulary and the development design
gallery rather than duplicating it across screens.

## Screen patterns

- **Authentication:** an ambient brand hero plus a stable raised form panel.
  The hero compacts for short viewports, large text, and the software keyboard;
  the form remains reachable by scrolling.
- **App shell:** phone layouts use the bottom navigation bar; expanded layouts
  use a rail, extending it only when width and text scale permit. Active campus,
  role, offline state, and permission-derived destinations remain explicit.
- **Home:** one restrained greeting hero followed only by authoritative,
  enabled actions. Student and faculty language changes with the active grant.
- **Academics and profile:** dense work uses quiet surfaces, exact status
  language, and semantic feedback. Identity can carry a focal raised treatment;
  account and security actions stay sober and unmistakable.

## Accessibility and adaptation

- Support light and dark themes, logical focus order, TalkBack labels, and
  keyboard navigation where applicable.
- Interactive targets are at least 44 logical pixels and preferably 48.
- Test at 1.0x, 1.3x, and 2.0x text scale. Content may wrap, stack, or scroll;
  it must not clip, overlap, or hide an action.
- Normal text contrast is at least 4.5:1; large text, controls, focus rings,
  and meaningful graphics are at least 3:1. Glow does not count as contrast.
- Reduced motion uses the same information and hierarchy with static
  atmosphere and immediate or short state transitions.
- Decorative paint, glow, and ribbons are excluded from semantics. Every
  loading, error, offline, draft, pending, and confirmed state has readable
  text and an appropriate icon or semantic label.

## Galaxy A35 performance contract

The Galaxy A35 must sustain the 60 Hz budget defined in the performance
document. Keep the current aurora static by default, bounded to one custom
paint pass, and isolated from content repaint. Prefer pre-tinted translucent
surfaces to backdrop blur; never use large, nested, full-screen, or scrolling
blur. Flatten overlapping shadows, glows, clips, and opacity layers, and stop
offscreen or hidden animation work. Any unmeasured hardware result is
`unknown`, not a pass.

## Non-negotiable anti-patterns

- No fake production features, destinations, records, counts, or campus data.
- No UI that bypasses authorization, attendance, offline-draft, repository,
  or server-authority contracts.
- No unfinished tab or teaser in production navigation; ship a complete,
  permission-backed vertical slice first.
- No feature-local palette, spacing scale, typography system, or competing
  ambient motif.
- No neon body copy, decoration on every card, large backdrop blur, full-screen
  shader stacks, or continuous decorative motion.
- No fixed text heights, color-only state, hidden focus, or action that becomes
  unreachable with the keyboard or 200% text.
