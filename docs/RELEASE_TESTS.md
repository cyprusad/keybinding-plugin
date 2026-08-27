# Keybind Dojo release-gate evidence

Status: **AUTOMATED PASS; LIVE/MANUAL GATE PENDING**

This document is intentionally updated as the installed-plugin release gate is
run. It must not be marked `PASS` until the live matrix, privacy inspection,
performance measurements, and non-interference comparison are complete.

## Environment

Captured from the development machine on 2026-08-27:

| Item | Value |
|---|---|
| Omarchy | `4.0.1-1` |
| Quickshell | `0.3.1` |
| Plugin commit used for live checks | `e0b5435` |
| Hyprland version/commit | Pending live capture; `hyprctl` was unavailable from the agent shell session. |
| Active XKB layouts | Pending live capture. |
| Monitor count/scales | Pending live capture. |

## Manual progress

- **Step 1 — Preflight: PASS.** User confirmed the plugin is enabled and
  `hyprctl configerrors` is clean.
- **Step 2 — Local data inspection: PASS.** User confirmed the state directory
  is `700`, present data files and lock are `600`, and no unexpected raw-event
  file is present. `stats.json` has not been created yet, which is expected
  before the first persisted tracked observation. The controller `backups`
  directory reports `755`, but remains protected by its parent `700` directory.
- **Step 3 — Tracking round trip: PASS.** User disabled tracking through the
  panel, confirmed browse-only behavior, then re-enabled it through the review
  and consent flow; Hyprland remained error-free and the guide returned.
- **Step 4 — Ordinary typing privacy: PASS.** User entered prose, shell
  metacharacters, and a synthetic password in a disposable text field; no
  content or raw-event file appeared in plugin state.
- **Step 5 — Live guide and aggregate tracking: PASS.** User confirmed the
  guide returned after re-enabling tracking and that a matched shortcut created
  `stats.json` with three tracked opaque binding IDs, total XP `227`, streak
  `1`, and a completed daily quest for `2026-08-27`.
- **Step 6 — Guide settings and fullscreen behavior: PASS.** User verified
  all delay choices and confirmed fullscreen suppression toggles correctly.
- **Step 7 — Shell and Hyprland reload recovery: PASS.** User verified the
  plugin survived an Omarchy shell restart and Hyprland reload with clean
  config errors, normal guide lifecycle, and a usable full overlay.
- **Step 8 — Lock-screen suppression: PASS.** User confirmed the guide stayed
  hidden while the session was locked and returned normally after unlock.
- **Step 9 — Stats reset and recovery: PASS.** User confirmed that clearing
  local data produced a recovery archive for the previous stats and wrote a
  fresh stats file with empty profile data.
- **Step 10 — Focused-monitor routing: PASS.** User verified on a dual-monitor
  setup that the guide appears only on the monitor containing the focused
  workspace/window.

## Automated results

Passed:

- `tests/shell/run all` — all repository cases passed.
- Manifest and entry-point layout checks passed.
- `qmllint` passed for all QML entry points.
- `luac -p bridge.lua` and generated bridge-catalog validation passed.
- Catalog JSON schema and dispatcher-argument exclusion checks passed.
- Static scans passed for network clients, privilege escalation, dynamic
  evaluation, and process/file work in the keyboard callback.
- Fixture mutation containment passed; the all-suite runner verifies that the
  tracked worktree status is unchanged after the run.
- `omarchy plugin validate .` passed.

The service and guide model tests run headlessly with Qt's minimal platform.
This avoids treating the known Qt5/Wayland `qmltestrunner` abort in this
development session as a product failure; the models themselves pass.

## Live functional matrix

| Check | Result | Evidence/notes |
|---|---|---|
| Install and enable from a clean checkout | Passed manually | Plugin enabled; `hyprctl configerrors` clean |
| Browse-only catalog before consent | Passed manually | Browse-only behavior confirmed before re-enabling tracking |
| One-click enable and disable | Passed manually | Tracking disabled and re-enabled through the panel/consent flow |
| Git-managed symlink target | Pending | Use a controlled test config when available |
| Shell restart and plugin reload | Passed manually | Guide and overlay returned normally after shell restart |
| Hyprland reload and catalog regeneration | Passed manually | Reload recovery passed with clean config errors |
| Focused-monitor guide routing | Passed manually | Dual-monitor check: guide appears only on the focused workspace's monitor |
| Delay values and fullscreen suppression | Passed manually | All delay choices and fullscreen toggle verified |
| Lock/credential suppression | Partially passed manually | Lock-screen suppression passed; credential-prompt surface remains pending |
| Representative bindings and release/submap cases | Pending | At least 50 safe bindings where available |
| Overlay navigation and practice completion | Passed manually in Task 12 | Final release retest remains optional before Task 15 |
| Stats flush/reload and reset recovery | Passed manually | Previous stats archived; fresh empty stats file verified |

## Privacy, performance, and non-interference

Remaining live verification:

- Unmatched application shortcuts and a final review that no raw key log,
  dispatcher argument, entered text, window title, application identifier,
  network request, or unmatched custom event is stored. Ordinary typing,
  metacharacters, and a synthetic password already passed manually.
- At least 100 Super-down latency samples with p95 below 50 ms.
- Five-minute idle bridge/service CPU average below 0.2% attributable CPU.
- Sustained synthetic stream with no unbounded queue/model growth.
- Aggregate writes remain batched rather than one write per event.
- Normalized `hyprctl binds` metadata remains identical before and after
  integration, with no duplicate bindings.

## Final result

`FAIL` / `PASS`: **PENDING LIVE/MANUAL GATE**
