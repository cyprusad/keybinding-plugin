.pragma library

var ID_RE = /^sha256:[0-9a-f]{64}$/
var DATE_RE = /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/
var LEVELS = [
  { index: 0, name: "Initiate", threshold: 0 },
  { index: 1, name: "Apprentice", threshold: 200 },
  { index: 2, name: "Tiler", threshold: 600 },
  { index: 3, name: "Navigator", threshold: 1200 },
  { index: 4, name: "Omarchist", threshold: 2000 },
  { index: 5, name: "Sensei", threshold: 3500 }
]

function validOpaqueId(value) { return typeof value === "string" && ID_RE.test(value) }

function validDay(value) {
  if (typeof value !== "string") return false
  var match = value.match(DATE_RE)
  if (!match) return false
  var date = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
  return date.getFullYear() === Number(match[1])
    && date.getMonth() === Number(match[2]) - 1
    && date.getDate() === Number(match[3])
}

function emptyStats() {
  return { schemaVersion: 1, totalXp: 0, currentLevel: 0, streak: 0,
    lastQualifiedDay: null, bindings: {}, dailyQuest: null }
}

function clone(value) { return JSON.parse(JSON.stringify(value)) }

function normalizedStats(value) {
  var parsed = value
  if (typeof parsed === "string") {
    try { parsed = JSON.parse(parsed) } catch (e) { return emptyStats() }
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return emptyStats()
  var result = emptyStats()
  result.totalXp = Number(parsed.totalXp || 0)
  result.currentLevel = Number(parsed.currentLevel || 0)
  result.streak = Number(parsed.streak || 0)
  result.lastQualifiedDay = parsed.lastQualifiedDay || null
  result.bindings = parsed.bindings && typeof parsed.bindings === "object" ? clone(parsed.bindings) : {}
  result.dailyQuest = parsed.dailyQuest ? clone(parsed.dailyQuest) : null
  return result
}

function dateKey(timestamp) {
  var date = new Date(Number(timestamp) * 1000)
  function pad(value) { return value < 10 ? "0" + value : String(value) }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
}

function dayDate(day) {
  if (!validDay(day)) return null
  var parts = day.split("-")
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 12, 0, 0, 0)
}

function dayKey(date) { return dateKey(date.getTime() / 1000) }

function shiftDay(day, amount) {
  var date = dayDate(day)
  if (!date) return ""
  date.setDate(date.getDate() + amount)
  return dayKey(date)
}

function levelForXp(totalXp) {
  var xp = Number(totalXp)
  if (!isFinite(xp) || xp < 0 || Math.floor(xp) !== xp) xp = 0
  var selected = LEVELS[0]
  for (var i = 0; i < LEVELS.length; i++) if (xp >= LEVELS[i].threshold) selected = LEVELS[i]
  return {
    index: selected.index,
    name: selected.name,
    threshold: selected.threshold,
    nextThreshold: selected.index + 1 < LEVELS.length
      ? LEVELS[selected.index + 1].threshold : null
  }
}

function qualifiesForDay(stats, date) {
  var day = String(date || "")
  if (!validDay(day)) return false
  var value = normalizedStats(stats)
  var distinct = {}
  for (var id in value.bindings) {
    var entry = value.bindings[id]
    if (entry && entry.daily && Number(entry.daily[day] || 0) > 0) distinct[id] = true
  }
  return Object.keys(distinct).length >= 3
}

function qualifiedDays(stats, today) {
  var value = normalizedStats(stats)
  var days = {}
  for (var id in value.bindings) {
    var daily = value.bindings[id].daily || {}
    for (var day in daily)
      if (validDay(day) && day <= today && Number(daily[day]) > 0) days[day] = true
  }
  var qualified = []
  for (var candidate in days) if (qualifiesForDay(value, candidate)) qualified.push(candidate)
  qualified.sort()
  return qualified
}

function recalculateStreak(stats, today) {
  var day = String(today || "")
  if (!validDay(day)) return 0
  var value = normalizedStats(stats)
  var previous = value.lastQualifiedDay
  if (previous && previous <= day) {
    var yesterday = shiftDay(day, -1)
    if (previous === day) return value.streak
    if (previous === yesterday && value.streak > 0)
      return value.streak + (qualifiesForDay(value, day) ? 1 : 0)
    if (previous < yesterday) return qualifiesForDay(value, day) ? 1 : 0
  }
  var qualified = qualifiedDays(value, day)
  if (qualified.length === 0) return 0
  var lookup = {}
  for (var i = 0; i < qualified.length; i++) lookup[qualified[i]] = true
  var latest = qualified[qualified.length - 1]
  var distance = 0
  var cursor = latest
  while (lookup[cursor]) {
    distance += 1
    cursor = shiftDay(cursor, -1)
  }
  var gap = dayDate(day).getTime() - dayDate(latest).getTime()
  if (gap > 86400000) return 0
  return distance
}

function eligibleBinding(binding) {
  if (!binding || binding.trackable !== true) return false
  if (binding.available === false || binding.unavailable === true) return false
  if (String(binding.description || "").trim() === "") return false
  if (binding.pluginOwned === true || binding.owner === "io.github.cyprusad.keybind-dojo") return false
  return validOpaqueId(binding.id)
}

function candidates(catalog, stats) {
  var value = normalizedStats(stats)
  var bindings = catalog && Array.isArray(catalog.bindings) ? catalog.bindings : []
  var result = []
  for (var i = 0; i < bindings.length; i++) {
    var binding = bindings[i]
    if (!eligibleBinding(binding)) continue
    var entry = value.bindings[binding.id]
    result.push({
      id: binding.id,
      neverUsed: !entry || entry.count === 0,
      lastUsed: entry && entry.lastUsed > 0 ? entry.lastUsed : 0,
      count: entry ? entry.count : 0
    })
  }
  result.sort(function(a, b) {
    if (a.neverUsed !== b.neverUsed) return a.neverUsed ? -1 : 1
    if (a.lastUsed !== b.lastUsed) return a.lastUsed - b.lastUsed
    if (a.count !== b.count) return a.count - b.count
    return a.id < b.id ? -1 : a.id > b.id ? 1 : 0
  })
  return result
}

function recommendBindings(catalog, stats, limit, date) {
  var maximum = Number(limit)
  if (!isFinite(maximum) || maximum <= 0) return []
  maximum = Math.floor(maximum)
  var ranked = candidates(catalog, stats)
  var result = []
  for (var i = 0; i < ranked.length && i < maximum; i++) result.push(ranked[i].id)
  return result
}

function chooseDailyQuest(catalog, stats, date) {
  var day = String(date || "")
  if (!validDay(day)) return null
  var value = normalizedStats(stats)
  var active = {}
  var bindings = catalog && Array.isArray(catalog.bindings) ? catalog.bindings : []
  for (var i = 0; i < bindings.length; i++) if (eligibleBinding(bindings[i])) active[bindings[i].id] = true
  if (value.dailyQuest && value.dailyQuest.date === day && active[value.dailyQuest.bindingId])
    return value.dailyQuest.bindingId
  var ranked = candidates(catalog, value)
  return ranked.length > 0 ? ranked[0].id : null
}
