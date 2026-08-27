import QtQuick 2.15
import QtTest 1.3
import "../../Stats.js" as Stats
import "../../Recommendations.js" as Recommendations

TestCase {
  name: "KeybindDojoGamification"

  function id(letter) { return "sha256:" + Array(65).join(letter) }
  function timestamp(day) { return new Date(2026, 0, day, 12, 0, 0).getTime() / 1000 }
  function dayKey(day) { return Stats.dateKey(timestamp(day)) }

  function test_xpBranchesAndRepeatCap() {
    var questId = id("a")
    var stats = Stats.emptyStats()
    stats.dailyQuest = { date: dayKey(1), bindingId: questId, completed: false }
    stats = Stats.recordObservation(stats, questId, timestamp(1))
    compare(stats.totalXp, 85) // 50 first-ever + 10 first-day + 25 quest
    verify(stats.dailyQuest.completed)

    for (var repeat = 0; repeat < 10; repeat++)
      stats = Stats.recordObservation(stats, questId, timestamp(1))
    compare(stats.totalXp, 105) // ten repeat awards, then the cap is reached
    stats = Stats.recordObservation(stats, questId, timestamp(1))
    compare(stats.totalXp, 105)
    stats = Stats.recordObservation(stats, questId, timestamp(2))
    compare(stats.totalXp, 115) // a new day earns the first-of-day bonus
  }

  function test_levelBoundaries() {
    var cases = [
      { xp: 0, index: 0, name: "Initiate", next: 200 },
      { xp: 199, index: 0, name: "Initiate", next: 200 },
      { xp: 200, index: 1, name: "Apprentice", next: 600 },
      { xp: 600, index: 2, name: "Tiler", next: 1200 },
      { xp: 1200, index: 3, name: "Navigator", next: 2000 },
      { xp: 2000, index: 4, name: "Omarchist", next: 3500 },
      { xp: 3500, index: 5, name: "Sensei", next: null },
      { xp: 10000, index: 5, name: "Sensei", next: null }
    ]
    for (var i = 0; i < cases.length; i++) {
      var level = Recommendations.levelForXp(cases[i].xp)
      compare(level.index, cases[i].index)
      compare(level.name, cases[i].name)
      compare(level.nextThreshold, cases[i].next)
    }
  }

  function test_qualificationStreakAndFutureDates() {
    var stats = Stats.emptyStats()
    var ids = [id("a"), id("b"), id("c")]
    for (var day = 1; day <= 3; day++)
      for (var i = 0; i < ids.length; i++)
        stats = Stats.recordObservation(stats, ids[i], timestamp(day))
    verify(Recommendations.qualifiesForDay(stats, dayKey(1)))
    compare(Recommendations.recalculateStreak(stats, dayKey(3)), 3)

    var missing = Stats.emptyStats()
    for (i = 0; i < ids.length; i++) {
      missing = Stats.recordObservation(missing, ids[i], timestamp(1))
      missing = Stats.recordObservation(missing, ids[i], timestamp(3))
    }
    compare(Recommendations.recalculateStreak(missing, dayKey(3)), 1)
    compare(Recommendations.recalculateStreak(missing, dayKey(5)), 0)

    var persisted = Stats.emptyStats()
    for (i = 0; i < ids.length; i++) persisted = Stats.recordObservation(persisted, ids[i], timestamp(1))
    persisted.lastQualifiedDay = dayKey(1)
    persisted.streak = 1
    for (i = 0; i < ids.length; i++) persisted = Stats.recordObservation(persisted, ids[i], timestamp(3))
    compare(Recommendations.recalculateStreak(persisted, dayKey(3)), 1)

    var withFuture = Stats.recordObservation(stats, id("d"), timestamp(10))
    compare(Recommendations.recalculateStreak(withFuture, dayKey(3)), 3)
  }

  function test_streakSurvivesNinetyDayDailyRetention() {
    var stats = Stats.emptyStats()
    var ids = [id("a"), id("b"), id("c")]
    for (var day = 1; day <= 100; day++) {
      for (var i = 0; i < ids.length; i++)
        stats = Stats.recordObservation(stats, ids[i], timestamp(day))
      if (Recommendations.qualifiesForDay(stats, dayKey(day))) {
        stats.streak = Recommendations.recalculateStreak(stats, dayKey(day))
        stats.lastQualifiedDay = dayKey(day)
      }
    }
    compare(stats.streak, 100)
    compare(Recommendations.recalculateStreak(stats, dayKey(100)), 100)
    compare(Object.keys(stats.bindings[ids[0]].daily).length, 90)
  }

  function catalogEntry(letter, description) {
    return { id: id(letter), description: description, trackable: true, available: true }
  }

  function test_recommendationFilteringAndStableRanking() {
    var goodA = catalogEntry("a", "Alpha")
    var goodF = catalogEntry("f", "Foxtrot")
    var unavailable = catalogEntry("b", "Unavailable")
    unavailable.available = false
    var mouse = catalogEntry("c", "Mouse")
    mouse.trackable = false
    var empty = catalogEntry("d", "")
    var owned = catalogEntry("e", "Plugin control")
    owned.pluginOwned = true
    var catalog = { bindings: [goodF, unavailable, mouse, empty, owned, goodA] }
    var stats = Stats.recordObservation(Stats.emptyStats(), goodF.id, timestamp(1))
    var before = JSON.stringify(stats)
    var result = Recommendations.recommendBindings(catalog, stats, 10, dayKey(2))
    compare(result.length, 2)
    compare(result[0], goodA.id)
    compare(result[1], goodF.id)
    compare(JSON.stringify(stats), before)
    compare(Recommendations.recommendBindings(catalog, stats, 1, dayKey(2)).length, 1)
    compare(Recommendations.recommendBindings({ bindings: [] }, stats, 10, dayKey(2)).length, 0)
  }

  function test_questFreezeCompletionAndDisappearance() {
    var first = catalogEntry("a", "Alpha")
    var second = catalogEntry("b", "Beta")
    var catalog = { bindings: [first, second] }
    var day = dayKey(1)
    var stats = Stats.emptyStats()
    compare(Recommendations.chooseDailyQuest(catalog, stats, day), first.id)
    stats.dailyQuest = { date: day, bindingId: second.id, completed: false }
    compare(Recommendations.chooseDailyQuest(catalog, stats, day), second.id)
    catalog.bindings = [first]
    compare(Recommendations.chooseDailyQuest(catalog, stats, day), first.id)

    var unchanged = JSON.stringify(stats)
    stats.dailyQuest.bindingId = first.id
    stats = Stats.recordObservation(stats, first.id, timestamp(1))
    compare(stats.totalXp, 85) // the service persists the replacement before use
    verify(JSON.stringify(stats) !== unchanged)
    stats = Stats.recordObservation(stats, first.id, timestamp(1))
    verify(stats.totalXp < 110) // quest completion is awarded only once
  }
}
