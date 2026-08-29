# Task 14 — Integration, Privacy, and Performance Release Gate

## Objective

Exercise the complete plugin as installed software and produce evidence that it meets its compatibility, privacy, non-interference, and performance promises.

## Depends on

Tasks 07–13.

## Automated suite

Create one top-level test command through `tests/shell/run all` that covers:

- Manifest and file-layout checks.
- Catalog, inspector, patcher, bridge, service, guide, onboarding, stats, recommendations, overlay, and hardening suites.
- Generated JSON and Lua schema validation.
- Static scans for forbidden runtime writes, privilege commands, network clients, dispatcher argument persistence, `eval`, and process/file work in the input callback.
- Fixture mutation containment: tests may write only under their temporary roots.

## Live test prerequisites

Record:

```text
Omarchy version
Hyprland version/commit
Quickshell version
active XKB layouts
monitor count/scales
plugin commit
```

Use the bridge controller for every live config mutation and record a clean pre-test hash. Do not continue if the initial `hyprctl configerrors` is nonempty; report the pre-existing error without claiming the plugin caused it.

## Live functional matrix

- Install/enable plugin from a clean checkout.
- Browse-only catalog before consent.
- One-click regular-file enable/disable.
- One-click Git-managed symlink-target enable/disable using a controlled test config when possible.
- Shell restart, plugin hot reload, Hyprland reload, and catalog regeneration.
- Guide on focused monitor across monitor focus changes.
- Every delay value.
- Lock, credential surface where testable, fullscreen suppression, and bar positions.
- At least 50 safe representative bindings.
- Release/media/custom/submap/layout cases available on the machine.
- Overlay navigation, practice completion, stats flush/reload, and reset recovery.

## Privacy verification

Use a disposable text field and enter:

- Ordinary prose.
- Shell metacharacters.
- A synthetic password.
- Ctrl-based application shortcuts not configured as global bindings.

Verify:

- No Omakeez custom event for unmatched input.
- No raw key log exists.
- State contains only opaque IDs and aggregate numeric/date fields.
- No dispatcher arguments, entered text, window titles, or application identifiers occur anywhere under the state directory.
- No network socket or request is opened by the plugin.

Never use a real password or secret in testing.

## Performance verification

- Repeat at least 100 Super-down latency samples; p95 must remain below 50 ms.
- Measure idle bridge/service CPU for five minutes; average attributable CPU below 0.2%.
- Generate a sustained synthetic mocked stream to verify no unbounded queue/model growth.
- Confirm one aggregate write per dirty batching window, not per event.
- Confirm no process launch or file operation occurs in the keyboard callback.

## Non-interference verification

Compare normalized `hyprctl binds` before/after integration. Dispatcher, argument, flags, submap, key, and modifier metadata must be identical. Verify no duplicate bindings were registered and no standard command changes behavior.

## Evidence

Write `docs/RELEASE_TESTS.md` with:

- Environment.
- Automated results.
- Live matrix with pass/fail/skipped reason.
- Latency distribution and CPU measurement.
- Privacy inspection.
- Binding metadata diff.
- Remaining known limitations.
- Final `PASS` or `FAIL`.

## Acceptance criteria

- All automated checks pass.
- Required live checks pass and `hyprctl configerrors` is empty.
- Performance and privacy budgets are satisfied.
- Any skipped hardware-specific case has a reason and fixture coverage.
- A `FAIL` blocks task 15 release packaging.
