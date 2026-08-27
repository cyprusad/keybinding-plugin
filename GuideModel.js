.pragma library

function exactModifiers(binding, mask) {
  if (!binding || !Array.isArray(binding.modifiers)) return false
  var expected = String(mask || "SUPER").split("_")
  if (expected.length !== binding.modifiers.length) return false
  for (var i = 0; i < expected.length; i++) {
    if (expected[i] !== binding.modifiers[i]) return false
  }
  return true
}

function cardModel(catalog, mask, limit) {
  var source = catalog && Array.isArray(catalog.bindings) ? catalog.bindings : []
  var matches = []
  for (var i = 0; i < source.length; i++) {
    var binding = source[i]
    if (!binding || binding.trackable !== true || binding.guideEligible !== true) continue
    if (exactModifiers(binding, mask)) matches.push(binding)
  }
  matches.sort(function(a, b) {
    var left = String(a.description || "").toLowerCase()
    var right = String(b.description || "").toLowerCase()
    if (left < right) return -1
    if (left > right) return 1
    return String(a.id).localeCompare(String(b.id))
  })
  var count = Number(limit)
  if (!isFinite(count) || count < 1) count = 12
  count = Math.floor(count)
  return { items: matches.slice(0, count), total: matches.length, more: Math.max(0, matches.length - count) }
}

function laneCounts(catalog) {
  var result = { SHIFT: 0, CTRL: 0, ALT: 0 }
  var source = catalog && Array.isArray(catalog.bindings) ? catalog.bindings : []
  for (var i = 0; i < source.length; i++) {
    var modifiers = source[i] && source[i].modifiers
    if (!Array.isArray(modifiers) || modifiers.length !== 2 || modifiers[0] !== "SUPER") continue
    if (result[modifiers[1]] !== undefined) result[modifiers[1]] += 1
  }
  return result
}

function eligible(state) {
  if (!state || state.integrationState !== "enabled" || state.catalogState !== "ready") return false
  if (state.desktopLocked === true || state.credentialPromptActive === true) return false
  return state.showInFullscreen === true || state.activeWindowFullscreen !== true
}

function delayMode(guideVisible, delay) {
  if (guideVisible !== true) return "hidden"
  var value = Number(delay)
  if (value === 0) return "immediate"
  if (value === 80 || value === 150 || value === 250) return "delayed"
  return "disabled"
}

function focusedVisible(shouldShow, screenName, focusedName) {
  return shouldShow === true && String(screenName || "") !== ""
    && String(screenName || "") === String(focusedName || "")
}

function barOffset(position, size, hidden) {
  return String(position || "top") === "top" && hidden !== true ? Math.max(0, Number(size) || 0) : 0
}
