# Live feasibility gate

## Environment

- Omarchy: 4.0.1-1
- Hyprland: 0.56.2, commit `efb50993780079460b0cbed1363e2166a2de1d9f`
- Quickshell: 0.3.1
- Monitor/session: active Wayland session, two monitors observed
- Active layout: English (US)
- Plugin bridge commit: `7dd6bdb`

## Result: FAIL

The bridge was enabled only through `scripts/bridge-control` using the inspected hash, and Hyprland reloaded with clean `hyprctl configerrors`. A filtered socket2 listener was kept open while Super was physically pressed and released multiple times. It received no `keybind-dojo:v1:` events.

A separate temporary Super-only in-memory diagnostic callback did receive the physical presses, and a harmless direct custom event reached the same socket listener. This isolates the failure to bridge loading/registration or callback execution, rather than the keyboard or socket transport.

The temporary managed block was disabled through `bridge-control`. The real configuration was restored to its original SHA-256 hash:

`sha256:d9ff826374b81f6360958280ed2169dda5b015f953accd95ff4a3abf8ff8e24b`

`hyprctl configerrors` is clean. The 50-binding matrix, 100-sample latency, CPU, and full privacy checks were not run because the first required event criterion failed.

Per the implementation plan, this FAIL blocks production service and UI work until the bridge issue is fixed and the live gate is repeated.
