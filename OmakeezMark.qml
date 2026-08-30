import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  // The two references distilled into monochrome, theme-native marks.
  // "compact" is the heavier, small-size-friendly version; "outline" is the
  // lighter architectural version for panel-scale use.
  property string variant: "compact"
  property color color: Color.foreground
  readonly property bool compact: variant !== "outline"
  readonly property real stroke: Math.max(1, Math.min(width, height) * (compact ? 0.115 : 0.078))

  implicitWidth: 24
  implicitHeight: 24

  Shape {
    anchors.fill: parent
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    // Outer key shell. It deliberately has a broad lower rail and chamfered
    // shoulders, echoing the physical O-key silhouette in both concepts.
    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      startX: root.width * (root.compact ? 0.23 : 0.20)
      startY: root.height * (root.compact ? 0.15 : 0.11)
      PathLine { x: root.width * (root.compact ? 0.77 : 0.80); y: root.height * (root.compact ? 0.15 : 0.11) }
      PathLine { x: root.width * (root.compact ? 0.90 : 0.92); y: root.height * (root.compact ? 0.31 : 0.27) }
      PathLine { x: root.width * (root.compact ? 0.90 : 0.92); y: root.height * (root.compact ? 0.78 : 0.80) }
      PathLine { x: root.width * (root.compact ? 0.80 : 0.79); y: root.height * (root.compact ? 0.90 : 0.92) }
      PathLine { x: root.width * (root.compact ? 0.20 : 0.21); y: root.height * (root.compact ? 0.90 : 0.92) }
      PathLine { x: root.width * (root.compact ? 0.10 : 0.08); y: root.height * (root.compact ? 0.78 : 0.80) }
      PathLine { x: root.width * (root.compact ? 0.10 : 0.08); y: root.height * (root.compact ? 0.31 : 0.27) }
      PathLine { x: root.width * (root.compact ? 0.23 : 0.20); y: root.height * (root.compact ? 0.15 : 0.11) }
    }

    // The recessed key face keeps the mark legible as an O-key rather than a
    // generic rounded square.
    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      startX: root.width * 0.28
      startY: root.height * 0.28
      PathLine { x: root.width * 0.72; y: root.height * 0.28 }
      PathLine { x: root.width * 0.72; y: root.height * 0.72 }
      PathLine { x: root.width * 0.28; y: root.height * 0.72 }
      PathLine { x: root.width * 0.28; y: root.height * 0.28 }
    }

    // The O itself is intentionally a true ring so it survives both dark and
    // light themes without depending on a fixed background color.
    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: root.stroke * (root.compact ? 1.18 : 1.0)
      PathAngleArc {
        centerX: root.width * 0.50
        centerY: root.height * 0.50
        radiusX: root.width * 0.115
        radiusY: root.height * 0.115
        startAngle: 0
        sweepAngle: 360
      }
    }
  }
}
