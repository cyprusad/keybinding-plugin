import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "io.github.cyprusad.omakeez"

  property var service: null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property string statusMark: !service || service.integrationState === "disabled"
    ? " ·" : service.integrationState === "error" ? " !" : service.integrationState === "disconnected" ? " ?" : ""
  readonly property string tooltipSummary: service && service.integrationState === "enabled"
    ? "Omakeez keyboard shortcuts enabled"
    : service && service.integrationState === "disconnected"
      ? "Omakeez keyboard shortcuts disconnected"
      : service && service.integrationState === "error"
        ? "Omakeez needs attention"
        : "Set up Omakeez keyboard shortcuts"

  function syncService() {
    service = bar && bar.shell && typeof bar.shell.serviceFor === "function"
      ? bar.shell.serviceFor(moduleName) : null
  }

  onServiceChanged: if (panelLoader.item) panelLoader.item.service = service

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch)
      panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: syncService()
  Component.onCompleted: syncService()

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      item.bar = root.bar
      // Anchor to the registered bar-widget surface. It has the reliable
      // QsWindow relationship used by KeyboardPanel even when the nested
      // visual button is incubated before the bar finishes configuring it.
      item.anchorItem = root
      item.hostWidget = root
      item.service = root.service
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      OmakeezMark {
        anchors.centerIn: parent
        width: Style.bar.iconCanvas
        height: Style.bar.iconCanvas
        variant: "compact"
        color: root.bar ? root.bar.barForeground : Color.foreground
      }
    }
    tooltipText: root.tooltipSummary
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }
}
