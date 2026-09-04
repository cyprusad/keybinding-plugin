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
  property bool showDiff: false

  readonly property bool onboarding: !service || service.integrationState !== "enabled"
  readonly property string displayedHash: preview && typeof preview.currentHash === "string"
    ? preview.currentHash : ""
  readonly property string displayedDiff: preview && typeof preview.proposedDiff === "string"
    ? preview.proposedDiff : ""
  readonly property string bridgeSourceUrl: "https://github.com/cyprusad/omakeez/blob/main/bridge.lua"
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

  function symlinkPathsMatch() {
    var logical = root.preview ? root.preview.logicalPath : ""
    var resolved = root.preview ? root.preview.resolvedPath : ""
    return logical !== "" && resolved !== "" && logical === resolved
  }

  function symlinkCheckSummary() {
    if (root.symlinkPathsMatch()) return "OK — logical and resolved paths match"
    if (root.preview && root.preview.logicalPath && root.preview.resolvedPath)
      return "Review required — paths differ"
    return "Review required — paths unavailable"
  }

  function safetySummary() {
    if (root.preview && root.preview.safeToPatch === true) return "OK — safe to enable"
    var reason = root.pathValue("reasonCode")
    return reason === "—" ? "Review required" : "Review required — " + reason
  }

  function gitCheckSummary() {
    if (!root.preview || root.preview.gitManaged !== true) return "Not tracked"
    var rootPath = root.pathValue("gitRoot")
    return "Tracked — " + rootPath + (root.preview.gitDirty === true ? " (working tree changed)" : " (clean)")
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
    showDiff = false
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
    if (service.integrationState === "disconnected") return "Visual guide is disconnected from the current configuration"
    if (service.integrationState === "enabled") return "Visual guide enabled"
    return "Ready for review"
  }

  function enableLabel() {
    if (!service) return "Service unavailable"
    if (service.integrationMutationRunning) return "Working…"
    return "Enable visual keybinding guide"
  }

  function enableIntegration() {
    if (root.enableReady) root.service.enableIntegration(root.displayedHash)
  }

  function openBridgeSource() {
    Qt.openUrlExternally(root.bridgeSourceUrl)
  }

  readonly property var activationLabels: ["Instant", "80 ms", "150 ms", "250 ms", "Double tap", "Off"]

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
    // The scroll view has its own inset in addition to KeyboardPanel's card
    // padding. Include it so the compact sizing never clips the final CTA.
    contentHeight: panel.fittedContentHeight(
      contentColumn.implicitHeight + Style.spacing.popupPadding * 2,
      Style.space(640))

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
            text: root.onboarding ? "SET UP OMAKEEZ" : "OMAKEEZ"
            color: Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            width: parent.width
            visible: !root.service || root.service.integrationMutationRunning
              || root.service.integrationInspectRunning
              || root.service.integrationState === "error"
              || root.service.integrationState === "disconnected"
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

          PanelSeparator { width: parent.width }

          Text {
            width: parent.width
            text: "CONFIGURATION REVIEW"
            color: Color.foreground
            opacity: 0.82
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            text: "Omakeez checks the Hyprland file before it changes anything."
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
              spacing: Style.space(7)

              Text { width: parent.width; text: "Safety"; color: Color.foreground; opacity: 0.68; font.pixelSize: Style.font.caption; font.bold: true }
              Text { width: parent.width; text: root.safetySummary(); color: root.safetyColor(); font.pixelSize: Style.font.body; font.bold: true; wrapMode: Text.WordWrap }
              Text {
                width: parent.width
                text: root.enableReady
                  ? "Omakeez can add its small local bridge without changing your existing bindings."
                  : "Automatic setup needs review before Omakeez can change this file."
                color: Color.foreground
                opacity: 0.76
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              Row {
                width: parent.width
                spacing: Style.space(16)

                Column {
                  width: (parent.width - parent.spacing) / 2
                  spacing: Style.space(2)
                  Text { width: parent.width; text: "Symlink check"; color: Color.foreground; opacity: 0.62; font.pixelSize: Style.font.caption; font.bold: true }
                  Text { width: parent.width; text: root.symlinkCheckSummary(); color: root.symlinkPathsMatch() ? Color.foreground : root.safetyColor(); opacity: 0.86; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
                }

                Column {
                  width: (parent.width - parent.spacing) / 2
                  spacing: Style.space(2)
                  Text { width: parent.width; text: "Git check"; color: Color.foreground; opacity: 0.62; font.pixelSize: Style.font.caption; font.bold: true }
                  Text { width: parent.width; text: root.gitCheckSummary(); color: Color.foreground; opacity: 0.86; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }
                }
              }

              Column {
                visible: !root.symlinkPathsMatch()
                width: parent.width
                spacing: Style.space(2)
                Text { width: parent.width; text: "Logical path: " + root.pathValue("logicalPath"); color: Color.foreground; opacity: 0.78; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
                Text { width: parent.width; text: "Resolved path: " + root.pathValue("resolvedPath"); color: Color.foreground; opacity: 0.78; elide: Text.ElideMiddle; font.pixelSize: Style.font.caption }
              }
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

          PanelSeparator {
            width: parent.width
            visible: root.displayedDiff !== ""
          }

          Text {
            width: parent.width
            visible: root.displayedDiff !== ""
            text: "WHAT OMAKEEZ CHANGES"
            color: Color.foreground
            opacity: 0.82
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width
            visible: root.displayedDiff !== ""
            text: "One small, local bridge is added to Hyprland so the visual guide can see registered keyboard shortcuts."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Row {
            width: parent.width
            visible: root.displayedDiff !== ""
            spacing: Style.space(14)

            Text {
              text: root.showDiff ? "Hide exact change" : "Review exact change"
              color: Color.accent
              opacity: 0.86
              font.pixelSize: Style.font.caption
              font.underline: diffToggleMouse.containsMouse
              MouseArea {
                id: diffToggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showDiff = !root.showDiff
              }
            }

            Text {
              text: "View bridge source"
              color: Color.accent
              opacity: 0.86
              font.pixelSize: Style.font.caption
              font.underline: bridgeSourceMouse.containsMouse
              MouseArea {
                id: bridgeSourceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openBridgeSource()
              }
            }
          }

          BorderSurface {
            width: parent.width
            height: Style.space(170)
            visible: root.displayedDiff !== "" && root.showDiff
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
            visible: !!root.service && root.preview && root.preview.safeToPatch !== true
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

          Text {
            width: parent.width
            text: "Omakeez shows a visual guide for registered keyboard shortcuts while you hold their starting keys."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: "ACTIVATION"
            color: Color.foreground
            opacity: 0.70
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: "How much intent a guide should ask for before it covers the screen. A delay waits while you hold the key. Double tap opens the guide on the second press instead, so holding the key on its own stays silent. Off keeps Omakeez enabled without showing a guide."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Flow {
            width: parent.width
            spacing: Style.space(4)
            Repeater {
              model: root.activationLabels
              Button {
                required property int index
                text: root.activationLabels[index]
                selected: root.service && root.service.guideActivationIndex === index
                onClicked: root.service.setGuideActivation(index)
              }
            }
          }

          PanelSeparator { width: parent.width; strength: 0.09 }

          Row {
            width: parent.width
            spacing: Style.space(10)
            Column {
              width: parent.width - fullscreenToggle.width - parent.spacing
              spacing: Style.space(2)
              Text {
                width: parent.width
                text: "FULLSCREEN"
                color: Color.foreground
                opacity: 0.70
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Text {
                width: parent.width
                text: "Keep the guide visible while you use fullscreen apps."
                color: Color.foreground
                opacity: 0.78
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
            ToggleSwitch {
              id: fullscreenToggle
              anchors.verticalCenter: parent.verticalCenter
              checked: root.service && root.service.showInFullscreen
              onToggled: root.service.setShowInFullscreen(!checked)
            }
          }

          PanelSeparator { width: parent.width; strength: 0.09 }

          Text {
            width: parent.width
            text: "SHOW GUIDES FOR"
            color: Color.foreground
            opacity: 0.70
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: "Choose which held keys open a visual guide. Shortcuts continue to work normally."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
          Flow {
            width: parent.width
            spacing: Style.space(12)
            Repeater {
              model: ["SUPER", "SHIFT", "CTRL", "ALT"]
              Row {
                required property string modelData
                spacing: Style.space(6)
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: parent.modelData
                  color: Color.foreground
                  opacity: 0.82
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
                ToggleSwitch {
                  checked: root.service && root.service.guideRootEnabled(parent.modelData)
                  onToggled: root.service.setGuideRootEnabled(parent.modelData, !checked)
                }
              }
            }
          }

          PanelSeparator { width: parent.width }

          Text {
            width: parent.width
            text: "INTEGRATION"
            color: Color.foreground
            opacity: 0.82
            font.pixelSize: Style.font.caption
            font.bold: true
          }
          Text {
            width: parent.width
            text: "The local Hyprland bridge is active. Disable it to remove the bridge and stop the visual guide."
            color: Color.foreground
            opacity: 0.78
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Item {
            width: parent.width
            height: disableActions.implicitHeight

            Row {
              id: disableActions
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(8)

              Button {
                text: root.confirmDisable ? "Confirm disable guide" : "Disable visual guide"
                selected: true
                onClicked: {
                  if (!root.confirmDisable) root.confirmDisable = true
                  else root.service.disableIntegration(root.displayedHash)
                }
              }
              Button {
                visible: root.confirmDisable
                text: "Keep guide enabled"
                onClicked: root.confirmDisable = false
              }
            }
          }
        }
      }
    }
  }
}
