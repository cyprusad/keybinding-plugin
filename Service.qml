import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "ServiceModel.js" as Model
import "Stats.js" as Stats
import "Recommendations.js" as Recommendations

Item {
  id: root

  signal bindingMatched(string bindingId)

  readonly property string moduleName: "io.github.cyprusad.omakeez"
  property var shell: null
  property var manifest: null

  property string integrationState: "disabled"
  property var integrationDetails: ({})
  property var catalog: null
  property var stats: Stats.emptyStats()
  property bool guideVisible: false
  property string activeModifiers: ""
  property string activeGuideRoot: ""
  property string highlightedBindingId: ""
  property int guideDelayMs: 0
  property bool showInFullscreen: false
  property bool guideSuperEnabled: true
  property bool guideShiftEnabled: true
  property bool guideCtrlEnabled: true
  property bool guideAltEnabled: true
  property bool desktopLocked: false
  property bool credentialPromptActive: false
  property bool activeWindowFullscreen: false

  property string catalogState: "loading"
  property string statsState: "loading"
  property bool statsLoaded: false
  property bool statsDirty: false
  property bool statsResetPending: false
  property bool statsArchivePending: false
  property string statsArchiveAction: ""
  property string statsWriteOutput: ""
  property var observedProtocolKeys: ({})
  property string manualSnippet: ""
  property string lastProtocolError: ""
  property int bridgeEventCount: 0
  property var sessionDiagnostics: ({
    catalogLoadFailures: 0,
    integrationFailures: 0,
    fullscreenQueryCount: 0,
    fullscreenQueryFailures: 0
  })

  // These diagnostics remain intentionally in memory only. They are useful to
  // the feasibility IPC target and do not become a statistics implementation.
  property double pendingGuideReceivedMs: 0
  property int observedEventCount: 0
  property var latencySamples: []

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string stateDir: stateHome + "/omarchy/omakeez"

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.substring(7))
    return value
  }

  readonly property string generatorPath: localPath(Qt.resolvedUrl("scripts/generate-catalog"))
  readonly property string controllerPath: localPath(Qt.resolvedUrl("scripts/bridge-control"))
  readonly property string statsStorePath: localPath(Qt.resolvedUrl("scripts/stats-store"))
  readonly property string statsPath: stateDir + "/stats.json"
  readonly property string statsRecoveryDir: stateDir + "/recovery"
  readonly property bool catalogGenerationRunning: catalogGenerationProcess.running
  readonly property bool integrationInspectRunning: integrationInspectProcess.running
  readonly property bool integrationMutationRunning: integrationMutationProcess.running
  readonly property bool statsWriteRunning: statsWriteProcess.running
  readonly property bool statsRecoveryRunning: statsArchiveProcess.running
  readonly property var currentLevel: Stats.levelForXp(stats.totalXp)
  readonly property int currentStreak: Math.max(0, Number(stats.streak || 0))
  readonly property var dailyQuest: dailyQuestForToday()

  function protocolPayload(event) {
    if (!event || String(event.name || "") !== "custom") return ""
    var payload = String(event.data || "")
    return payload.indexOf("omakeez:") === 0 ? payload : ""
  }

  function setDiagnostic(name, delta) {
    var next = {}
    for (var key in sessionDiagnostics) next[key] = sessionDiagnostics[key]
    next[name] = Number(next[name] || 0) + Number(delta || 1)
    sessionDiagnostics = next
  }

  function handleProtocolEvent(payload) {
    bridgeEventCount += 1
    observedEventCount += 1
    var parsed = Model.parseProtocol(payload, root.catalog)
    if (!parsed.ok) {
      lastProtocolError = parsed.error
      return false
    }

    lastProtocolError = ""
    if (parsed.type === "guide") {
      if (parsed.phase === "down") {
        if (!root.guideRootEnabled(parsed.root)) {
          activeModifiers = ""
          activeGuideRoot = ""
          guideVisible = false
          pendingGuideReceivedMs = 0
          return true
        }
        pendingGuideReceivedMs = Date.now()
        activeGuideRoot = parsed.root
        activeModifiers = parsed.root
        highlightedBindingId = ""
        guideVisible = true
      } else {
        activeModifiers = ""
        activeGuideRoot = ""
        guideVisible = false
        pendingGuideReceivedMs = 0
      }
      return true
    }
    if (parsed.type === "mods") {
      if (guideVisible) activeModifiers = parsed.modifiers
      return true
    }
    if (parsed.type === "match") {
      if (!parsed.known) {
        lastProtocolError = "unknown-binding-id"
        return false
      }
      highlightedBindingId = parsed.id
      root.recordStatsObservation(parsed.id, parsed.phase)
      bindingMatched(parsed.id)
      return true
    }
    return false
  }

  function recordGuideVisible() {
    if (pendingGuideReceivedMs <= 0) return
    var next = latencySamples.slice()
    next.push(Math.max(0, Date.now() - pendingGuideReceivedMs))
    latencySamples = next
    pendingGuideReceivedMs = 0
  }

  function resetDiagnostics() {
    guideVisible = false
    activeModifiers = ""
    activeGuideRoot = ""
    highlightedBindingId = ""
    pendingGuideReceivedMs = 0
    observedEventCount = 0
    bridgeEventCount = 0
    latencySamples = []
    lastProtocolError = ""
  }

  function diagnosticsJson() {
    return JSON.stringify({
      eventCount: observedEventCount,
      bridgeEventCount: bridgeEventCount,
      sampleCount: latencySamples.length,
      samplesMs: latencySamples,
      guideVisible: guideVisible,
      catalogState: catalogState,
      integrationState: integrationState,
      lastProtocolError: lastProtocolError,
      sessionDiagnostics: sessionDiagnostics
    })
  }

  function loadCatalog(raw) {
    var result = Model.normalizeCatalog(raw)
    if (!result.ok) {
      catalog = null
      catalogState = "error"
      setDiagnostic("catalogLoadFailures", 1)
      return false
    }
    catalog = result.catalog
    catalogState = "ready"
    return true
  }

  function bindingForId(id) {
    var key = String(id || "")
    return catalog && catalog.byId ? (catalog.byId[key] || null) : null
  }

  function recordStatsObservation(bindingId, phase) {
    if (!statsLoaded || !catalog || !catalog.byId || !catalog.byId[bindingId]) return false
    var key = String(bindingId) + ":" + String(phase)
    if (root.observedProtocolKeys[key] === true) return false
    var keys = {}
    for (var observed in root.observedProtocolKeys) keys[observed] = true
    keys[key] = true
    root.observedProtocolKeys = keys
    Qt.callLater(function() { root.observedProtocolKeys = ({}) })

    var timestamp = Date.now() / 1000
    var today = Stats.dateKey(timestamp)
    var prepared = Stats.normalize(stats).stats
    var questId = Recommendations.chooseDailyQuest(catalog, prepared, today)
    if (!prepared.dailyQuest || prepared.dailyQuest.date !== today
        || !catalog.byId[prepared.dailyQuest.bindingId]) {
      prepared.dailyQuest = questId ? {
        date: today, bindingId: questId, completed: false
      } : null
    }
    var next = Stats.recordObservation(prepared, bindingId, timestamp)
    next.streak = Recommendations.recalculateStreak(next, today)
    if (Recommendations.qualifiesForDay(next, today)
        && (!next.lastQualifiedDay || today > next.lastQualifiedDay))
      next.lastQualifiedDay = today
    if (JSON.stringify(next) === JSON.stringify(stats)) return false
    stats = next
    statsDirty = true
    if (!statsFlushTimer.running && !statsWriteProcess.running && !statsArchiveProcess.running)
      statsFlushTimer.start()
    return true
  }

  function recommendations(limit) {
    return Recommendations.recommendBindings(catalog, stats, limit,
      Stats.dateKey(Date.now() / 1000))
  }

  function dailyQuestForToday() {
    if (!statsLoaded || !catalog) return null
    var today = Stats.dateKey(Date.now() / 1000)
    var id = Recommendations.chooseDailyQuest(catalog, stats, today)
    if (!id) return null
    if (stats.dailyQuest && stats.dailyQuest.date === today
        && stats.dailyQuest.bindingId === id)
      return {
        date: today, bindingId: id, completed: stats.dailyQuest.completed === true
      }
    return { date: today, bindingId: id, completed: false }
  }

  function openGuide() { guideVisible = true }
  function closeGuide() { guideVisible = false }
  function beginClearLocalData() {
    if (!statsLoaded || statsWriteProcess.running || statsArchiveProcess.running)
      return false
    stats = Stats.emptyStats()
    statsDirty = true
    statsState = "ready"
    statsArchiveAction = "reset"
    statsArchiveProcess.command = ["python3", statsStorePath, "archive",
      "--path", statsPath, "--recovery-dir", statsRecoveryDir, "--keep", "5"]
    statsArchiveProcess.running = true
    return true
  }

  function clearLocalData(confirmed) {
    if (confirmed !== true || !statsLoaded || statsArchiveProcess.running)
      return false
    if (statsWriteProcess.running) {
      statsResetPending = true
      return true
    }
    return beginClearLocalData()
  }

  function parseStatsResult(raw) {
    try { return JSON.parse(String(raw || "")) } catch (e) { return null }
  }

  function finishStatsArchive(raw, exitCode) {
    var result = parseStatsResult(raw)
    if (exitCode !== 0 || !result || result.ok !== true) {
      statsArchivePending = false
      statsState = "error"
      return false
    }
    statsArchivePending = false
    var action = statsArchiveAction
    statsArchiveAction = ""
    if (action === "corrupt") {
      statsState = "recovered"
      statsDirty = true
    }
    if (!statsWriteProcess.running && statsDirty) flushStatsNow()
    return true
  }

  function loadStats(raw) {
    if (statsLoaded) return statsState !== "error"
    var result = Stats.normalize(raw)
    if (result.ok) {
      stats = result.stats
      statsState = "ready"
      statsLoaded = true
      return true
    }

    stats = Stats.emptyStats()
    statsState = "recovered"
    statsLoaded = true
    statsArchiveAction = "corrupt"
    statsArchivePending = true
    statsArchiveProcess.command = ["python3", statsStorePath, "archive",
      "--path", statsPath, "--recovery-dir", statsRecoveryDir]
    statsArchiveProcess.running = true
    return false
  }

  function initializeMissingStats() {
    if (statsLoaded) return
    stats = Stats.emptyStats()
    statsState = "ready"
    statsLoaded = true
  }

  function flushStatsNow() {
    if (!statsLoaded || !statsDirty || statsWriteProcess.running || statsArchiveProcess.running)
      return false
    statsFlushTimer.stop()
    statsWriteOutput = ""
    statsWriteProcess.command = ["python3", statsStorePath, "write",
      "--path", statsPath, "--recovery-dir", statsRecoveryDir]
    statsWriteProcess.running = true
    return true
  }

  function finishStatsWrite(raw, exitCode) {
    var result = parseStatsResult(raw)
    if (exitCode !== 0 || !result || result.ok !== true) {
      statsState = "error"
      statsResetPending = false
      return false
    }
    statsDirty = false
    if (statsResetPending) {
      statsResetPending = false
      beginClearLocalData()
    }
    return true
  }

  function settingsEntry() {
    return Model.settingsFor(shell ? shell.shellConfig : null, root.moduleName)
  }

  function syncSettings() {
    var entry = settingsEntry()
    guideDelayMs = Model.normalizeDelay(entry.guideDelayMs)
    showInFullscreen = Model.normalizeFullscreen(entry.showInFullscreen)
    guideSuperEnabled = Model.normalizeGuideRoot(entry.guideSuperEnabled)
    guideShiftEnabled = Model.normalizeGuideRoot(entry.guideShiftEnabled)
    guideCtrlEnabled = Model.normalizeGuideRoot(entry.guideCtrlEnabled)
    guideAltEnabled = Model.normalizeGuideRoot(entry.guideAltEnabled)
    if (!guideRootEnabled(activeGuideRoot)) {
      guideVisible = false
      activeModifiers = ""
      activeGuideRoot = ""
    }
  }

  function persistSettings(changes) {
    if (!shell || typeof shell.updateEntryInline !== "function") return false
    var entry = settingsEntry()
    var next = { id: root.moduleName }
    for (var key in entry) if (key !== "id") next[key] = entry[key]
    for (var changed in changes) next[changed] = changes[changed]
    shell.updateEntryInline(root.moduleName, next)
    return true
  }

  function setGuideDelayMs(value) {
    var next = Model.normalizeDelay(value)
    if (next === guideDelayMs) return false
    guideDelayMs = next
    return persistSettings({ guideDelayMs: next })
  }

  function setShowInFullscreen(value) {
    var next = Model.normalizeFullscreen(value)
    if (next === showInFullscreen) return false
    showInFullscreen = next
    return persistSettings({ showInFullscreen: next })
  }

  function guideRootEnabled(rootName) {
    if (rootName === "SUPER") return guideSuperEnabled
    if (rootName === "SHIFT") return guideShiftEnabled
    if (rootName === "CTRL") return guideCtrlEnabled
    if (rootName === "ALT") return guideAltEnabled
    return false
  }

  function setGuideRootEnabled(rootName, value) {
    var next = Model.normalizeGuideRoot(value)
    var setting = ""
    if (rootName === "SUPER") setting = "guideSuperEnabled"
    else if (rootName === "SHIFT") setting = "guideShiftEnabled"
    else if (rootName === "CTRL") setting = "guideCtrlEnabled"
    else if (rootName === "ALT") setting = "guideAltEnabled"
    else return false

    if (guideRootEnabled(rootName) === next) return false
    if (rootName === "SUPER") guideSuperEnabled = next
    else if (rootName === "SHIFT") guideShiftEnabled = next
    else if (rootName === "CTRL") guideCtrlEnabled = next
    else guideAltEnabled = next
    if (!next && activeGuideRoot === rootName) {
      guideVisible = false
      activeModifiers = ""
      activeGuideRoot = ""
    }
    var changes = {}
    changes[setting] = next
    return persistSettings(changes)
  }

  property var lockService: null
  property var polkitService: null

  function refreshSuppressionServices() {
    var nextLock = null
    var nextPolkit = null
    if (shell && typeof shell.serviceFor === "function") {
      nextLock = shell.serviceFor("omarchy.lock")
      nextPolkit = shell.serviceFor("omarchy.polkit")
    }
    lockService = nextLock
    polkitService = nextPolkit
    desktopLocked = !!(lockService && lockService.locked === true)
    credentialPromptActive = !!(polkitService && polkitService.dialogVisible === true)
  }

  function applyIntegrationResult(raw, exitCode) {
    if (exitCode !== 0) {
      integrationState = "error"
      setDiagnostic("integrationFailures", 1)
      return false
    }
    var parsed
    try { parsed = JSON.parse(String(raw || "")) } catch (e) {
      integrationState = "error"
      setDiagnostic("integrationFailures", 1)
      return false
    }
    integrationDetails = parsed
    if (parsed.managedBlockState === "present") integrationState = "enabled"
    else if (parsed.managedBlockState === "absent") {
      integrationState = (integrationState === "enabled" || integrationState === "disconnected")
        ? "disconnected" : "disabled"
      guideVisible = false
      activeModifiers = ""
      activeGuideRoot = ""
      highlightedBindingId = ""
    } else integrationState = "error"
    return integrationState !== "error"
  }

  function applyManualSnippet(raw, exitCode) {
    if (exitCode !== 0) return false
    try {
      var parsed = JSON.parse(String(raw || ""))
      if (parsed && parsed.ok === true && typeof parsed.snippet === "string") {
        manualSnippet = parsed.snippet
        return true
      }
    } catch (e) {}
    return false
  }

  function inspectIntegration() {
    if (integrationInspectProcess.running || controllerPath === "") return false
    integrationInspectProcess.command = [controllerPath, "inspect"]
    integrationInspectProcess.running = true
    return true
  }

  function mutateIntegration(action, expectedHash) {
    var hash = String(expectedHash || "")
    if (!hash || integrationMutationProcess.running || controllerPath === "") return false
    integrationState = "enabling"
    integrationMutationAction = action
    integrationMutationProcess.command = [controllerPath, action, "--expected-hash", hash]
    integrationMutationProcess.running = true
    return true
  }

  function enableIntegration(expectedHash) { return mutateIntegration("enable", expectedHash) }
  function disableIntegration(expectedHash) { return mutateIntegration("disable", expectedHash) }

  function recordFullscreenResult(raw, exitCode) {
    var next = {}
    for (var key in sessionDiagnostics) next[key] = sessionDiagnostics[key]
    next.fullscreenQueryCount = Number(next.fullscreenQueryCount || 0) + 1
    sessionDiagnostics = next
    if (exitCode !== 0) {
      setDiagnostic("fullscreenQueryFailures", 1)
      return false
    }
    var parsed = Model.parseActiveWindow(raw)
    if (!parsed.ok) {
      setDiagnostic("fullscreenQueryFailures", 1)
      return false
    }
    activeWindowFullscreen = parsed.fullscreen
    return true
  }

  property bool fullscreenQueryPending: false

  function requestFullscreenRefresh() {
    fullscreenQueryPending = true
    fullscreenQueryTimer.restart()
  }

  function handleRawEvent(event) {
    if (!event) return
    var name = String(event.name || "")
    if (name === "custom") {
      var payload = protocolPayload(event)
      if (payload !== "") handleProtocolEvent(payload)
      return
    }
    if (Model.isCatalogChangeEvent(name)) catalogChangeTimer.restart()
    if (Model.isFullscreenEvent(name)) requestFullscreenRefresh()
  }

  Timer {
    id: catalogChangeTimer
    interval: 350
    repeat: false
    onTriggered: root.regenerateCatalog()
  }

  property bool catalogRegenerationPending: false
  property string generatorOutput: ""

  function regenerateCatalog() {
    if (catalogGenerationProcess.running) {
      catalogRegenerationPending = true
      return false
    }
    if (generatorPath === "") return false
    catalogRegenerationPending = false
    catalogGenerationProcess.command = ["python3", generatorPath, "--output-dir", stateDir]
    catalogGenerationProcess.running = true
    return true
  }

  FileView {
    id: catalogFile
    path: root.stateDir + "/catalog.json"
    watchChanges: true
    onLoaded: root.loadCatalog(text())
    onLoadFailed: {
      root.catalog = null
      root.catalogState = "error"
      root.setDiagnostic("catalogLoadFailures", 1)
    }
  }

  FileView {
    id: statsFile
    path: root.statsPath
    watchChanges: false
    printErrors: false
    onLoaded: root.loadStats(text())
    onLoadFailed: root.initializeMissingStats()
  }

  Timer {
    id: statsFlushTimer
    interval: 5000
    repeat: false
    onTriggered: root.flushStatsNow()
  }

  Process {
    id: statsArchiveProcess
    running: false
    stdout: StdioCollector { id: statsArchiveStdout; waitForEnd: true }
    onExited: root.finishStatsArchive(statsArchiveStdout.text, exitCode)
  }

  Process {
    id: statsWriteProcess
    running: false
    stdinEnabled: true
    stdout: StdioCollector { id: statsWriteStdout; waitForEnd: true }
    onStarted: {
      write(JSON.stringify(root.stats))
      stdinEnabled = false
    }
    onExited: root.finishStatsWrite(statsWriteStdout.text, exitCode)
  }

  Process {
    id: catalogGenerationProcess
    running: false
    stdout: StdioCollector { id: generatorStdout; waitForEnd: true }
    onExited: {
      root.generatorOutput = String(generatorStdout.text || "")
      if (exitCode !== 0) {
        root.catalogState = "error"
        root.setDiagnostic("catalogLoadFailures", 1)
      } else {
        catalogFile.reload()
      }
      if (root.catalogRegenerationPending) {
        root.catalogRegenerationPending = false
        catalogChangeTimer.restart()
      }
    }
  }

  Process {
    id: integrationInspectProcess
    running: false
    stdout: StdioCollector { id: integrationInspectStdout; waitForEnd: true }
    onExited: root.applyIntegrationResult(integrationInspectStdout.text, exitCode)
  }

  Process {
    id: manualSnippetProcess
    running: false
    stdout: StdioCollector { id: manualSnippetStdout; waitForEnd: true }
    onExited: root.applyManualSnippet(manualSnippetStdout.text, exitCode)
  }

  property string integrationMutationAction: ""
  Process {
    id: integrationMutationProcess
    running: false
    stdout: StdioCollector { id: integrationMutationStdout; waitForEnd: true }
    onExited: {
      var parsed = null
      try { parsed = JSON.parse(String(integrationMutationStdout.text || "")) } catch (e) {}
      if (exitCode !== 0 || !parsed || parsed.ok !== true) {
        root.integrationState = "error"
        root.setDiagnostic("integrationFailures", 1)
      } else {
        root.integrationDetails = parsed
        Qt.callLater(root.inspectIntegration)
      }
    }
  }

  Timer {
    id: integrationInspectTimer
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.inspectIntegration()
  }

  Timer {
    id: fullscreenQueryTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (!root.fullscreenQueryPending || fullscreenQueryProcess.running) return
      root.fullscreenQueryPending = false
      fullscreenQueryProcess.running = true
    }
  }

  Process {
    id: fullscreenQueryProcess
    command: ["hyprctl", "-j", "activewindow"]
    running: false
    stdout: StdioCollector { id: fullscreenStdout; waitForEnd: true }
    onExited: {
      root.recordFullscreenResult(fullscreenStdout.text, exitCode)
      if (root.fullscreenQueryPending) fullscreenQueryTimer.restart()
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) { root.handleRawEvent(event) }
  }

  Connections {
    target: root.shell
    ignoreUnknownSignals: true
    function onShellConfigChanged() { root.syncSettings() }
  }

  Connections {
    target: root.lockService
    ignoreUnknownSignals: true
    function onLockedChanged() { root.refreshSuppressionServices() }
  }

  Connections {
    target: root.polkitService
    ignoreUnknownSignals: true
    function onDialogVisibleChanged() { root.refreshSuppressionServices() }
  }

  Timer {
    id: suppressionRefreshTimer
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refreshSuppressionServices()
  }

  IpcHandler {
    target: "omakeez-feasibility"
    function diagnostics(): string { return root.diagnosticsJson() }
    function reset(): string { root.resetDiagnostics(); return "ok" }
  }

  Component.onCompleted: Qt.callLater(function() {
    root.syncSettings()
    root.refreshSuppressionServices()
    root.inspectIntegration()
    manualSnippetProcess.command = [root.controllerPath, "manual-snippet"]
    manualSnippetProcess.running = true
    root.regenerateCatalog()
    root.requestFullscreenRefresh()
  })

  Component.onDestruction: root.flushStatsNow()

  onShellChanged: Qt.callLater(function() {
    root.syncSettings()
    root.refreshSuppressionServices()
  })

  SuperGuide {
    service: root
  }
}
