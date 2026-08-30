# Privacy-first guide coverage

Status: implemented for the `0.1.0` release.

## Current boundary

Omakeez provides transient visual guides for four Hyprland modifier roots:

- `SUPER GUIDE`
- `SHIFT GUIDE`
- `CTRL GUIDE`
- `ALT GUIDE`

The first held modifier is the guide root. Adding another modifier selects the
exact chord lane; releasing the root closes the guide. Each root can be turned
on or off in the Omakeez panel without changing any underlying shortcut.

The bridge receives Hyprland keyboard transitions but reduces them immediately
to an allowlisted modifier/code/phase/submap tuple. It emits only guide state,
modifier names, and opaque IDs for configured matches. Unmatched keys are
discarded. See [SECURITY.md](SECURITY.md) and the in-source comments in
[bridge.lua](../bridge.lua) for the complete boundary.

## Data minimization

The release stores no activity history and has no policy file:

- no raw key logs, typed text, passwords, or command arguments;
- no per-binding counts, timestamps, or any other usage history;
- no activity-data files or unused full-screen browser; and
- no network telemetry.

Only the regenerated catalog/bridge lookup and controller safety files remain.
They describe registered shortcuts and config transactions; they do not record
how the user uses their keyboard.

## Future direction

Application-local providers—for example documented Tmux or Herdr bindings—may
be added later as read-only reference sources. They must never enter the
Hyprland bridge match table, observe raw application keystrokes, or add
activity tracking. Any future per-binding selection policy requires a separate
privacy review and explicit user consent.
