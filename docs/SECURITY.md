# Security and privacy

Keybind Dojo runs as an Omarchy shell plugin. Omarchy plugins are not a
security sandbox, so installing this plugin grants its QML, JavaScript, Lua,
and helper-script code the capabilities available to the user session. Review
the repository before installing updates.

## Boundaries

The plugin may:

- Read the resolved Hyprland Lua configuration, `hyprctl binds`, and the active
  XKB keymap to build a local catalog.
- Read the Omarchy shell's own service state for lock, Polkit credential,
  fullscreen, and shell lifecycle suppression.
- Write the resolved Hyprland Lua target only after the user reviews the exact
  diff and consents through the panel.
- Write local state under `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/keybind-dojo/`:
  `catalog.json`, `bridge-catalog.lua`, `stats.json`, `recovery/`,
  `backups/`, and `bridge-control.lock`.

The controller requires user ownership, safe permissions, a regular file with
one link, and a user-home or user-owned Git-root location. It writes through a
same-directory temporary file and atomic replacement, creates protected
backups, validates Lua syntax, checks Hyprland reload errors, and rolls back a
failed live mutation.

The plugin does not use `/dev/input`, evdev, a raw keyboard log, root access,
`sudo`, `pkexec`, a package manager, or a network API. The keyboard callback in
`bridge.lua` performs only in-memory matching and emits opaque protocol events;
it does not read files or launch processes.

## Data policy

The bridge emits only Super lifecycle, modifier-mask, and opaque SHA-256
binding-match events. The catalog uses dispatcher arguments only while hashing
an ID; arguments are not written to the catalog, bridge lookup, statistics, or
protocol. Statistics contain aggregate numeric/date values and opaque IDs.

Ordinary typing, passwords, commands, window titles, application identifiers,
and unmatched input are not persisted. A 1Password unlock field is an
application-owned credential surface and is intentionally not inspected; the
plugin only suppresses the guide for Omarchy lock and exposed Polkit state.

## Audit points

- `bridge.lua`: input callback, event protocol, and fail-closed behavior.
- `scripts/generate-catalog`: catalog inputs and argument exclusion.
- `scripts/bridge-control`: path safety, exact diff, backup, atomic write,
  validation, reload, and rollback.
- `scripts/stats-store`: permission-restricted atomic statistics and recovery.
- `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/keybind-dojo/`: runtime data.
- The guarded `Keybind Dojo managed bridge` block in the resolved Hyprland Lua
  target.

Use the installed plugin's controller when auditing a live managed block. A
checkout copy embeds the checkout's bridge path and can report an installed
block as malformed even when the installed block is valid.

## Reporting a vulnerability

Please do not include passwords, private configuration, or state files in a
public issue. For sensitive reports, use the repository's GitHub Security
Advisories flow: <https://github.com/cyprusad/keybinding-plugin/security/advisories/new>.
For non-sensitive bugs, open an issue at
<https://github.com/cyprusad/keybinding-plugin/issues>.

