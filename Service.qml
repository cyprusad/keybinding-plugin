import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool guideVisible: false
  property double pendingSuperReceivedMs: 0
  property int observedEventCount: 0
  property var latencySamples: []

  function protocolPayload(event) {
    if (!event || String(event.name || "") !== "custom") return ""
    var payload = String(event.data || "")
    return payload.indexOf("keybind-dojo:v1:") === 0 ? payload : ""
  }

  function handleProtocolEvent(payload) {
    observedEventCount += 1
    if (payload === "keybind-dojo:v1:super:down") {
      pendingSuperReceivedMs = Date.now()
      guideVisible = true
    } else if (payload === "keybind-dojo:v1:super:up") {
      guideVisible = false
    }
  }

  function recordGuideVisible() {
    if (pendingSuperReceivedMs <= 0) return
    var next = latencySamples.slice()
    next.push(Math.max(0, Date.now() - pendingSuperReceivedMs))
    latencySamples = next
    pendingSuperReceivedMs = 0
  }

  function resetDiagnostics() {
    guideVisible = false
    pendingSuperReceivedMs = 0
    observedEventCount = 0
    latencySamples = []
  }

  function diagnosticsJson() {
    return JSON.stringify({
      eventCount: observedEventCount,
      sampleCount: latencySamples.length,
      samplesMs: latencySamples,
      guideVisible: guideVisible
    })
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var payload = root.protocolPayload(event)
      if (payload !== "") root.handleProtocolEvent(payload)
    }
  }

  IpcHandler {
    target: "keybind-dojo-feasibility"
    function diagnostics(): string { return root.diagnosticsJson() }
    function reset(): string { root.resetDiagnostics(); return "ok" }
  }

  SuperGuide {
    service: root
  }
}
