import QtQuick
import qs.Ui

Panel {
  id: root

  moduleName: "io.github.sai.keybind-dojo"
  ipcTarget: "io.github.sai.keybind-dojo"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

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
