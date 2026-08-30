# UX Polish 02 — Omakeez panel and privacy simplification

Status: implemented for the `0.1.0` release.

## Outcome

Omakeez is a visual, local-first reference for configured shortcuts. It is not
a game, productivity tracker, or shortcut-use analytics product.

The active panel is intentionally compact:

- visual behavior comes first: hold delay, fullscreen behavior, and independent
  `SUPER`/`SHIFT`/`CTRL`/`ALT` guide-root switches;
- the integration section comes last, with a centered **Disable visual guide**
  action;
- onboarding shows a reviewed safety verdict, a concise explanation, an
  optional exact diff/source inspection path, and one primary enable action;
- no usage-history, reset, or catalog-browser controls are exposed; and
- the bar has no activity badge and uses a plain operational tooltip.

The implementation contains no activity persistence and no unused full-screen
browser—not merely hidden UI surfaces.

## Deferred work

- A future security-documentation browser link from the active panel.
- Read-only provider cards for application-local documentation such as Tmux or
  Herdr.
- A custom Omakeez mark, only after a designer supplies a full logo and a
  separately optimized micro-icon. The experimental raster-derived mark was
  rejected and the original keyboard glyph remains in use.
