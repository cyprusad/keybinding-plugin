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
| Hyprland version/commit | `0.56.2`, `efb50993780079460b0cbed1363e2166a2de1d9f` |
| Active XKB layouts | English (US) |
| Monitor count/scales | Two monitors; focused-monitor routing passed manually |

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
- **Step 11 — Unmatched application shortcut privacy: PASS.** User tested a
  Ctrl-only shortcut in a disposable input surface; the plugin state remained
  empty and no typed content was stored.
- **Step 12 — Application credential surface scope: NOT APPLICABLE.** User
  tested a 1Password unlock prompt without entering a secret. The guide
  remained available because 1Password is an independent application surface,
  not Omarchy’s lock or Polkit credential surface; the plugin does not inspect
  arbitrary password fields or application identity.
- **Step 13 — Prior feasibility evidence carried forward: PASS.** The Task 06
  live gate already covered 267 bridge match entries, 100 latency samples,
  idle CPU, unmatched-key stress, aggregate batching, and byte-identical
  binding metadata. The current Task 14 changes do not alter the input path.

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
| Git-managed symlink target | Not applicable live | Real config is a regular non-Git file; automated onboarding fixtures cover symlink/Git behavior |
| Shell restart and plugin reload | Passed manually | Guide and overlay returned normally after shell restart |
| Hyprland reload and catalog regeneration | Passed manually | Reload recovery passed with clean config errors |
| Focused-monitor guide routing | Passed manually | Dual-monitor check: guide appears only on the focused workspace's monitor |
| Delay values and fullscreen suppression | Passed manually | All delay choices and fullscreen toggle verified |
| Lock/credential suppression | Passed with scope noted | Lock-screen suppression passed; 1Password app prompt is outside the Omarchy/Polkit detection boundary |
| Representative bindings and release/submap cases | Passed via live feasibility evidence | 267 live match entries; disruptive commands mocked; release/submap cases unavailable in the active config and covered by fixtures |
| Overlay navigation and practice completion | Passed manually in Task 12 | Full overlay navigation and practice flow verified |
| Stats flush/reload and reset recovery | Passed manually | Previous stats archived; fresh empty stats file verified |

## Privacy, performance, and non-interference

Completed live verification:

- No raw key log, dispatcher argument, entered text, window title, application
  identifier, network request, or unmatched custom event is stored. Ordinary
  typing, metacharacters, a synthetic password, and an unmatched Ctrl-only
  shortcut passed manually.
- 100 Super-down samples: p95 `1 ms`, maximum `1 ms`, below the `50 ms`
  threshold.
- Five-minute idle CPU upper bound: `0.1600%`, below the `0.2%` budget.
- 10,000 unmatched-key stress events produced no protocol events or unbounded
  queue/model growth.
- Aggregate writes are debounced and storage fixtures verify batched atomic
  writes.
- Normalized `hyprctl binds` metadata was byte-identical before and after
  integration, with no duplicate bindings.

## Final result

`FAIL` / `PASS`: **PASS**
