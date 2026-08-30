# Omakeez release evidence

Release target: `0.1.0`  
Prepared: 2026-08-30

## Automated evidence

Run from the repository root:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml Panel.qml Service.qml SuperGuide.qml
luac -p bridge.lua
tests/shell/run all
```

The release suite covers manifest structure, catalog generation, configuration
inspection and patching, symlink/Git safety, bridge protocol behavior,
guide layout, no-persistence runtime checks, QML models, and static release
hardening. Its no-persistence check fails if the removed stats, gamification,
or full-overlay sources return or if runtime code references activity history.

Result: **PASS** on 2026-08-30 from a fresh local clone. Manifest validation,
QML lint, Lua syntax validation, and `tests/shell/run all` all passed with a
clean post-test worktree.

## Manual release smoke

The following checks require a real Omarchy session and should be repeated by
the release owner before publishing a GitHub release:

| Check | Expected result |
|---|---|
| Fresh add without `--enable` | Plugin is discovered but inactive. |
| Enable plugin | Bar icon and setup panel appear; no bridge is added yet. |
| Consent flow | Exact diff is visible; enabling adds only the managed bridge block. |
| Guide roots | Enabled `SUPER`/`SHIFT`/`CTRL`/`ALT` roots show a guide; disabled roots do not. Shortcuts retain normal behavior. |
| Lock and fullscreen | Guide hides while locked and obeys the fullscreen setting. |
| Disable guide | Only the managed bridge block is removed; `hyprctl configerrors` stays clean. |
| Remove plugin | Shell remains healthy. An intentionally retained inert `pcall` block causes no config errors. |

## Publication artefacts

- README includes a Super Guide hero plus enabled/setup panel screenshots.
- No generated state, backup, local configuration, or secrets are tracked in
  the release tree; the three committed screenshots are intentional README
  assets.
- The source-linked bridge has in-place security comments for reviewer audit.
