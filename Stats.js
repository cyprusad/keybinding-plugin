.pragma library

var ID_RE = /^sha256:[0-9a-f]{64}$/
var DATE_RE = /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/
var TOP_LEVEL_KEYS = [
  "schemaVersion", "totalXp", "currentLevel", "streak",
  "lastQualifiedDay", "bindings", "dailyQuest"
]
var BINDING_KEYS = ["count", "firstUsed", "lastUsed", "daily"]
var QUEST_KEYS = ["date", "bindingId", "completed"]
var DAILY_LIMIT = 90

function validOpaqueId(value) {
  return typeof value === "string" && ID_RE.test(value)
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function isFiniteNumber(value) {
  return typeof value === "number" && isFinite(value)
}

function isNonNegativeInteger(value) {
  return isFiniteNumber(value) && Math.floor(value) === value && value >= 0
}

function hasOnlyKeys(value, allowed) {
  if (!isObject(value)) return false
  for (var key in value) if (allowed.indexOf(key) === -1) return false
  return true
}

function validDateKey(value) {
  if (value === null || value === undefined) return false
  var match = String(value).match(DATE_RE)
  if (!match) return false
  var year = Number(match[1])
  var month = Number(match[2])
  var day = Number(match[3])
  var date = new Date(year, month - 1, day)
  return date.getFullYear() === year && date.getMonth() === month - 1
    && date.getDate() === day
}

function validTimestamp(value) {
  return isFiniteNumber(value) && value >= 0
    && isFinite(new Date(value * 1000).getTime())
}

function dateKey(timestamp) {
  if (!validTimestamp(timestamp)) return ""
  var date = new Date(timestamp * 1000)
  function pad(value) { return value < 10 ? "0" + value : String(value) }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
}

function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function emptyStats() {
  return {
    schemaVersion: 1,
    totalXp: 0,
    currentLevel: 0,
    streak: 0,
    lastQualifiedDay: null,
    bindings: {},
    dailyQuest: null
  }
}

var LEVELS = [
  { index: 0, name: "Initiate", threshold: 0 },
  { index: 1, name: "Apprentice", threshold: 200 },
  { index: 2, name: "Tiler", threshold: 600 },
  { index: 3, name: "Navigator", threshold: 1200 },
  { index: 4, name: "Omarchist", threshold: 2000 },
  { index: 5, name: "Sensei", threshold: 3500 }
]

function levelForXp(totalXp) {
  var xp = isNonNegativeInteger(totalXp) ? totalXp : 0
  var selected = LEVELS[0]
  for (var i = 0; i < LEVELS.length; i++) {
    if (xp >= LEVELS[i].threshold) selected = LEVELS[i]
  }
  return {
    index: selected.index,
    name: selected.name,
    threshold: selected.threshold,
    nextThreshold: selected.index + 1 < LEVELS.length
      ? LEVELS[selected.index + 1].threshold : null
  }
}

function pruneDaily(daily) {
  var keys = Object.keys(daily).sort()
  while (keys.length > DAILY_LIMIT) delete daily[keys.shift()]
}

function normalize(raw) {
  var value = raw
  if (typeof value === "string") {
    if (value.trim() === "") return { ok: true, stats: emptyStats(), missing: true }
    try { value = JSON.parse(value) } catch (e) { return { ok: false, error: "invalid-json" } }
  }
  if (!isObject(value) || !hasOnlyKeys(value, TOP_LEVEL_KEYS) || value.schemaVersion !== 1)
    return { ok: false, error: "invalid-schema" }

  var stats = emptyStats()
  if (value.totalXp !== undefined) {
    if (!isNonNegativeInteger(value.totalXp)) return { ok: false, error: "invalid-total-xp" }
    stats.totalXp = value.totalXp
  }
  if (value.currentLevel !== undefined) {
    if (!isNonNegativeInteger(value.currentLevel)) return { ok: false, error: "invalid-level" }
    stats.currentLevel = value.currentLevel
  }
  if (value.streak !== undefined) {
    if (!isNonNegativeInteger(value.streak)) return { ok: false, error: "invalid-streak" }
    stats.streak = value.streak
  }
  if (value.lastQualifiedDay !== undefined && value.lastQualifiedDay !== null) {
    if (!validDateKey(value.lastQualifiedDay)) return { ok: false, error: "invalid-qualified-day" }
    stats.lastQualifiedDay = String(value.lastQualifiedDay)
  }

  if (value.bindings !== undefined) {
    if (!isObject(value.bindings)) return { ok: false, error: "invalid-bindings" }
    for (var id in value.bindings) {
      if (!ID_RE.test(id)) return { ok: false, error: "invalid-binding-id" }
      var entry = value.bindings[id]
      if (!isObject(entry) || !hasOnlyKeys(entry, BINDING_KEYS))
        return { ok: false, error: "invalid-binding-record" }

      var count = entry.count === undefined ? 0 : entry.count
      var first = entry.firstUsed === undefined ? 0 : entry.firstUsed
      var last = entry.lastUsed === undefined ? 0 : entry.lastUsed
      if (!isNonNegativeInteger(count)) return { ok: false, error: "invalid-binding-count" }
      if (!validTimestamp(first) && first !== 0) return { ok: false, error: "invalid-first-used" }
      if (!validTimestamp(last) && last !== 0) return { ok: false, error: "invalid-last-used" }
      if (first > 0 && last > 0 && first > last) return { ok: false, error: "invalid-used-order" }

      var daily = entry.daily === undefined ? {} : entry.daily
      if (!isObject(daily)) return { ok: false, error: "invalid-daily" }
      var normalizedDaily = {}
      for (var day in daily) {
        if (!validDateKey(day) || !isNonNegativeInteger(daily[day]))
          return { ok: false, error: "invalid-daily-entry" }
        normalizedDaily[day] = daily[day]
      }
      pruneDaily(normalizedDaily)
      stats.bindings[id] = {
        count: count,
        firstUsed: first,
        lastUsed: last,
        daily: normalizedDaily
      }
    }
  }

  if (value.dailyQuest !== undefined && value.dailyQuest !== null) {
    var quest = value.dailyQuest
    if (!isObject(quest) || !hasOnlyKeys(quest, QUEST_KEYS)
        || !validDateKey(quest.date)
        || typeof quest.bindingId !== "string" || !ID_RE.test(quest.bindingId)
        || typeof quest.completed !== "boolean")
      return { ok: false, error: "invalid-daily-quest" }
    stats.dailyQuest = {
      date: String(quest.date),
      bindingId: quest.bindingId,
      completed: quest.completed
    }
  }

  return { ok: true, stats: stats }
}

function recordObservation(stats, bindingId, timestamp) {
  var parsed = normalize(stats)
  var next = parsed.ok ? parsed.stats : emptyStats()
  var id = String(bindingId || "")
  if (!ID_RE.test(id) || !validTimestamp(timestamp)) return next

  var entry = next.bindings[id]
  var firstEver = !entry || entry.count === 0
  var day = dateKey(timestamp)
  var previousDayCount = entry && entry.daily ? Number(entry.daily[day] || 0) : 0
  var earnedXp = firstEver ? 50 : 0
  if (previousDayCount === 0) earnedXp += 10
  else if (previousDayCount <= 10) earnedXp += 2
  if (!entry) {
    entry = { count: 0, firstUsed: 0, lastUsed: 0, daily: {} }
    next.bindings[id] = entry
  }
  if (entry.firstUsed === 0) entry.firstUsed = timestamp
  entry.lastUsed = timestamp
  entry.count += 1
  entry.daily[day] = Number(entry.daily[day] || 0) + 1
  pruneDaily(entry.daily)
  if (next.dailyQuest && next.dailyQuest.date === day
      && next.dailyQuest.bindingId === id && next.dailyQuest.completed === false) {
    next.dailyQuest.completed = true
    earnedXp += 25
  }
  next.totalXp += earnedXp
  next.currentLevel = levelForXp(next.totalXp).index
  return next
}

function dailyCount(stats, bindingId, day) {
  var parsed = normalize(stats)
  if (!parsed.ok || !validDateKey(day) || !ID_RE.test(String(bindingId || ""))) return 0
  var entry = parsed.stats.bindings[String(bindingId)]
  return entry && entry.daily ? Number(entry.daily[day] || 0) : 0
}
