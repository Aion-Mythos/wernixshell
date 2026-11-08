pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vaxison.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property real borderThickness // Thickness of the screen border on the edges without the bar

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int position: Config.bar.position
    readonly property bool vertical: position === BarPosition.Left || position === BarPosition.Right

    // Thickness of the bar's edge (animated); the border thickness when the bar is hidden
    property real size: fullscreen ? 0 : Config.border.thickness
    readonly property real clampedSize: Math.max(Config.border.minThickness, size)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentSize: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentSize : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered

    // Space taken on each screen edge: the bar's edge uses the bar size, the others the border
    readonly property real leftInset: position === BarPosition.Left ? size : borderThickness
    readonly property real rightInset: position === BarPosition.Right ? size : borderThickness
    readonly property real topInset: position === BarPosition.Top ? size : borderThickness
    readonly property real bottomInset: position === BarPosition.Bottom ? size : borderThickness

    // Whether (x, y) in window coordinates is over the bar's edge (clamped so it is always reachable)
    function contains(x: real, y: real, w: real, h: real): bool {
        switch (position) {
        case BarPosition.Left:
            return x < clampedSize;
        case BarPosition.Right:
            return x > w - clampedSize;
        case BarPosition.Top:
            return y < clampedSize;
        default:
            return y > h - clampedSize;
        }
    }

    // Position along the bar's axis
    function axisPos(x: real, y: real): real {
        return vertical ? y : x;
    }

    // Distance dragged away from the bar's edge, positive means into the screen
    function dragInward(dx: real, dy: real): real {
        switch (position) {
        case BarPosition.Left:
            return dx;
        case BarPosition.Right:
            return -dx;
        case BarPosition.Top:
            return dy;
        default:
            return -dy;
        }
    }

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(pos: real): void {
        (content.item as Bar)?.checkPopout(pos);
    }

    function handleWheel(pos: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(pos, angleDelta);
    }

    clip: true
    visible: size > Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.size: root.contentSize
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "size"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "size"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        // Sized to the bar's thickness and stuck to the screen edge; the wrapper clips it while it animates
        x: root.position === BarPosition.Left ? root.width - width : 0
        y: root.position === BarPosition.Top ? root.height - height : 0
        width: root.vertical ? root.contentSize : root.width
        height: root.vertical ? root.height : root.contentSize

        active: root.shouldBeVisible

        sourceComponent: Bar {
            vertical: root.vertical
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
            fullscreen: root.fullscreen
        }
    }
}
