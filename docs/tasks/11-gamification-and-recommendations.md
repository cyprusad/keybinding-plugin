# Task 11 — Gamification and Recommendations

## Objective

Implement deterministic XP, levels, streaks, daily quests, and binding recommendations as pure logic, then expose them through the service.

## Depends on

Tasks 02 and 10.

## Required pure API

Implement in `js/Recommendations.js` and `js/Stats.js`:

```text
recordObservation(stats, bindingId, timestamp) -> newStats
levelForXp(totalXp) -> { index, name, threshold, nextThreshold }
qualifiesForDay(stats, date) -> boolean
recalculateStreak(stats, today) -> integer
chooseDailyQuest(catalog, stats, date) -> bindingId|null
recommendBindings(catalog, stats, limit, date) -> bindingId[]
```

Functions must not mutate their arguments, read files, access QML objects, or use randomness.

## Fixed rules

Use exactly the XP, level, streak, ranking, and tie-break rules in `PLAN.md` section 10.

Additional clarifications:

- First-ever XP and first-of-day XP both apply on the first observation.
- The 25 quest bonus applies in addition to normal observation XP.
- Re-observing after the daily repeat cap still increments count but awards zero repeat XP.
- Quest selection is frozen for the local date once written unless the binding disappears from the current catalog.
- On catalog disappearance, select the next deterministic candidate and do not penalize the user.
- Streak calculation uses qualified local dates and ignores future buckets.
- A clock rollback must not award duplicate first-of-day or quest bonuses.

## Recommendation filtering

Eligible recommendations must be active, trackable keyboard bindings. Exclude:

- Mouse bindings.
- Hardware/media entries marked unavailable by catalog generation.
- Bindings with empty descriptions.
- The plugin’s own integration/control actions if later added.

Order by never-used, oldest `lastUsed`, lowest count, then opaque ID. Return no duplicates and at most `limit`.

## Tests

Use table-driven tests for:

- Every XP branch and repeat cap.
- All level boundaries.
- Three-distinct-binding qualification.
- Streak continue, reset, future date, and clock rollback.
- Quest completion once.
- Catalog entry removal.
- Stable deterministic tie-breaking.
- Empty catalog and fewer candidates than limit.
- Input immutability.

Include golden scenarios spanning at least 100 simulated days to catch retention/streak interactions.

## Integration

- Service records observations through the pure API.
- Expose current level, daily quest, streak, and recommendations to all UIs.
- Guide sorting consumes the same recommendation result; it must not implement separate ranking.
- Update bar tooltip and panel placeholders with real values.

## Validation

```sh
tests/shell/run gamification
qmllint -I "$OMARCHY_PATH/shell" Service.qml BarWidget.qml Panel.qml SuperGuide.qml
```

## Acceptance criteria

- Replaying the same catalog, stats, date, and events yields identical output.
- XP cannot be farmed beyond the stated daily caps except by learning different bindings.
- UI surfaces agree because all use the service’s canonical calculations.
- No shaming, XP loss, negative score, or network leaderboard exists.
