import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "io.github.cyprusad.keybind-dojo"

  property var service: null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property int currentStreak: service && service.stats
    ? Math.max(0, Number(service.stats.currentStreak || service.stats.streak || 0)) : 0
  readonly property string statusMark: !service || service.integrationState === "disabled"
    ? " ·" : service.integrationState === "error" ? " !" : service.integrationState === "disconnected" ? " ?" : ""
  readonly property string tooltipSummary: service && service.integrationState === "enabled"
    ? "Keybind Dojo · streak " + currentStreak
    : "Set up Keybind Dojo"

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
      item.anchorItem = button
      item.hostWidget = root
      item.service = root.service
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌" + (root.currentStreak > 0 ? " " + root.currentStreak : "") + root.statusMark
    tooltipText: root.tooltipSummary
    fontSize: Style.font.body
    labelVisible: true
    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }
}
