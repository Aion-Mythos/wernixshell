pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vaxison.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    // Clamped so the edges stay reachable; the bar's edge uses the bar's size
    readonly property real left: bar.position === BarPosition.Left ? bar.clampedSize : clampedThickness
    readonly property real right: bar.position === BarPosition.Right ? bar.clampedSize : clampedThickness
    readonly property real top: bar.position === BarPosition.Top ? bar.clampedSize : clampedThickness
    readonly property real bottom: bar.position === BarPosition.Bottom ? bar.clampedSize : clampedThickness

    x: left + win.dragMaskPadding
    y: top + win.dragMaskPadding
    width: win.width - left - right - win.dragMaskPadding * 2
    height: win.height - top - bottom - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.bar.topInset
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.bar.bottomInset
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.bar.rightInset + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.bar.rightInset
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.bar.rightInset + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.bar.topInset
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.bar.bottomInset
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel.width * (root.bar.vertical ? 1 - root.panels.popoutsWrapper.offsetScale : 1)
        height: panel.height * (root.bar.vertical ? 1 : 1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.bar.leftInset
        y: panel.y + root.bar.topInset
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
