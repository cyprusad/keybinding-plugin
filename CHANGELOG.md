# Changelog

## Unreleased

- Added `guideTopOffset`, which moves the guide down from the top edge of the
  screen so a notch or camera housing does not cover it. The offset band is
  left transparent, so the bar underneath stays readable. The panel offers 24,
  32, 48 and 64 px; the setting accepts 0-320. Defaults to 0, leaving the
  existing appearance unchanged.

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
