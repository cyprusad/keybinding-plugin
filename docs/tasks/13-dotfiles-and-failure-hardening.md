# Task 13 — Dotfiles and Failure-Mode Hardening

## Objective

Complete the unusual-config, redeployment, recovery, and shell-reload behaviors that make the one-click integration safe outside a default installation.

## Depends on

Tasks 04 and 09.

## Required scenarios

Extend fixtures and UI/controller behavior for:

1. `~/.config/hypr/hyprland.lua` is a relative or absolute symlink.
2. `~/.config`, `~/.config/hypr`, or multiple parent components are symlinks.
3. The target lives in a clean or dirty user-owned Git worktree.
4. The Git repository uses spaces, Unicode, or shell metacharacters in its path.
5. The symlink is retargeted between inspection and enable.
6. A dotfile deployment removes the managed block while the plugin runs.
7. A deployment replaces the target inode with equivalent or different content.
8. Managed markers are duplicated, partial, reversed, nested, or user-edited.
9. The target ends in a legal top-level return.
10. The target is CRLF, lacks a final newline, or contains non-ASCII comments.
11. The target has multiple hard links, becomes read-only, changes owner in a mocked fixture, or lies outside safe roots.
12. The plugin directory disappears while the guarded block remains.
13. The state directory is missing, unwritable, corrupt, or has unsafe permissions.
14. `luac`, `hyprctl`, `xkbcli`, `jq`, `git`, or `flock` is unavailable.

## Fixed responses

- Missing optional `git`: report `gitManaged:false` unless outside `$HOME`, where safe-root proof fails and automatic patching is refused.
- Missing required `luac`, `hyprctl`, `xkbcli`, `jq`, or `flock`: browse-only mode with a named missing-dependency error; do not install anything.
- Deployment removes/retargets integration: set `disconnected`, stop guide expectations, retain stats, and require a new inspection/consent click.
- Malformed markers: never repair automatically; display the manual snippet and marker-removal guidance.
- Missing plugin file with stale guarded block: `pcall` keeps Hyprland clean; status after reinstall is `disconnected` until the user reviews current integration.
- Unsafe state directory ownership/permissions: refuse bridge enable and persistence; browse-only catalog may remain in memory.

## Health monitoring

Implement a low-frequency status check at startup, after local plugin reload, after config reload, and every 30 seconds. Coalesce concurrent checks. Health checks are read-only and must not recreate or patch configuration.

When a previously enabled integration becomes disconnected, hide the guide immediately and surface a non-modal bar status mark. Do not display repeated desktop notifications.

## Backup/recovery controls

- List controller-created backups in reverse time order inside troubleshooting output, not the main panel.
- Do not add a general “restore backup” UI in v1; automatic rollback is transaction-local.
- Never delete a backup outside Keybind Dojo’s state directory.
- Document manual recovery with paths and hashes.

## Validation

```sh
tests/shell/run hardening
qmllint -I "$OMARCHY_PATH/shell" Service.qml Panel.qml
```

## Acceptance criteria

- The full scenario matrix has deterministic tests.
- No unsafe case produces a write or privilege request.
- Symlink and dotfile redeployment never triggers silent reinsertion.
- Every failure has a stable reason code and actionable, non-destructive UI message.
- Browse-only mode remains available whenever a catalog can be read safely.
