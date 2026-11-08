pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vaxison.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    // Space the bar and border take on the left and top edges, to convert bar coordinates to ours
    required property real leftInset
    required property real topInset

    readonly property alias content: content
    readonly property int position: Config.bar.position
    readonly property bool vertical: position === BarPosition.Left || position === BarPosition.Right
    property real offsetScale: x > 0 || content.hasCurrent ? 0 : 1

    // Start of a popout of the given size centred on `center`, kept inside the parent
    function along(center: real, size: real, parentSize: real): real {
        const off = center - size / 2;
        const diff = parentSize - Math.floor(off + size);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    // Position of a popout of the given size sliding in from the start or end of the parent
    function slide(atStart: bool, size: real, parentSize: real): real {
        const hidden = (size + 5) * offsetScale;
        return atStart ? -hidden : parentSize - size + hidden;
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (vertical ? 1 - offsetScale : 1)
    implicitHeight: content.implicitHeight * (vertical ? 1 : 1 - offsetScale)

    // Popouts are centred on the hovered item along the bar and stuck to the bar's edge
    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (vertical)
            return position === BarPosition.Right ? parent.width - width : 0;
        return along(content.currentCenter - leftInset, content.nonAnimWidth, parent.width);
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (!vertical)
            return position === BarPosition.Bottom ? parent.height - height : 0;
        return along(content.currentCenter - topInset, content.nonAnimHeight, parent.height);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        enabled: root.vertical || root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: !root.vertical || root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        // Centred along the bar and slides in from the bar's edge (anchors can't be reset on live changes)
        x: root.vertical ? root.slide(root.position === BarPosition.Left, width, root.width) : (root.width - width) / 2
        y: root.vertical ? (root.height - height) / 2 : root.slide(root.position === BarPosition.Top, height, root.height)
    }
}
