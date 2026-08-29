# Omakeez

> Pre-release: UX polish and final release smoke testing are still in progress.

Omakeez is a local-first Omarchy plugin that helps you learn the
keybindings you already use. Hold Super to see a visual guide for the focused
workspace, browse the full catalog, practice bindings, and review aggregate
progress.

## Install

Validated with Omarchy 4.0.1-1, Quickshell 0.3.1, and Hyprland 0.56.2.

```sh
omarchy plugin add https://github.com/cyprusad/keybinding-plugin.git --enable
```

The bar widget opens browse-only mode first. Choosing **Enable tracking and
Super Guide** shows the exact proposed diff, then edits the resolved
Hyprland Lua target through a guarded controller after consent. Symlinks are
preserved and user-owned Git-managed targets are supported when they pass the
safety checks. Unsafe targets remain usable in browse-only/manual-fallback
mode.

## Using the guide

The guide follows the monitor containing the focused workspace. Settings control
the Super Guide delay, fullscreen visibility, and local data. The full overlay
contains Bindings, Practice, Progress, and Settings sections. Press `Esc` or
the visible **Close overlay** control to leave it.

The plugin records observed candidate activations using opaque binding IDs. It
does not claim to be an exact dispatcher-execution logger or a general
keylogger: a candidate activation can be observed without proving that
Hyprland completed the command.

## Local data

Data is stored locally under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/omakeez/
```

The catalog and bridge lookup contain binding metadata needed for display and
matching. `stats.json` contains aggregate counts, dates, XP, streaks, and
daily-quest state; it does not contain typed text, passwords, commands,
window titles, application names, or raw key logs. Settings explains the data
boundary and **Clear local data** archives the current stats file before
starting a fresh profile.

Disable tracking before removing the plugin:

```sh
omarchy plugin disable io.github.cyprusad.omakeez
omarchy plugin remove io.github.cyprusad.omakeez
```

Updates preserve local state and the managed integration:

```sh
omarchy plugin update io.github.cyprusad.omakeez --yes
```

For recovery and audit procedures, see [SECURITY.md](docs/SECURITY.md) and
[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md). The release evidence is in
[docs/RELEASE_TESTS.md](docs/RELEASE_TESTS.md).
