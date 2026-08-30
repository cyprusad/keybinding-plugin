# Troubleshooting

## Safe first steps

```sh
omarchy plugin validate .
omarchy-shell shell rescanPlugins
qs log -p "$OMARCHY_PATH/shell" --tail 100
hyprctl reload
hyprctl configerrors
```

After an update, refresh the installed plugin and reopen its panel:

```sh
omarchy plugin update io.github.cyprusad.omakeez --yes
omarchy restart shell
```

The live controller is the copy inside the installed plugin directory. Do not
use a checkout controller to mutate a bridge installed from a different path;
the exact-marker protection intentionally rejects it.

## Controller reason codes

`bridge-control inspect` reports these stable reason codes:

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
| `malformed-markers` | The guarded block is incomplete or embeds a different bridge path; use the installed controller and review the diff. |
| `changed-since-inspect` | The file changed after preview; inspect again before retrying. |
| `syntax-error` | The proposed Lua failed validation; do not force the change. |
| `hyprland-error` | Reload or `hyprctl configerrors` failed; the controller attempts rollback. |
| `concurrent-change` | The target changed during mutation; stop and inspect before retrying. |
| `unsupported` | The filesystem or encoding is unsupported; remain in setup mode. |

## Common recovery cases

If the bar widget is absent, confirm the plugin is enabled and run the rescan
command above. If a guide is absent, verify that its starting key is enabled in
the Omakeez panel, the catalog has finished generating, the active window is
not fullscreen (unless enabled), and the session is not locked or showing an
Omarchy Polkit dialog.

If the catalog is stale after a Hyprland configuration or layout change, run:

```sh
hyprctl reload
hyprctl configerrors
```

Then reopen Omakeez; it regenerates its local catalog from the active binding
table. A clean `hyprctl configerrors` result has no output.

For a cautious local audit, list only Omakeez's operational state:

```sh
omakeez_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/omakeez"
find "$omakeez_state_dir" -maxdepth 2 -type f -printf '%M %f %s bytes\n' | sort
```

If setup fails, do not delete a managed block blindly. Use **Review exact
change**, compare the installed bridge path, and use **Copy manual snippet** if
the controller has correctly refused the target.
