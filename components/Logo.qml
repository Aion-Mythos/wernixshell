import QtQuick
import QtQuick.Shapes
import qs.services

// The VexilionOS vxs logo (assets/logo.svg), drawn with theme colours
Item {
    id: root

    readonly property real designWidth: 160
    readonly property real designHeight: 52

    property color topColour: Colours.palette.m3primary // The accents
    property color bottomColour: Colours.palette.m3onSurface // The letters
    property color holeColour: Colours.palette.m3surface // Behind the ring of the X

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        // V
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 3
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M6,6 L26,46 L46,6 M2,6 L15,6"
            }
        }

        ShapePath {
            fillColor: root.topColour
            strokeColor: "transparent"

            PathSvg {
                path: "M22.85,46 A3.15,3.15 0 1 0 29.15,46 A3.15,3.15 0 1 0 22.85,46 Z"
            }
        }

        // X
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 3
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M60,6 L100,46 M100,6 L60,46"
            }
        }

        ShapePath {
            fillColor: root.holeColour
            strokeColor: root.topColour
            strokeWidth: 3

            PathSvg {
                path: "M74,26 A6,6 0 1 0 86,26 A6,6 0 1 0 74,26 Z"
            }
        }

        // S
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.bottomColour
            strokeWidth: 3
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M154,6 H123 A9,9 0 0 0 114,15 V17 A9,9 0 0 0 123,26 H145 A9,9 0 0 1 154,35 V37 A9,9 0 0 1 145,46 H114"
            }
        }
    }
}
