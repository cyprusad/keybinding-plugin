# Keybind Dojo progress

| Task | Status | Commit | Notes |
|---|---|---|---|
| 01 — Repository and plugin skeleton | Complete | 2ae6a48 | Manifest, loadable entry points, bar/panel lifecycle, smoke harness, and validations pass. |
| 02 — Catalog generator | Complete | 88e1679 | Offline and live read-only validation pass: 228 active bindings, valid Lua, and second run reports `changed:false` with unchanged mtime. |
| 03 — Configuration inspector | Complete | 512367d | Read-only path, symlink, safety, marker, Git, and diff inspection pass in fixtures and live mode. |
| 04 — Transactional patcher | Complete | 1ffa8d8 | Fixture-only transactional enable/disable, hash checks, backups, Lua validation, atomic replacement, and restoration pass. |
| 05 — Lua bridge | Complete | 6bc16ab | Fail-closed bridge, exact protocol matching, modifier state, duplicate-load guard, and mock stress tests pass. |
| 06 — Live feasibility gate | Complete | 75ef370 | Live bridge PASS: 267-match matrix, physical lifecycle/chord checks, p95 1 ms, 0.1600% five-minute Quickshell CPU ceiling, identical bind metadata, and byte-identical cleanup. |
| 07 — Production service | Complete | c4023c6 | Strict catalog/protocol service, async regeneration and bridge inspection, inline settings, lock/polkit state, debounced fullscreen queries, and QML model tests pass. |
| 08 — Instant Super Guide | Complete | dce6e24 | Pre-created per-screen visual guide, focused-monitor routing, delay/suppression behavior, exact filtering, truncation, highlight timing, and guide model tests pass. |
| 09 — Bar widget and onboarding | Complete (manual gate passed) | dd3b60c | Bar status/streak tooltip, consent preview, exact diff/hash boundary, fixture safety tests, settings panel, readable guide layout, and live consent flow pass. Full access to truncated bindings remains Task 12. |
| 10 — Aggregate persistence | Complete | e45f586 | Validated aggregate stats, 90-day local buckets, duplicate-turn suppression, atomic 0600 writes, corruption/reset recovery, five-copy retention, and panel data reset confirmation. Pure and storage fixtures pass; existing Wayland guide QML runner still aborts in this session. |
| 11 — Gamification and recommendations | Complete | c057362 | Deterministic XP/levels/streaks/quests, canonical recommendations, availability filtering, 100-day streak coverage, and real bar/panel progress values. |
| 12 — Full Dojo overlay | Complete (manual gate passed) | f234331 | Full browsing/practice/progress/settings overlay; responsive layout, close affordance, keyboard navigation, search refocus, and menu-surface styling verified manually. |
| 13 — Dotfiles and failure hardening | Complete | c368aaa | Symlink/deployment/marker/permission/dependency matrix, safe state handling, troubleshooting backup listing, and immediate guide disconnect behavior pass. |
| 14 — Integration, privacy, and performance | Complete (manual gate passed) | 98fcd92 | Automated suite and live release evidence pass; manual lock/privacy/reset/focused-monitor checks pass, with the 1Password app prompt documented outside the detection boundary. |
| 15 — Documentation and release | In progress (draft documentation) | — | README, security, troubleshooting, license, and changelog drafted; UX polish and final release smoke test remain. |

## UX polish workstream

| Polish | Status | Commit | Notes |
|---|---|---|---|
| 01 — Super Guide behavior and look | In progress (implementation updated; live UX gate pending) | — | The ranked canopy follows the familiar `SUPER+K` order from the center outward in both primary and secondary rows, resolves physical `code:N` bindings through the active XKB keymap, and uses stepped corner caps that attach to the secondary row plus extended edge wings to expose six additional low-priority shortcuts. The duplicate Copilot menu binding is labeled accurately but excluded from the guide. Shift/Ctrl/Alt discovery is a terse header hint with no footer or counts, active lanes use human-readable chords, and the guide aligns with the top screen edge. Two-line cards, contrast shield, hover expansion, and restrained motion remain. True backdrop blur is deferred because it would require compositor-specific configuration. See `UX_POLISH_01_SUPER_GUIDE.md`. |
| 02 — Bar panel and full Dojo | Deferred | — | To be planned after UX Polish 01 manual gate. |

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
| `c4023c6` | Implement the Task 07 production service and its protocol/catalog test suite. |
| `dce6e24` | Implement the Task 08 instant Super Guide and its focus/filtering test suite. |
| `2171c07` | Implement the Task 09 bar widget, onboarding consent preview, settings panel, and fixture safety tests; pause before live consent. |
| `dd3b60c` | Finish Task 09 presentation fixes and record the live manual consent gate as passed. |
| `e45f586` | Add aggregate usage persistence, recovery storage, reset confirmation, and Task 10 tests. |
| `ce34f8f` | Record Task 10 completion in the progress checklist. |
| `c057362` | Add deterministic gamification, streaks, quests, recommendations, and real progress surfaces. |
| `c368aaa` | Harden integration/recovery paths and add the Task 13 scenario matrix. |
| `2b7fb92` | Implement the full Dojo overlay shell and static smoke test. |
| `1b99c95` | Harden overlay styling, keycap surfaces, and shortcut interception. |
| `59b2d2a` | Clarify the overlay close affordance and Escape guidance. |
| `cd486b4` | Make the close control and Escape keycap visibly explicit; simplify search text. |
| `e0ca7aa` | Make Tab focus navigation wrap and show the active tab target. |
| `833f6ca` | Stabilize overlay keyboard focus and align binding keycaps with menu surfaces. |
| `2a252b3` | Add `/` and `Ctrl+F` keyboard shortcuts to refocus search. |
| `3ebe8f5` | Match binding keycaps to the Practice menu surface. |
| `f234331` | Match binding result rows to the Practice menu background; manual Task 12 gate passed. |
| `b799d8a` | Record Task 12 completion and its full overlay commit trail. |
| `75d6433` | Add the Task 14 all-suite runner and release-gate automation. |
| `03302ac` | Add Task 14 release evidence and the manual-gate checklist. |
| `90bbfd1` | Explain local data storage and privacy in Settings. |
| `0ffc0de` | Record release-gate preflight. |
| `d3f7838` | Record local data inspection. |
| `3d62a9b` | Record tracking round-trip verification. |
| `7efc421` | Record ordinary typing privacy verification. |
| `eb4e95a` | Fix stats writer input closure so aggregate data persists. |
| `fdf297f` | Record aggregate tracking evidence. |
| `f0d72f5` | Capture exact stats release evidence. |
| `73a830f` | Record guide settings verification. |
| `f7fcae5` | Record shell and Hyprland reload recovery. |
| `1863dfd` | Record lock-screen suppression. |
| `e0b5435` | Make local-data reset actionable during pending stats flushes. |
| `4530df8` | Record stats reset and recovery verification. |
| `771db7f` | Add the UX Polish 01 Super Guide behavior and look plan. |
| `6ce5632` | Model ranked, dense Super Guide canopy layouts and readable raw key labels. |
| `77df621` | Render the transparent glass Super Guide canopy. |
| `dc67acd` | Fix deferred production-service timer restarts found during live refresh. |
| `e0d4f01` | Expand Super Guide overflow on pointer hover. |
| `e0d9b52` | Polish canopy expansion motion and record the implementation checkpoint. |
| `815a533` | Add a theme-aware Super Guide contrast gradient and legible two-line cards. |
| `fea4f41` | Mirror Omarchy's `SUPER+K` ordering and resolve physical code bindings through XKB. |
| `81f61ca` | Add wide-screen Super Guide corner caps for two more low-priority bindings. |
| `7b5974a` | Alternate the Super Guide secondary row outward from the overflow pill. |
| `74d5441` | Extend wide-screen guide edge wings for four more visible shortcuts. |
| `969adf9` | Label Omarchy's Copilot key and hide its duplicate menu binding from the guide. |
| `4a7c0eb` | Step Super Guide corner caps inward on the secondary row. |
| `8a8a929` | Attach Super Guide corner caps to the outer secondary-card boundary. |
| `034002d` | Replace opaque modifier counts with plain-language Shift/Ctrl/Alt discovery guidance. |
| `a9df5a4` | Move Shift/Ctrl/Alt discovery to the header and remove the footer. |
| `e56f846` | Render active guide lanes as shortcut chords instead of internal masks. |
