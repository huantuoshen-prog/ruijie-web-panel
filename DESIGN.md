---
version: alpha
name: Professional Network Console
description: A restrained, high-clarity design system for the Ruijie web panel, tuned for router-hosted network operations on desktop and mobile.
colors:
  bg-base: "#090B10"
  bg-surface: "#0F131A"
  bg-elevated: "#141A23"
  bg-sidebar: "#0C1118"
  bg-input: "#101722"
  bg-overlay: "rgba(6, 9, 14, 0.78)"
  text-primary: "#F3F6FB"
  text-secondary: "#A7B3C3"
  text-tertiary: "#748195"
  text-inverse: "#08111B"
  border-subtle: "rgba(167, 179, 195, 0.10)"
  border-default: "rgba(167, 179, 195, 0.18)"
  border-strong: "rgba(184, 207, 255, 0.28)"
  border-focus: "#6EA8FF"
  brand-primary: "#6EA8FF"
  brand-light: "#D8E7FF"
  brand-dark: "#3D73D1"
  success: "#38C793"
  warning: "#F2B14A"
  error: "#FF6B7A"
  info: "#7FC3FF"
  bg-code: "#05070B"
  text-code: "#DCE7F7"
  light-bg-base: "#F6F8FB"
  light-bg-surface: "#FFFFFF"
  light-bg-elevated: "#EEF3F9"
  light-bg-sidebar: "#F0F4FA"
  light-bg-input: "#FFFFFF"
  light-bg-overlay: "rgba(238, 243, 249, 0.86)"
  light-text-primary: "#0E1621"
  light-text-secondary: "#5A697D"
  light-text-tertiary: "#66758A"
  light-border-subtle: "rgba(14, 22, 33, 0.08)"
  light-border-default: "rgba(14, 22, 33, 0.14)"
  light-border-strong: "rgba(61, 115, 209, 0.22)"
  light-bg-code: "#F1F5FA"
  light-text-code: "#102033"
  light-brand-primary: "#2E69CC"
  light-brand-light: "#D9E8FF"
  light-brand-dark: "#1D4E9B"
  light-success: "#1E8C63"
  light-warning: "#A96912"
  light-error: "#C14757"
  light-info: "#2A73D9"
typography:
  heading-lg:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 1.375rem
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: -0.03em
  heading-md:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 1.0625rem
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: -0.02em
  body-md:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 0.9375rem
    fontWeight: 400
    lineHeight: 1.65
    letterSpacing: -0.01em
  body-sm:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 0.8125rem
    fontWeight: 400
    lineHeight: 1.55
  label-md:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 0.8125rem
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: 0.02em
  metric-lg:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 2rem
    fontWeight: 600
    lineHeight: 1.05
    letterSpacing: -0.04em
  metric-md:
    fontFamily: "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, PingFang SC, Hiragino Sans GB, Microsoft YaHei, Noto Sans SC, sans-serif"
    fontSize: 1.5rem
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: -0.03em
  code-md:
    fontFamily: "JetBrains Mono, SFMono-Regular, Cascadia Code, Fira Code, ui-monospace, monospace"
    fontSize: 0.8125rem
    fontWeight: 400
    lineHeight: 1.55
rounded:
  xs: 6px
  sm: 10px
  md: 14px
  lg: 18px
  xl: 24px
  2xl: 32px
  full: 9999px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  3xl: 64px
  content-max: 88rem
breakpoints:
  xs: 24rem
  sm: 40rem
  md: 48rem
  lg: 64rem
  xl: 80rem
elevation:
  shadow-sm: "0 8px 24px rgba(3, 7, 13, 0.18)"
  shadow-md: "0 16px 40px rgba(3, 7, 13, 0.24)"
  shadow-lg: "0 28px 72px rgba(3, 7, 13, 0.30)"
  shadow-overlay: "0 36px 96px rgba(2, 6, 12, 0.42)"
  light-shadow-sm: "0 12px 28px rgba(15, 23, 36, 0.08)"
  light-shadow-md: "0 18px 40px rgba(15, 23, 36, 0.12)"
  light-shadow-lg: "0 28px 72px rgba(15, 23, 36, 0.16)"
  light-shadow-overlay: "0 36px 96px rgba(15, 23, 36, 0.18)"
zIndex:
  base: 0
  raised: 10
  sticky: 20
  drawer: 40
  overlay: 50
  modal: 60
  toast: 70
components:
  button-primary:
    backgroundColor: "{colors.brand-primary}"
    textColor: "{colors.text-inverse}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: 12px
  button-secondary:
    backgroundColor: "{colors.bg-surface}"
    textColor: "{colors.text-primary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: 12px
  input-primary:
    backgroundColor: "{colors.bg-input}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: 14px
  metric-display:
    textColor: "{colors.text-primary}"
    typography: "{typography.metric-lg}"
  user-message:
    backgroundColor: "{colors.bg-elevated}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body-md}"
    rounded: "{rounded.lg}"
    padding: 16px
  code-block:
    backgroundColor: "{colors.bg-code}"
    textColor: "{colors.text-code}"
    typography: "{typography.code-md}"
    rounded: "{rounded.lg}"
    padding: 16px
---

## Overview

This project is a network operations console, not a landing page. The target feel is precise, quiet, and premium, with the clarity of a professional control surface rather than the warmth of the workspace mother template.

The primary reference direction is a careful blend of Linear and Vercel:

- Linear influences information density, navigation rhythm, status language, and workmanlike control surfaces.
- Vercel influences surface finish, dark-theme restraint, spacing confidence, and the polish of buttons, inputs, and overlays.

The result should feel advanced without becoming glossy, decorative, or futuristic for its own sake. The interface must look trustworthy on a router, readable at a glance, and calm under operational stress.

## Colors

The default experience uses a deep graphite palette with cool neutral surfaces and a single restrained blue accent.

- Base layers should sit in dark graphite and slate rather than pure black.
- Accent blue is for action, selection, focus, and key system state only.
- Status colors must stay clean and readable; they should not overpower the page.
- Light mode is fully supported, but dark mode is the primary visual identity for this panel.
- Light mode must have its own semantic border, input, code, and state tokens. Do not reuse dark-mode accents blindly on white surfaces.

Background images are secondary personalization. They must never define the product identity, reduce text contrast, or become necessary for the UI to feel complete. If a custom background is enabled, the interface must add enough overlay treatment to preserve clarity.

## Typography

Typography should feel technical and refined rather than editorial or playful.

- Use a modern UI sans for interface text and a dedicated mono stack for logs, timestamps, PID values, URLs, and network diagnostics.
- Major headings should stay compact and confident, not oversized.
- Dense operational data should rely on spacing, grouping, and typographic contrast instead of loud color.
- Core dashboard readings may use the dedicated metric scale so the most important values stand out without drifting into hero typography.
- Mixed Chinese and English text must remain balanced and legible at small sizes.

Avoid display fonts, oversized hero typography, and any treatment that makes the panel feel like marketing material.

## Layout

The panel should follow a clear control-room hierarchy.

- Desktop uses a shell layout with a narrow navigation rail and a wider task workspace.
- Mobile uses a single-column flow with persistent section navigation and a strong top-level summary.
- Responsive shifts should key off the shared breakpoint scale rather than ad hoc media queries.
- Overview must surface the most important state immediately: network status, daemon state, account summary, recent activity, and critical actions.
- Logs belong to their own high-focus workspace rather than being buried in a general dashboard card.
- Settings should separate operational configuration from personalization; background customization stays secondary and may be collapsed by default.

Prefer whitespace and section rhythm over visual separators. When space is limited, reduce chrome before reducing readability.

## Elevation & Depth

Depth should be subtle, cool, and deliberate.

- Use layered surfaces and thin borders before relying on strong shadow.
- Use the shared elevation tokens for panels, drawers, overlays, and modals; do not invent stronger shadows per component.
- Overlays, drawers, and login flows may use soft blur, but only in support of separation and focus.
- Glass-heavy treatments, neon bloom, and ornamental gradients are not allowed.
- Motion should stay short and functional: fade, slide, and state transitions that explain context changes are acceptable; idle flourish is not.

## Shapes

The shape language should feel modern and composed.

- Inputs and cards use medium-to-large rounding for comfort.
- Buttons, tabs, and chips use tighter radii for precision.
- The UI should avoid both sharp industrial rectangles and overly pill-shaped softness.

Rounded shapes should support usability, not become stylistic decoration.

## Components

Components must read as a coherent system built for network management.

- Navigation items should feel compact, crisp, and clearly stateful.
- Status cards should surface one primary metric or state each, with strong label-value contrast.
- Metric cards may use `metric-lg` or `metric-md`, while supporting labels and deltas stay on the regular UI text scale.
- Buttons should clearly differentiate primary, secondary, ghost, and danger intent without relying on color alone.
- Inputs, selects, and toggles should feel dense but breathable, with visible focus states and strong disabled states.
- Log panels should resemble a modern console workspace: filter controls up top, stable scroll region, mono text, readable timestamps, and clear severity tagging.
- Empty states and warnings should feel instructive and calm. Missing backend state, auth expiry, and script absence must use the same visual language as the rest of the panel.
- Login should appear as a first-class product experience, not a browser prompt.

For theming, dark and light mode must share one token system. For responsiveness, mobile should preserve action priority rather than mirroring desktop layout. For personalization, background settings must be visually subordinate to operational settings and safely ignored by default.

## Accessibility

This panel may be used on phones, laptops, and bright operational environments, so contrast needs active attention rather than best-effort assumptions.

- Secondary and tertiary text must be validated against the actual background token they sit on, especially at small sizes.
- New combinations should clear WCAG AA for normal UI text unless they are purely decorative.
- Focus rings must remain visible in both themes and on top of custom backgrounds.
- If a background image or translucent surface lowers contrast, add overlay treatment or fall back to a flatter surface.

## Do's and Don'ts

**Do**

- Use semantic tokens for all durable color, spacing, radius, and state decisions.
- Keep the overall tone closer to a premium internal tool than a consumer app.
- Give logs, status, and controls clear hierarchy through layout and typography first.
- Use the shared breakpoint, elevation, and z-index tokens instead of per-component improvisation.
- Preserve visible `:focus-visible` states on every interactive element.
- Treat desktop and mobile as separate presentations of the same priorities, not the same layout scaled down.
- Write any new durable visual rule back into this file during implementation.

**Don't**

- Introduce purple or blue-purple gradients as a shortcut to "modern" styling.
- Depend on background images, blur, or glow for visual quality.
- Use decorative animation, oversized hero sections, or marketing-page framing.
- Hardcode one-off colors where a semantic token should exist.
- Make the control surface feel noisy, playful, or overly branded.
- Bury core operational actions behind personalization or secondary panels.
