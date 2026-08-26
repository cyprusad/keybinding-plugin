# Keybind Dojo — Decision-Complete Engineering Plan

Status: approved design, implementation not started  
Target: Omarchy Quattro with Hyprland 0.56.2 or newer  
Plugin ID: `io.github.sai.keybind-dojo`  
License: MIT

## 1. Product definition

Keybind Dojo is a local-first Omarchy shell plugin that helps a user discover and learn their actual Hyprland keyboard bindings. Its primary experience is an instant, non-interactive “Super Guide” that appears while Super is held and behaves like a desktop-scale which-key panel. Usage statistics, recommendations, practice, XP, and streaks support that experience.

The plugin must be useful immediately after normal Omarchy installation in browse-only mode. Tracking and the Super Guide require one explicit consent click. That click performs the required Hyprland Lua config integration automatically; the user does not manually edit a file in the normal path.

### Success criteria

- Standard install is `omarchy plugin add <repository-url> --enable`, followed by one consent click.
- Super-down reaches an already-loaded guide with p95 event-to-visible latency below 50 ms.
- The guide never accepts keyboard or pointer input and never changes shortcut behavior.
- Ordinary typing, passwords, commands, window titles, and unmatched keycodes never leave Hyprland and are never persisted.
- Existing bindings retain their original dispatcher types and `hyprctl binds` metadata.
- Regular files, symlinked files, symlinked parent directories, and user-owned Git dotfiles receive an exact preview and safe transactional patch.
- Unsafe or immutable configurations remain usable in browse-only mode and receive a manual fallback snippet.
- State is local, aggregate-only, permission-restricted, and clearable.

### Explicit v1 exclusions

- `/dev/input`, evdev listeners, root access, the `input` group, or a general keylogger.
- A compiled Hyprland plugin, a patched Hyprland package, or a Hyprland fork.
- Mouse binding tracking.
- Neovim, Tmux, Ghostty, browser, and other application-local bindings.
- Mouse-action inference such as guessing that a click could have been a shortcut.
- Cloud telemetry, accounts, leaderboards, or remote speech services.
- Voice search; retain an extension point, but implement it after v1.

## 2. Why this architecture

Omarchy Quattro hosts third-party QML plugins inside one long-running Quickshell process. A plugin may provide a bar widget, service, and overlay. The service is the correct owner for shared state and the pre-created guide window.

Hyprland’s public socket2 event stream does not emit a “binding fired” event. Hyprland 0.56.2 does expose `hl.on("input.keyboard.key", callback)` to its Lua configuration. That callback runs immediately before Hyprland resolves keybindings, so it can observe a candidate chord without replacing its dispatcher.

The chosen design is therefore:

```text
physical keyboard
  → Hyprland input.keyboard.key Lua callback
  → constant-time lookup in a generated allowlist
  → hl.dsp.event("keybind-dojo:...")
  → Hyprland socket2 custom event
  → Quickshell Hyprland.rawEvent
  → Keybind Dojo service
  → guide UI + aggregate statistics
```

This is an observed-activation transport, not proof that the dispatcher executed. Shortcut inhibitors, input-capture sessions, or other compositor conditions can rarely prevent dispatch after the raw event. The UI and documentation must use “observed” terminology. V1 does not infer confirmation by correlating unrelated workspace/window events; exact confirmation is reserved for a future compositor event.

Do not wrap `o.bind` or `hl.bind`, replace dispatchers with Lua closures, register duplicate observer bindings, parse debug logs, or launch a process for every event. Those alternatives either change behavior/metadata, miss events, create privacy risk, or add latency.

## 3. Repository and plugin structure

The implemented repository will have this shape:

```text
manifest.json
BarWidget.qml
Panel.qml
Overlay.qml
Service.qml
SuperGuide.qml
bridge.lua
js/
  Catalog.js
  Recommendations.js
  Stats.js
scripts/
  bridge-control
  generate-catalog
tests/
  fixtures/
  qml/
  shell/
docs/
  PLAN.md
  SECURITY.md
  TROUBLESHOOTING.md
  tasks/
README.md
LICENSE
```

Do not write generated or runtime files into the Git checkout. Runtime state belongs under `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/keybind-dojo/`.

### Manifest contract

The final manifest is:

```json
{
  "schemaVersion": 1,
  "id": "io.github.sai.keybind-dojo",
  "name": "Keybind Dojo",
  "version": "0.1.0",
  "author": "Sai",
  "license": "MIT",
  "description": "A local-first, gamified Omarchy keybinding guide.",
  "kinds": ["bar-widget", "service", "overlay"],
  "entryPoints": {
    "barWidget": "BarWidget.qml",
    "service": "Service.qml",
    "overlay": "Overlay.qml"
  },
  "barWidget": {
    "displayName": "Keybind Dojo",
    "category": "Learning",
    "allowMultiple": false,
    "defaultSection": "right",
    "defaults": {
      "guideDelayMs": 0,
      "showInFullscreen": false
    },
    "schema": [
      {
        "key": "guideDelayMs",
        "type": "integer",
        "label": "Super Guide delay (ms)"
      },
      {
        "key": "showInFullscreen",
        "type": "boolean",
        "label": "Show over fullscreen windows"
      }
    ]
  }
}
```

The service loads whenever the plugin is enabled through its bar entry. The full overlay loads on demand. `SuperGuide.qml` is instantiated by the service at startup and stays hidden until needed.

## 4. Binding catalog

### Sources

Build the catalog from the running system, not from a static manual:

1. Parse plain `hyprctl binds`; do not depend on `hyprctl -j binds` because affected Hyprland versions have emitted malformed bind JSON.
2. Reuse the behavior of Omarchy’s `omarchy-menu-keybindings` implementation for Lua-only `__lua` binds and missing `code:` keys.
3. Use the active XKB keymap to translate named keysyms to XKB keycodes. Prefer `xkbcli dump-keymap-wayland` plus `xkbcli how-to-type --keysym --keymap` and handle multiple valid keycodes.
4. Normalize modifier order to `SUPER`, `SHIFT`, `CTRL`, `ALT` and normalize aliases such as `CONTROL` to `CTRL`.
5. Include press/release phase and submap when available.

### Public catalog format

Write `${stateDir}/catalog.json` atomically with mode `0600`:

```json
{
  "schemaVersion": 1,
  "generatedAt": 1787750000,
  "sourceHash": "sha256:...",
  "bindings": [
    {
      "id": "sha256:opaque-id",
      "combo": "SUPER + RETURN",
      "modifiers": ["SUPER"],
      "key": "RETURN",
      "xkbCodes": [36],
      "description": "Terminal",
      "category": "applications",
      "phase": "press",
      "submap": "",
      "dispatcherKind": "exec",
      "trackable": true,
      "guideEligible": true
    }
  ]
}
```

Derive `id` from a SHA-256 hash of normalized combo, description, dispatcher kind, dispatcher argument, phase, and submap. The dispatcher argument participates in the hash but must not be written to `catalog.json` or any statistics file.

Categories are deterministic keyword-based classifications with these values only:

```text
windows, workspaces, applications, system, capture, media, clipboard, notifications, style, other
```

Unknown bindings use `other`; agents must not invent additional categories.

### Bridge lookup format

Write `${stateDir}/bridge-catalog.lua` atomically with mode `0600`. It contains only lookup keys and opaque IDs:

```lua
return {
  schemaVersion = 1,
  sourceHash = "sha256:...",
  modifierCodes = {
    SUPER = { 133, 134 },
    SHIFT = { 50, 62 },
    CTRL = { 37, 105 },
    ALT = { 64, 108 }
  },
  matches = {
    ["SUPER|36|press|"] = "sha256:opaque-id"
  }
}
```

Lua string serialization must escape all values safely. Descriptions, commands, and dispatcher arguments must never appear in this file.

Regenerate on startup and after `configreloaded` or active-layout changes. Compare `sourceHash`; do nothing when unchanged. If the bridge lookup changes while tracking is enabled, perform at most one additional guarded `hyprctl reload`, using a reload-generation guard to prevent a loop.

## 5. Hyprland bridge

`bridge.lua` is loaded by the user’s Hyprland Lua config through one guarded `pcall(dofile, ...)` block.

At config evaluation, it may read `bridge-catalog.lua` once. The keyboard callback itself must never read files or start processes. A missing, malformed, wrong-schema, or incomplete bridge catalog fails closed: the bridge registers no input callback and emits no event.

The bridge will:

- Subscribe to `input.keyboard.key` and `keybinds.submap`.
- Track left/right Super, Shift, Ctrl, and Alt states using generated XKB modifier keycodes.
- Treat Wayland state `1` as press and `0` as release.
- On Super press/release, emit guide lifecycle events even if no binding matches.
- On modifier changes while Super is held, emit the canonical modifier mask.
- Look up non-modifier events by modifier mask, XKB code, phase, and submap.
- Emit a matched opaque ID only when the lookup contains that exact event.
- Ignore unmatched input immediately.
- Avoid recursive callbacks and duplicate press/release accounting.

Socket2 custom event payloads are versioned:

```text
keybind-dojo:v1:super:down
keybind-dojo:v1:super:up
keybind-dojo:v1:mods:SUPER_SHIFT
keybind-dojo:v1:match:<opaque-id>:press
keybind-dojo:v1:match:<opaque-id>:release
```

No other event shapes are accepted. Malformed or unknown-version events are ignored by the service.

## 6. Configuration inspection and patching

### Controller interface

`scripts/bridge-control` exposes commands that print one JSON object and use nonzero exit status on failure:

```text
bridge-control inspect
bridge-control enable --expected-hash <sha256>
bridge-control disable --expected-hash <sha256>
bridge-control status
bridge-control manual-snippet
```

QML must invoke this program with a `Process` argument array; never interpolate paths or output into a shell command.

`inspect` is read-only and returns:

```json
{
  "schemaVersion": 1,
  "logicalPath": "/home/user/.config/hypr/hyprland.lua",
  "resolvedPath": "/home/user/dotfiles/hypr/hyprland.lua",
  "symlinked": true,
  "gitManaged": true,
  "gitRoot": "/home/user/dotfiles",
  "gitDirty": false,
  "fileType": "regular",
  "ownerUid": 1000,
  "mode": "0644",
  "writable": true,
  "safeToPatch": true,
  "reasonCode": "ok",
  "currentHash": "sha256:...",
  "managedBlockState": "absent",
  "proposedDiff": "..."
}
```

Use stable `reasonCode` values:

```text
ok, missing, dangling-symlink, symlink-loop, non-regular, wrong-owner,
not-writable, outside-safe-root, multiple-hardlinks, duplicate-markers,
malformed-markers, changed-since-inspect, syntax-error, hyprland-error,
concurrent-change, unsupported
```

### Symlink and dotfiles policy

Resolve the full logical path, including symlinked parent directories. Preserve the symlink and patch its final target.

Automatic patching is allowed only when the final target:

- Exists and is a regular file.
- Is owned and writable by the current UID.
- Has exactly one hard link.
- Is under `$HOME`, or is inside a Git worktree whose root is owned and writable by the current UID.
- Has zero or one well-formed Keybind Dojo managed block.

Git-managed targets remain eligible. The onboarding screen shows the logical path, resolved target, Git root, dirty state, and exact diff before the button is enabled.

Refuse automatic edits for dangling/cyclic symlinks, non-regular files, unsafe ownership, immutable/unwritable files, external non-Git targets, hard-linked files, ambiguous markers, or files changed since inspection. Stay browse-only, explain the exact reason, and offer the loader snippet. Never request `sudo`.

### Transaction

On enable or disable:

1. Acquire `${stateDir}/bridge-control.lock` with `flock`.
2. Re-resolve and verify device, inode, ownership, and expected SHA-256.
3. Save contents and metadata under `${stateDir}/backups/`; never create `.bak` files in the dotfiles repository.
4. Preserve file mode and line-ending style.
5. Add or remove only the exact marker block.
6. Append after Omarchy bootstrap/default loading. If a top-level final `return` prevents appending, insert immediately before it.
7. Validate the candidate with `luac -p` before replacement.
8. Create the temporary file in the target directory and rename it atomically over the resolved target.
9. Run `hyprctl reload`, wait for completion, then run `hyprctl configerrors`.
10. If errors are reported, roll back only when the current hash still equals the expected patched hash; otherwise report `concurrent-change` and preserve both versions.

`Disable tracking` uses the same transaction and removes only the marked block.

The service checks integration status on startup, on relevant file changes, and every 30 seconds. If a dotfile deployment removes the block or retargets the symlink, mark tracking disconnected and never reinsert automatically.

Omarchy currently has no plugin uninstall hook. Removing the repository can leave the guarded block. The missing `dofile` is swallowed by `pcall`, so it remains inert. Documentation must recommend `Disable tracking` before `omarchy plugin remove`.

## 7. Quickshell service and interfaces

`Service.qml` is the single owner of runtime state. It receives `shell` and `manifest` from Omarchy.

It must expose these properties and methods for the bar widget, panel, and overlay:

```qml
property string integrationState // disabled, enabling, enabled, disconnected, error
property var integrationDetails   // last bridge-control JSON result
property var catalog              // normalized catalog object
property var stats                // normalized stats object
property bool guideVisible
property string activeModifiers
property string highlightedBindingId
property int guideDelayMs
property bool showInFullscreen
property bool desktopLocked
property bool credentialPromptActive
property bool activeWindowFullscreen

function inspectIntegration()
function enableIntegration(expectedHash)
function disableIntegration(expectedHash)
function regenerateCatalog()
function clearLocalData()
function openGuide()
function closeGuide()
function bindingForId(id)
function recommendations(limit)
```

Listen to `Quickshell.Hyprland.Hyprland.rawEvent`. Accept only `custom` events beginning with `keybind-dojo:v1:`. Never evaluate payload content as code.

The service reads bar settings from the plugin’s entry in `shell.shellConfig.bar.layout` and updates them through `shell.updateEntryInline`. Do not create a second preferences file.

The bar widget accesses the singleton through `bar.shell.serviceFor(moduleName)`. `Overlay.qml` declares `property var service`; Omarchy injects the matching service automatically.

For suppression state, read `locked` from `shell.serviceFor("omarchy.lock")` and `dialogVisible` from `shell.serviceFor("omarchy.polkit")` when those properties exist. Maintain `activeWindowFullscreen` with a debounced `hyprctl -j activewindow` query at service startup and after `activewindow`, `activewindowv2`, or `fullscreen` socket events. Parse only the documented boolean/integer fullscreen field, record query failure in session diagnostics, and never run this query from the Super/input-event path.

## 8. Super Guide

`SuperGuide.qml` creates one visual-only layer-shell window per screen but sets only the focused monitor’s instance visible.

Required behavior:

- Default delay: `0` ms.
- Supported settings: `0`, `80`, `150`, `250`, and disabled.
- No keyboard focus.
- Empty pointer mask.
- `ExclusionMode.Ignore`; never reserve desktop space.
- Use Omarchy `Style`, `Color`, and `Border` tokens.
- If the bar is at the top, position below it; otherwise use the top screen edge.
- Hide on Super release, plugin disable, shell lock, catalog error, or integration disconnect.
- Suppress while an Omarchy credential surface is active where its service exposes state.
- Suppress over fullscreen windows when `showInFullscreen` is false.

Content rules:

- Super alone shows direct Super bindings, the daily recommendation, and modifier lanes for Shift/Ctrl/Alt.
- Adding modifiers filters to the exact canonical modifier set.
- Show at most 12 exact commands; append a `+N more` affordance when truncated.
- Sort the daily recommendation first, then never-used bindings, then description alphabetically.
- Highlight a matched binding for 140 ms before hiding, unless Super remains held for another chord.
- A fluent chord completed before the first rendered frame may result in no visible flash; this is desirable.

The guide is display-only. Users open the full overlay from the bar when they want to search or interact.

## 9. Bar panel and full overlay

### Bar widget

Show a compact belt icon and streak. If the integration is disabled or broken, show a small status indicator without exposing error text directly in the bar.

Left click opens `Panel.qml`. The panel contains, in order:

1. Integration status.
2. Logical/resolved path, Git status, and proposed diff during onboarding.
3. Enable/disable/recheck controls.
4. Guide delay selector and fullscreen toggle.
5. Daily recommendation.
6. XP, streak, unique count, most-used, and least-used summaries.
7. `Open Dojo` and `Clear local data` actions.

Any destructive reset requires an in-panel confirmation state; no separate desktop prompt.

### Full overlay

`Overlay.qml` is keyboard-interactive only while open and supports Escape to close. It contains four fixed tabs:

```text
Bindings, Practice, Progress, Settings
```

- Bindings: searchable catalog, deterministic categories, combo and description.
- Practice: daily recommendation followed by due/never-used bindings.
- Progress: aggregate heat map, XP, level, streak, most/least used.
- Settings: the same integration and guide controls as the panel, plus data reset.

Do not execute a binding from the catalog in v1. Practice means recalling or physically using the real shortcut; the bridge records the observation.

## 10. Statistics and recommendations

Write `${stateDir}/stats.json` atomically with mode `0600`; the state directory uses `0700`. Maintain no raw event log.

```json
{
  "schemaVersion": 1,
  "totalXp": 420,
  "currentLevel": 2,
  "streak": 4,
  "lastQualifiedDay": "2026-08-26",
  "bindings": {
    "sha256:opaque-id": {
      "count": 18,
      "firstUsed": 1787700000,
      "lastUsed": 1787750000,
      "daily": {
        "2026-08-26": 5
      }
    }
  },
  "dailyQuest": {
    "date": "2026-08-26",
    "bindingId": "sha256:opaque-id",
    "completed": true
  }
}
```

Batch writes five seconds after the first dirty change and again on service destruction. Keep at most 90 daily buckets per binding.

XP rules are fixed:

- First-ever observation of a binding: 50 XP.
- First observation of that binding on a day: 10 XP.
- Additional observations that day: 2 XP, capped at 20 repeat XP per binding per day.
- Daily quest completion: additional 25 XP once.

Level thresholds and names are fixed:

```text
0 Initiate
200 Apprentice
600 Tiler
1200 Navigator
2000 Omarchist
3500 Sensei
```

A day qualifies for the streak after three distinct bindings are observed. Missing a day resets the active streak but never removes XP.

The daily quest is deterministic for a date and current stats. Rank trackable bindings by:

1. Never used.
2. Longest time since last use.
3. Lowest lifetime count.
4. Opaque ID lexical order as the stable tie-breaker.

Exclude hardware/media bindings unavailable on the current machine and bindings whose catalog entry is no longer active.

## 11. Security and failure behavior

- Treat plugin QML, scripts, and Lua as unsandboxed user code and keep dependencies auditable.
- Never use `eval`, `source` generated shell text, or construct shell command strings from QML.
- Use `jq --arg` or equivalent safe serializers for JSON.
- Use Lua `%q`-style serialization or a purpose-built encoder for generated Lua values.
- Never persist dispatcher arguments.
- Never write into `$OMARCHY_PATH`, `/usr/share/omarchy`, or the plugin Git checkout at runtime.
- Never invoke `sudo`, `pkexec`, a package manager, or a remote API.
- Ignore malformed event payloads, catalog entries, and stats instead of crashing `omarchy-shell`.
- On corrupt stats, move the file to `${stateDir}/recovery/` and start clean; do not delete it.
- Browse-only mode must remain available after every bridge/configuration error.

## 12. Feasibility gate and performance budget

Before building gamification or the full overlay, complete the live feasibility task.

Pass criteria:

- Hyprland loads the guarded bridge with no config error.
- 50 representative Omarchy bindings still execute correctly.
- `hyprctl binds` reports the same dispatcher metadata before and after enabling.
- Ordinary typing produces zero Keybind Dojo socket events.
- Matched test chords produce exactly one expected event per configured phase.
- Super-down to guide visibility has p95 below 50 ms over at least 100 samples.
- Idle CPU attributable to the bridge/service remains below 0.2% averaged over five minutes.
- No per-event process creation or file operation appears in tracing/log inspection.

If any pass criterion fails, stop. Do not silently switch to evdev, dispatcher wrapping, duplicate binds, a C++ plugin, or a patched compositor. Record the failure and keep the plugin browse-only while the design is revisited.

## 13. Compatibility and future transport

Initial support is Omarchy Quattro and Hyprland 0.56.2+. Capability detection, not version comparison alone, controls bridge availability.

Keep event ingestion behind one service function so a future exact event can replace the candidate bridge. The preferred long-term upstream change is a documented socket2 event emitted after successful binding dispatch with a stable binding identifier. Do not distribute a patched Hyprland build merely to obtain it. If an exact transport is adopted later, introduce confirmation semantics through a new state schema rather than reinterpreting v1 observations.

Voice search may later add a local transcription adapter that returns text to the existing catalog search and practice queue. It must never execute transcript text as a command and must remain optional.

## 14. Required validation commands

Every implementation task runs the checks relevant to its files. Before release, all of these must pass:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml Panel.qml Overlay.qml Service.qml SuperGuide.qml
luac -p bridge.lua
tests/shell/run
```

Live Hyprland changes additionally require:

```sh
hyprctl reload
hyprctl configerrors
```

`hyprctl configerrors` must be empty. Automated tests must use temporary fixture trees and must never patch the operator’s real config.

## 15. Implementation sequence

Work is split into dependency-ordered briefs under `docs/tasks/`. Agents must execute only one task at a time and must not implement future-task features opportunistically.

The sequence is:

1. Repository and plugin skeleton.
2. Catalog generator and pure model.
3. Read-only configuration inspector.
4. Transactional configuration patcher.
5. Lua bridge and isolated tests.
6. Live feasibility gate.
7. Production service and event protocol.
8. Instant Super Guide.
9. Bar widget, onboarding, and settings panel.
10. Aggregate persistence.
11. Recommendations, XP, levels, and streaks.
12. Full Dojo overlay.
13. Dotfiles and failure-mode hardening.
14. Integration, privacy, and performance tests.
15. Documentation and release packaging.

The task index defines the exact entry/exit criteria for each step.
