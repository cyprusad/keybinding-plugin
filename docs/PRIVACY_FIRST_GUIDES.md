# Privacy-first guide coverage

Status: in progress — phase 1 generic Hyprland guides

## Goal

First, extend the existing visual reference from Super to every standard
Hyprland modifier root. Selection and data-minimization changes follow as
separate work so the guide behavior can be verified independently.

The transient guide should work for modifier roots:

- `SUPER GUIDE`
- `CTRL GUIDE`
- `ALT GUIDE`
- `SHIFT GUIDE`

Adding a modifier shows the exact chord lane under that guide root. A bare-key
binding remains browseable in the full Dojo but has no hold-to-reveal guide.

## Phase 1: generic Hyprland guides

Under the existing integration consent, holding the first of `SUPER`, `CTRL`,
`ALT`, or `SHIFT` opens the corresponding guide. Adding other modifiers shows
the exact chord lane; releasing the first-held root closes that session.

This phase does not change catalog generation, matching, stored statistics, or
the current consent model. It is intentionally limited to guide lifecycle and
presentation.

## Phase 2: privacy boundary and selection

The Hyprland callback necessarily receives keycode press/release events, but
the generated bridge allowlist is the boundary for what may leave that callback.
The UI must not be the only filter.

1. The catalog continues to list all discovered bindings locally.
2. A small local policy records only selected opaque binding IDs and enabled
   guide roots; it has mode `0600` and contains neither text input nor commands.
3. Catalog generation compiles that policy into `bridge-catalog.lua`.
4. The bridge emits a match only for a selected, unambiguous binding ID.
5. The bridge emits guide lifecycle events only for opted-in roots. `SUPER` is
   initially the only root enabled.
6. The service drops all guide and match events while locked or during a known
   credential prompt. No shortcut observation is persisted.

This remains an allowlisted raw-input observer, not a claim that the callback
never sees keyboard events. Documentation and the later Settings UX must say
so plainly.

## Selection model (future phase)

Each discovered binding has one inclusion toggle:

- **Included**: may appear in its applicable guide and may produce an
  in-memory highlight while that guide is open.
- **Excluded**: stays visible in the catalog but is omitted from guides and
  excluded from the bridge match allowlist.

The initial policy includes existing `SUPER` bindings so the current guide
continues working after migration. All non-Super entries are excluded until a
user opts in. Root switches control whether holding `CTRL`, `ALT`, or `SHIFT`
can open a guide; they do not implicitly include every binding in that lane.

Bindings with the same normalized modifier mask, physical keycode, phase, and
submap are ambiguous. They remain browseable but cannot be selected for bridge
matching until the active Hyprland configuration makes them unambiguous. This
avoids attributing one physical chord to the wrong action.

## Generic guide lifecycle

Generic, versioned guide events carry the held root and current canonical
modifier mask. The Lua
bridge owns the physical first-held root and closes the guide when that root is
released, so `SHIFT` followed by `CTRL` is a `SHIFT GUIDE` lane and releases
cleanly even when Ctrl remains held.

The service freezes the root, mask, card order, and selected subset for one
guide session. `SuperGuide.qml` derives its header from that root, for example
`ALT GUIDE` with `Hold ALT · Add SHIFT / CTRL / SUPER` guidance. The existing
canopy, hover reveal, monitor routing, contrast treatment, and non-interactive
behavior are reused.

## Potential later simplification: remove activity tracking and gamification

If confirmed after the guide and selection work, the product can stop retaining
key-use history. That later change would remove:

- aggregate counts, dates, and the stats writer/recovery files;
- XP, levels, streaks, daily quests, recommendations, and practice scoring;
- Progress and Practice overlay sections and bar progress summaries.

Keep only transient in-memory highlighting while a guide session is open.
The remaining local state is the regenerated catalog, bridge lookup/control
files, integration backups, and the explicit selection policy.

Existing `stats.json` is not migrated into new data. The removal migration
offers a clear-local-data action and documents that pre-existing stats may be
deleted by the user; it never converts history into the policy.

## Delivery order

1. Generalize the Lua and service protocol for all four modifier-root guides.
2. Generalize guide filtering/header copy and test all modifier lanes.
3. Add pure policy parsing, schema validation, collision detection, and tests.
4. Compile selection into the bridge allowlist; default to selected `SUPER`
   bindings only. Add locked/credential event dropping.
5. If confirmed, remove persistent activity tracking and gamification, including tests and
   stale documentation.
6. In UX Polish 02, redesign the clickable overlay around shortcut selection,
   guide-root switches, catalog browsing, and an easily reachable security
   README.

## Future application-local sources

Tmux and Herdr bindings are not Hyprland bindings, so they cannot become guide
cards merely by enabling `CTRL GUIDE`. A future context-aware source can read
their declared configuration (for example `tmux list-keys`) when the matching
application is focused. It should be a reference-only integration: no raw
application keystroke observation, no tracking, and no command execution.

Omarchy's Learn menu already supplies two useful read-only sources:

- `omarchy-menu-tmux-keybindings --print` starts an isolated temporary Tmux
  server, reads the resolved user configuration, and prints annotated bindings.
- `omarchy-menu-herdr-keybindings --print` combines Herdr defaults with the
  user's TOML overrides and prints the resulting bindings.

Omakeez should treat these as provider adapters, not scrape their menu UI.
The same adapter shape can support future applications:

```text
provider id + label + availability/context predicate
  -> read-only binding records { combo, description, mode/context }
  -> visual cards in the focused application's guide/overlay
```

Providers may enrich the catalog for browsing and visual reference, but they
never enter the Hyprland bridge match table. This preserves the distinction
between global Hyprland shortcuts and application-local documentation. A later
provider registry can load built-in adapters plus explicitly installed local
provider descriptors, with validation and no network access.

## Manual gates

- Consent preview clearly explains the allowlisted input observer and default
  scope before enabling integration.
- `SUPER GUIDE` works after migration without selecting non-Super entries.
- Opting into one `ALT` or `CTRL` binding enables only that exact unambiguous
  chord and its opted-in guide root.
- Typing ordinary content produces no policy change, no files, and no emitted
  match for excluded bindings.
- Lock-screen and credential-prompt checks produce no visible guide or
  in-memory highlight.
- Existing `stats.json` can be cleared and is not read by the visual-reference
  build.
