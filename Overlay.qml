import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Stats.js" as Stats

Item {
  id: root

  property var service: null
  property string payloadJson: ""
  property bool opened: false
  property string currentTab: "Bindings"
  property string searchText: ""
  property string categoryFilter: "All"
  property int selectedIndex: 0
  property int focusIndex: 0
  property int modelRevision: 0
  property bool confirmClear: false
  property var revealed: ({})
  property var practiceCompleted: ({})
  property var skippedToday: ({})

  readonly property var tabs: ["Bindings", "Practice", "Progress", "Settings"]
  readonly property var categories: ["All", "windows", "workspaces", "applications",
    "system", "capture", "media", "clipboard", "notifications", "style", "other"]
  readonly property string today: Stats.dateKey(Date.now() / 1000)

  visible: opened

  function open(payload) {
    payloadJson = payload === undefined || payload === null ? "" : String(payload)
    currentTab = "Bindings"
    searchText = ""
    categoryFilter = "All"
    selectedIndex = 0
    focusIndex = 0
    confirmClear = false
    opened = true
    parsePayload(payloadJson)
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    opened = false
    payloadJson = ""
    confirmClear = false
  }

  function toggle() {
    if (opened) close()
    else open("")
  }

  function parsePayload(raw) {
    if (!raw) return
    try {
      var value = JSON.parse(raw)
      if (value && tabs.indexOf(value.tab) !== -1) currentTab = value.tab
    } catch (e) {}
  }

  function bumpRevision() { modelRevision += 1 }

  function setTab(tab) {
    if (tabs.indexOf(tab) === -1) return
    currentTab = tab
    selectedIndex = 0
    focusIndex = 1 + tabs.indexOf(tab)
    bumpRevision()
  }

  function setSearch(value) {
    searchText = String(value || "")
    selectedIndex = 0
    bumpRevision()
  }

  function appendSearch(text) {
    if (text && text.length === 1 && text.charCodeAt(0) >= 32 && text.charCodeAt(0) !== 127)
      setSearch(searchText + text)
  }

  function filteredBindings() {
    var revision = modelRevision
    var result = []
    var query = searchText.toLowerCase()
    var entries = service && service.catalog && Array.isArray(service.catalog.bindings)
      ? service.catalog.bindings : []
    for (var i = 0; i < entries.length; i++) {
      var binding = entries[i]
      if (categoryFilter !== "All" && binding.category !== categoryFilter) continue
      var haystack = String(binding.combo || "") + " " + String(binding.description || "")
      if (query !== "" && haystack.toLowerCase().indexOf(query) === -1) continue
      var usage = service && service.stats && service.stats.bindings
        ? service.stats.bindings[binding.id] : null
      result.push({
        id: binding.id,
        combo: binding.combo,
        description: binding.description,
        category: binding.category,
        count: usage ? Number(usage.count || 0) : 0,
        lastUsed: usage ? Number(usage.lastUsed || 0) : 0
      })
    }
    result.sort(function(a, b) {
      var combo = String(a.combo).localeCompare(String(b.combo))
      if (combo !== 0) return combo
      var description = String(a.description).localeCompare(String(b.description))
      return description !== 0 ? description : String(a.id).localeCompare(String(b.id))
    })
    return result
  }

  function bindingForId(id) {
    return service && typeof service.bindingForId === "function"
      ? service.bindingForId(id) : null
  }

  function lastUsedLabel(timestamp) {
    var value = Number(timestamp || 0)
    if (value <= 0) return "never used"
    var seconds = Math.max(0, Math.floor(Date.now() / 1000 - value))
    if (seconds < 60) return "just now"
    if (seconds < 3600) return Math.floor(seconds / 60) + "m ago"
    if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago"
    return Math.floor(seconds / 86400) + "d ago"
  }

  function selectResult(delta) {
    var count = filteredBindings().length
    if (count <= 0) {
      selectedIndex = 0
      return
    }
    selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + delta))
    focusIndex = 5
  }

  function selectAbsolute(index) {
    var count = filteredBindings().length
    selectedIndex = count <= 0 ? 0 : Math.max(0, Math.min(count - 1, index))
    focusIndex = 5
  }

  function toggleReveal(id) {
    var next = {}
    for (var key in revealed) next[key] = revealed[key]
    next[id] = next[id] !== true
    revealed = next
    bumpRevision()
  }

  function practiceItems() {
    var ids = []
    var quest = service && service.dailyQuest ? service.dailyQuest : null
    if (quest && quest.bindingId && skippedToday[quest.bindingId] !== true)
      ids.push(quest.bindingId)
    var recommendations = service && typeof service.recommendations === "function"
      ? service.recommendations(20) : []
    for (var i = 0; i < recommendations.length && ids.length < 21; i++) {
      var id = String(recommendations[i])
      if (ids.indexOf(id) === -1 && skippedToday[id] !== true) ids.push(id)
    }
    return ids
  }

  function markPracticeMatch(id) {
    var items = practiceItems()
    if (items.indexOf(id) === -1) return
    var next = {}
    for (var key in practiceCompleted) next[key] = practiceCompleted[key]
    next[id] = true
    practiceCompleted = next
    bumpRevision()
  }

  function skipPractice(id) {
    var next = {}
    for (var key in skippedToday) next[key] = skippedToday[key]
    next[id] = true
    skippedToday = next
    bumpRevision()
  }

  function distinctToday() {
    var count = 0
    var bindings = service && service.stats ? service.stats.bindings : {}
    for (var id in bindings) if (bindings[id].daily && Number(bindings[id].daily[today] || 0) > 0) count += 1
    return count
  }

  function trackedCount() {
    var bindings = service && service.stats ? service.stats.bindings : {}
    return Object.keys(bindings).length
  }

  function heatDays() {
    var days = []
    var now = new Date()
    now.setHours(12, 0, 0, 0)
    for (var offset = 89; offset >= 0; offset--) {
      var date = new Date(now.getTime())
      date.setDate(date.getDate() - offset)
      var day = Stats.dateKey(date.getTime() / 1000)
      var count = 0
      var bindings = service && service.stats ? service.stats.bindings : {}
      for (var id in bindings) count += Number(bindings[id].daily ? bindings[id].daily[day] || 0 : 0)
      days.push({ day: day, count: count })
    }
    return days
  }

  function rankedUsed(least) {
    var result = []
    var entries = service && service.catalog && Array.isArray(service.catalog.bindings)
      ? service.catalog.bindings : []
    var bindings = service && service.stats ? service.stats.bindings : {}
    for (var i = 0; i < entries.length; i++) {
      var binding = entries[i]
      if (binding.trackable !== true || binding.available === false || !String(binding.description || "").trim()) continue
      var usage = bindings[binding.id]
      if (!usage || Number(usage.count || 0) === 0) continue
      result.push({ id: binding.id, count: Number(usage.count || 0),
        lastUsed: Number(usage.lastUsed || 0) })
    }
    result.sort(function(a, b) {
      var count = a.count - b.count
      if (count !== 0) return least ? count : -count
      return least ? a.lastUsed - b.lastUsed : b.lastUsed - a.lastUsed
    })
    return result.slice(0, 5)
  }

  function moveFocus(delta) {
    var targetCount = 6
    focusIndex = (focusIndex + delta) % targetCount
    if (focusIndex < 0) focusIndex += targetCount
  }

  function retainKeyboardFocus() {
    if (!opened) return
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function focusSearch() {
    focusIndex = 0
    retainKeyboardFocus()
  }

  function focusLabel() {
    if (focusIndex === 0) return "Search"
    if (focusIndex <= 4) return tabs[focusIndex - 1]
    return "Results"
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onCatalogChanged() { root.bumpRevision() }
    function onStatsChanged() { root.bumpRevision() }
    function onDailyQuestChanged() { root.bumpRevision() }
    function onBindingMatched(bindingId) { root.markPracticeMatch(String(bindingId)) }
  }

  PanelWindow {
    id: overlayWindow
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "keybind-dojo-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      MouseArea {
        anchors.fill: parent
        onClicked: root.close()
      }
    }

    BorderSurface {
      id: card
      z: 2
      width: Math.min(parent.width - Style.space(32), Style.space(980))
      height: Math.min(parent.height - Style.space(32), Style.space(700))
      anchors.centerIn: parent
      color: Color.menu.background
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(10)

        Row {
          width: parent.width
          height: Style.space(32)
          spacing: Style.space(10)
          Item {
            width: Math.max(0, parent.width - closeButton.implicitWidth - escapeAffordance.implicitWidth - Style.space(20))
            height: parent.height
            Text {
              id: titleText
              text: "KEYBIND DOJO"
              color: Color.menu.selectedText
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
            }
            Text {
              anchors.left: titleText.right
              anchors.leftMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              text: root.service ? "Learn your actual shortcuts" : "Loading service…"
              color: Color.menu.text
              opacity: 0.72
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
          Button {
            id: closeButton
            text: "Close overlay"
            bordered: true
            background: Qt.rgba(Color.menu.text.r, Color.menu.text.g, Color.menu.text.b, 0.06)
            foreground: Color.menu.text
            tooltipText: "Escape also closes this overlay"
            onClicked: root.close()
          }
          Row {
            id: escapeAffordance
            spacing: Style.space(5)
            anchors.verticalCenter: parent.verticalCenter
            BorderSurface {
              width: Style.space(34)
              height: Style.space(24)
              color: Qt.rgba(Color.menu.text.r, Color.menu.text.g, Color.menu.text.b, 0.12)
              borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
              radius: Style.cornerRadius
              Text {
                anchors.centerIn: parent
                text: "Esc"
                color: Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }
            Text {
              text: "to close"
              color: Color.menu.text
              opacity: 0.88
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        Row {
          width: parent.width
          height: Style.space(34)
          spacing: Style.space(4)
          Repeater {
            model: root.tabs
            delegate: Button {
              required property string modelData
              text: modelData
              selected: root.currentTab === modelData
              hasCursor: root.focusIndex === 1 + index
              onClicked: { root.setTab(modelData); root.retainKeyboardFocus() }
            }
          }
        }

        Item {
          width: parent.width
          height: parent.height - Style.space(86)
          visible: !!root.service

          Column {
            anchors.fill: parent
            spacing: Style.space(8)
            visible: root.currentTab === "Bindings"

            Rectangle {
              width: parent.width
              height: Style.space(36)
              color: "transparent"
              border.width: root.focusIndex === 0 ? Math.max(1, Style.space(1)) : 0
              border.color: Color.menu.selectedBorder
              radius: Style.cornerRadius
              Text {
                anchors.fill: parent
                anchors.margins: Style.space(8)
                text: root.searchText === "" ? "Search combo or description…" : root.searchText
                color: Color.menu.text
                opacity: root.searchText === "" ? 0.58 : 1
                font.pixelSize: Style.font.body
                verticalAlignment: Text.AlignVCenter
              }
              MouseArea {
                anchors.fill: parent
                onClicked: root.focusSearch()
              }
            }

            Flow {
              width: parent.width
              height: Style.space(30)
              spacing: Style.space(3)
              Repeater {
                model: root.categories
                delegate: Button {
                  required property string modelData
                  text: modelData
                  selected: root.categoryFilter === modelData
                  onClicked: { root.categoryFilter = modelData; root.selectedIndex = 0; root.bumpRevision() }
                }
              }
            }

            ListView {
              id: bindingList
              width: parent.width
              height: parent.height - Style.space(74)
              clip: true
              spacing: Style.space(3)
              model: root.filteredBindings()
              delegate: Rectangle {
                required property var modelData
                width: bindingList.width
                height: Style.space(52)
                color: Color.menu.background
                border.width: index === root.selectedIndex && root.focusIndex === 5 ? Math.max(1, Style.space(1)) : 0
                border.color: Color.menu.selectedBorder
                radius: Style.cornerRadius
                Row {
                  anchors.fill: parent
                  anchors.margins: Style.space(7)
                  spacing: Style.space(10)
                  Column {
                    width: Math.min(Style.space(260), parent.width * 0.32)
                    BorderSurface {
                      width: Math.min(parent.width, Style.space(240))
                      height: Style.space(24)
                      color: Color.menu.background
                      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
                      radius: Style.cornerRadius
                      Text { anchors.fill: parent; anchors.leftMargin: Style.space(6); text: modelData.combo; color: Color.menu.selectedText; font.pixelSize: Style.font.bodySmall; font.bold: true; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                    }
                    Text { width: parent.width; text: modelData.category; color: Color.menu.text; opacity: 0.6; font.pixelSize: Style.font.caption }
                  }
                  Text { width: parent.width * 0.42; text: modelData.description; color: Color.menu.text; font.pixelSize: Style.font.bodySmall; elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                  Column {
                    width: parent.width * 0.22
                    Text { width: parent.width; text: modelData.count + " uses"; color: Color.menu.text; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignRight }
                    Text { width: parent.width; text: root.lastUsedLabel(modelData.lastUsed); color: Color.menu.text; opacity: 0.6; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignRight }
                  }
                }
                MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = index; root.focusIndex = 5 } }
              }
              Text {
                anchors.centerIn: parent
                visible: bindingList.count === 0
                text: root.searchText === "" ? "No bindings available." : "No matching bindings."
                color: Color.menu.text
                opacity: 0.7
                font.pixelSize: Style.font.body
              }
            }
          }

          Flickable {
            id: practiceView
            anchors.fill: parent
            visible: root.currentTab === "Practice"
            contentWidth: width
            contentHeight: practiceColumn.implicitHeight
            clip: true
            Column {
              id: practiceColumn
              width: practiceView.width
              spacing: Style.space(8)
              Text { text: "Practice by using the real shortcut"; color: Color.menu.selectedText; font.pixelSize: Style.font.heading; font.bold: true }
              Text { width: parent.width; text: "The guide never executes a binding for you. Reveal a combo, then use it physically."; color: Color.menu.text; opacity: 0.72; wrapMode: Text.WordWrap; font.pixelSize: Style.font.caption }
              Repeater {
                model: root.practiceItems()
                delegate: BorderSurface {
                  required property string modelData
                  width: practiceColumn.width
                  height: Style.space(76)
                  color: root.practiceCompleted[modelData] === true ? Color.menu.selectedBackground : Color.menu.background
                  borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
                  radius: Style.cornerRadius
                  Row {
                    anchors.fill: parent
                    anchors.margins: Style.space(9)
                    spacing: Style.space(10)
                    Column {
                      width: parent.width - Style.space(210)
                      Text { width: parent.width; text: root.bindingForId(modelData) ? root.bindingForId(modelData).description : "Binding unavailable"; color: Color.menu.text; font.pixelSize: Style.font.body; elide: Text.ElideRight }
                      Text { width: parent.width; text: root.practiceCompleted[modelData] === true ? "Completed by live use" : "Use this shortcut to mark it complete"; color: Color.menu.text; opacity: 0.62; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
                    }
                    Button {
                      text: root.revealed[modelData] === true && root.bindingForId(modelData) ? root.bindingForId(modelData).combo : "Reveal combo"
                      background: Qt.rgba(Color.menu.text.r, Color.menu.text.g, Color.menu.text.b, 0.08)
                      foreground: Color.menu.text
                      onClicked: root.toggleReveal(modelData)
                    }
                    Button { text: "Skip today"; onClicked: root.skipPractice(modelData) }
                  }
                }
              }
              Text { visible: root.practiceItems().length === 0; text: "No practice recommendations yet."; color: Color.menu.text; opacity: 0.7; font.pixelSize: Style.font.body }
            }
          }

          Flickable {
            id: progressView
            anchors.fill: parent
            visible: root.currentTab === "Progress"
            contentWidth: width
            contentHeight: progressColumn.implicitHeight
            clip: true
            Column {
              id: progressColumn
              width: progressView.width
              spacing: Style.space(10)
              Text { text: "Progress"; color: Color.menu.selectedText; font.pixelSize: Style.font.heading; font.bold: true }
              Row {
                width: parent.width
                spacing: Style.space(20)
                Text { text: "Level: " + (service.currentLevel ? service.currentLevel.name : "Initiate"); color: Color.menu.text; font.pixelSize: Style.font.body }
                Text { text: "XP: " + Number(service.stats.totalXp || 0); color: Color.menu.text; font.pixelSize: Style.font.body }
                Text { text: "Streak: " + Number(service.currentStreak || 0); color: Color.menu.text; font.pixelSize: Style.font.body }
                Text { text: "Used today: " + root.distinctToday(); color: Color.menu.text; font.pixelSize: Style.font.body }
              }
              Text { text: "90-day activity"; color: Color.menu.text; font.pixelSize: Style.font.body; font.bold: true }
              Grid {
                columns: 15
                spacing: Style.space(3)
                Repeater {
                  model: root.heatDays()
                  delegate: Rectangle {
                    required property var modelData
                    width: Style.space(18)
                    height: Style.space(18)
                    radius: Style.cornerRadius
                    color: modelData.count === 0 ? Color.menu.background : Qt.rgba(Color.menu.selectedBorder.r, Color.menu.selectedBorder.g, Color.menu.selectedBorder.b, Math.min(1, 0.25 + modelData.count / 12))
                    border.width: 1
                    border.color: Color.menu.border
                  }
                }
              }
              Row {
                width: parent.width
                spacing: Style.space(16)
                Column {
                  width: (parent.width - Style.space(16)) / 2
                  Text { text: "Most used"; color: Color.menu.text; font.bold: true; font.pixelSize: Style.font.body }
                  Repeater {
                    model: root.rankedUsed(false)
                    delegate: Text {
                      required property var modelData
                      text: (root.bindingForId(modelData.id) ? root.bindingForId(modelData.id).description : modelData.id) + " · " + modelData.count
                      color: Color.menu.text; font.pixelSize: Style.font.caption; elide: Text.ElideRight; width: parent.width
                    }
                  }
                }
                Column {
                  width: (parent.width - Style.space(16)) / 2
                  Text { text: "Least used"; color: Color.menu.text; font.bold: true; font.pixelSize: Style.font.body }
                  Repeater {
                    model: root.rankedUsed(true)
                    delegate: Text {
                      required property var modelData
                      text: (root.bindingForId(modelData.id) ? root.bindingForId(modelData.id).description : modelData.id) + " · " + modelData.count
                      color: Color.menu.text; font.pixelSize: Style.font.caption; elide: Text.ElideRight; width: parent.width
                    }
                  }
                }
              }
              Text { visible: root.trackedCount() === 0; text: "Use a few shortcuts to build your first progress snapshot."; color: Color.menu.text; opacity: 0.7; font.pixelSize: Style.font.body }
            }
          }

          Flickable {
            id: settingsView
            anchors.fill: parent
            visible: root.currentTab === "Settings"
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight
            clip: true
            Column {
              id: settingsColumn
              width: settingsView.width
              spacing: Style.space(10)
              Text { text: "Settings"; color: Color.menu.selectedText; font.pixelSize: Style.font.heading; font.bold: true }
              Text { width: parent.width; text: service.integrationState === "enabled" ? "Tracking enabled" : "Tracking is not enabled"; color: Color.menu.text; font.pixelSize: Style.font.body }
              Text { width: parent.width; text: "Resolved config: " + (service.integrationDetails && service.integrationDetails.resolvedPath ? service.integrationDetails.resolvedPath : "—"); color: Color.menu.text; opacity: 0.72; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }
              Text { text: "Guide delay"; color: Color.menu.text; font.pixelSize: Style.font.body; font.bold: true }
              Flow {
                width: parent.width
                spacing: Style.space(4)
                Repeater {
                  model: ["Instant", "80 ms", "150 ms", "250 ms", "Off"]
                  delegate: Button {
                    required property int index
                    text: modelData
                    selected: service.guideDelayMs === [0, 80, 150, 250, -1][index]
                    onClicked: service.setGuideDelayMs([0, 80, 150, 250, -1][index])
                  }
                }
              }
              Button {
                text: "Show in fullscreen: " + (service.showInFullscreen ? "On" : "Off")
                onClicked: service.setShowInFullscreen(!service.showInFullscreen)
              }
              Text { text: "Local data & privacy"; color: Color.menu.selectedText; font.pixelSize: Style.font.body; font.bold: true }
              Text {
                width: parent.width
                text: "Stored locally in: " + service.stateDir
                color: Color.menu.text
                opacity: 0.78
                font.pixelSize: Style.font.caption
                wrapMode: Text.WrapAnywhere
              }
              Text {
                width: parent.width
                text: "Stored: opaque binding IDs, aggregate counts, first/last observed times, daily totals (up to 90 days), XP, streaks, and daily quest state."
                color: Color.menu.text
                opacity: 0.78
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              Text {
                width: parent.width
                text: "Not stored: raw keypress logs, typed text or passwords, commands, window titles, application names, or network data. Stats are private (directory 0700, files 0600)."
                color: Color.menu.text
                opacity: 0.78
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              Text {
                width: parent.width
                text: service.statsResetPending ? "Saving current stats before reset…"
                  : service.statsRecoveryRunning ? "Archiving current stats for recovery…"
                  : "Clear local data archives the current stats file for recovery, then starts a fresh profile."
                color: Color.menu.text
                opacity: 0.78
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              Row {
                spacing: Style.space(8)
                Button { text: "Recheck integration"; onClicked: service.inspectIntegration() }
                Button { text: "Close"; onClicked: root.close() }
              }
              Button {
                text: root.confirmClear ? "Confirm clear local data" : "Clear local data"
                enabled: service.statsLoaded && !service.statsRecoveryRunning
                onClicked: {
                  if (!root.confirmClear) root.confirmClear = true
                  else if (service.clearLocalData(true)) root.confirmClear = false
                }
              }
            }
          }
        }

        Text {
          visible: !root.service
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Service is reloading. Close and reopen this overlay if it does not return."
          color: Color.menu.text
          opacity: 0.75
          font.pixelSize: Style.font.body
        }
      }
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      z: 3
      focus: root.opened
      activeFocusOnTab: false
      Keys.priority: Keys.BeforeItem
      onActiveFocusChanged: if (root.opened && !activeFocus) root.retainKeyboardFocus()
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        } else if ((event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier))
                   || (event.text === "/" && event.modifiers === Qt.NoModifier)) {
          root.focusSearch()
          event.accepted = true
        } else if (event.key === Qt.Key_Tab) {
          root.moveFocus(event.modifiers & Qt.ShiftModifier ? -1 : 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Backtab) {
          root.moveFocus(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Left && root.focusIndex >= 1 && root.focusIndex <= 4) {
          root.setTab(root.tabs[Math.max(0, root.tabs.indexOf(root.currentTab) - 1)])
          event.accepted = true
        } else if (event.key === Qt.Key_Right && root.focusIndex >= 1 && root.focusIndex <= 4) {
          root.setTab(root.tabs[Math.min(3, root.tabs.indexOf(root.currentTab) + 1)])
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          if (root.focusIndex >= 1 && root.focusIndex <= 4) {
            root.setTab(root.tabs[root.focusIndex - 1])
            event.accepted = true
          }
        } else if (event.key === Qt.Key_Up && root.focusIndex === 5) {
          root.selectResult(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Down && root.focusIndex === 5) {
          root.selectResult(1)
          event.accepted = true
        } else if (event.key === Qt.Key_PageUp && root.focusIndex === 5) {
          root.selectResult(-8)
          event.accepted = true
        } else if (event.key === Qt.Key_PageDown && root.focusIndex === 5) {
          root.selectResult(8)
          event.accepted = true
        } else if (event.key === Qt.Key_Home && root.focusIndex === 5) {
          root.selectAbsolute(0)
          event.accepted = true
        } else if (event.key === Qt.Key_End && root.focusIndex === 5) {
          root.selectAbsolute(999999)
          event.accepted = true
        } else if (event.key === Qt.Key_Backspace && root.focusIndex === 0) {
          root.setSearch(root.searchText.slice(0, -1))
          event.accepted = true
        } else if (event.text && root.focusIndex === 0
                   && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
          root.appendSearch(event.text)
          event.accepted = true
        } else if (event.modifiers & Qt.MetaModifier) {
          // Keep compositor shortcuts from firing while the exclusive Dojo
          // surface is open; users can dismiss explicitly with Escape.
          event.accepted = true
        }
      }
    }
  }
}
