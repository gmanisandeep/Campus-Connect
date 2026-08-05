# CampusConnect design contract

CampusConnect uses **Campus Native**: a fast, content-first interface that
feels like a daily social utility rather than an institutional dashboard.
Identity is confident but quiet—near-black or soft-neutral foundations, one
clear violet accent, native controls, dense readable lists, and media/content
allowed to lead. The product should feel immediately learnable to people who
already use modern social, music, and messaging apps without copying any one
brand.

The existing `purple_universe` source namespace remains for compatibility. Its
semantic tokens now implement Campus Native; new feature code must consume the
tokens rather than the legacy namespace name.

## Thesis

- The user’s reason for opening the app appears before atmosphere or brand
  theatre.
- Familiar destinations stay at the thumb edge. Filters stay beside the
  content they control. Creation and messaging remain one gesture away.
- Academic authority remains explicit, but it does not make social access feel
  like a locked portal.
- Violet signals CampusConnect ownership and active state. It is not wallpaper.

## Source of truth

- `lib/core/theme/app_theme.dart` composes Material 3 light and dark themes.
- `cc_colors.dart`, `cc_theme_extension.dart`, and `cc_gradients.dart` own all
  semantic color and surface roles.
- `cc_typography.dart`, `cc_spacing.dart`, and `cc_radius.dart` own hierarchy,
  rhythm, and geometry.
- `cc_motion.dart` owns short state transitions. Presentation never delays or
  commits business state.

## Visual grammar

- Dark mode uses near-black canvas, charcoal surfaces, high-contrast text, and
  violet active states. Light mode uses soft neutral canvas and white surfaces.
- Prefer flat surfaces and separators. Use elevation only for modal or raised
  focus; use no scrolling glass, glow, spotlight, or decorative animation.
- Cards group shortcuts or exceptional states. Feeds and conversations are
  edge-to-edge lists with content padding inside the row.
- Use circular avatars for identity, rounded rectangles for grouped utility,
  capsules for buttons and filters, and unframed icons for navigation.
- Headlines are compact and operational. Do not place a marketing hero inside
  an authenticated daily-use screen.

## Shared components

- `CcAmbientBackground` is a neutral foundation. Phone and authenticated quiet
  surfaces are effectively solid; wide authentication may use one faint top
  brand wash.
- `CcSurface` supplies flat base, raised, translucent-solid compatibility, and
  outline variants—never backdrop blur.
- `CcPrimaryButton` and `CcSecondaryButton` use capsule geometry and bounded
  press feedback without glow.
- `CcNavigationBar` sits flush to the bottom screen edge with a divider and
  clear active icon/label. `CcNavigationRail` is the equivalent desktop edge.
- `CcBrandLockup`, `CcIconTile`, `CcSectionHeader`, and `CcInlineMessage` carry
  the same identity and semantic-state rules across roles.

## Screen patterns

- **Authentication:** compact brand, direct form, visible sign-up recovery, and
  no oversized mobile marketing copy. Wide screens may pair the form with a
  restrained product statement.
- **Home:** time-aware greeting and identity, then real “jump back in” shortcuts
  derived from backend configuration and active permissions.
- **Social:** stable top brand/action bar, one-tap feed filters, edge-to-edge
  posts, immediate engagement actions, and bottom navigation.
- **Messages:** requests are separated from accepted conversations. Threads use
  dense avatar rows; conversations use compact directional bubbles and a
  persistent composer.
- **Academics and college console:** calmer dense utility, explicit authority,
  clear state text, and no social decoration.

## Accessibility and adaptation

- Interactive targets are at least 44 logical pixels and preferably 48.
- Support light/dark themes, TalkBack labels, keyboard navigation, logical
  focus order, and 1.0x, 1.3x, and 2.0x text scaling.
- Content may wrap, stack, or scroll; it must never clip or hide an action.
- Normal text contrast is at least 4.5:1; large text and controls are at least
  3:1. Status is never color-only.
- Reduced motion retains identical information with immediate state changes.

## Galaxy A35 performance contract

- Target the 60 Hz frame budget. There is no continuous decorative motion.
- Avoid full-screen blur, nested clips, shader stacks, scroll-linked effects,
  and broad repaint regions.
- Size and decode user media for its rendered bounds; stop hidden video work.
- Unmeasured physical performance remains `unknown`, never an assumed pass.

## Non-negotiable anti-patterns

- No fake records, counts, destinations, colleges, or recommendations.
- No UI that bypasses authorization, attendance, offline-draft, repository, or
  server-authority contracts.
- No oversized authenticated hero, floating glass dock, spotlight card, neon
  body copy, gradient on every action, or decoration on every surface.
- No unfinished production tab, fixed text height, hidden focus, or unreachable
  action at 200% text.
