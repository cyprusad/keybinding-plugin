# Changelog

## Unreleased

- Added `guideDoubleTapEnabled`, a trigger that opens a guide only after its
  key is tapped once. A plain hold stays silent, so the guide never appears
  during the holds that using a shortcut involves.

  It joins the delay on one **Activation** control rather than arriving as a
  second setting beside it. The two are answers to the same question -- how
  much intent a guide should ask for before it covers the screen -- and as
  independent settings they would stack into a tap-then-hold nobody wants.
  Selecting the tap zeroes the delay, so the press after the tap opens the
  guide at once. The panel's DELAY section becomes ACTIVATION, with Double
  tap added between the delays and Off.

- Fixed the panel's **Off** delay choice, which wrote `-1` but read it back as
  `0` and silently selected Instant instead. `-1` is the sentinel the delay
  normalizer itself returns, so it now survives a round trip through the config.

## 0.1.2 — 2026-09-03

- Fixed fresh-install setup failing with `unsafe-state-directory` after the
  catalog generator created its output directory with permissions inherited
  from the user's umask.
- The generator now creates or repairs its user-owned state directory as
  `0700`, keeps catalog files at `0600`, and rejects symlinked or foreign-owned
  output directories.

## 0.1.1 — 2026-08-31

- Fixed fresh-install catalog generation hanging when `xkbcli` inherited
  Quickshell's permanently open stdin pipe.
- Added a regression test that models the service pipe boundary and a bounded
  timeout for non-interactive catalog discovery commands.

## 0.1.0 — 2026-08-30

- Added a local visual guide for registered `SUPER`, `SHIFT`, `CTRL`, and
  `ALT` keyboard shortcuts on the focused monitor.
- Added configurable guide roots, hold delay, fullscreen behavior, hover
  expansion, keyboard-friendly guide interaction, and focused-monitor routing.
- Added consent-led Hyprland integration with exact diff preview, safe
  symlink/Git target handling, atomic replacement, rollback, and a manual
  fallback.
- Added lock-screen and Omarchy Polkit-dialog guide suppression.
- Added security-oriented bridge comments, privacy documentation, hardening,
  release-gate checks, and troubleshooting guidance.
- Kept the release focused on the visual guide: Omakeez does not store
  shortcut-use history or ship an unused full-screen browser.

Known limitations:

- The guide identifies configured binding candidates; it does not prove a
  later Hyprland dispatcher completed successfully.
- App-owned credential prompts such as 1Password are outside the Omarchy
  lock/Polkit suppression boundary. Typed content is never stored or emitted.
