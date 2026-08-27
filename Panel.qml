import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "io.github.sai.keybind-dojo"
  ipcTarget: "io.github.sai.keybind-dojo"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property var preview: ({})
  property bool confirmDisable: false

  readonly property bool onboarding: !service || service.integrationState !== "enabled"
  readonly property string displayedHash: preview && typeof preview.currentHash === "string"
    ? preview.currentHash : ""
  readonly property string displayedDiff: preview && typeof preview.proposedDiff === "string"
    ? preview.proposedDiff : ""

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
    if (service.catalogGenerationRunning) return "Generating keybinding catalog…"
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
    return "Enable tracking and Super Guide"
  }

  function delayValue(index) { return [0, 80, 150, 250, -1][index] }

  onBarChanged: syncService()
  Component.onCompleted: syncService()

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onIntegrationDetailsChanged() { root.refreshPreview() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(500))
    contentHeight: panel.fittedContentHeight(Style.space(570))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
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
            text: root.onboarding ? "Set up Keybind Dojo" : "Keybind Dojo"
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

              Text { width: parent.width; text: "Logical: " + root.pathValue("logicalPath"); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Resolved: " + root.pathValue("resolvedPath"); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Symlink: " + (root.preview && root.preview.symlinked === true ? "preserved" : "no"); color: Color.foreground; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Git: " + root.pathValue("gitRoot") + (root.preview && root.preview.gitDirty === true ? " (dirty)" : ""); color: Color.foreground; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              Text { width: parent.width; text: "Safety: " + root.pathValue("reasonCode"); color: root.preview && root.preview.safeToPatch === true ? Color.foreground : Color.urgent; font.pixelSize: Style.font.caption }
            }
          }

          Text {
            width: parent.width
            visible: root.displayedDiff !== ""
            text: "Proposed diff"
            color: Color.foreground
            font.pixelSize: Style.font.caption
            font.bold: true
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
                text: root.displayedDiff
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
            text: "The button edits the resolved target, preserves the symlink, validates Hyprland, and keeps a rollback backup. No elevated privileges are offered."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Button {
            width: parent.width
            text: root.enableLabel()
            enabled: !!root.service && root.preview && root.preview.safeToPatch === true
              && root.displayedHash !== "" && !root.service.integrationMutationRunning
            onClicked: root.service.enableIntegration(root.displayedHash)
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
              text: "Recheck"
              onClicked: { root.service.inspectIntegration(); root.refreshPreview() }
            }
            Button {
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
          Row {
            width: parent.width
            spacing: Style.space(4)
            Repeater {
              model: ["Instant", "80 ms", "150 ms", "250 ms", "Off"]
              Button {
                required property int index
                text: modelData
                selected: root.service && root.service.guideDelayMs === root.delayValue(index)
                onClicked: root.service.setGuideDelayMs(root.delayValue(index))
              }
            }
          }
          Row {
            width: parent.width
            spacing: Style.space(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Show in fullscreen"; color: Color.foreground; font.pixelSize: Style.font.caption }
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
              Text { text: "Stats and recommendations arrive with Tasks 10–11."; color: Color.foreground; font.pixelSize: Style.font.caption }
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
            text: "Clear local data"
            enabled: false
            tooltipText: "Available when aggregate persistence is implemented"
          }
        }
      }
    }
  }
}
