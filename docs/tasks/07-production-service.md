# Task 07 — Production Quickshell Service

## Objective

Replace the feasibility-only counter with the production `Service.qml` state owner and strict socket event ingestion.

## Depends on

Task 06 with a recorded `PASS`.

## Required state interface

Implement every property and method in `PLAN.md` section 7. Maintain these additional internal states:

```text
catalogState: loading, ready, error
statsState: loading, ready, recovered, error
lastProtocolError: string
bridgeEventCount: integer (session-only diagnostic)
```

## Required behavior

1. Load the catalog from the XDG state directory without blocking QML startup. Validate `schemaVersion`, binding field types, allowed categories, opaque ID format, and duplicate IDs.
2. Listen through `Quickshell.Hyprland.Hyprland.rawEvent`.
3. Accept only `custom` events whose payload begins exactly `keybind-dojo:v1:`.
4. Parse only the five protocol forms specified in the plan. Reject extra fields, unknown event types, wrong versions, invalid modifiers, and invalid IDs.
5. A match ID not present in the current catalog is ignored and counted only in session diagnostics.
6. Super lifecycle updates service state immediately; guide timing is delegated to the guide component.
7. Wire config/layout change events to a debounced catalog regeneration process. Prevent concurrent generators and reload loops.
8. Expose lookup and recommendation placeholders with stable return types; do not implement scoring yet.
9. Inspect bridge status on startup and every 30 seconds. Do not mutate configuration from a timer.
10. Access plugin settings from `shell.shellConfig` and expose setters that call `shell.updateEntryInline` only when values change.
11. Expose `desktopLocked` from `shell.serviceFor("omarchy.lock").locked` and `credentialPromptActive` from `shell.serviceFor("omarchy.polkit").dialogVisible` when available; missing services/properties default false without throwing.
12. Maintain `activeWindowFullscreen` with one debounced `hyprctl -j activewindow` argument-array process at startup and after `activewindow`, `activewindowv2`, or `fullscreen` raw events. Never query it from Super event handling.

## Component boundaries

- The service owns state and processes.
- `SuperGuide.qml` receives properties/signals and contains presentation only.
- Bar/Panel/Overlay call service methods; they do not read files or launch scripts directly.
- The service may run `bridge-control` and `generate-catalog` only through argument-array `Process` objects.

## Tests

Add QML or JS tests for:

- Every valid protocol event.
- Every malformed/wrong-version form.
- Unknown binding ID.
- Catalog missing, corrupt, duplicate, wrong-schema, and recovered after regeneration.
- Debounced config reload and single generator execution.
- Service lookup through `shell.serviceFor(pluginId)`.
- Setting normalization: delay only `0`, `80`, `150`, `250`, or disabled; fullscreen boolean only.
- Lock/polkit service present, absent, and reloaded; fullscreen query success, failure, and debouncing.

## Validation

```sh
qmllint -I "$OMARCHY_PATH/shell" Service.qml SuperGuide.qml
tests/shell/run service
omarchy plugin validate .
```

## Acceptance criteria

- Service survives every malformed input without throwing or crashing the shell.
- Valid Super events update properties synchronously.
- No UI component duplicates catalog, bridge, or settings ownership.
- Config regeneration cannot loop indefinitely.
- No statistics or gamification is implemented yet.
