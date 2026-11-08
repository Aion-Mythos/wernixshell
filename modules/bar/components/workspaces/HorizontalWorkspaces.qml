pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Vaxison
import Vaxison.Config
import qs.components
import qs.services

// Workspaces for horizontal bars: a row of workspaces with the same indicator, occupied background and gap markers
Item {
    id: root

    required property var wsIds
    required property int activeWsId
    required property int activeWsIdx
    required property int groupOffset
    required property HyprlandMonitor monitor

    // Workspace items in order, and where each one will end up once animations finish
    readonly property var items: {
        CUtils.dependency(repeater.count);
        return Array.from({
            length: repeater.count
        }, (_, i) => repeater.itemAt(i)).filter(i => i);
    }
    readonly property var targets: {
        const starts = [];
        const lengths = [];
        let pos = 0;
        for (const item of items) {
            starts.push(pos);
            lengths.push(item.preferredLength);
            pos += item.preferredLength + row.spacing;
        }
        return {
            starts,
            lengths
        };
    }

    implicitWidth: row.implicitWidth + Tokens.padding.extraSmall * 2
    implicitHeight: Tokens.sizes.bar.innerWidth

    Behavior on implicitWidth {
        Anim {}
    }

    Loader {
        asynchronous: true
        opacity: Config.bar.workspaces.occupiedBg ? 1 : 0
        active: opacity > 0

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        sourceComponent: HOccupiedBg {
            workspaces: root.items
            wsSpacing: row.spacing
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Row {
        id: row

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: repeater

            model: root.wsIds

            Workspace {
                vertical: false
                activeWsId: root.activeWsId
                ws: Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
                monitor: root.monitor

                displayType: Config.bar.workspaces.displayType
                showWindows: Config.bar.workspaces.showWindows
                iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                activeLabel: Config.bar.workspaces.activeLabel
                occupiedLabel: Config.bar.workspaces.occupiedLabel
                label: Config.bar.workspaces.label
            }
        }
    }

    Loader {
        asynchronous: true
        opacity: Config.bar.workspaces.showUnoccupied ? 0 : 1
        active: opacity > 0

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        sourceComponent: HGapMarkers {
            workspaces: root.items
            wsSpacing: row.spacing
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.top: row.top
        anchors.bottom: row.bottom
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: HActiveIndicator {
            mask: row
            starts: root.targets.starts
            lengths: root.targets.lengths
            activeIdx: root.activeWsIdx
        }
    }

    MouseArea {
        anchors.fill: row
        onClicked: event => {
            const ws = (row.childAt(event.x, event.y) as Workspace)?.ws;
            if (!ws)
                return;
            if (Hypr.activeWsId !== ws)
                Hypr.focusWorkspace(ws);
            else
                Hypr.toggleSpecial("special");
        }
    }
}
