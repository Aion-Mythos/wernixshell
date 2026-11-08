pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vaxison.Config
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar

    // The zone on the bar's edge reserves the bar's space, the others only the border
    ExclusionZone {
        anchors.left: true
        edge: BarPosition.Left
    }

    ExclusionZone {
        anchors.top: true
        edge: BarPosition.Top
    }

    ExclusionZone {
        anchors.right: true
        edge: BarPosition.Right
    }

    ExclusionZone {
        anchors.bottom: true
        edge: BarPosition.Bottom
    }

    component ExclusionZone: StyledWindow {
        property int edge

        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: root.bar.position === edge ? root.bar.exclusiveZone : contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
