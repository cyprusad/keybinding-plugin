# Task 01 — Repository and Plugin Skeleton

## Objective

Create the smallest valid Omarchy plugin structure and test harness without implementing tracking, configuration edits, statistics, or final UI.

## Inputs

- `docs/PLAN.md`, especially sections 3 and 14.
- Read-only examples:
  - `$OMARCHY_PATH/shell/plugins/panels/clock/`
  - `$OMARCHY_PATH/shell/plugins/emojis/`
  - `$OMARCHY_PATH/shell/plugins/services/battery/`
  - `$OMARCHY_PATH/shell/README.md`

## Required changes

1. Add the exact `manifest.json` contract from the plan.
2. Add minimal loadable entry points:
   - `Service.qml`: an `Item` accepting `shell` and `manifest`.
   - `BarWidget.qml`: a valid `BarWidget` with module name `io.github.sai.keybind-dojo` and a text/icon button.
   - `Panel.qml`: a keyboard-closeable anchored panel loaded by the bar widget.
   - `Overlay.qml`: a hidden overlay implementing `open(payloadJson)` and `close()`.
   - `SuperGuide.qml`: a non-visible placeholder component; do not create a layer-shell window yet.
3. Wire the bar widget to its nested panel using the established Omarchy clock pattern. Forward `opened`, `open()`, `close()`, `toggle()`, and `closeForPopoutSwitch()`.
4. Add empty JS library files with exported placeholders only where QML import resolution requires them.
5. Add `tests/shell/run`, which executes all shell tests discovered under `tests/shell/cases/` and returns nonzero on the first failure.
6. Add a minimal `.gitignore` for generated test output and local state. Do not ignore source fixtures.

## Constraints

- Do not clone a built-in into the repository; use it only as a structural reference.
- Do not touch `~/.config/omarchy`, `~/.config/hypr`, or the running shell.
- Do not add package dependencies, build systems, generated assets, or speculative abstractions.
- No entry point may start a process in this task.

## Validation

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml Panel.qml Overlay.qml Service.qml SuperGuide.qml
tests/shell/run
```

If `qmllint` reports warnings originating exclusively in Omarchy imports, record them separately; errors in repository files must be zero.

## Acceptance criteria

- The manifest is valid and all entry points exist.
- All QML files parse and import correctly.
- The bar/panel lifecycle matches the built-in contract.
- The overlay can be instantiated without doing work while closed.
- The test runner succeeds with at least one smoke case.
- No runtime or user configuration has been modified.

## Out of scope

Catalog parsing, Lua input hooks, live installation, onboarding logic, statistics, guide rendering, and gamification.
