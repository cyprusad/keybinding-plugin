import QtQuick 2.15
import QtTest 1.3
import "../../GuideModel.js" as GuideModel

TestCase {
  name: "KeybindDojoGuideModel"

  function binding(number, modifiers, description, trackable, eligible) {
    return {
      id: "sha256:" + String(number).repeat(64),
      combo: modifiers.join(" + ") + " + KEY" + number,
      modifiers: modifiers,
      key: "KEY" + number,
      xkbCodes: [number + 10],
      description: description,
      category: "other",
      phase: "press",
      submap: "",
      dispatcherKind: "exec",
      trackable: trackable === undefined ? true : trackable,
      guideEligible: eligible === undefined ? true : eligible,
      repeat: false
    }
  }

  function catalog() {
    var bindings = []
    for (var i = 0; i < 14; i++) bindings.push(binding(i, ["SUPER"], "Command " + String.fromCharCode(90 - i)))
    bindings.push(binding(20, ["SUPER", "SHIFT"], "Shift command"))
    bindings.push(binding(21, ["SUPER", "CTRL"], "Hidden command", false))
    return { bindings: bindings }
  }

  function test_exactFilteringAndLimit() {
    var cards = GuideModel.cardModel(catalog(), "SUPER", 12)
    compare(cards.total, 14)
    compare(cards.items.length, 12)
    compare(cards.more, 2)
    compare(cards.items[0].description, "Command M")

    var shift = GuideModel.cardModel(catalog(), "SUPER_SHIFT", 12)
    compare(shift.total, 1)
    compare(shift.items[0].description, "Shift command")
    compare(GuideModel.cardModel(catalog(), "SHIFT", 12).total, 0)
  }

  function test_lanesAndAccessibilityFiltering() {
    var lanes = GuideModel.laneCounts(catalog())
    compare(lanes.SHIFT, 1)
    compare(lanes.CTRL, 1)
    compare(lanes.ALT, 0)
    compare(GuideModel.cardModel(catalog(), "SUPER_CTRL", 12).total, 0)
  }

  function test_suppressionAndDelayModes() {
    var state = {
      integrationState: "enabled",
      catalogState: "ready",
      desktopLocked: false,
      credentialPromptActive: false,
      activeWindowFullscreen: false,
      showInFullscreen: false
    }
    verify(GuideModel.eligible(state))
    state.desktopLocked = true
    verify(!GuideModel.eligible(state))
    state.desktopLocked = false
    state.credentialPromptActive = true
    verify(!GuideModel.eligible(state))
    state.credentialPromptActive = false
    state.activeWindowFullscreen = true
    verify(!GuideModel.eligible(state))
    state.showInFullscreen = true
    verify(GuideModel.eligible(state))

    compare(GuideModel.delayMode(false, 0), "hidden")
    compare(GuideModel.delayMode(true, 0), "immediate")
    compare(GuideModel.delayMode(true, 80), "delayed")
    compare(GuideModel.delayMode(true, 150), "delayed")
    compare(GuideModel.delayMode(true, 250), "delayed")
    compare(GuideModel.delayMode(true, -1), "disabled")
  }

  function test_focusAndBarPlacement() {
    verify(GuideModel.focusedVisible(true, "DP-1", "DP-1"))
    verify(!GuideModel.focusedVisible(true, "DP-1", "HDMI-A-1"))
    verify(!GuideModel.focusedVisible(false, "DP-1", "DP-1"))
    verify(!GuideModel.focusedVisible(true, "", "DP-1"))
    compare(GuideModel.barOffset("top", 32, false), 32)
    compare(GuideModel.barOffset("bottom", 32, false), 0)
    compare(GuideModel.barOffset("left", 32, false), 0)
    compare(GuideModel.barOffset("top", 32, true), 0)
  }
}
