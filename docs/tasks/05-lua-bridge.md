# Task 05 — Lua Bridge and Isolated Tests

## Objective

Implement `bridge.lua` and prove its event filtering and protocol with a mocked Hyprland Lua API, without loading it into the real compositor.

## Depends on

Task 02.

## Required behavior

1. Resolve the state directory from `XDG_STATE_HOME`, falling back to `$HOME/.local/state`.
2. Load `bridge-catalog.lua` once during config evaluation with `pcall`. If absent, malformed, wrong-schema, or missing complete modifier code sets, fail closed without registering callbacks or emitting events.
3. Register only these callbacks:
   - `hl.on("input.keyboard.key", ...)`
   - `hl.on("keybinds.submap", ...)`
4. Maintain left/right modifier state without file or process access.
5. Emit protocol messages using `hl.dispatch(hl.dsp.event(payload))`.
6. Match the exact canonical modifier mask, XKB code, press/release phase, and current submap.
7. Emit Super lifecycle once per transition and modifier updates only while Super is held.
8. Suppress duplicate press, impossible release, recursive callback, malformed lookup, and unmatched input.
9. Keep callback work bounded to state updates, string/key construction, table lookup, and an optional event dispatch.
10. Export no module globals except one namespaced guard used to prevent duplicate registration within a config evaluation.

## Mock harness

Create a Lua test harness that provides mock implementations for `hl.on`, `hl.dispatch`, and `hl.dsp.event`. It must invoke registered callbacks and capture emitted payloads.

Cover:

- Super press/release.
- Left/right Super overlap.
- Super then Shift and Shift then Super.
- Exact match and unmatched ordinary key.
- Press and release binding phases.
- Submap change.
- Duplicate callbacks/config load.
- Missing/corrupt/wrong-schema catalog and missing modifier code sets.
- At least 10,000 ordinary unmatched key events with zero emitted match events.
- Adversarial opaque IDs rejected unless they match the allowed ID format.

## Validation

```sh
luac -p bridge.lua
tests/shell/run bridge
```

Add a static test that fails if `bridge.lua` contains process APIs, shell execution, network APIs, or file operations inside the keyboard callback body.

## Acceptance criteria

- Emitted messages exactly match the versioned protocol in `PLAN.md`.
- Ordinary typing never emits a payload unless it is an exact allowlisted global binding.
- A bad catalog registers no input callback, emits nothing, and does not break Hyprland config evaluation.
- Loading the bridge twice does not double-register callbacks.
- The real Hyprland config and running compositor remain untouched.

## Out of scope

Live loading, QML event reception, guide rendering, statistics, and configuration UI.
