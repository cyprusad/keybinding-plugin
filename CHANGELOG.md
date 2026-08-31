# Changelog

## 0.1.1 — 2026-08-31

- Fixed a first-install race that could leave the integration enabled while
  `catalog.json` and `bridge-catalog.lua` were missing.
- Added bounded automatic catalog recovery, explicit reload verification, a
  manual retry action, and accurate incomplete-setup status in the panel and
  bar tooltip.

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
