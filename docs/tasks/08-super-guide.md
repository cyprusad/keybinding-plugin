# Task 08 — Instant Super Guide

## Objective

Implement the polished, always-loaded, visual-only Super Guide driven by the production service.

## Depends on

Task 07.

## Required window behavior

1. Create one layer-shell guide window per Quickshell screen.
2. Only the window corresponding to Hyprland’s focused monitor may be visible.
3. Set overlay layer, `ExclusionMode.Ignore`, no keyboard focus, and an empty pointer mask.
4. Position at the top screen edge, offset below a top Omarchy bar using live bar position/size when available.
5. Instantiate windows at service startup; visibility changes must not create a component or process.
6. Use Omarchy `Style`, `Color`, and `Border` values. Do not introduce hard-coded theme colors.
7. Hide on integration disconnect, plugin disable, catalog error, Super release, lock, or detectable credential prompt.
8. Respect `showInFullscreen`; default false.

## Timing

Implement exact settings:

```text
0 ms, 80 ms, 150 ms, 250 ms, disabled
```

At `0`, set visibility during the Super-down event handling turn. At delayed values, restart a single-shot timer. Super release before the timer fires must leave the guide invisible.

When a binding matches, highlight it for 140 ms. If Super has been released, hide after the highlight. If Super remains held, return to the filtered list so another chord may be learned.

## Content and ordering

- Super alone: daily recommendation first, then direct Super bindings, then modifier-lane summaries.
- Additional modifiers: exact canonical modifier match only.
- Maximum 12 binding cards.
- If more exist, render `+N more` without making it clickable.
- Sort recommendation first, never-used next, then description case-insensitively, then opaque ID.
- Until statistics exist, treat every binding as never used and let the service return no recommendation.
- Display key and description; never display dispatcher arguments.

## Accessibility and non-interference

- The guide is not focusable and is excluded from keyboard navigation.
- Pointer events pass through the entire surface.
- Text must elide rather than expand the surface beyond the focused monitor.
- Use sufficient theme-derived contrast and honor Omarchy scale/font settings.

## Tests

- Focus changes between two virtual/test screens.
- Bar top, bottom, side, hidden, and unavailable.
- Every delay option and release-before-delay.
- Exact modifier filtering.
- More than 12 matches.
- Lock/fullscreen suppression.
- Match highlight and repeated chord while Super remains held.
- Assertions that keyboard focus is none and input mask is empty.

## Validation

```sh
qmllint -I "$OMARCHY_PATH/shell" Service.qml SuperGuide.qml
tests/shell/run guide
```

Run the live latency subset and confirm the task 06 p95 budget remains satisfied.

## Acceptance criteria

- The default is immediate display with no interactive input region.
- Fluent chords may finish before a rendered frame without leaving a flash behind.
- The guide follows the focused monitor and never reserves space.
- Existing shortcut behavior remains unchanged.
