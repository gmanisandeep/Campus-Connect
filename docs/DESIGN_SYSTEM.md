# Design system

## Character

Modern, academic, energetic, trustworthy, and youthful without feeling childish. Material 3 supplies interaction and accessibility behavior; CampusConnect tokens supply the visual voice.

## Tokens

| Token | Value |
|---|---|
| Primary | Indigo `#4F46E5` light / `#8B8CF8` dark |
| Secondary | Cyan `#0891B2` light / `#67E8F9` dark |
| Error | Material semantic error role; never raw red text on color |
| Spacing | 4, 8, 12, 16, 24, 32, 48 |
| Radius | 8 control, 12 card, 20 prominent surface, full pill |
| Touch target | Minimum 44 logical pixels; prefer 48 |
| Motion | 120 ms micro, 200 ms standard, 300 ms emphasized; disable nonessential motion for reduced-motion contexts |

Use scheme roles (`surface`, `onSurface`, `primaryContainer`) instead of hardcoded widget colors. Gradients and glass effects are restrained and never reduce contrast.

## Typography

Use the platform/system sans-serif with Material display/headline/title/body/label roles. Do not disable text scaling. Layouts must survive 200% text and long translated labels without clipping.

## Components

Buttons expose clear hierarchy: filled primary, tonal secondary, outlined alternative, text tertiary. Destructive actions use confirmation only when impact is irreversible/high. Inputs retain labels, helper/error text, keyboard type, autofill hints, and validation. Cards group one coherent task. Status badges always pair color with text/icon.

Async pages use a consistent state frame: skeleton/loading announcement, purposeful empty state, safe error with retry, stale/offline marker, and content. Snackbars acknowledge reversible/low-impact outcomes; dialogs are reserved for high-impact decisions.

## Responsive behavior

Phone layouts use bottom navigation. At 720 logical pixels, navigation rail and wider content constraints become available. Lists remain lists on phones; dense tables use responsive cards or horizontal scrolling with an explicit affordance. Maximum reading width is 1200.

## Accessibility checklist

- WCAG 2.2 AA contrast where applicable; never encode status using color alone.
- Semantic names, roles, values, headings, and live-region announcements.
- Logical focus/reading order and visible keyboard focus.
- 44px minimum targets, large-text QA, reduced-motion support.
- Error summary plus field errors; no disappearing placeholder-only labels.
- Charts provide text summaries and non-color patterns.
