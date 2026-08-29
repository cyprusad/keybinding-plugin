import QtQuick 2.15
import QtTest 1.3
import "../../Stats.js" as Stats

TestCase {
  name: "OmakeezStats"

  function id(letter) { return "sha256:" + Array(65).join(letter) }
  function timestamp(year, month, day) { return new Date(year, month - 1, day, 12, 0, 0).getTime() / 1000 }

  function test_emptyAndRoundTrip() {
    var empty = Stats.normalize("")
    verify(empty.ok)
    verify(empty.missing)
    compare(empty.stats.schemaVersion, 1)
    compare(Object.keys(empty.stats.bindings).length, 0)

    var first = Stats.recordObservation(empty.stats, id("a"), timestamp(2026, 1, 2))
    var roundTrip = Stats.normalize(JSON.stringify(first))
    verify(roundTrip.ok)
    compare(JSON.stringify(roundTrip.stats), JSON.stringify(first))
  }

  function test_rejectsInvalidFieldFamilies() {
    verify(!Stats.normalize("not json").ok)
    verify(!Stats.normalize({ schemaVersion: 2 }).ok)
    verify(!Stats.normalize({ schemaVersion: 1, unexpected: true }).ok)
    verify(!Stats.normalize({ schemaVersion: 1, totalXp: -1 }).ok)
    verify(!Stats.normalize({ schemaVersion: 1, streak: 1.5 }).ok)
    verify(!Stats.normalize({ schemaVersion: 1, lastQualifiedDay: "2026-02-30" }).ok)
    verify(!Stats.normalize({ schemaVersion: 1, bindings: { "not-an-id": { count: 1 } } }).ok)
    var negativeCount = { schemaVersion: 1, bindings: {} }
    negativeCount.bindings[id("a")] = { count: -1 }
    verify(!Stats.normalize(negativeCount).ok)
    var invalidTimestamp = { schemaVersion: 1, bindings: {} }
    invalidTimestamp.bindings[id("a")] = { count: 1, firstUsed: "now" }
    verify(!Stats.normalize(invalidTimestamp).ok)
    var invalidDaily = { schemaVersion: 1, bindings: {} }
    invalidDaily.bindings[id("a")] = { count: 1, daily: { "2026-02-30": 1 } }
    verify(!Stats.normalize(invalidDaily).ok)
    verify(!Stats.normalize({ schemaVersion: 1, dailyQuest: {
      date: "2026-01-01", bindingId: id("a"), completed: "no"
    } }).ok)
  }

  function test_recordIsImmutableAndTracksAggregateFields() {
    var original = Stats.emptyStats()
    var when = timestamp(2026, 3, 4)
    var next = Stats.recordObservation(original, id("b"), when)
    verify(next !== original)
    compare(Object.keys(original.bindings).length, 0)
    compare(next.bindings[id("b")].count, 1)
    compare(next.bindings[id("b")].firstUsed, when)
    compare(next.bindings[id("b")].lastUsed, when)
    compare(Stats.dailyCount(next, id("b"), "2026-03-04"), 1)
    compare(Object.keys(Stats.recordObservation(next, "bad-id", when).bindings).length, 1)
  }

  function test_prunesToNewestNinetyLocalDays() {
    var stats = Stats.emptyStats()
    var bindingId = id("c")
    for (var day = 1; day <= 95; day++)
      stats = Stats.recordObservation(stats, bindingId, timestamp(2026, 1, day))

    var daily = stats.bindings[bindingId].daily
    compare(Object.keys(daily).length, 90)
    verify(daily["2026-01-01"] === undefined)
    verify(daily["2026-01-05"] === undefined)
    compare(daily["2026-01-06"], 1)
    compare(daily["2026-04-05"], 1)
  }
}
