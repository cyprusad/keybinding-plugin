import QtQuick

Item {
  id: root

  property var service: null
  property string payloadJson: ""
  visible: false

  function open(payload) {
    payloadJson = payload === undefined || payload === null ? "" : String(payload)
    visible = true
  }

  function close() {
    visible = false
    payloadJson = ""
  }
}
