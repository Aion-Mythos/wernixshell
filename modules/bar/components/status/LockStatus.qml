import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

GridLayout {
    id: root

    required property bool vertical
    required property color colour
    required property int parentSpacing

    property real gap: Hypr.capsLock && Hypr.numLock ? parentSpacing : 0
    // Size of each icon's slot along the bar's axis
    property real capsHeight: Hypr.capsLock ? (vertical ? capslockIcon.implicitHeight : capslockIcon.implicitWidth) : 0
    property real numHeight: Hypr.numLock ? (vertical ? numlockIcon.implicitHeight : numlockIcon.implicitWidth) : 0

    columns: vertical ? 1 : 1000
    rowSpacing: Math.round(gap)
    columnSpacing: Math.round(gap)

    Behavior on gap {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Item {
        implicitWidth: root.vertical ? capslockIcon.implicitWidth : Math.round(root.capsHeight)
        implicitHeight: root.vertical ? Math.round(root.capsHeight) : capslockIcon.implicitHeight

        MaterialIcon {
            id: capslockIcon

            anchors.centerIn: parent

            scale: Hypr.capsLock ? 1 : 0.5
            opacity: Hypr.capsLock ? 1 : 0

            text: "keyboard_capslock_badge"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Item {
        implicitWidth: root.vertical ? numlockIcon.implicitWidth : Math.round(root.numHeight)
        implicitHeight: root.vertical ? Math.round(root.numHeight) : numlockIcon.implicitHeight

        MaterialIcon {
            id: numlockIcon

            anchors.centerIn: parent

            scale: Hypr.numLock ? 1 : 0.5
            opacity: Hypr.numLock ? 1 : 0

            text: "looks_one"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
