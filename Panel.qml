import QtQuick
import qs.Ui

Panel {
  id: root

  moduleName: "io.github.sai.keybind-dojo"
  ipcTarget: "io.github.sai.keybind-dojo"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null

  function syncService() {
    service = bar && bar.shell && typeof bar.shell.serviceFor === "function"
      ? bar.shell.serviceFor(moduleName) : null
  }

  function open() {
    controller.show()
  }

  function close() {
    controller.hide()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    close()
  }

  onBarChanged: syncService()
  Component.onCompleted: syncService()

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    contentWidth: 240
    contentHeight: 80

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }
  }
}
