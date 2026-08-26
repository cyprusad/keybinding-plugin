# Live feasibility gate

## Environment

- Date: 2026-08-26
- Omarchy: 4.0.1-1
- Hyprland: 0.56.2, commit `efb50993780079460b0cbed1363e2166a2de1d9f`
- Quickshell: 0.3.1
- Session: active Wayland session with two monitors and English (US) layout
- Feasibility spike tip before this report: `af08db5`

## Decision: PASS

The Lua callback, Hyprland `socket2` custom-event transport, and pre-instantiated
Quickshell guide satisfy the feasibility and performance thresholds. Tasks that
depend on this gate may proceed.

The earlier failed run was traced to the managed loader pointing at
`$XDG_STATE_HOME/omarchy/keybind-dojo/bridge.lua`, where no bridge was installed.
The loader now resolves the installed plugin's `bridge.lua`. A full Hyprland Lua
reload then registered the production callback, and physical keyboard events
arrived through the intended architecture.

## Live integration evidence

- `bridge-control inspect` reported the real config safe to patch. Enable and
  disable both used the immediately inspected SHA-256 hash; the file was never
  edited directly.
- The generated catalog contained 228 active binding IDs in nine categories.
  Its bridge table contained 267 unique XKB-code match entries across 13
  modifier masks. The active configuration had only the default submap and
  press-phase bindings, so non-default-submap and release cases were not
  applicable to this machine.
- `tests/live-bridge-matrix.lua` exercised all 267 live match entries through
  the real bridge callback. It mocked only Hyprland's final event dispatch, so
  disruptive commands such as logout, shutdown, capture, and close-all were
  not executed.
- Physical input checks covered bare Super, Super+Return, Super+Ctrl+E, and
  Super+Alt+Space. Bare Super emitted exactly one down and one up lifecycle
  event. Each tested chord emitted exactly one opaque match event for its
  configured press phase; the Ctrl and Alt tests also reported the expected
  modifier state.
- Baseline and enabled `hyprctl binds` captures were byte-identical. No
  dispatcher, argument, repeat, release, locked, mouse, or submap metadata was
  replaced or duplicated, so the observer did not alter the original command
  path.
- `hyprctl configerrors` was empty after enable, full reload, physical testing,
  disable, and final full reload.

## Latency and lifecycle

A controlled live sequence delivered 100 Super-down/up custom events at the
same `socket2` ingress used by the bridge. The already-instantiated guide
recorded its visible-state transition synchronously at receipt:

| Samples | p50 | p95 | Maximum | Threshold |
|---:|---:|---:|---:|---:|
| 100 | 0 ms | 1 ms | 1 ms | p95 < 50 ms |

Final diagnostics contained 118 visibility samples, all between 0 and 1 ms,
with `guideVisible:false`. Physical tests also ended with balanced Super
down/up transitions.

## Idle CPU

The complete Quickshell process was sampled from `/proc/<pid>/stat` for 300
idle seconds. It consumed 48 ticks at 100 ticks/second:

`(48 / 100) / 300 * 100 = 0.1600% CPU`

This is a conservative upper bound because it includes the whole Omarchy shell,
not only Keybind Dojo. It remains below the 0.2% attributable-CPU budget.

## Privacy and callback work

- A persistent listener filtered to `keybind-dojo:v1:` received no events from
  ordinary typing. No typed key, prose, command text, or password-like content
  was inspected or logged.
- The bridge emits only Super lifecycle, modifier-mask, and opaque SHA-256 match
  events. Descriptions, dispatcher arguments, and raw ordinary keys never enter
  the protocol.
- Callback-source inspection rejects process creation, socket setup, and file
  APIs inside the keyboard callback. Catalog loading occurs once before callback
  registration. The existing 10,000-event unmatched-key stress test emitted no
  protocol events and created no per-event work queue.

## Validation

The following checks passed:

```text
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml Overlay.qml Service.qml SuperGuide.qml
luac -p bridge.lua
tests/shell/run
XDG_STATE_HOME=... lua tests/live-bridge-matrix.lua ...
```

The live matrix result was:

```text
live_bridge_matrix=pass matches=267 modifier_masks=13 phases=1 submaps=1
```

## Cleanup

The managed bridge block was disabled through `bridge-control`, followed by a
full Hyprland reload. The real Lua configuration was restored to its original,
byte-identical hash and the managed block is absent:

`sha256:d9ff826374b81f6360958280ed2169dda5b015f953accd95ff4a3abf8ff8e24b`

The installed plugin remains enabled in browse-only mode; the temporary live
bridge integration is disabled.
