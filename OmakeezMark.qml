import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  // A logo needs two optical sizes. The full mark preserves the key's layered
  // frame and side rails; the micro mark intentionally keeps only the O-key
  // silhouette and ring, which is the most that remains legible in a bar.
  property string variant: "full" // "full" or "micro"
  property color color: Color.foreground
  readonly property bool micro: variant === "micro"
  readonly property real stroke: Math.max(1, Math.min(width, height) * (micro ? 0.115 : 0.066))

  implicitWidth: 32
  implicitHeight: 32

  // The small version is deliberately a single O-key: full nested geometry
  // at this scale reads as a rendering error, not as a richer logo.
  Rectangle {
    visible: root.micro
    anchors.centerIn: parent
    width: Math.min(parent.width, parent.height) * 0.82
    height: width
    radius: width * 0.24
    color: "transparent"
    border.color: root.color
    border.width: root.stroke

    Shape {
      anchors.centerIn: parent
      width: parent.width * 0.46
      height: width
      antialiasing: true
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: root.color
        fillColor: "transparent"
        strokeWidth: root.stroke * 1.1
        PathAngleArc {
          centerX: parent.width / 2
          centerY: parent.height / 2
          radiusX: parent.width * 0.31
          radiusY: parent.height * 0.31
          startAngle: 0
          sweepAngle: 360
        }
      }
    }
  }

  // Full panel-scale mark traced from the supplied O-key reference: a broad
  // outer shell, an inset key face, and a central O ring. It has no fill, so
  // it adapts to every shell background and foreground palette.
  Shape {
    visible: !root.micro
    anchors.fill: parent
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      startX: root.width * 0.25
      startY: root.height * 0.10
      PathLine { x: root.width * 0.75; y: root.height * 0.10 }
      PathLine { x: root.width * 0.90; y: root.height * 0.25 }
      PathLine { x: root.width * 0.90; y: root.height * 0.75 }
      PathLine { x: root.width * 0.80; y: root.height * 0.91 }
      PathLine { x: root.width * 0.20; y: root.height * 0.91 }
      PathLine { x: root.width * 0.10; y: root.height * 0.75 }
      PathLine { x: root.width * 0.10; y: root.height * 0.25 }
      PathLine { x: root.width * 0.25; y: root.height * 0.10 }
    }

    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      startX: root.width * 0.29
      startY: root.height * 0.28
      PathLine { x: root.width * 0.71; y: root.height * 0.28 }
      PathLine { x: root.width * 0.71; y: root.height * 0.71 }
      PathLine { x: root.width * 0.29; y: root.height * 0.71 }
      PathLine { x: root.width * 0.29; y: root.height * 0.28 }
    }

    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke * 1.35
      PathAngleArc {
        centerX: root.width * 0.50
        centerY: root.height * 0.50
        radiusX: root.width * 0.14
        radiusY: root.height * 0.14
        startAngle: 0
        sweepAngle: 360
      }
    }
  }
}
