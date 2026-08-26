# Task 04 — Transactional Configuration Patcher

## Objective

Add safe `enable` and `disable` mutations to `scripts/bridge-control`, fully tested against temporary fixture trees only.

## Depends on

Task 03.

## Required CLI

```text
bridge-control enable --expected-hash <sha256> [--config <path>] [--state-dir <dir>] [--no-live-reload]
bridge-control disable --expected-hash <sha256> [--config <path>] [--state-dir <dir>] [--no-live-reload]
```

`--no-live-reload` is mandatory in automated fixture tests. Without it, the command performs real Hyprland validation and is allowed only when the caller has explicitly authorized a live integration change.

## Required transaction

1. Acquire `${stateDir}/bridge-control.lock` with `flock`.
2. Re-run inspection under the lock.
3. Require `safeToPatch:true` and an exact match with `--expected-hash`.
4. Recheck canonical path, device, inode, owner, mode, and link count immediately before replacement.
5. Store the original content plus a JSON metadata record under `${stateDir}/backups/<UTC timestamp>-<hash>/` with permissions `0700`/`0600`.
6. Add or remove only the exact managed block.
7. Preserve LF/CRLF style, trailing newline behavior, and mode bits.
8. Run `luac -p` on the candidate.
9. Write a same-directory temporary with mode `0600`, adjust it to the original mode, fsync when supported, and atomically rename it over the resolved target. The logical symlink must remain unchanged.
10. Without `--no-live-reload`, run `hyprctl reload` followed by `hyprctl configerrors`.
11. If validation fails, restore only when the target hash equals the expected patched hash. Otherwise return `concurrent-change` and preserve the backup and failed candidate for recovery.
12. Print a single JSON result containing old/new hashes, logical/resolved paths, backup path, validation result, and whether rollback occurred.

Enable is idempotent when exactly one valid block is already present. Disable is idempotent when the block is absent. Neither case rewrites the file.

## Failure injection tests

Add controllable test hooks, available only when `KEYBIND_DOJO_TESTING=1`, for:

- Lock contention.
- File change after inspection.
- `luac` failure.
- Rename failure.
- Hyprland reload failure.
- Nonempty config errors.
- Concurrent edit before rollback.

Never enable test hooks in normal execution based on untrusted input.

## Validation

```sh
tests/shell/run patcher
```

Do not run a live enable/disable operation in this task.

## Acceptance criteria

- All fixture types from task 03 retain their expected safe/refused behavior.
- Symlinks and Git metadata remain intact.
- Only the managed block differs after enable; enable then disable restores byte-identical original content.
- Hash mismatch prevents every write.
- Rollback never overwrites a concurrent edit.
- No backup appears inside the dotfiles worktree.
- No command uses `sudo`, `pkexec`, `eval`, or an interpolated shell command.

## Out of scope

Live config modification, the Lua callback, QML onboarding, and event processing.
