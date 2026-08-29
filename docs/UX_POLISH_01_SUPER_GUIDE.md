# UX Polish 01 — Super Guide behavior and look

Status: **Proposed; implementation not started**

This workstream covers only the transient guide shown while Super is held.
Polish for the bar widget, its side panel, and the full Dojo overlay will be
planned separately.

## 1. Outcome

Turn the current full-width card grid into a fast, symmetric, transparent
command canopy:

- Show materially more bindings without covering the desktop with a panel.
- Put the most useful bindings nearest the horizontal center.
- Distribute lower-priority bindings outward and then down the screen edges.
- Replace the dead `+N more` row with a prominent hover-to-expand pill.
- Keep the canvas transparent so the individual binding pills are the visual
  object, with a liquid-glass feel derived from the active Omarchy theme.
- Preserve instant display, focused-monitor routing, and shortcut behavior.

The LazyVim `which-key` popup is the density/reference model: compact
key-to-description pairs, predictable scanning, and immediate discoverability.
The Super Guide should borrow that clarity without becoming a terminal panel
or copying its rectangular list layout.

## 2. Problems in the current guide

The screenshot exposes several structural problems rather than isolated style
bugs:

1. `GuideModel.cardModel()` hard-caps the visible deck at 12.
2. The guide sorts alphabetically instead of consuming the canonical service
   recommendations promised by Task 11.
3. Every card is a two-line, roughly equal-size rectangle. On a wide display,
   that spends too much area per binding while still revealing few bindings.
4. `Flow` fills left-to-right, so the final row ends abruptly and looks
   unbalanced.
5. The opaque outer `BorderSurface` visually blankets the top of the desktop.
6. `+N more` is intentionally noninteractive and offers no route to the hidden
   bindings.
7. The same hard cap and ragged geometry recur for Super+Shift, Super+Ctrl,
   and Super+Alt lanes.
8. Raw labels such as `code:20` are implementation details rather than useful
   display names.
9. The guide currently has an empty pointer mask. That guarantees perfect
   pointer pass-through, but it also makes hover expansion impossible. The new
   contract must address that tradeoff explicitly.

## 3. Design principles

### Glanceable, not modal

The guide should feel attached to the held modifier, not like an application
that opened. It keeps no keyboard focus, executes no binding, and disappears
on Super release.

### Stable before clever

Important bindings belong near the center, but positions must not shuffle
while the user is reading. The deck order is frozen when Super goes down and
remains fixed until the guide closes or the modifier lane changes.

### Transparent canvas, legible objects

Remove the full-width background. Pills receive translucent theme-derived
fills, borders, and restrained depth. Text remains high contrast even when the
pill surface fades.

### Dense by default, complete on demand

Collapsed mode should show at least 50% more bindings than the current 12-card
limit on a 1920-pixel-or-wider display. Expanded mode should reveal the entire
eligible modifier lane within safe screen bounds.

### Symmetry is a layout rule

Cards are assigned center-out into mirrored slot pairs. A partial row must
remain visually balanced instead of stopping abruptly on the left.

### Non-interference remains a release gate

No keyboard focus, process launch, file access, dispatcher replacement, or
binding execution is added to the guide path. Pointer capture is restricted to
the overflow reveal pill and tested separately.

## 4. Proposed visual system: the glass canopy

### Collapsed state

The highest-priority bindings form a compact two-row crown at the screen edge,
layered over the transparent bar surface. Remaining collapsed bindings become left and right wings that step
outward and then downward, preserving the center of the desktop.

Where the secondary row leaves enough space, two low-priority corner caps sit
one row below the crown and attach to its outer cards with the standard card
gap. Together with the lower side wings, they create a continuous stepped
outline rather than cards that hug the absolute upper corners. They are not
rendered when the secondary row would crowd them.

The side wings use four left/right pairs on wide displays (rather than two),
so four additional low-priority bindings remain visible at their normal,
readable card width. Narrow displays retain the smaller two-pair wing.

The collapsed canopy is a fixed visual frame: hover expansion never moves a
visible card. The first new binding fills the former overflow center; the rest
balance across open interior space between the fixed left and right wings.
Modifier lanes that already fit retain that same frame rather than switching to
a separate centered-grid layout. This preserves the eye's anchors while making
the previously hidden choices available.

Conceptual placement, where lower numbers have higher priority:

```text
                         [ SUPER GUIDE · SUPER ]

             [8] [6] [4] [2] [1] [3] [5] [7] [9]
        [17] [15] [13] [11] [ +26 MORE · HOVER ] [12] [14] [16] [18]
      [22] [20]                                         [19] [21]

                     [Shift 38] [Ctrl 42] [Alt 25]
```

This is a canopy rather than a third and fourth full-width row:

- Rank 1 occupies the visual center.
- Subsequent ranks alternate right and left to keep the deck balanced.
- The first two rows carry the clearest and most prominent pills.
- Lower-priority wings descend only near the screen edges.
- Wing surfaces fade by vertical depth as they approach the center of the
  desktop; text opacity retains an accessibility floor.
- The overflow pill is larger than an ordinary binding pill and stays centered.

The exact slot count is responsive. The diagram describes the ordering and
shape, not hard-coded coordinates.

### Expanded state

Hovering over the overflow pill for a short dwell expands the current modifier
lane:

- Every eligible binding becomes visible in a dense, symmetric command sheet.
- Additional rows grow from the crown and wings rather than replacing the
  first 12 items.
- All binding pills switch to full surface opacity while expanded.
- The overflow pill changes to `ALL N BINDINGS` so the state is unambiguous.
- Expansion remains sticky until Super is released or the modifier mask
  changes. The user can move the pointer away without the deck collapsing
  under their eyes.
- There is no click action.

For unusually large lanes, the layout increases columns before rows and uses
the compact pill tier. It must never silently truncate at 12. A safety ceiling
may exist only if the model returns an explicit residual count and the UX plan
is revisited; the current machine's 38–42-item lanes should fit in full.

### Modifier changes

Pressing Shift, Ctrl, or Alt while Super remains held replaces the lane using
the same canopy geometry. Each lane starts collapsed and has its own exact
overflow count. Returning to bare Super restores the bare-Super deck.

## 5. Binding pill anatomy

Move from two-line cards to mostly one-line command pills:

```text
[ SUPER + W ]  Close window
```

- Combo and description are visually distinct in two compact rows. The
  shortcut uses the first row; its plain-language purpose uses the second.
- Primary crown pills may be slightly wider/taller than wing pills.
- Mirrored slot pairs use the same width, based on the wider member of the
  pair, so text length cannot break symmetry.
- Long labels may shrink slightly to fit, but instructional text should not
  fall back to an ellipsis in the normal canopy.
- Raw `code:N` labels should be resolved to a human-readable key name when the
  active keymap provides one. If resolution is impossible, display `Key N`
  rather than exposing parser syntax.
- Matched bindings receive the existing short accent highlight without
  moving their slot.

Target tiers, expressed through `Style.space()` rather than fixed physical
pixels:

| Tier | Role | Density | Collapsed surface |
|---|---|---|---|
| Primary | Center crown | Most readable | Full or near-full glass opacity |
| Secondary | Outer crown | Compact | Slightly translucent |
| Wing | Descending edges | Densest | Progressively translucent by depth |
| Expanded | Entire lane | Dense and uniform | Full opacity |

Text should remain substantially more opaque than a faded surface. Decorative
transparency must never make a binding unreadable.

When the plain Super lane is visible, the header itself gives the terse next
step: “hold Super · add Shift / Ctrl / Alt.” There is no footer, no separate
lane control, and no binding counts competing with the shortcuts.

Internal modifier masks are never shown verbatim. For example, `SUPER_SHIFT`
renders as the human-readable chord `SUPER + SHIFT`.

## 6. Ranking and position stability

The Super Guide should not maintain a separate alphabetical ranking. It should
consume the same stable priority order as Omarchy's `SUPER+K` keybindings menu.
This keeps the desktop guide familiar and stops usage or gamification state
from making the primary muscle-memory positions move.

For this polish pass:

1. The catalog generator mirrors Omarchy's `SUPER+K` priority rules, then uses
   combo, description, and opaque ID only as stable ties.
2. The first eligible binding occupies the top-row center. Each successive
   item is placed alternately left then right, moving outward by priority.
   The second row repeats that same alternating order around the centered
   overflow pill; the wings and corner caps contain the remaining lowest
   collapsed priorities.
3. Preserve the same catalog order in every modifier lane and freeze it at
   guide-open time.
4. A matched-binding highlight changes appearance, not rank or position.

The active XKB keymap also resolves raw `code:N` bindings while the catalog is
generated. For example, the current `code:10`–`code:20` entries become `1`–`0`
and `-`. Omarchy's `code:201` is the dedicated Copilot key, so it is labeled
`COPILOT` but excluded from the guide because it duplicates `SUPER + SPACE`.
An otherwise unresolvable hardware code remains an explicit `KEY N` fallback.

Context-aware ranking from active workspace, terminal/browser context, and
local history remains the separate design described in `PLAN.md` section 13.1.
The canopy model should accept future priority scores, but UX Polish 01 must
not begin collecting or persisting application names, window titles, pane
content, or commands.

## 7. Hover and input contract

Hover expansion conflicts with the current `mask: Region {}` design. The safe
implementation target is:

- Keep `WlrKeyboardFocus.None` at all times.
- Give only the overflow pill a pointer input region while collapsed.
- Use hover dwell, not click, to expand.
- Once expanded, keep the state sticky so ordinary pills need no pointer input
  region.
- Reset expansion on Super release, modifier-lane change, guide suppression,
  or focused-monitor change.
- Never execute a binding from a pill.

The first interaction spike must prove that a tiny layer-shell input region can
observe hover without swallowing unrelated clicks outside that pill. If the
compositor/Quickshell combination cannot provide that boundary reliably, the
fallback is a prolonged-Super dwell expansion with the pointer mask kept empty.
Broad pointer capture over the whole canopy is not acceptable.

Suggested timing:

- Hover dwell before expansion: approximately 120–180 ms.
- Expansion animation: approximately 140–180 ms.
- No collapse animation while Super is released; disappearance should remain
  immediate enough to avoid a lingering overlay.

Exact values will be tuned in the manual UX gate.

## 8. Glass treatment

### Default: glass-lite

The default implementation requires no Hyprland config mutation:

- `PanelWindow.color` stays transparent.
- Remove the full outer `BorderSurface`.
- Use `Util.alpha()` with `Color.menu.background`, `Color.menu.border`, and
  accent tokens for translucent pill surfaces.
- Use restrained theme-derived highlights and short opacity/scale motion.
- Keep the small title and modifier summaries as floating micro-pills.
- Do not hard-code white, black, purple, or screenshot-specific colors.

### Iteration: contrast shield and legible card hierarchy

Live review found that a fully transparent canopy can visually collide with a
terminal or a visually busy application. The implemented baseline is therefore
a theme-native vertical gradient behind the guide: near-opaque at the header
and primary cards, then progressively transparent below the final row. It uses
`Color.menu.background`, so bright and dark themes preserve their intended
contrast rather than receiving a fixed grey overlay.

Each card uses its full width for two single-line rows: the shortcut is first,
and the plain-language description is second. Horizontal fitting can shrink a
rare long label slightly, but truncation ellipses are avoided. This retains the
approved canopy geometry while making the guide's instructional text usable.

### Optional feasibility spike: true backdrop blur

Translucent QML surfaces are feasible now; true blur of arbitrary desktop
content behind a layer-shell window is a separate compositor-level question.
Before promising “liquid glass,” test whether the installed Omarchy/Hyprland
stack exposes a plugin-safe backdrop-blur route for this namespace.

The plugin must not silently edit the user's Hyprland appearance configuration
for a cosmetic effect. If true blur requires a user layer rule, document it as
an optional enhancement and keep glass-lite as the supported default.

## 9. Responsive geometry

The layout model receives available width, available height, scale, bar offset,
card metrics, item count, and expanded state. It returns pure placement data;
QML renders that data without ad-hoc `Flow` decisions.

Targets:

| Display class | Collapsed target | Expanded target |
|---|---:|---:|
| 2560px-wide reference | 18–24 bindings | Entire 38–42-item lane |
| 1920px wide | 18 or more bindings | Entire normal lane |
| Narrow/low-height | 10–16 bindings | More columns/compact tiers before clipping |

- Collapsed mode should ordinarily consume no more than about one quarter of
  screen height.
- Expanded mode should ordinarily remain below about 45% of screen height.
- The crown stays below a top bar and adapts to bottom/side/hidden bars.
- Every placement must remain inside the focused monitor's logical bounds.
- Scale and font metrics, not physical screenshot pixels, control sizing.
- Odd item counts keep a center item; even counts use a balanced center pair.

## 10. State model

Model the behavior explicitly:

```text
hidden
  -> collapsed(mask, frozen deck)
  -> expanded(mask, same frozen deck)
  -> highlighted(binding id, collapsed or expanded)
  -> hidden on Super release/suppression
```

Modifier-mask changes create a new frozen collapsed deck. Catalog/stat changes
while visible are deferred until the next lane/open cycle unless the current
binding disappears, preventing visual churn.

Suggested pure model additions:

```text
rankGuideBindings(catalog, stats, recommendationIds, modifierMask)
collapsedCapacity(viewport, metrics, itemCount)
canopyPlacements(items, viewport, expanded)
displayKey(binding)
```

Each function must be deterministic, immutable, and testable without a live
Wayland session.

## 11. Implementation sequence and commits

### 01A — Pure deck and geometry model

- Replace the alphabetical/hard-limit model with canonical ranked IDs.
- Add responsive capacity and center-out mirrored placement helpers.
- Add display-key normalization.
- Add table-driven model tests.

Suggested commit: `feat: model ranked super guide canopy`

### 01B — Transparent compact canopy

- Remove the outer opaque surface.
- Render compact one-line glass pills from placement data.
- Add crown, wings, title chip, modifier chips, and exact overflow pill.
- Preserve an empty pointer mask in this intermediate commit.

Suggested commit: `feat: render transparent super guide canopy`

### 01C — Hover expansion

- Add the overflow-only hover region and dwell state.
- Make expansion sticky for the current Super hold.
- Add full-opacity expanded layout and reset rules.
- Verify no click action and no keyboard focus.

Suggested commit: `feat: expand super guide overflow on hover`

### 01D — Motion and optional blur spike

- Tune short position/opacity transitions without delaying first visibility.
- Test glass-lite across light/dark themes.
- Evaluate true backdrop blur separately and retain glass-lite if unsafe or
  configuration-dependent.

Suggested commit: `style: polish super guide glass motion`

Each commit must pass its automated checks and be pushed independently before
the manual UX gate.

## 12. Automated validation

Pure/model coverage:

- Exact modifier filtering remains unchanged.
- Recommendation order reaches center slots.
- Center-out assignments are symmetric for odd/even and partial decks.
- Mirrored pairs have equal widths.
- Capacity is deterministic across representative viewport sizes.
- Overflow counts are exact in every modifier lane.
- Expanded mode includes every eligible binding exactly once.
- No raw dispatcher argument enters display data.
- Human-readable fallback replaces raw `code:N` display syntax.

QML/static coverage:

- Window background is transparent and no full-width opaque surface remains.
- Keyboard focus is always none.
- Collapsed pointer mask contains only the overflow hover target.
- No binding pill has a click action.
- Expanded state resets on release, suppression, modifier change, and monitor
  focus change.
- All placements remain in monitor bounds under tested scale/font settings.
- Existing lock/fullscreen/delay/highlight tests continue to pass.

Validation commands:

```sh
qmllint -I /usr/share/omarchy/shell Service.qml SuperGuide.qml
tests/shell/run guide
tests/shell/run all
```

## 13. Manual UX gate

Use screenshots from the same wide monitor and at least one narrower monitor.
Verify:

1. Bare Super shows a balanced canopy rather than a ragged grid.
2. At least 18 bindings are visible by default on a 1920px-or-wider display.
3. The highest-priority bindings occupy the central crown.
4. The desktop remains visibly present between and behind pills.
5. Wing opacity fades gracefully without sacrificing text readability.
6. `+N more · hover` reveals the full lane without a click.
7. Expanded pills are fully legible and do not collapse when the pointer leaves.
8. Super+Shift, Super+Ctrl, and Super+Alt each receive correct counts and the
   same symmetric treatment.
9. Super release closes the guide immediately from collapsed and expanded
   states.
10. Hover capture does not interfere with pointer use outside the overflow pill.
11. The guide stays on the focused monitor and below the bar.
12. Light/dark themes and monitor scaling retain contrast and bounds.
13. Super-down latency remains under the existing p95 budget.

The gate should be reviewed primarily through screenshots and a short live
interaction session. Small visual decisions—opacity floors, pill widths,
animation timing, and wing depth—belong in this gate rather than being frozen
prematurely in code.

## 14. Acceptance criteria

UX Polish 01 is complete when:

- The guide has no opaque full-width background.
- The collapsed layout is symmetric and shows at least 50% more bindings than
  the current 12-card design on standard desktop widths.
- Hidden bindings are discoverable through a clear hover affordance.
- The full active modifier lane can be inspected without opening the full Dojo.
- Central placement follows canonical recommendations and remains stable for
  the duration of a guide session.
- Pointer input is restricted to the overflow affordance; keyboard focus and
  binding behavior remain unchanged.
- Theme, scaling, focused-monitor, lock, fullscreen, and latency checks pass.
- The user approves the look and behavior in the manual screenshot gate.

## 15. Deferred from this workstream

- Bar-widget and side-panel UX polish.
- Full Dojo overlay UX polish.
- Removal or redesign of XP, streaks, levels, and quests.
- Context-aware application/workspace/pane ranking from `PLAN.md` section 13.1.
- Binding execution from the guide.
- Automatic Hyprland appearance edits solely to enable blur.
