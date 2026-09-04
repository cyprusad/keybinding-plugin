import QtQuick 2.15
import QtTest 1.3
import "../../ServiceModel.js" as Model

TestCase {
  name: "OmakeezServiceModel"

  function id(letter) { return "sha256:" + Array(65).join(letter) }

  function validCatalog() {
    var binding = {
      id: id("b"),
      combo: "SUPER + RETURN",
      modifiers: ["SUPER"],
      key: "RETURN",
      xkbCodes: [36],
      description: "Terminal",
      category: "applications",
      phase: "press",
      submap: "",
      dispatcherKind: "exec",
      trackable: true,
      guideEligible: true,
      repeat: false
    }
    var release = JSON.parse(JSON.stringify(binding))
    release.id = id("c")
    release.phase = "release"
    return {
      schemaVersion: 1,
      generatedAt: 1,
      sourceHash: id("a"),
      bindings: [binding, release]
    }
  }

  function test_validCatalogAndLookup() {
    var result = Model.normalizeCatalog(validCatalog())
    verify(result.ok)
    compare(result.catalog.bindings.length, 2)
    compare(result.catalog.byId[id("b")].description, "Terminal")
  }

  function test_catalogRejectsMalformedInputs() {
    verify(!Model.normalizeCatalog("not json").ok)
    var wrongSchema = validCatalog()
    wrongSchema.schemaVersion = 2
    verify(!Model.normalizeCatalog(wrongSchema).ok)

    var duplicate = validCatalog()
    duplicate.bindings.push(duplicate.bindings[0])
    verify(!Model.normalizeCatalog(duplicate).ok)

    var badBinding = validCatalog()
    badBinding.bindings[0].category = "invented"
    verify(!Model.normalizeCatalog(badBinding).ok)

    var badTypes = validCatalog()
    badTypes.bindings[0].trackable = "true"
    verify(!Model.normalizeCatalog(badTypes).ok)
  }

  function test_everyValidProtocolForm() {
    var catalog = Model.normalizeCatalog(validCatalog()).catalog
    compare(Model.parseProtocol("omakeez:v1:super:down", catalog).root, "SUPER")
    compare(Model.parseProtocol("omakeez:v1:guide:down:ALT", catalog).root, "ALT")
    compare(Model.parseProtocol("omakeez:v1:guide:up", catalog).phase, "up")
    compare(Model.parseProtocol("omakeez:v1:mods:SUPER_SHIFT_CTRL_ALT", catalog).modifiers, "SUPER_SHIFT_CTRL_ALT")
    compare(Model.parseProtocol("omakeez:v1:mods:SHIFT_ALT", catalog).modifiers, "SHIFT_ALT")
    var press = Model.parseProtocol("omakeez:v1:match:" + id("b") + ":press", catalog)
    verify(press.ok)
    verify(press.known)
    compare(press.phase, "press")
    var release = Model.parseProtocol("omakeez:v1:match:" + id("c") + ":release", catalog)
    verify(release.ok)
    compare(release.phase, "release")
  }

  function test_protocolRejectsMalformedAndUnknownForms() {
    var catalog = Model.normalizeCatalog(validCatalog()).catalog
    verify(!Model.parseProtocol("omakeez:v2:super:down", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:super:down:extra", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:guide:down:CAPS", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:guide:up:extra", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:mods:SUPER_CTRL_SHIFT", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:match:" + id("b") + ":press:extra", catalog).ok)
    verify(!Model.parseProtocol("omakeez:v1:match:" + id("b") + ":release", catalog).ok)
    var unknown = Model.parseProtocol("omakeez:v1:match:" + id("d") + ":press", catalog)
    verify(unknown.ok)
    verify(!unknown.known)
  }

  function test_settingsAndShellLookup() {
    compare(Model.normalizeDelay(0), 0)
    compare(Model.normalizeDelay(80), 80)
    compare(Model.normalizeDelay("150"), 150)
    compare(Model.normalizeDelay("disabled"), -1)
    compare(Model.normalizeDelay(-1), -1)
    compare(Model.normalizeDelay("-1"), -1)
    compare(Model.normalizeDelay(99), 0)
    compare(Model.normalizeFullscreen(true), true)
    compare(Model.normalizeFullscreen("true"), false)
    compare(Model.normalizeGuideRoot(undefined), true)
    compare(Model.normalizeGuideRoot(true), true)
    compare(Model.normalizeGuideRoot(false), false)

    var config = { bar: { layout: { left: [], center: [], right: [
      { id: "io.github.cyprusad.omakeez", guideDelayMs: 150,
        guideDoubleTapEnabled: true, showInFullscreen: true,
        guideSuperEnabled: false, guideShiftEnabled: true, guideCtrlEnabled: false, guideAltEnabled: true }
    ] } } }
    var settings = Model.settingsFor(config, "io.github.cyprusad.omakeez")
    compare(settings.guideDelayMs, 150)
    compare(settings.guideDoubleTapEnabled, true)
    compare(settings.showInFullscreen, true)
    compare(settings.guideSuperEnabled, false)
    compare(settings.guideCtrlEnabled, false)
    compare(Model.settingsFor({}, "io.github.cyprusad.omakeez").guideDelayMs, undefined)
  }

  function test_activationIsOneAxis() {
    // Every stored pair resolves to exactly one choice on the control.
    compare(Model.activationIndex(0, false), 0)
    compare(Model.activationIndex(80, false), 1)
    compare(Model.activationIndex(150, false), 2)
    compare(Model.activationIndex(250, false), 3)
    compare(Model.activationIndex(0, true), 4)
    compare(Model.activationIndex(-1, false), 5)

    // A config written before the two settings were merged can hold a delay
    // and the tap together. The tap wins and the delay drops to zero, so the
    // press after the tap opens the guide instead of starting a hold.
    compare(Model.activationIndex(250, true), 4)
    compare(Model.effectiveDelay(250, true), 0)
    compare(Model.effectiveDoubleTap(250, true), true)

    // Off wins over both, because off has to mean off.
    compare(Model.activationIndex(-1, true), 5)
    compare(Model.effectiveDelay(-1, true), -1)
    compare(Model.effectiveDoubleTap(-1, true), false)

    // A plain delay keeps its value and never implies a tap.
    compare(Model.effectiveDelay(150, false), 150)
    compare(Model.effectiveDoubleTap(150, false), false)

    // Junk falls back to the first choice rather than an unreachable state.
    compare(Model.activationIndex(99, false), 0)
    compare(Model.effectiveDelay(undefined, undefined), 0)
    compare(Model.activationAt(-1).delayMs, 0)
    compare(Model.activationAt(99).delayMs, 0)
    compare(Model.activationAt("notanumber").doubleTapEnabled, false)

    // Selecting a choice and reading it back is a round trip, which is what
    // keeps the panel selection and the stored config from drifting apart.
    for (var i = 0; i < 6; i++) {
      var choice = Model.activationAt(i)
      compare(Model.activationIndex(choice.delayMs, choice.doubleTapEnabled), i)
    }
  }

  function test_doubleTapArming() {
    // A hold with nothing armed stays silent.
    var down = Model.tapGateDown(Model.emptyTapState(), "SUPER", 1000)
    compare(down.show, false)

    // Releasing that press quickly arms the same root...
    var armed = Model.tapGateUp(down.state, 1100)
    compare(armed.armedRoot, "SUPER")

    // ...and the next press of it opens the guide.
    var second = Model.tapGateDown(armed, "SUPER", 1200)
    compare(second.show, true)
    compare(second.state.armedRoot, "")

    // Arming is per root: a tap of SUPER does not open SHIFT.
    compare(Model.tapGateDown(armed, "SHIFT", 1200).show, false)

    // Arming expires.
    compare(Model.tapGateDown(armed, "SUPER", 1100 + 801).show, false)

    // A long press is a hold, not a tap, so it never arms.
    var held = Model.tapGateDown(Model.emptyTapState(), "SUPER", 2000)
    compare(Model.tapGateUp(held.state, 2000 + 401).armedRoot, "")

    // Releasing a press that opened a guide clears the state instead of
    // re-arming, so one tap cannot open two guides.
    compare(Model.tapGateUp(second.state, 1250).armedRoot, "")

    // A backwards clock reads as not armed rather than arming forever.
    compare(Model.tapGateDown(armed, "SUPER", 900).show, false)

    // Malformed state is treated as empty.
    compare(Model.tapGateDown(null, "SUPER", 10).show, false)
    compare(Model.tapGateUp(undefined, 10).armedRoot, "")

    compare(Model.normalizeDoubleTap(true), true)
    compare(Model.normalizeDoubleTap("true"), false)
    compare(Model.normalizeDoubleTap(undefined), false)
  }

  function test_fullscreenAndEventClassification() {
    compare(Model.parseActiveWindow('{"fullscreen":true}').fullscreen, true)
    compare(Model.parseActiveWindow('{"fullscreen":2}').fullscreen, true)
    compare(Model.parseActiveWindow('{"fullscreen":0}').fullscreen, false)
    verify(!Model.parseActiveWindow('{"fullscreen":"1"}').ok)
    verify(!Model.parseActiveWindow('{"class":"kitty"}').ok)
    verify(Model.isCatalogChangeEvent("configreloaded"))
    verify(Model.isCatalogChangeEvent("activelayout"))
    verify(Model.isFullscreenEvent("activewindowv2"))
    verify(!Model.isFullscreenEvent("custom"))
  }
}
