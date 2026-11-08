pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Vaxison
import Vaxison.Config
import qs.components
import qs.services

// Special workspaces for horizontal bars
// shortcut: no scrolling, so many special workspaces get clipped; add a scrollable row if that matters
Item {
    id: root

    required property HyprlandMonitor monitor

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
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

    implicitWidth: row.implicitWidth

    Row {
        id: row

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            model: root.wsIds

            Workspace {
                vertical: false
                activeWsId: root.activeSpecialId
                ws: modelData
                monitor: root.monitor
                offMonitorColour: Colours.palette.m3outline
                displayType: Config.bar.workspaces.specialDisplayType
                showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
                iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
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
            activeIdx: root.wsIds.indexOf(root.activeSpecialId)
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const ws = row.childAt(event.x, event.y) as Workspace;
            const match = ws ? Hypr.workspaces.values.find(w => w.id === ws.ws) : null;
            Hypr.toggleSpecial(match ? Hypr.trimWsName(match.name) : "special");
        }
    }
}
