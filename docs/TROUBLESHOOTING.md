# Troubleshooting

## Safe first steps

```sh
omarchy plugin validate .
omarchy-shell shell rescanPlugins
qs log -p "$OMARCHY_PATH/shell" --tail 100
hyprctl reload
hyprctl configerrors
```

After a code update, refresh the installed plugin and reopen the overlay:

```sh
omarchy plugin update io.github.cyprusad.keybind-dojo --yes
omarchy-shell shell rescanPlugins
```

The live controller is the copy inside the installed plugin directory. Do not
use a checkout controller to mutate a config block installed from a different
path; its exact-marker check will intentionally reject the differing bridge
path.

## Controller reason codes

`bridge-control inspect` reports one of these stable codes:

| Code | Meaning and safe response |
|---|---|
| `ok` | Target is user-owned, writable, regular, safe, and ready for consent. |
| `missing` | The logical Hyprland Lua path does not exist; confirm the Omarchy config path. |
| `dangling-symlink` | A symlink target is missing; repair the dotfiles deployment first. |
| `symlink-loop` | Symlink resolution loops; fix the dotfiles links manually. |
| `non-regular` | The target is not a regular file; automatic patching is refused. |
| `wrong-owner` | The target is not owned by the current user; do not use privilege escalation. |
| `not-writable` | The target or containing safe root is not writable; fix user permissions if appropriate. |
| `outside-safe-root` | The resolved target is outside the user home or user-owned Git root. |
| `multiple-hardlinks` | The file has multiple hard links; automatic replacement is refused. |
| `duplicate-markers` | More than one managed block exists; remove ambiguity manually after review. |
| `malformed-markers` | The guarded block is incomplete or has a different exact bridge path; use the installed controller and inspect the diff. |
| `changed-since-inspect` | The file changed after preview; inspect again before retrying. |
| `syntax-error` | The proposed Lua failed validation; do not force the change. |
| `hyprland-error` | Reload or `hyprctl configerrors` failed; the controller attempts rollback. |
| `concurrent-change` | The target changed during mutation; stop and inspect before retrying. |
| `unsupported` | The filesystem or encoding is unsupported; remain in browse-only mode. |

Browse-only mode is intentional after any controller/configuration failure. It
does not execute bindings and does not require `sudo`, `pkexec`, or a package
installation.

## Common recovery cases

If the bar widget is absent, confirm the plugin is enabled, then run the
rescan command above. If the guide is absent, check that tracking is enabled,
the catalog is ready, fullscreen suppression is not active, and the session is
not locked or showing an Omarchy Polkit credential surface.

If the state directory reports an error, inspect only the plugin's state:

```sh
dojo_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/keybind-dojo"
find "$dojo_state_dir" -maxdepth 2 -type f -printf '%M %f %s bytes\n' | sort
```

Corrupt statistics are moved to `recovery/` and replaced with a fresh profile.
Use the Settings **Clear local data** action for an intentional reset; it
archives the current stats before writing an empty profile. Do not delete the
managed Hyprland block or recovery files while diagnosing an issue.

If the catalog is stale after a Hyprland config or layout change, reload the
shell and allow the plugin to regenerate it. A clean result is:

```sh
hyprctl reload
hyprctl configerrors
```

with no output from `hyprctl configerrors`.

