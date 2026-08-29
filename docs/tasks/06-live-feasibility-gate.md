# Task 06 — Live Feasibility Gate

## Objective

Perform the smallest possible live integration test that proves the chosen Lua-to-socket2 architecture is viable before investing in the production service and UI.

## Depends on

Tasks 01–05.

## Authority boundary

This task intentionally modifies the operator’s real Hyprland Lua configuration through the completed patcher. Do not execute it unless the user’s implementation request explicitly authorizes the live feasibility test. Never edit the file directly.

Before applying anything:

- Run `bridge-control inspect`.
- Show the logical path, resolved path, Git status, and exact proposed diff.
- Confirm that the expected hash used for enable is the inspected hash.

## Required spike implementation

1. Add a temporary minimal event counter to `Service.qml`; it may log protocol event names and monotonic timestamps but must not log keycodes, descriptions, or ordinary input.
2. Add a minimal visual guide surface sufficient to measure Super-down visibility. It must already be instantiated, use no keyboard focus, and have an empty pointer mask.
3. Generate the live catalog into the real state directory.
4. Enable the bridge only through `bridge-control enable --expected-hash`.
5. Capture baseline and enabled `hyprctl binds` output for comparison under a temporary test directory.

## Test matrix

Exercise at least 50 representative bindings, including:

- Direct Super navigation/window commands.
- Super+Shift, Super+Ctrl, and Super+Alt commands.
- Workspace numbers and arrows.
- App launch bindings.
- Clipboard/capture commands safe to trigger.
- One media key if available.
- One release binding if configured.
- One user-custom binding if present.
- Current default submap and any configured non-default submap.

For destructive or disruptive bindings such as shutdown, close-all-windows, suspend, and logout, validate catalog matching through the mock harness instead of executing them.

Also type ordinary prose, shell commands, and a synthetic password into a local disposable input field. Inspect only Omakeez’s own event counter and verify no events were emitted.

## Performance measurement

Collect at least 100 Super-down samples using monotonic timestamps at bridge emission receipt and guide visible-state transition.

Pass thresholds:

- p95 event-to-visible below 50 ms.
- No missed Super lifecycle transitions.
- Idle CPU attributable to the bridge/service below 0.2% averaged over five minutes.
- No process creation or file access per keyboard event.

## Validation and cleanup

```sh
hyprctl reload
hyprctl configerrors
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" Service.qml SuperGuide.qml
```

`hyprctl configerrors` must be empty.

After recording results, disable the bridge through `bridge-control disable` unless the user explicitly asks to leave the development integration enabled. Verify byte-identical restoration where no external edit occurred.

Write `docs/FEASIBILITY.md` containing environment versions, test counts, latency summary, CPU result, metadata diff result, privacy result, and a clear `PASS` or `FAIL` decision.

## Acceptance criteria

All pass criteria in `PLAN.md` section 12 succeed and `docs/FEASIBILITY.md` records evidence. If any fail, mark `FAIL`, stop the implementation sequence, and do not proceed to task 07.

## Forbidden fallback

Do not switch to evdev, `/dev/input`, dispatcher wrapping, duplicate binds, log parsing, a C++ Hyprland plugin, or a patched compositor.
