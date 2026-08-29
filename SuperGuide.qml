import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "GuideModel.js" as GuideModel

Item {
  id: root

  property var service: null
  property bool delayedVisible: false
  property bool expanded: false
  property string renderedHighlightId: ""
  property int focusRevision: 0
  property string frozenMask: ""
  property var frozenCards: []

  readonly property bool eligible: service ? GuideModel.eligible({
    integrationState: service.integrationState,
    catalogState: service.catalogState,
    desktopLocked: service.desktopLocked,
    credentialPromptActive: service.credentialPromptActive,
    activeWindowFullscreen: service.activeWindowFullscreen,
    showInFullscreen: service.showInFullscreen
  }) : false
  readonly property int delayValue: service ? Number(service.guideDelayMs) : -1
  readonly property string currentMask: service && String(service.activeModifiers || "") !== ""
    ? String(service.activeModifiers) : "SUPER"
  readonly property var lanes: GuideModel.laneCounts(service ? service.catalog : null)
  readonly property var bar: service && service.shell ? service.shell.bar : null
  readonly property string barPosition: bar ? String(bar.position || "top") : "top"
  readonly property int barSize: bar && Number(bar.barSize) > 0 ? Math.round(Number(bar.barSize)) : 0
  readonly property bool barHidden: bar ? bar.barHidden === true : false

  function pushUnique(list, id) {
    var value = String(id || "")
    if (value !== "" && list.indexOf(value) === -1) list.push(value)
  }

  function priorityIds() {
    var result = []
    if (!service) return result
    var quest = service.dailyQuest
    if (quest) pushUnique(result, quest.bindingId)
    if (service.recommendations) {
      var recommendations = service.recommendations(64)
      for (var i = 0; i < recommendations.length; i++) pushUnique(result, recommendations[i])
    }
    return result
  }

  function resetDeck() {
    frozenMask = currentMask
    frozenCards = GuideModel.rankedBindings(service ? service.catalog : null,
      frozenMask, priorityIds())
    expanded = false
  }

  function showGuide() {
    if (!delayedVisible || frozenMask !== currentMask) resetDeck()
    delayedVisible = true
  }

  function hideGuide() {
    guideDelayTimer.stop()
    overflowHoverTimer.stop()
    delayedVisible = false
    expanded = false
  }

  function expandOverflow() {
    if (!delayedVisible || expanded || frozenCards.length === 0) return
    expanded = true
  }

  function focusedScreenName() {
    var revision = focusRevision
    var monitor = Hyprland.focusedMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  function syncVisibility() {
    var mode = GuideModel.delayMode(service && service.guideVisible === true, delayValue)
    if (!eligible || mode === "hidden" || mode === "disabled") {
      hideGuide()
      return
    }
    if (mode === "immediate") {
      guideDelayTimer.stop()
      showGuide()
      return
    }
    if (!delayedVisible) {
      guideDelayTimer.interval = delayValue
      guideDelayTimer.restart()
    }
  }

  function beginHighlight(bindingId) {
    renderedHighlightId = String(bindingId || "")
    highlightTimer.restart()
  }

  Timer {
    id: guideDelayTimer
    repeat: false
    onTriggered: {
      if (root.eligible && root.service && root.service.guideVisible === true)
        root.showGuide()
    }
  }

  Timer {
    id: highlightTimer
    interval: 140
    repeat: false
    onTriggered: root.renderedHighlightId = ""
  }

  Timer {
    id: overflowHoverTimer
    interval: 150
    repeat: false
    onTriggered: root.expandOverflow()
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onGuideVisibleChanged() { root.syncVisibility() }
    function onGuideDelayMsChanged() { root.syncVisibility() }
    function onIntegrationStateChanged() { root.syncVisibility() }
    function onCatalogStateChanged() { root.syncVisibility() }
    function onDesktopLockedChanged() { root.syncVisibility() }
    function onCredentialPromptActiveChanged() { root.syncVisibility() }
    function onActiveWindowFullscreenChanged() { root.syncVisibility() }
    function onShowInFullscreenChanged() { root.syncVisibility() }
    function onActiveModifiersChanged() {
      if (root.delayedVisible && root.service && root.service.guideVisible === true)
        root.resetDeck()
    }
    function onBindingMatched(bindingId) { root.beginHighlight(bindingId) }
  }

  Connections {
    target: Hyprland
    function onFocusedMonitorChanged() {
      root.focusRevision += 1
      if (root.delayedVisible) root.resetDeck()
    }
  }

  Component.onCompleted: syncVisibility()

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: guideWindow
        required property var modelData

        screen: modelData
        visible: GuideModel.focusedVisible(
          root.delayedVisible,
          modelData ? modelData.name : "",
          root.focusedScreenName())
        color: "transparent"
        implicitHeight: guideContent.y + guideContent.height + Style.space(4)
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true; right: true }

        WlrLayershell.namespace: "keybind-dojo-guide"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // Hover is intentionally confined to this single pill. Every other
        // part of the guide remains pointer-transparent and the expanded
        // state is sticky, so cards themselves never need an input region.
        mask: Region {
          item: overflowPill.visible && !root.expanded ? overflowPill : null
        }

        readonly property var guideLayout: GuideModel.canopyLayout(root.frozenCards, {
          width: Math.max(1, guideContent.width),
          height: Math.max(1, height)
        }, root.expanded)

        onVisibleChanged: {
          if (visible && root.service && root.service.recordGuideVisible)
            root.service.recordGuideVisible()
        }

        Item {
          id: guideContent
          x: Style.space(4)
          y: GuideModel.barOffset(root.barPosition, root.barSize, root.barHidden) + Style.space(4)
          width: Math.max(1, parent.width - Style.space(8))
          height: headerChip.height + Style.space(5) + deckCanvas.height
            + (laneSummary.visible ? Style.space(5) + laneSummary.height : 0)

          BorderSurface {
            id: headerChip
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: headerRow.implicitWidth + Style.space(14)
            implicitHeight: Style.space(24)
            color: Util.alpha(Color.menu.background, 0.82)
            borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border,
              Math.max(1, Style.space(1)))
            radius: Style.cornerRadius

            Row {
              id: headerRow
              anchors.centerIn: parent
              spacing: Style.space(5)
              Text {
                text: "SUPER GUIDE"
                color: Color.menu.selectedText
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Text {
                text: root.expanded ? "all " + guideWindow.guideLayout.total + " bindings"
                  : root.frozenMask === "SUPER" ? "hold Super" : root.frozenMask
                color: Color.menu.text
                opacity: 0.84
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }
          }

          Item {
            id: deckCanvas
            x: 0
            y: headerChip.height + Style.space(5)
            width: parent.width
            height: guideWindow.guideLayout.height

            Repeater {
              model: guideWindow.guideLayout.items

              delegate: BorderSurface {
                required property var modelData
                readonly property bool highlighted: modelData.binding.id === root.renderedHighlightId

                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                radius: Style.cornerRadius
                color: highlighted ? Color.menu.selectedBackground
                  : Util.alpha(Color.menu.background, modelData.opacity)
                borderSpec: highlighted
                  ? Border.surfaceSpec("menu", "selected-border", Color.menu.selectedBorder,
                    Math.max(1, Style.space(1)))
                  : Border.surfaceSpec("menu", "border",
                    Util.alpha(Color.menu.border, Math.min(1, modelData.opacity + 0.12)),
                    Math.max(1, Style.space(1)))

                Row {
                  anchors.fill: parent
                  anchors.margins: Style.space(4)
                  spacing: Style.space(5)

                  BorderSurface {
                    id: comboKeycap
                    width: Math.min(parent.width * 0.5,
                      Math.max(Style.space(48), comboLabel.implicitWidth + Style.space(8)))
                    height: parent.height
                    color: highlighted ? Util.alpha(Color.menu.selectedText, 0.13)
                      : Util.alpha(Color.menu.text, 0.08)
                    borderSpec: Border.none()
                    radius: Style.cornerRadius

                    Text {
                      id: comboLabel
                      anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Style.space(4)
                      }
                      text: modelData.binding.combo
                      color: highlighted ? Color.menu.selectedText : Color.menu.text
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      elide: Text.ElideRight
                      maximumLineCount: 1
                      horizontalAlignment: Text.AlignHCenter
                    }
                  }

                  Text {
                    width: Math.max(1, parent.width - comboKeycap.width - parent.spacing)
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.binding.description
                    color: highlighted ? Color.menu.selectedText : Color.menu.text
                    opacity: highlighted ? 1 : 0.92
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    verticalAlignment: Text.AlignVCenter
                  }
                }
              }
            }

            BorderSurface {
              id: overflowPill
              visible: guideWindow.guideLayout.more > 0 && guideWindow.guideLayout.overflow
              x: visible ? guideWindow.guideLayout.overflow.x : 0
              y: visible ? guideWindow.guideLayout.overflow.y : 0
              width: visible ? guideWindow.guideLayout.overflow.width : 0
              height: visible ? guideWindow.guideLayout.overflow.height : 0
              radius: Style.cornerRadius
              color: Util.alpha(Color.menu.background, 0.9)
              borderSpec: Border.surfaceSpec("menu", "border", Color.menu.selectedBorder,
                Math.max(1, Style.space(1)))

              Text {
                anchors.centerIn: parent
                text: "+" + guideWindow.guideLayout.more + " MORE · HOVER"
                color: Color.menu.selectedText
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              HoverHandler {
                id: overflowHover
                enabled: overflowPill.visible && !root.expanded
                onHoveredChanged: {
                  if (hovered) overflowHoverTimer.restart()
                  else overflowHoverTimer.stop()
                }
              }
            }
          }

          Row {
            id: laneSummary
            visible: root.frozenMask === "SUPER"
            y: deckCanvas.y + deckCanvas.height + Style.space(5)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(5)

            Repeater {
              model: [
                { label: "Shift", count: root.lanes.SHIFT },
                { label: "Ctrl", count: root.lanes.CTRL },
                { label: "Alt", count: root.lanes.ALT }
              ]
              delegate: BorderSurface {
                required property var modelData
                implicitWidth: laneLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(20)
                color: Util.alpha(Color.menu.background, 0.62)
                borderSpec: Border.surfaceSpec("menu", "border", Util.alpha(Color.menu.border, 0.72),
                  Math.max(1, Style.space(1)))
                radius: Style.cornerRadius
                Text {
                  id: laneLabel
                  anchors.centerIn: parent
                  text: modelData.label + " " + modelData.count
                  color: Color.menu.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  opacity: 0.88
                }
              }
            }
          }
        }
      }
    }
  }
}
