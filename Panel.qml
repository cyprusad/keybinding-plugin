import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "io.github.cyprusad.omakeez"
  ipcTarget: "io.github.cyprusad.omakeez"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property var preview: ({})
  property bool confirmDisable: false
  property bool confirmClear: false

  readonly property bool onboarding: !service || service.integrationState !== "enabled"
  readonly property string displayedHash: preview && typeof preview.currentHash === "string"
    ? preview.currentHash : ""
  readonly property string displayedDiff: preview && typeof preview.proposedDiff === "string"
    ? preview.proposedDiff : ""
  readonly property bool enableReady: !!root.service && root.preview
    && root.preview.safeToPatch === true && root.displayedHash !== ""
    && !root.service.integrationMutationRunning

  function htmlEscape(value) {
    return String(value || "").replace(/&/g, "&amp;")
      .replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/ /g, "&nbsp;")
  }

  function diffAddedColor() {
    var luminance = Color.menu.background.r * 0.2126
      + Color.menu.background.g * 0.7152 + Color.menu.background.b * 0.0722
    return luminance < 0.5 ? "#8bd49c" : "#236b3e"
  }

  function diffRemovedColor() {
    var luminance = Color.menu.background.r * 0.2126
      + Color.menu.background.g * 0.7152 + Color.menu.background.b * 0.0722
    return luminance < 0.5 ? "#f08a8a" : "#a52d3c"
  }

  function safetyColor() {
    var luminance = Color.menu.background.r * 0.2126
      + Color.menu.background.g * 0.7152 + Color.menu.background.b * 0.0722
    if (root.preview && root.preview.safeToPatch === true)
      return luminance < 0.5 ? "#8bd49c" : "#236b3e"
    return luminance < 0.5 ? "#f0c674" : "#8a5a00"
  }

  function symlinkSummary() {
    var logical = root.preview ? root.preview.logicalPath : ""
    var resolved = root.preview ? root.preview.resolvedPath : ""
    if (!logical || !resolved) return "Unknown — paths unavailable"
    return logical === resolved ? "No — paths match" : "Yes — logical path resolves to target"
  }

  function safetySummary() {
    if (root.preview && root.preview.safeToPatch === true) return "OK — safe to enable"
    var reason = root.pathValue("reasonCode")
    return reason === "—" ? "Review required" : "Review required — " + reason
  }

  function diffMarkup() {
    var lines = displayedDiff.split("\n")
    var output = []
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      var color = line.indexOf("+++") === 0 || line.indexOf("---") === 0
        ? String(Color.menu.text)
        : line.indexOf("+") === 0 ? diffAddedColor()
        : line.indexOf("-") === 0 ? diffRemovedColor() : String(Color.menu.text)
      output.push("<font color=\"" + color + "\">" + htmlEscape(line) + "</font>")
    }
    return output.join("<br/>")
  }

  function syncService() {
    service = bar && bar.shell && typeof bar.shell.serviceFor === "function"
      ? bar.shell.serviceFor(moduleName) : null
    refreshPreview()
  }

  function refreshPreview() {
    preview = service && service.integrationDetails ? service.integrationDetails : ({})
  }

  function open() {
    if (service && service.integrationState !== "enabled") service.inspectIntegration()
    refreshPreview()
    controller.show()
  }

  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function closeForPopoutSwitch() { close() }

  function pathValue(name) {
    var value = preview ? preview[name] : ""
    return value === null || value === undefined || value === "" ? "—" : String(value)
  }

  function statusText() {
    if (!service) return "Service unavailable; browse-only mode"
    if (service.integrationMutationRunning || service.integrationState === "enabling") return "Patching configuration…"
    if (service.integrationInspectRunning) return "Verifying integration status…"
    if (service.integrationState === "error") return "Integration error: " + pathValue("reasonCode")
    if (service.integrationState === "disconnected") return "Tracking is disconnected from the current configuration"
    if (service.integrationState === "enabled") return "Tracking enabled"
    return "Ready for review"
  }

  function enableLabel() {
    if (!service) return "Service unavailable"
    if (service.integrationMutationRunning) return "Working…"
    return "Enable tracking and visual keybinding guide"
  }

  function enableIntegration() {
    if (root.enableReady) root.service.enableIntegration(root.displayedHash)
  }

  function delayValue(index) { return [0, 80, 150, 250, -1][index] }

  function trackedBindingCount() {
    return root.service && root.service.stats && root.service.stats.bindings
      ? Object.keys(root.service.stats.bindings).length : 0
  }

  function questSummary() {
    if (!root.service || !root.service.dailyQuest) return "None available"
    var quest = root.service.dailyQuest
    var binding = root.service.bindingForId(quest.bindingId)
    var label = binding ? String(binding.description || binding.combo || quest.bindingId) : quest.bindingId
    return label + (quest.completed ? " (complete)" : "")
  }

  onBarChanged: syncService()
  Component.onCompleted: syncService()

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onIntegrationDetailsChanged() { root.refreshPreview() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.hostWidget || root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar || (root.hostWidget ? root.hostWidget.bar : null)
    open: root.opened
    // Follow the clicked widget along the bar; this places a top-right panel
    // below the top-right icon instead of moving it to the screen's corner.
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.fittedContentHeight(Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.enableIntegration()
    }

    Flickable {
      id: scroll
      anchors.fill: parent
      anchors.margins: Style.spacing.popupPadding
      contentWidth: width
      contentHeight: contentColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height

      Column {
        id: contentColumn
        width: scroll.width
        spacing: Style.space(12)

        Column {
          width: parent.width
          spacing: Style.space(3)

          Text {
            width: parent.width
            text: root.onboarding ? "Set up Omakeez" : "Omakeez"
            color: Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            width: parent.width
            text: root.statusText()
            color: root.service && root.service.integrationState === "error" ? Color.urgent : Color.foreground
            opacity: 0.78
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        Column {
          visible: root.onboarding
          width: parent.width
          spacing: Style.space(8)

          PanelSectionHeader { text: "Configuration review"; width: parent.width }

          Text {
            width: parent.width
            text: "Omakeez checks the Hyprland file it would update. This confirms the real target, symlink and Git safety, and that the managed bridge can be added without disturbing your existing bindings."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          BorderSurface {
            width: parent.width
            implicitHeight: detailsColumn.implicitHeight + Style.space(16)
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
            borderSpec: Border.flat(Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12), 1)
            radius: Style.cornerRadius

            Column {
              id: detailsColumn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(8)
              spacing: Style.space(3)

              Text { width: parent.width; text: "Logical path to Hyprland config: " + root.pathValue("logicalPath"); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Resolved path: " + root.pathValue("resolvedPath"); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Symlink: " + root.symlinkSummary(); color: Color.foreground; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Git: " + root.pathValue("gitRoot") + (root.preview && root.preview.gitDirty === true ? " (dirty)" : ""); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Safety: " + root.safetySummary(); color: root.safetyColor(); font.pixelSize: Style.font.caption; font.bold: true }
            }
          }

          Text {
            width: parent.width
            visible: !!root.service && root.preview && root.preview.safeToPatch !== true
            text: "Automatic patching is unavailable for this path. Review the reason above, then use Copy manual snippet to add the bridge yourself."
            color: root.safetyColor()
            opacity: 0.9
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            visible: root.displayedDiff !== ""
            text: "Proposed diff"
            color: Color.foreground
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            visible: root.displayedDiff !== ""
            text: "This is the small bridge change Omakeez would make. Red lines are the old managed block and green lines are its replacement: both sides show one change, not two bridges."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          BorderSurface {
            width: parent.width
            height: Style.space(170)
            visible: root.displayedDiff !== ""
            color: Qt.rgba(0, 0, 0, 0.18)
            borderSpec: Border.flat(Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12), 1)
            radius: Style.cornerRadius

            Flickable {
              anchors.fill: parent
              anchors.margins: Style.space(6)
              contentWidth: Math.max(width, diffText.paintedWidth)
              contentHeight: Math.max(height, diffText.paintedHeight)
              clip: true
              boundsBehavior: Flickable.StopAtBounds
              TextEdit {
                id: diffText
                width: Math.max(parent.width, paintedWidth)
                text: root.diffMarkup()
                textFormat: TextEdit.RichText
                readOnly: true
                selectByMouse: true
                color: Color.foreground
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                wrapMode: TextEdit.NoWrap
              }
            }
          }

          Text {
            width: parent.width
            text: "Only the managed bridge block changes. Existing bindings remain intact; Hyprland is validated and a rollback backup is kept."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Button {
            width: parent.width
            text: root.enableLabel()
            selected: root.enableReady
            focusable: true
            enabled: root.enableReady
            onClicked: root.enableIntegration()
          }

          Text {
            width: parent.width
            visible: !!root.service && root.service.integrationState === "error"
            text: "Reason: " + root.pathValue("reasonCode") + "\nReview the configuration, then recheck before trying again."
            color: Color.urgent
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Row {
            width: parent.width
            spacing: Style.space(8)
            Button {
              width: (parent.width - Style.space(8)) / 2
              text: "Recheck"
              enabled: !!root.service
              onClicked: if (root.service) { root.service.inspectIntegration(); root.refreshPreview() }
            }
            Button {
              width: (parent.width - Style.space(8)) / 2
              text: "Copy manual snippet"
              enabled: !!root.service && root.service.manualSnippet !== ""
              onClicked: Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(root.service.manualSnippet) + " | wl-copy"])
            }
          }
        }

        Column {
          visible: !root.onboarding
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader { text: "Integration"; width: parent.width }
          Text { width: parent.width; text: root.statusText() + "\n" + root.pathValue("resolvedPath"); color: Color.foreground; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }

          Row {
            width: parent.width
            spacing: Style.space(8)
            Button {
              text: root.confirmDisable ? "Confirm disable" : "Disable tracking"
              onClicked: {
                if (!root.confirmDisable) root.confirmDisable = true
                else root.service.disableIntegration(root.displayedHash)
              }
            }
            Button {
              visible: root.confirmDisable
              text: "Keep enabled"
              onClicked: root.confirmDisable = false
            }
          }

          PanelSectionHeader { text: "Guide"; width: parent.width }
          Text { width: parent.width; text: "Delay"; color: Color.foreground; font.pixelSize: Style.font.caption; font.bold: true }
          Flow {
            width: parent.width
            spacing: Style.space(4)
            Repeater {
              model: ["Instant", "80 ms", "150 ms", "250 ms", "Off"]
              Button {
                required property int index
                text: ["Instant", "80 ms", "150 ms", "250 ms", "Off"][index]
                selected: root.service && root.service.guideDelayMs === root.delayValue(index)
                onClicked: root.service.setGuideDelayMs(root.delayValue(index))
              }
            }
          }
          Row {
            width: parent.width
            spacing: Style.space(10)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Show in fullscreen: " + (root.service && root.service.showInFullscreen ? "On" : "Off")
              color: Color.foreground
              font.pixelSize: Style.font.caption
            }
            ToggleSwitch {
              checked: root.service && root.service.showInFullscreen
              onToggled: root.service.setShowInFullscreen(!checked)
            }
          }

          PanelSectionHeader { text: "Progress"; width: parent.width }
          BorderSurface {
            width: parent.width
            implicitHeight: statsColumn.implicitHeight + Style.space(16)
            color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
            borderSpec: Border.flat(Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.10), 1)
            radius: Style.cornerRadius
            Column {
              id: statsColumn
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(3)
              Text { text: "Tracked bindings: " + root.trackedBindingCount(); color: Color.foreground; font.pixelSize: Style.font.caption }
              Text { text: "Level: " + (root.service && root.service.currentLevel ? root.service.currentLevel.name : "Initiate") + " · XP: " + (root.service ? Number(root.service.stats.totalXp || 0) : 0); color: Color.foreground; font.pixelSize: Style.font.caption }
              Text { text: "Daily quest: " + root.questSummary(); color: Color.foreground; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
              Text { text: "Persistence: " + (root.service ? root.service.statsState : "unavailable"); color: Color.foreground; font.pixelSize: Style.font.caption }
              Text { text: "Session events: " + (root.service ? root.service.observedEventCount : 0); color: Color.foreground; font.pixelSize: Style.font.caption }
            }
          }

          Button {
            width: parent.width
            text: "Open Dojo"
            onClicked: if (root.service && root.service.shell) root.service.shell.summon(root.moduleName, "{}")
          }
          Button {
            width: parent.width
            text: root.confirmClear ? "Confirm clear local data" : "Clear local data"
            enabled: !!root.service && root.service.statsLoaded
              && !root.service.statsRecoveryRunning
            onClicked: {
              if (!root.confirmClear) root.confirmClear = true
              else if (root.service.clearLocalData(true)) root.confirmClear = false
            }
          }
        }
      }
    }
  }
}
