pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Vaxison.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool vertical
    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall

    property bool expanded

    // Size of the icons along the bar's axis, and of the tray without animations
    readonly property real layoutLength: vertical ? layout.implicitHeight : layout.implicitWidth
    readonly property real expandLength: vertical ? expandIcon.implicitHeight : expandIcon.implicitWidth
    readonly property real nonAnimLength: {
        if (!Config.bar.tray.compact)
            return layoutLength + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return expandLength + layoutLength + spacing + pad;
        return Math.max(Config.bar.tray.background ? Tokens.sizes.bar.innerWidth : 0, expandLength + pad);
    }

    clip: true
    visible: vertical ? height > 0 : width > 0

    implicitWidth: vertical ? Tokens.sizes.bar.innerWidth : nonAnimLength
    implicitHeight: vertical ? nonAnimLength : Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    // A column on vertical bars, a row on horizontal ones
    Grid {
        id: layout

        x: root.vertical ? (parent.width - width) / 2 : root.padding
        y: root.vertical ? root.padding : (parent.height - height) / 2
        columns: root.vertical ? 1 : Math.max(1, items.count)
        spacing: Tokens.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        x: root.vertical ? (parent.width - width) / 2 : parent.width - width
        y: root.vertical ? parent.height - height : (parent.height - height) / 2

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - Tokens.padding.small

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small
                text: "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: (root.vertical ? 0 : 90) + (root.expanded ? 180 : 0)

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        enabled: root.vertical

        Anim {}
    }

    Behavior on implicitWidth {
        enabled: !root.vertical

        Anim {}
    }
}
