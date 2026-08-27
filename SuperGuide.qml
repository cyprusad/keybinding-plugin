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
  property string renderedHighlightId: ""
  property int cardRevision: 0
  property int focusRevision: 0

  readonly property bool eligible: service ? GuideModel.eligible({
    integrationState: service.integrationState,
    catalogState: service.catalogState,
    desktopLocked: service.desktopLocked,
    credentialPromptActive: service.credentialPromptActive,
    activeWindowFullscreen: service.activeWindowFullscreen,
    showInFullscreen: service.showInFullscreen
  }) : false
  readonly property int delayValue: service ? Number(service.guideDelayMs) : -1
  readonly property var cards: root.makeCardModel()
  readonly property var lanes: GuideModel.laneCounts(service ? service.catalog : null)
  readonly property var bar: service && service.shell ? service.shell.bar : null
  readonly property string barPosition: bar ? String(bar.position || "top") : "top"
  readonly property int barSize: bar && Number(bar.barSize) > 0 ? Math.round(Number(bar.barSize)) : 0
  readonly property bool barHidden: bar ? bar.barHidden === true : false

  function makeCardModel() {
    // Read the revision so catalog and active-modifier changes invalidate this
    // binding even when the service keeps its catalog object identity.
    var revision = cardRevision
    var mask = service && String(service.activeModifiers || "") !== ""
      ? String(service.activeModifiers) : "SUPER"
    return GuideModel.cardModel(service ? service.catalog : null, mask, 12)
  }

  function focusedScreenName() {
    var revision = focusRevision
    var monitor = Hyprland.focusedMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  function syncVisibility() {
    var mode = GuideModel.delayMode(service && service.guideVisible === true, delayValue)
    if (!eligible || mode === "hidden" || mode === "disabled") {
      guideDelayTimer.stop()
      delayedVisible = false
      return
    }
    if (mode === "immediate") {
      guideDelayTimer.stop()
      delayedVisible = true
      return
    }
    delayedVisible = false
    guideDelayTimer.interval = delayValue
    guideDelayTimer.restart()
  }

  function beginHighlight(bindingId) {
    renderedHighlightId = String(bindingId || "")
    cardRevision += 1
    highlightTimer.restart()
  }

  Timer {
    id: guideDelayTimer
    repeat: false
    onTriggered: {
      if (root.eligible && root.service && root.service.guideVisible === true)
        root.delayedVisible = true
    }
  }

  Timer {
    id: highlightTimer
    interval: 140
    repeat: false
    onTriggered: {
      root.renderedHighlightId = ""
      root.cardRevision += 1
    }
  }

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    function onGuideVisibleChanged() { root.syncVisibility() }
    function onGuideDelayMsChanged() { root.syncVisibility() }
    function onIntegrationStateChanged() { root.syncVisibility() }
    function onCatalogStateChanged() { root.syncVisibility(); root.cardRevision += 1 }
    function onDesktopLockedChanged() { root.syncVisibility() }
    function onCredentialPromptActiveChanged() { root.syncVisibility() }
    function onActiveWindowFullscreenChanged() { root.syncVisibility() }
    function onShowInFullscreenChanged() { root.syncVisibility() }
    function onActiveModifiersChanged() { root.cardRevision += 1 }
    function onCatalogChanged() { root.cardRevision += 1 }
    function onBindingMatched(bindingId) { root.beginHighlight(bindingId) }
  }

  Connections {
    target: Hyprland
    function onFocusedMonitorChanged() {
      root.focusRevision += 1
      root.cardRevision += 1
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
        implicitHeight: surface.y + surface.implicitHeight + Style.space(4)
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true; right: true }

        WlrLayershell.namespace: "keybind-dojo-guide"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        onVisibleChanged: {
          if (visible && root.service && root.service.recordGuideVisible)
            root.service.recordGuideVisible()
        }

        BorderSurface {
          id: surface
          y: GuideModel.barOffset(root.barPosition, root.barSize, root.barHidden)
          anchors {
            left: parent.left
            right: parent.right
            margins: Style.space(4)
          }
          implicitHeight: content.implicitHeight + Style.space(4) * 2
          color: Color.menu.background
          borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
          radius: Style.cornerRadius
          clip: true

          Column {
            id: content
            anchors {
              fill: parent
              margins: Style.space(4)
            }
            spacing: Style.space(2)

            Row {
              width: parent.width
              height: Style.space(22)
              spacing: Style.space(3)

              Text {
                text: "SUPER GUIDE"
                color: Color.menu.selectedText
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
              Text {
                text: root.service && root.service.activeModifiers !== "SUPER"
                  ? String(root.service.activeModifiers || "") : "Hold Super to learn your shortcuts"
                color: Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
                width: Math.max(1, parent.width - x)
              }
            }

            Flow {
              id: cardsFlow
              width: parent.width
              spacing: Style.space(2)
              height: Math.max(Style.space(52), childrenRect.height)

              Repeater {
                model: root.cards.items
                delegate: Item {
                  required property var modelData
                  // Four readable lanes are the baseline; Flow adds more
                  // lanes on wide displays and fewer on narrow ones. The
                  // previous six-column minimum made cards too narrow for
                  // ordinary descriptions.
                  width: Math.min(Style.space(300), Math.max(Style.space(180), Math.floor((cardsFlow.width - Style.space(6)) / 4)))
                  height: Style.space(52)

                  BorderSurface {
                    anchors.fill: parent
                    radius: Style.cornerRadius
                    color: modelData.id === root.renderedHighlightId
                      ? Color.menu.selectedBackground : Color.menu.background
                    borderSpec: modelData.id === root.renderedHighlightId
                      ? Border.surfaceSpec("menu", "selected-border", Color.menu.selectedBorder, Math.max(1, Style.space(1)))
                      : Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))

                    Column {
                      anchors {
                        fill: parent
                        topMargin: Style.space(1)
                        rightMargin: Style.space(2)
                        bottomMargin: Style.space(1)
                        leftMargin: Style.space(2)
                      }
                      spacing: 0
                      Text {
                        width: parent.width
                        text: String(modelData.combo || "")
                        color: modelData.id === root.renderedHighlightId
                          ? Color.menu.selectedText : Color.menu.text
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                      }
                      Text {
                        width: parent.width
                        text: String(modelData.description || "")
                        color: Color.menu.text
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        clip: true
                      }
                    }
                  }
                }
              }
            }

            BorderSurface {
              width: parent.width
              height: Style.space(30)
              visible: root.cards.more > 0
              color: Color.menu.background
              borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))
              radius: Style.cornerRadius

              Text {
                anchors.centerIn: parent
                text: "+" + root.cards.more + " more"
                color: Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
              }
            }

            Flow {
              width: parent.width
              height: Style.space(24)
              visible: root.service && root.service.activeModifiers === "SUPER"
              spacing: Style.space(4)
              Text { text: "Shift " + root.lanes.SHIFT; color: Color.menu.text; font.family: Style.font.family; font.pixelSize: Style.font.caption }
              Text { text: "Ctrl " + root.lanes.CTRL; color: Color.menu.text; font.family: Style.font.family; font.pixelSize: Style.font.caption }
              Text { text: "Alt " + root.lanes.ALT; color: Color.menu.text; font.family: Style.font.family; font.pixelSize: Style.font.caption }
            }
          }
        }
      }
    }
  }
}
