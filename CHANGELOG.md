# Changelog

## 0.1.0 — Unreleased

- Added a local Super Guide for the focused workspace and monitor.
- Added catalog browsing, search, practice, progress, and settings views.
- Added one-click consent with exact diff preview, guarded Lua integration,
  backups, validation, rollback, and browse-only fallback.
- Added aggregate-only local usage statistics, XP, streaks, daily quests, and
  reset/recovery storage.
- Added lock-screen and Omarchy credential-surface suppression.
- Added privacy, hardening, release-gate, security, and troubleshooting
  documentation.

Known limitations:

- v1 records observed candidate activations rather than exact dispatcher
  execution.
- Release/submap bindings unavailable on a particular machine are covered by
  fixtures rather than executed destructively.
- Application-owned credential prompts such as 1Password are outside the
  Omarchy lock/Polkit suppression boundary.
