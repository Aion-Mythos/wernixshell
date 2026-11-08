import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root

    readonly property real designWidth: 128
    readonly property real designHeight: 90.38

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        // Placeholder VexilionOS "vxs" logo; replace with the real one.
        ShapePath {
            fillColor: root.topColour
            strokeColor: "transparent"

            PathSvg {
                path: "M0,0 L24,0 L64,70 L104,0 L128,0 L74,90.38 L54,90.38 Z"
            }
        }
    }
}
