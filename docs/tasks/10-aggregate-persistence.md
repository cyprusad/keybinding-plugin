# Task 10 — Aggregate Usage Persistence

## Objective

Persist observed usage safely without retaining a raw event history.

## Depends on

Task 07.

## Required implementation

Implement pure functions in `js/Stats.js` and integrate them into `Service.qml`.

### Load

- Read `${stateDir}/stats.json` asynchronously.
- Validate every field and normalize missing optional fields.
- Reject wrong schema, negative counts, invalid dates/timestamps, unknown top-level types, and non-opaque binding IDs.
- On corruption, atomically move the original to `${stateDir}/recovery/stats-<UTC>-<hash>.json`, set `statsState: recovered`, and initialize empty state.

### Record

- Record only catalog-known opaque IDs received through valid match events.
- Maintain count, first/last timestamps, and per-day count.
- Use local calendar dates in `YYYY-MM-DD` for daily buckets.
- Retain at most the newest 90 daily buckets per binding.
- Duplicate identical event messages in the same service turn count once; later repeated physical uses count normally.

### Save

- Mark state dirty after a valid change.
- Start one five-second single-shot flush timer on the first dirty change.
- Write through a same-directory temporary and atomic rename with mode `0600`.
- Flush again on service destruction when possible.
- Never write per keyboard event.

### Reset

`clearLocalData()` requires a confirmation parameter from UI, resets in memory, and archives the previous stats in `recovery/` rather than deleting it permanently. Retain at most five recovery copies, deleting only the oldest Keybind Dojo-owned recovery file.

## Tests

- Empty/missing state.
- Valid round trip.
- Every invalid field family.
- Corrupt recovery.
- Atomic write failure preserving the previous valid file.
- Five-second batching under many events.
- 90-day pruning.
- Unknown catalog ID ignored.
- Reset and five-copy recovery retention.
- State directory/file permission assertions.

Use a fake clock in pure tests; do not depend on wall-clock timing.

## Validation

```sh
tests/shell/run stats
qmllint -I "$OMARCHY_PATH/shell" Service.qml
```

## Acceptance criteria

- No raw events, keycodes, descriptions, commands, or window data are persisted.
- A burst of events produces one batched write.
- Corruption cannot crash the shell or silently destroy the original file.
- Reset affects only files owned by Keybind Dojo inside its state directory.

## Out of scope

XP, quests, levels, streak calculation, heat-map presentation, and cloud export.
