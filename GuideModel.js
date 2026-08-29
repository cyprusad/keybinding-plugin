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

function displayCombo(binding) {
  var combo = String(binding && binding.combo || "")
  var key = String(binding && binding.key || "")
  var code = /^code:([0-9]+)$/i.exec(key)
  if (code) {
    var replacement = "KEY " + code[1]
    if (combo === "" || /^code:[0-9]+$/i.test(combo)) return replacement
    return combo.replace(/code:[0-9]+$/i, replacement)
  }
  return combo !== "" ? combo : key
}

function priorityLookup(ids) {
  var result = {}
  var source = Array.isArray(ids) ? ids : []
  for (var i = 0; i < source.length; i++) {
    var id = String(source[i] || "")
    if (id !== "" && result[id] === undefined) result[id] = i
  }
  return result
}

function rankedBindings(catalog, mask, priorityIds) {
  var source = catalog && Array.isArray(catalog.bindings) ? catalog.bindings : []
  var priorities = priorityLookup(priorityIds)
  var matches = []
  for (var i = 0; i < source.length; i++) {
    var binding = source[i]
    if (!binding || binding.trackable !== true || binding.guideEligible !== true) continue
    if (!exactModifiers(binding, mask)) continue
    matches.push({
      id: String(binding.id || ""),
      combo: displayCombo(binding),
      description: String(binding.description || ""),
      category: String(binding.category || "other"),
      priority: priorities[binding.id] === undefined ? -1 : priorities[binding.id],
      catalogOrder: i
    })
  }
  matches.sort(function(a, b) {
    var aPriority = Number(a.priority)
    var bPriority = Number(b.priority)
    if (aPriority >= 0 || bPriority >= 0) {
      if (aPriority < 0) return 1
      if (bPriority < 0) return -1
      if (aPriority !== bPriority) return aPriority - bPriority
    }
    return a.catalogOrder - b.catalogOrder
  })
  return matches
}

function cardModel(catalog, mask, limit, priorityIds) {
  var matches = rankedBindings(catalog, mask, priorityIds)
  var count = Number(limit)
  if (!isFinite(count) || count < 1) count = 12
  count = Math.floor(count)
  return { items: matches.slice(0, count), total: matches.length, more: Math.max(0, matches.length - count) }
}

function number(value, fallback) {
  var parsed = Number(value)
  return isFinite(parsed) && parsed > 0 ? parsed : fallback
}

function clamp(value, minimum, maximum) {
  return Math.max(minimum, Math.min(maximum, value))
}

function canopyMetrics(viewport, expanded) {
  var width = number(viewport && viewport.width, 1920)
  var compact = width >= 2400 ? 206 : width >= 1800 ? 182 : 158
  if (expanded === true) compact = Math.max(142, compact - 18)
  var gap = width >= 1800 ? 8 : 6
  var margin = width >= 1800 ? 18 : 10
  var columns = Math.floor((width - margin * 2 + gap) / (compact + gap))
  columns = clamp(columns, 5, expanded === true ? 12 : 9)
  if (columns % 2 === 0 && columns > 5) columns -= 1
  return {
    width: width,
    cardWidth: compact,
    // A two-line card keeps the complete shortcut and its purpose legible
    // without making the canopy any wider.
    cardHeight: expanded === true ? 42 : 46,
    gap: gap,
    margin: margin,
    crownColumns: columns
  }
}

function centeredOffsets(count) {
  var total = Math.max(0, Math.floor(Number(count) || 0))
  var result = []
  if (total % 2 === 1) {
    result.push(0)
    for (var distance = 1; result.length < total; distance++) {
      result.push(-distance)
      if (result.length < total) result.push(distance)
    }
    return result
  }
  for (var half = 0.5; result.length < total; half += 1) {
    result.push(-half)
    if (result.length < total) result.push(half)
  }
  return result
}

function placeCentered(items, start, count, metrics, y, tier, opacity) {
  var result = []
  var offsets = centeredOffsets(count)
  var center = metrics.width / 2
  var step = metrics.cardWidth + metrics.gap
  for (var i = 0; i < count; i++) {
    var binding = items[start + i]
    if (!binding) break
    result.push({
      binding: binding,
      x: Math.round(center + offsets[i] * step - metrics.cardWidth / 2),
      y: Math.round(y),
      width: metrics.cardWidth,
      height: metrics.cardHeight,
      tier: tier,
      opacity: opacity
    })
  }
  return result
}

function append(destination, values) {
  for (var i = 0; i < values.length; i++) destination.push(values[i])
}

function denseLayout(items, metrics) {
  var placements = []
  var columns = metrics.crownColumns
  var index = 0
  var row = 0
  while (index < items.length) {
    var count = Math.min(columns, items.length - index)
    append(placements, placeCentered(items, index, count, metrics,
      row * (metrics.cardHeight + metrics.gap), "expanded", 1))
    index += count
    row += 1
  }
  return {
    items: placements,
    more: 0,
    total: items.length,
    visibleCount: items.length,
    expanded: true,
    height: Math.max(metrics.cardHeight, row * (metrics.cardHeight + metrics.gap) - metrics.gap),
    overflow: null,
    metrics: metrics
  }
}

function canopyLayout(items, viewport, expanded) {
  var source = Array.isArray(items) ? items : []
  var metrics = canopyMetrics(viewport, expanded)
  if (expanded === true) return denseLayout(source, metrics)

  var crown = metrics.crownColumns
  var capacity = crown + Math.max(0, crown - 1) + 4
  if (source.length <= capacity) return denseLayout(source, metrics)

  var placements = []
  append(placements, placeCentered(source, 0, crown, metrics, 0, "primary", 1))

  var center = metrics.width / 2
  var moreWidth = Math.round(metrics.cardWidth * 1.45)
  var secondCount = crown - 1
  var leftCount = Math.floor(secondCount / 2)
  var rightCount = secondCount - leftCount
  var secondY = metrics.cardHeight + metrics.gap
  var cursor = crown
  var i
  for (i = 0; i < leftCount; i++) {
    var leftBinding = source[cursor++]
    placements.push({ binding: leftBinding,
      x: Math.round(center - moreWidth / 2 - metrics.gap - metrics.cardWidth * (i + 1) - metrics.gap * i),
      y: secondY, width: metrics.cardWidth, height: metrics.cardHeight,
      tier: "secondary", opacity: 0.9 })
  }
  for (i = 0; i < rightCount; i++) {
    var rightBinding = source[cursor++]
    placements.push({ binding: rightBinding,
      x: Math.round(center + moreWidth / 2 + metrics.gap + (metrics.cardWidth + metrics.gap) * i),
      y: secondY, width: metrics.cardWidth, height: metrics.cardHeight,
      tier: "secondary", opacity: 0.9 })
  }

  for (i = 0; i < 4; i++) {
    var wingBinding = source[cursor++]
    if (!wingBinding) break
    var wingRow = Math.floor(i / 2)
    var onLeft = i % 2 === 0
    placements.push({
      binding: wingBinding,
      x: onLeft ? metrics.margin : metrics.width - metrics.margin - metrics.cardWidth,
      y: Math.round((metrics.cardHeight + metrics.gap) * (2 + wingRow)),
      width: metrics.cardWidth,
      height: metrics.cardHeight,
      tier: "wing",
      opacity: wingRow === 0 ? 0.76 : 0.62
    })
  }

  var height = (metrics.cardHeight + metrics.gap) * 4 - metrics.gap
  return {
    items: placements,
    more: Math.max(0, source.length - placements.length),
    total: source.length,
    visibleCount: placements.length,
    expanded: false,
    height: height,
    overflow: {
      x: Math.round(center - moreWidth / 2),
      y: secondY,
      width: moreWidth,
      height: metrics.cardHeight
    },
    metrics: metrics
  }
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
