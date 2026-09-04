.pragma library

var CATEGORIES = [
  "windows", "workspaces", "applications", "system", "capture",
  "media", "clipboard", "notifications", "style", "other"
]
var MODIFIERS = ["SUPER", "SHIFT", "CTRL", "ALT"]
var PROTOCOL_PREFIX = "omakeez:v1:"

// Double-tap arming. A guide root pressed and released inside TAP_MAX_MS is a
// tap, which arms that root for ARM_WINDOW_MS; only a press arriving while the
// root is armed opens a guide. Both spans are compared with a non-negative age
// so a backwards clock reads as "not armed" instead of arming forever.
var TAP_MAX_MS = 400
var ARM_WINDOW_MS = 800

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function hasOnlyStrings(values, allowed) {
  if (!Array.isArray(values)) return false
  var seen = {}
  for (var i = 0; i < values.length; i++) {
    if (typeof values[i] !== "string" || allowed.indexOf(values[i]) === -1 || seen[values[i]]) return false
    seen[values[i]] = true
  }
  return true
}

function validId(value) {
  return typeof value === "string" && /^sha256:[0-9a-f]{64}$/.test(value)
}

function validSourceHash(value) {
  return validId(value)
}

function validCodeList(values) {
  if (!Array.isArray(values)) return false
  for (var i = 0; i < values.length; i++) {
    if (typeof values[i] !== "number" || !isFinite(values[i]) || Math.floor(values[i]) !== values[i] || values[i] < 1) return false
  }
  return true
}

function normalizedBinding(raw) {
  if (!isObject(raw)) return null
  var requiredStrings = ["id", "combo", "key", "description", "submap", "dispatcherKind"]
  for (var i = 0; i < requiredStrings.length; i++) {
    if (typeof raw[requiredStrings[i]] !== "string") return null
  }
  if (!validId(raw.id) || !hasOnlyStrings(raw.modifiers, MODIFIERS)) return null
  if (CATEGORIES.indexOf(raw.category) === -1) return null
  if (raw.phase !== "press" && raw.phase !== "release") return null
  if (!validCodeList(raw.xkbCodes)) return null
  if (typeof raw.trackable !== "boolean" || typeof raw.guideEligible !== "boolean") return null
  if (raw.repeat !== undefined && typeof raw.repeat !== "boolean") return null
  if (raw.available !== undefined && typeof raw.available !== "boolean") return null
  if (raw.unavailable !== undefined && typeof raw.unavailable !== "boolean") return null

  return {
    id: raw.id,
    combo: raw.combo,
    modifiers: raw.modifiers.slice(),
    key: raw.key,
    xkbCodes: raw.xkbCodes.slice(),
    description: raw.description,
    category: raw.category,
    phase: raw.phase,
    submap: raw.submap,
    dispatcherKind: raw.dispatcherKind,
    trackable: raw.trackable,
    guideEligible: raw.guideEligible,
    repeat: raw.repeat === true,
    available: raw.available !== false,
    unavailable: raw.unavailable === true
  }
}

function normalizeCatalog(raw) {
  var value = raw
  if (typeof value === "string") {
    try { value = JSON.parse(value) } catch (e) { return { ok: false, error: "invalid-json" } }
  }
  if (!isObject(value) || value.schemaVersion !== 1 || !validSourceHash(value.sourceHash)
      || typeof value.generatedAt !== "number" || !isFinite(value.generatedAt)
      || !Array.isArray(value.bindings)) {
    return { ok: false, error: "invalid-catalog" }
  }

  var bindings = []
  var byId = {}
  for (var i = 0; i < value.bindings.length; i++) {
    var binding = normalizedBinding(value.bindings[i])
    if (!binding || byId[binding.id]) return { ok: false, error: "invalid-binding" }
    byId[binding.id] = binding
    bindings.push(binding)
  }
  return {
    ok: true,
    catalog: {
      schemaVersion: 1,
      generatedAt: value.generatedAt,
      sourceHash: value.sourceHash,
      bindings: bindings,
      byId: byId
    }
  }
}

function allowedModifierMask(mask) {
  if (typeof mask !== "string" || mask === "") return false
  var parts = mask.split("_")
  var seen = {}
  for (var i = 0; i < parts.length; i++) {
    if (MODIFIERS.indexOf(parts[i]) === -1 || seen[parts[i]]) return false
    seen[parts[i]] = true
    if (i > 0 && MODIFIERS.indexOf(parts[i]) <= MODIFIERS.indexOf(parts[i - 1])) return false
  }
  return true
}

function parseProtocol(payload, catalog) {
  if (typeof payload !== "string" || payload.indexOf(PROTOCOL_PREFIX) !== 0)
    return { ok: false, error: "wrong-prefix" }

  // Retain the original Super events during the transition so an older bridge
  // cannot leave the service without a guide lifecycle.
  if (payload === PROTOCOL_PREFIX + "super:down") return { ok: true, type: "guide", phase: "down", root: "SUPER" }
  if (payload === PROTOCOL_PREFIX + "super:up") return { ok: true, type: "guide", phase: "up", root: "SUPER" }

  var guideDown = payload.match(/^omakeez:v1:guide:down:(SUPER|SHIFT|CTRL|ALT)$/)
  if (guideDown) return { ok: true, type: "guide", phase: "down", root: guideDown[1] }
  if (payload === PROTOCOL_PREFIX + "guide:up") return { ok: true, type: "guide", phase: "up" }

  var modifierMatch = payload.match(/^omakeez:v1:mods:(.*)$/)
  if (modifierMatch) {
    if (!allowedModifierMask(modifierMatch[1])) return { ok: false, error: "invalid-modifiers" }
    return { ok: true, type: "mods", modifiers: modifierMatch[1] }
  }

  var match = payload.match(/^omakeez:v1:match:(sha256:[0-9a-f]{64}):(press|release)$/)
  if (match) {
    var known = !!(catalog && catalog.byId && catalog.byId[match[1]])
    if (known && catalog.byId[match[1]].phase !== match[2]) return { ok: false, error: "phase-mismatch" }
    return { ok: true, type: "match", id: match[1], phase: match[2], known: known }
  }
  return { ok: false, error: "invalid-protocol" }
}

// -1 is the off sentinel this function itself returns, so it has to survive a
// round trip through the config. Without it the panel's Off button wrote -1,
// read back 0, and quietly selected Instant instead.
function normalizeDelay(value) {
  if (value === false || String(value).toLowerCase() === "disabled") return -1
  var number = Number(value)
  return [-1, 0, 80, 150, 250].indexOf(number) !== -1 ? number : 0
}

function emptyTapState() {
  return { armedRoot: "", armedAtMs: 0, downRoot: "", downAtMs: 0, shown: false }
}

function normalizeDoubleTap(value) {
  return value === true
}

// The delay and the double tap answer the same question -- how much intent a
// guide should demand before it covers the screen -- so they are one axis with
// one selected value, not two settings that stack. `guideDelayMs` and
// `guideDoubleTapEnabled` remain separate keys only so configs written before
// the merge keep loading; every reader goes through the helpers below.
var ACTIVATIONS = [
  { key: "instant", delayMs: 0, doubleTap: false },
  { key: "80ms", delayMs: 80, doubleTap: false },
  { key: "150ms", delayMs: 150, doubleTap: false },
  { key: "250ms", delayMs: 250, doubleTap: false },
  { key: "doubleTap", delayMs: 0, doubleTap: true },
  { key: "off", delayMs: -1, doubleTap: false }
]

function activationIndexOfKey(key) {
  for (var i = 0; i < ACTIVATIONS.length; i++) {
    if (ACTIVATIONS[i].key === key) return i
  }
  return 0
}

// Resolves any pair of stored values, including a hand-edited or pre-merge
// config that sets both, onto the one choice the control can express. Off wins
// over everything because off has to mean off; the tap wins over a delay
// because the tap is what replaced it.
function activationIndex(delayMs, doubleTapEnabled) {
  var delay = normalizeDelay(delayMs)
  if (delay < 0) return activationIndexOfKey("off")
  if (normalizeDoubleTap(doubleTapEnabled)) return activationIndexOfKey("doubleTap")
  for (var i = 0; i < ACTIVATIONS.length; i++) {
    if (!ACTIVATIONS[i].doubleTap && ACTIVATIONS[i].delayMs === delay) return i
  }
  return activationIndexOfKey("instant")
}

function activationAt(index) {
  var i = Number(index)
  if (!isFinite(i)) i = 0
  i = Math.floor(i)
  if (i < 0 || i >= ACTIVATIONS.length) i = 0
  return { delayMs: ACTIVATIONS[i].delayMs, doubleTapEnabled: ACTIVATIONS[i].doubleTap }
}

// Both effective values come off the same resolved index, so they cannot
// disagree: selecting the tap always means a zero delay, and the second press
// opens the guide at once instead of starting a hold on top of it.
function effectiveDelay(delayMs, doubleTapEnabled) {
  return activationAt(activationIndex(delayMs, doubleTapEnabled)).delayMs
}

function effectiveDoubleTap(delayMs, doubleTapEnabled) {
  return activationAt(activationIndex(delayMs, doubleTapEnabled)).doubleTapEnabled
}

// Press of a guide root. Opens a guide only when that same root is already
// armed by a preceding tap; otherwise it records the press so the matching
// release can decide whether it was one.
function tapGateDown(state, rootName, nowMs) {
  var current = isObject(state) ? state : emptyTapState()
  var age = nowMs - current.armedAtMs
  var armed = current.armedRoot === rootName && current.armedAtMs > 0 && age >= 0 && age <= ARM_WINDOW_MS
  return {
    show: armed,
    state: { armedRoot: "", armedAtMs: 0, downRoot: rootName, downAtMs: nowMs, shown: armed }
  }
}

// Release of a guide root. A short press that did not open a guide arms that
// root; anything else clears the arming, so a long hold cannot stand in for
// the first tap.
function tapGateUp(state, nowMs) {
  var current = isObject(state) ? state : emptyTapState()
  if (current.shown) return emptyTapState()
  var held = nowMs - current.downAtMs
  if (current.downRoot !== "" && current.downAtMs > 0 && held >= 0 && held <= TAP_MAX_MS)
    return { armedRoot: current.downRoot, armedAtMs: nowMs, downRoot: "", downAtMs: 0, shown: false }
  return emptyTapState()
}

function normalizeFullscreen(value) {
  return value === true
}

function normalizeGuideRoot(value) {
  return value !== false
}

function settingsFor(config, moduleName) {
  if (!isObject(config) || !isObject(config.bar) || !isObject(config.bar.layout)) return {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = config.bar.layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      if (isObject(entry) && String(entry.id || "") === moduleName) return entry
    }
  }
  return {}
}

function parseActiveWindow(raw) {
  var value = raw
  if (typeof value === "string") {
    try { value = JSON.parse(value) } catch (e) { return { ok: false, error: "invalid-json" } }
  }
  if (!isObject(value)) return { ok: false, error: "invalid-activewindow" }
  if (typeof value.fullscreen === "boolean") return { ok: true, fullscreen: value.fullscreen }
  if (typeof value.fullscreen === "number" && isFinite(value.fullscreen) && Math.floor(value.fullscreen) === value.fullscreen)
    return { ok: true, fullscreen: value.fullscreen > 0 }
  return { ok: false, error: "missing-fullscreen" }
}

function isCatalogChangeEvent(name) {
  return ["configreloaded", "configreloadedv2", "activelayout", "activekeyboardlayout", "keyboardlayout"].indexOf(String(name || "")) !== -1
}

function isFullscreenEvent(name) {
  return ["activewindow", "activewindowv2", "fullscreen"].indexOf(String(name || "")) !== -1
}
