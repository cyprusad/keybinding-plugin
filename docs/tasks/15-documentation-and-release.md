# Task 15 — Documentation and Release Packaging

## Objective

Prepare a complete, auditable `0.1.0` plugin release after the release gate passes.

## Depends on

Task 14 with `docs/RELEASE_TESTS.md` marked `PASS`.

## README

Write a concise user README containing:

- What the Super Guide does, with one screenshot/GIF placeholder only if an asset is actually produced.
- Supported Omarchy/Hyprland versions.
- Install command:

  ```sh
  omarchy plugin add https://github.com/sai/keybind-dojo.git --enable
  ```

- One-click consent explanation: the button edits the resolved Hyprland Lua target automatically after showing the exact diff.
- Symlink and Git-dotfiles behavior.
- Browse-only/manual fallback behavior.
- Guide timing controls.
- Local data location and reset behavior.
- Disable tracking before plugin removal.
- Update and remove commands.
- Known limitation that v1 records observed candidate activations rather than exact dispatcher execution.
- Troubleshooting link.

Do not market the plugin as an exact keybinding execution logger or a general keylogger.

## Security documentation

Create `docs/SECURITY.md` covering:

- Unsandboxed Omarchy plugin model.
- Exact user files the plugin may read/write.
- Why it does not use `/dev/input`.
- Data that is and is not emitted/persisted.
- No root/network/package installation.
- Config transaction and rollback model.
- Symlink/Git target rules.
- How to audit `bridge.lua`, generated lookup, state, and managed block.
- Vulnerability reporting instructions without inventing an unavailable email address; use repository security advisories/issues as appropriate.

Create `docs/TROUBLESHOOTING.md` covering every stable controller reason code, config error recovery, stale guarded block removal, disconnected dotfiles deployment, catalog regeneration, shell logs, and safe commands:

```sh
omarchy plugin validate .
omarchy-shell shell rescanPlugins
qs log -p "$OMARCHY_PATH/shell" --tail 100
hyprctl reload
hyprctl configerrors
```

## Repository completion

- Add MIT `LICENSE` with correct project copyright.
- Confirm manifest version `0.1.0`, author, license, repository ID, and description.
- Include no generated state, backups, test secrets, absolute development paths, or local config files.
- Ensure scripts have required executable bits.
- Add `CHANGELOG.md` with `0.1.0` features and known limitations.

## Final smoke test

Test from a fresh clone or clean archive, not the working directory’s previously enabled instance:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml Panel.qml Overlay.qml Service.qml SuperGuide.qml
luac -p bridge.lua
tests/shell/run all
```

Then verify:

1. Add without `--enable`: plugin is discovered but inactive.
2. Enable: bar widget appears and browse-only mode works.
3. Consent flow succeeds on an approved fixture/live config.
4. Update flow preserves state and integration.
5. Disable tracking removes only the managed block.
6. Remove plugin leaves Omarchy shell healthy.
7. Removing without cleanup leaves an inert `pcall` block and clean `hyprctl configerrors`.

## Acceptance criteria

- A new user can install and understand consent without reading source code.
- A security reviewer can identify every privilege, input, state, and config boundary.
- Release archive/repository root matches Omarchy’s plugin contract.
- Final smoke test passes and no machine-specific artifact is present.
- Marketplace submission may proceed only after these checks.
