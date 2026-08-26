# Task 03 — Read-Only Configuration Inspector

## Objective

Implement the non-mutating half of `scripts/bridge-control`: resolve the user’s Hyprland Lua entry point, evaluate whether it is safe to patch, and return an exact preview.

## Depends on

Task 01. It may be developed in parallel with task 02.

## Required CLI

```text
bridge-control inspect [--config <logical-path>] [--state-dir <directory>]
bridge-control status [--config <logical-path>] [--state-dir <directory>]
bridge-control manual-snippet
```

Default config: `${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua`  
Default state: `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/keybind-dojo`

All commands print one JSON object. `manual-snippet` returns the exact marked loader block as a JSON string.

## Required inspection behavior

1. Preserve the logical path for display while resolving every parent and final symlink to the canonical target.
2. Detect missing targets, dangling links, loops, non-regular targets, owner UID, writability, link count, mode, device, inode, line-ending style, and SHA-256.
3. Determine whether the canonical target is under `$HOME`.
4. If outside `$HOME`, identify a containing Git worktree without changing it. It is safe only when the Git root and target are owned and writable by the current UID.
5. If inside any Git worktree, report root and dirty state. Do not stage, commit, reset, or clean anything.
6. Parse managed markers exactly. Valid states are `absent` or `present`. Duplicate, nested, reversed, or partial markers are unsafe.
7. Construct the proposed enable diff when absent and disable diff when present.
8. Choose insertion after the Omarchy default/bootstrap loading area. If the file ends in a top-level `return`, preview insertion immediately before that return. If placement is ambiguous, report `unsupported` rather than guessing.
9. Emit the stable fields and reason codes defined in `PLAN.md`.
10. `inspect` must never create the state directory, backup, temporary file, or lock.

## Fixture matrix

Tests create all structures under a temporary directory:

- Plain regular file.
- File symlink.
- Symlinked parent directory.
- Multi-hop relative and absolute links.
- Dangling link and loop.
- Directory/FIFO target.
- One and multiple hard links.
- Clean and dirty Git worktree.
- User-home target and external user-owned Git target.
- External non-Git target.
- Valid existing block and every malformed-marker form.
- LF and CRLF source.
- Final top-level return.
- Path containing spaces and shell metacharacters.

## Validation

```sh
tests/shell/run inspector
scripts/bridge-control inspect | jq -e '
  .schemaVersion == 1 and
  (.logicalPath | type == "string") and
  (.safeToPatch | type == "boolean") and
  (.reasonCode | type == "string")'
```

The live command is read-only.

## Acceptance criteria

- Every fixture produces the planned reason code and exact canonical path.
- The proposed diff changes only the managed block.
- Inspecting a symlink never reports that the symlink itself will be replaced.
- Git dirty status is informational and does not make an otherwise safe target unsafe.
- Repeated inspection creates no files and changes no metadata.

## Out of scope

Applying the diff, backups, `hyprctl reload`, QML onboarding, and live bridge loading.
