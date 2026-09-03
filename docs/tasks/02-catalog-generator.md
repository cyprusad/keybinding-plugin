# Task 02 — Binding Catalog Generator

## Objective

Implement deterministic, privacy-preserving generation of `catalog.json` and `bridge-catalog.lua` from Hyprland and XKB data.

## Depends on

Task 01.

## Required interfaces

Create `scripts/generate-catalog` with this CLI:

```text
generate-catalog --output-dir <directory>
generate-catalog --hyprctl-file <fixture> --keymap-file <fixture> --output-dir <directory>
```

The first form performs read-only discovery from the live session. The second form must not call Hyprland and is used by tests.

On success, print one JSON status object:

```json
{"ok":true,"sourceHash":"sha256:...","bindingCount":123,"changed":true}
```

On failure, print one JSON error object to stderr and return nonzero:

```json
{"ok":false,"code":"hyprctl-unavailable","message":"..."}
```

## Required behavior

1. Parse plain `hyprctl binds` records, including modifier mask, key, keycode, description, dispatcher, argument, submap, and release/repeat flags when exposed.
2. Reproduce the installed Omarchy keybinding helper’s recovery for Lua-only `__lua` records. Keep the recovery code isolated and covered by fixtures.
3. Normalize combos and modifier aliases exactly as specified in `PLAN.md`.
4. Resolve named keysyms through the supplied/live XKB keymap. A binding may have multiple valid XKB codes; sort and deduplicate them numerically.
5. Assign only the fixed plan categories. Put unmatched descriptions in `other`.
6. Compute opaque IDs with the dispatcher argument included in the hash but never serialize that argument.
7. Generate the `modifierCodes` table for left/right Super, Shift, Ctrl, and Alt from the active/supplied XKB keymap; sort and deduplicate codes.
8. Mark mouse bindings untrackable and guide-ineligible instead of dropping them from `catalog.json`; omit them from `bridge-catalog.lua`.
9. Create or repair the user-owned output directory with mode `0700`, reject
   symlinked or foreign-owned output directories, and write both output files
   through same-directory temporaries followed by atomic rename with mode
   `0600`.
10. Produce byte-for-byte identical files for identical normalized inputs except `generatedAt`. To preserve change detection, do not rewrite files when `sourceHash` is unchanged.
11. Safely encode generated Lua; no fixture content may escape its quoted value or become executable syntax.

## Test fixtures

Add fixtures for:

- Standard Super binding with a named key.
- Numeric `code:` binding.
- Lua `__lua` record with recovered metadata.
- Release-only binding.
- Binding in a submap.
- Media key with no modifier.
- Mouse binding.
- Duplicate records.
- Comma/slash/minus/equal aliases.
- Two keyboard layouts with different physical mappings.
- Descriptions and commands containing quotes, commas, newlines, dollar signs, and Lua delimiters.

## Validation

```sh
tests/shell/run catalog
tmp_dir="$(mktemp -d)"
scripts/generate-catalog --output-dir "$tmp_dir"
jq -e '.schemaVersion == 1 and (.bindings | type == "array")' "$tmp_dir/catalog.json"
luac -p "$tmp_dir/bridge-catalog.lua"
```

The temporary directory may be removed after inspection.

## Acceptance criteria

- Fixture outputs match the formats in `PLAN.md`.
- No dispatcher argument occurs in either generated file.
- Generated Lua remains valid under adversarial fixture strings.
- Generated Lua contains complete, nonempty modifier code sets for the active keymap.
- Live read-only generation succeeds on the development machine without changing Hyprland or Omarchy state.
- A second identical run reports `changed:false` and leaves file mtimes unchanged.

## Out of scope

Loading the Lua bridge, modifying user configuration, receiving socket events, and calculating statistics.
