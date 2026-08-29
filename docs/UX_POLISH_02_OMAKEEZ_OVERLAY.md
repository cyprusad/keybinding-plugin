# UX Polish 02 — Omakeez overlay

Status: planned

## Product decision

Rename the user-facing product from **Omakeez** to **Omakeez**. Retain
the stable plugin ID `io.github.cyprusad.omakeez` so installed copies keep
receiving updates without migration or a duplicate plugin entry.

Omakeez is a visual, local-first reference for configured shortcuts. It is not
a game, productivity tracker, or shortcut-use analytics product.

## Data minimization

Remove all usage/activity persistence and gamification:

- no per-binding counts, first/last-used dates, daily buckets, or `stats.json`;
- no XP, levels, streaks, daily quests, recommendations, or practice scoring;
- no progress badge or streak number in the bar;
- no Progress or Practice sections in the full overlay.

Keep only the local files required to operate the guide safely:

- `catalog.json` and `bridge-catalog.lua`, regenerated from the active
  Hyprland configuration;
- the bridge control lock and recovery backups needed for safe integration;
- later, an explicit guide-selection policy if the user enables it.

These files contain configured shortcut metadata and opaque IDs, never typed
content, per-use history, commands, window titles, application activity, or
network telemetry.

## Panel: concise integration control

The bar-panel view should contain only:

1. **Omakeez** heading and a compact connection status.
2. **Hyprland integration** section:
   - enabled/disabled state;
   - resolved config path;
   - a `View integration change` control that exposes the exact managed diff;
   - `Disable integration` or `Enable integration` as the primary action.
3. **Guide behavior**:
   - one explicit toggle: `Show guide over full-screen apps`;
   - helper text: normally guides stay hidden over games, video, and other
     full-screen apps; turn this on only when an overlay is wanted there.
4. **Security**:
   - `Read security and privacy` opens the public security documentation in a
     browser.
5. **Open Omakeez** to browse the catalog; this is optional if the eventual
   overlay makes the panel redundant.

Remove the delay chooser, activity summary, persistence diagnostics, local-data
reset button, XP/quest language, and any count beside the bar icon.

## Full overlay direction

The full Omakeez overlay becomes a clean reference browser. This pass removes
Practice, Progress, and statistics; a later visual pass can redesign its
Bindings and Settings surfaces around:

- searchable configured bindings;
- category/filtering and guide inclusion controls;
- enabled `SUPER`/`CTRL`/`ALT`/`SHIFT` guide roots;
- an easily reachable explanation of the allowlisted input observer;
- future read-only provider cards for Tmux, Herdr, and other applications.

No logo work is required for this pass.

## Delivery order

1. Rebrand user-facing labels, manifest display text, panel, bar, overlay,
   README, and security documentation as Omakeez.
2. Delete the stats/recommendation/gamification pipeline and its storage files.
   Preserve transient in-memory guide highlights only.
3. Remove badge/count rendering from the bar and the progress/practice UI.
4. Reduce the panel to integration, fullscreen explanation, browser security
   link, and catalog access.
5. Add tests proving no activity file is created or written after matched
   shortcuts, plus regression tests for guide highlighting and integration.
6. Perform a manual security/UX gate and then start the detailed full-overlay
   visual design.

## Manual gate

- Omakeez has no user-facing “Dojo,” XP, streak, quest, or tracking language.
- The bar has no activity badge.
- A matched shortcut does not create or modify `stats.json` or another
  activity-history file.
- The panel accurately shows integration state and the exact managed config
  change before destructive actions.
- The full-screen toggle explanation is understandable without prior context.
- Security documentation opens from the panel and matches the implementation.
