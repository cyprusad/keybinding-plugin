# Keybind Dojo progress

| Task | Status | Commit | Notes |
|---|---|---|---|
| 01 — Repository and plugin skeleton | Complete | 2ae6a48 | Manifest, loadable entry points, bar/panel lifecycle, smoke harness, and validations pass. |
| 02 — Catalog generator | Complete | 88e1679 | Offline and live read-only validation pass: 228 active bindings, valid Lua, and second run reports `changed:false` with unchanged mtime. |
| 03 — Configuration inspector | Complete | 512367d | Read-only path, symlink, safety, marker, Git, and diff inspection pass in fixtures and live mode. |
| 04 — Transactional patcher | Complete | 1ffa8d8 | Fixture-only transactional enable/disable, hash checks, backups, Lua validation, atomic replacement, and restoration pass. |
| 05 — Lua bridge | Complete | 6bc16ab | Fail-closed bridge, exact protocol matching, modifier state, duplicate-load guard, and mock stress tests pass. |
| 06 — Live feasibility gate | Complete | 75ef370 | Live bridge PASS: 267-match matrix, physical lifecycle/chord checks, p95 1 ms, 0.1600% five-minute Quickshell CPU ceiling, identical bind metadata, and byte-identical cleanup. |
| 07 — Production service | Pending | — | |
| 08 — Instant Super Guide | Pending | — | |
| 09 — Bar widget and onboarding | Pending | — | |
| 10 — Aggregate persistence | Pending | — | |
| 11 — Gamification and recommendations | Pending | — | |
| 12 — Full Dojo overlay | Pending | — | |
| 13 — Dotfiles and failure hardening | Pending | — | |
| 14 — Integration, privacy, and performance | Pending | — | |
| 15 — Documentation and release | Pending | — | |

## Commit log

| Commit | Scope |
|---|---|
| `c284cd1` | Add approved engineering plan. |
| `2ae6a48` | Add Task 01 plugin skeleton and shell smoke harness. |
| `88e1679` | Add Task 02 offline catalog generator, fixtures, and tests. |
| `512367d` | Add Task 03 read-only bridge inspector and fixture tests. |
| `1ffa8d8` | Add Task 04 transactional bridge patcher and fixture test. |
| `6bc16ab` | Add Task 05 fail-closed Lua bridge and mock harness. |
| `7dd6bdb` | Correct the live Hyprland keyboard callback signature discovered during Task 06. |
| `07488dc` | Record the first live feasibility failure and safe config restoration. |
| `13e79af` | Load the bridge from the installed plugin path. |
| `25dd38e` | Harden bridge reload behavior and live catalog normalization. |
| `070c9c5` | Add the Task 06 live timing probe and minimal guide surface. |
| `d3dc99a` | Load the feasibility service in the installed Omarchy shell. |
| `af08db5` | Correct the bar widget properties found during live validation. |
| `75ef370` | Record the Task 06 PASS and add the 267-entry live catalog matrix. |
