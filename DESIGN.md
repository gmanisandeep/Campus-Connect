---
name: CampusConnect
description: A bright, image-led campus social utility with verified academic access.
colors:
  sky-blue: "#498ACA"
  sky-bright: "#69C5F2"
  sky-canvas: "#E9F7FF"
  sky-mist: "#DDF3FF"
  cloud-surface: "#FFFFFF"
  ink-black: "#010304"
  secondary-ink: "#344B5A"
  muted-ink: "#607A8B"
  coral: "#E9577B"
  coral-soft: "#FFE3E8"
  lilac-soft: "#E9E0FF"
typography:
  display:
    fontFamily: "system-ui, sans-serif"
    fontSize: "44px"
    fontWeight: 700
    lineHeight: 1.08
    letterSpacing: "-1.1px"
  headline:
    fontFamily: "system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.18
  title:
    fontFamily: "system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: "system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
rounded:
  compact: "8px"
  control: "16px"
  card: "24px"
  prominent: "30px"
  capsule: "999px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "40px"
  hero: "64px"
components:
  button-primary:
    backgroundColor: "{colors.ink-black}"
    textColor: "{colors.cloud-surface}"
    rounded: "{rounded.capsule}"
    height: "48px"
    padding: "12px 24px"
  card:
    backgroundColor: "{colors.cloud-surface}"
    textColor: "{colors.ink-black}"
    rounded: "{rounded.card}"
    padding: "24px"
  chip-default:
    backgroundColor: "{colors.cloud-surface}"
    textColor: "{colors.ink-black}"
    rounded: "{rounded.capsule}"
    height: "42px"
  chip-selected:
    backgroundColor: "{colors.ink-black}"
    textColor: "{colors.cloud-surface}"
    rounded: "{rounded.capsule}"
    height: "42px"
---

# Design System: CampusConnect

## Overview

**Creative North Star: "Campus Sky"**

Campus Sky is a bright social utility, not an institutional dashboard. A pale
blue atmosphere gives white content surfaces air, while decisive black type and
controls keep everyday actions fast and legible. The supplied reference informs
the openness, floating geometry, compact pills, and circular creation gesture;
its dating content, branding, people, and assets are outside this system.

Social content and people create the visual energy. Academic authority remains
explicit and sober without turning the rest of CampusConnect into a portal.

**Key Characteristics:**

- Light-first sky atmosphere with crisp white surfaces.
- Bold near-black hierarchy with one recognizable blue identity.
- Image-led social cards and a raised circular creation action.
- Truthful access, role, institution, and verification states.

## Colors

The palette combines an open blue field, paper-white content, decisive black,
and rare coral/lilac support accents.

### Primary

- **Campus Sky:** Owns identity, links, active navigation, and the creation orbit.
- **Sky Bright:** Supplies highlights inside the orbit and dark-theme primary states.

### Secondary

- **Warm Coral:** Calls attention to social/community shortcuts without competing
  with the brand blue.
- **Soft Lilac:** Separates academic utility from social utility in icon tiles.

### Neutral

- **Cloud Surface:** Holds cards, navigation trays, filters, and raised controls.
- **Ink Black:** Owns primary text and decisive light-theme actions.
- **Secondary Ink and Muted Ink:** Carry supporting copy and quiet metadata.

**The Blue Ownership Rule.** Blue signals CampusConnect identity or active
state; it is not applied to every surface.

## Typography

**Display Font:** Platform system sans-serif

**Body Font:** Platform system sans-serif

**Character:** Familiar mobile typography with bold editorial hierarchy and
compact labels. No decorative font competes with posts, profiles, or records.

### Hierarchy

- **Display** (700, 44px, 1.08): rare public/authentication statements.
- **Headline** (700, 22–28px, 1.18–1.22): screen and major section titles.
- **Title** (600, 15–20px, 1.25–1.35): cards, rows, names, and modules.
- **Body** (400, 14–16px, 1.48–1.50): post copy, explanations, and records.
- **Label** (600, 11–14px, 1.30–1.35): filters, buttons, status, and metadata.

**The Content Voice Rule.** Strong weight establishes hierarchy; gradients,
outlines, and all-caps decoration never substitute for hierarchy.

## Layout

Phone layouts use 16px horizontal gutters, bottom navigation, and a 4/8/12/16/
24/32/40/64 spacing rhythm. White cards float within the sky canvas rather than
touching every edge. Five-destination navigation elevates the middle creation
action. Wide layouts exchange the bottom tray for a navigation rail, center the
working area, and cap it at 1200px; dense academic views may use that width while
social reading columns remain visually contained by their cards.

## Elevation & Depth

Depth is ambient and blue-tinted. Ordinary light surfaces use one soft shadow
(`0 8px 20px rgba(40,101,137,0.12)`); the creation orbit uses a tighter blue
shadow (`0 7px 18px rgba(30,120,180,0.30)`). Cards do not combine an ordinary
border, tint, and shadow. Full-screen blur, glow stacks, and continuous shader
effects are outside the system.

**The One-Lift Rule.** A normal surface gets one depth device; reserve the
stronger orbit shadow for the central creation action.

## Shapes

Controls use 16px corners, cards use 24px, focal panels use 30px, and filters or
buttons use capsules. Avatars and the central creation action are circular. The
orbit's nested circle is the signature silhouette; it must not spread to every
icon.

## Components

### Buttons

- **Shape:** Capsule, 48px minimum height.
- **Primary:** Black with white text in light mode; the relationship reverses in dark mode.
- **Focus:** Visible boundary/focus state with no glow-heavy animation.

### Chips

- **Style:** Small white capsules with black text and no ordinary border.
- **State:** Selected filters invert to black with white text.

### Cards / Containers

- **Corner Style:** Airy 24px radius; prominent panels may use 30px.
- **Background:** White in light mode, raised navy in dark mode.
- **Shadow Strategy:** One ambient blue-tinted elevation role.
- **Internal Padding:** Usually 16px or 24px.

### Inputs / Fields

- **Style:** Filled semantic surface, 16px corners, and a contrast-safe boundary.
- **Focus:** Blue focus treatment; errors remain explicit text, never color-only.

### Navigation

Mobile navigation is a clean white tray. With exactly five destinations, the
middle creation action becomes a 52px glossy blue orbit with a dark inner core.
Desktop uses a quieter rail and never imitates the phone orbit.

## Do's and Don'ts

### Do:

- **Do** let real people, posts, and campus media supply visual energy.
- **Do** preserve 44px minimum targets, readable contrast, wrapping, and 200% text access.
- **Do** show institution, role, access, and verification only from server authority.
- **Do** keep academic and college-console screens calmer than the social feed.

### Don't:

- **Don't** copy the reference's dating copy, photography, branding, or fake data.
- **Don't** return to purple wallpaper, scrolling glass, neon body text, or gradients everywhere.
- **Don't** invent colleges, counts, recommendations, posts, or verification badges.
- **Don't** let presentation bypass authentication, attendance, repository, or authorization contracts.
