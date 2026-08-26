# Task 12 — Full Dojo Overlay

## Objective

Implement the keyboard-accessible full overlay for browsing, practicing, reviewing progress, and configuring the plugin.

## Depends on

Tasks 09–11.

## Window contract

- Implement `open(payloadJson)`, `close()`, and `toggle()`.
- Use a fullscreen layer-shell overlay with exclusive keyboard focus only while open.
- Escape closes the overlay; clicking the scrim closes it; clicks inside the content card do not propagate.
- Restore no synthetic input to the previously focused application.
- Declare `property var service` for Omarchy’s matching-service injection.
- Handle a temporarily null service during plugin reload by showing a loading/error state rather than throwing.

## Fixed tabs

Use exactly four tabs in this order:

```text
Bindings, Practice, Progress, Settings
```

### Bindings

- Search combo and description case-insensitively.
- Fixed category chips from the catalog schema; `All` is the default UI filter, not a stored category.
- List combo, description, category, observed count, and last-used relative time.
- Keyboard navigation: Tab/Shift+Tab between controls, arrows through results, Page Up/Down, Home/End.
- Do not execute selected bindings.

### Practice

- Show the daily quest first, then up to 20 service recommendations.
- A practice card initially emphasizes the description and lets the user reveal the combo.
- Completing practice requires physically using the actual binding; react to the service match signal and animate completion.
- Provide `Skip for today`; skipping changes only overlay session order and does not rewrite the deterministic daily quest.

### Progress

- Current level and progress to next threshold.
- Current streak and distinct bindings used today.
- Ninety-day activity heat map using aggregate daily counts.
- Five most-used and five least-used active bindings.
- Empty-state copy for a new user.

### Settings

- Reuse service methods and shared components for integration status, resolved config path, delay, fullscreen behavior, recheck, disable, manual snippet, and reset.
- Do not duplicate patching logic from `Panel.qml`.

## Visual constraints

- Use Omarchy theme tokens and font families.
- Fit common 1280×720 logical screens without clipping critical actions.
- Constrain content width and height; scroll lists rather than expanding past screen bounds.
- Maintain visible focus indicators and meaningful accessible names.
- No remote images, web views, or generated raster assets are needed.

## Tests

- Open/close/toggle and Escape/scrim behavior.
- Every tab and keyboard navigation path.
- Search with punctuation and no results.
- Category filtering.
- Practice reveal and live completion.
- New-user and populated progress states.
- Null/reloading service.
- 1280×720 and scaled/high-DPI geometry.
- Settings actions call service only.

## Validation

```sh
qmllint -I "$OMARCHY_PATH/shell" Overlay.qml Service.qml
tests/shell/run overlay
omarchy plugin validate .
```

## Acceptance criteria

- Every core function is usable without a mouse.
- The overlay captures keyboard only while visible.
- Search and practice never dispatch commands themselves.
- Closing returns the desktop to its previous state without leaving a surface or focus grab.
