# Task 09 — Bar Widget, Onboarding, and Settings Panel

## Objective

Implement the complete one-click consent flow and everyday quick panel through the Omarchy bar widget.

## Depends on

Tasks 04, 07, and 08.

## Bar widget

1. Resolve the service through `bar.shell.serviceFor(moduleName)`.
2. Show a compact belt icon plus current streak when stats are available.
3. Show a subtle status mark when integration is disabled, disconnected, or errored.
4. Tooltip text summarizes level/streak when enabled and says `Set up Keybind Dojo` when disabled.
5. Left click toggles the nested panel. Do not assign right/middle actions in v1.

## Onboarding panel

When integration is not enabled:

1. Call service inspection on open.
2. Show logical path, resolved target, symlink status, Git root, and dirty status.
3. Render the exact proposed diff in a scrollable monospace region.
4. Explain that clicking the button automatically edits the resolved target, preserves the symlink, validates Hyprland, and can roll back.
5. Enable `Enable tracking and Super Guide` only for `safeToPatch:true`.
6. Pass the displayed `currentHash` as `--expected-hash`; never silently re-inspect and apply a different diff under one click.
7. Show progress states for catalog generation, patching, reload, and status verification.
8. On success, transition to the normal panel without requiring shell restart.
9. On refusal/error, show the stable reason, `Recheck`, and a copyable manual snippet. Never offer elevated privileges.

## Normal panel

Render sections in the exact order from `PLAN.md`. Implement:

- Integration health and current resolved path.
- `Disable tracking`, requiring a small inline confirmation.
- Delay choices: Instant, 80 ms, 150 ms, 250 ms, Off.
- Fullscreen toggle.
- Placeholder stats/recommendation cards until tasks 10–11 populate them.
- `Open Dojo`, routed through `shell.summon(moduleName, "{}")` or the plugin’s supported shell call.
- `Clear local data`, disabled until persistence exists.

## Safety behavior

- QML never edits files itself; all mutations go through the service and `bridge-control`.
- If the file changes after preview, show `Configuration changed; review the new diff` and require a new click.
- Closing the panel does not cancel an already-started atomic transaction.
- All process output is parsed as JSON and displayed as text, never evaluated.

## Tests

- Safe regular config onboarding.
- Safe Git-managed symlink target onboarding.
- Unsafe target and manual fallback.
- Changed-since-preview refusal.
- Successful enable and disable state transitions using fixture-mode controller.
- Patcher validation failure and rollback presentation.
- Delay/fullscreen setting persistence through `shell.updateEntryInline`.
- Service temporarily unavailable during plugin reload.

## Validation

```sh
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml Service.qml
tests/shell/run onboarding
omarchy plugin validate .
```

## Acceptance criteria

- Typical onboarding requires exactly one informed button click after plugin installation.
- Symlinked/Git-managed paths are explicit and preserved.
- No stale preview can be applied.
- Unsafe cases remain understandable and usable in browse-only mode.
