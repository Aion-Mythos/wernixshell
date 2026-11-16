import QtQuick
import QtQuick.Shapes
import qs.services

// The WernixOS logo (assets/logo.svg), drawn with theme colours
Item {
    id: root

    readonly property real designWidth: 228
    readonly property real designHeight: 228

    property color topColour: Colours.palette.m3primary // The core
    property color bottomColour: Colours.palette.m3onSurface // The rings

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        // The three rings (the SVG's points, moved by +114 into this item)
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 10
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M114,14 L200.6,64 L200.6,164 L114,214 L27.4,164 L27.4,64 Z M126.16,45.06 L179.78,90.06 L167.62,159 L101.84,182.94 L48.22,137.94 L60.38,69 Z M129.05,72.65 L157.33,106.36 L142.28,147.71 L98.95,155.35 L70.67,121.64 L85.72,80.29 Z"
            }
        }

        // The core
        ShapePath {
            fillColor: root.topColour
            strokeColor: root.topColour
            strokeWidth: 2
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M126,93.22 L138,114 L126,134.78 L102,134.78 L90,114 L102,93.22 Z"
            }
        }
    }
}
