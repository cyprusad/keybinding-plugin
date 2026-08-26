import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
  id: root

  property var service: null

  visible: service ? service.guideVisible : false
  implicitHeight: Style.space(6)
  color: "transparent"
  anchors { top: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "keybind-dojo-feasibility"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  mask: Region {}

  onVisibleChanged: {
    if (visible && service && service.recordGuideVisible)
      service.recordGuideVisible()
  }

  Rectangle {
    anchors.fill: parent
    color: Color.accent
    opacity: 0.18
  }
}
