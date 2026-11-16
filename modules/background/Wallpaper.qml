pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import WernixShell
import WernixShell.Config
import WernixShell.I18n
import WernixShell.State
import qs.components
import qs.components.filedialog
import qs.components.widgets
import qs.services
import qs.utils

Item {
    id: root

    property bool completed

    readonly property ShellScreen screen: (QsWindow.window as QsWindow)?.screen ?? null
    readonly property var monitor: Hypr.monitorFor(screen)
    // A fullscreen or maximised window, or tiled windows filling the monitor, hide the wallpaper
    readonly property bool covered: {
        const windows = monitor?.activeWorkspace?.toplevels.values ?? [];
        if (windows.some(t => t.lastIpcObject.fullscreen > 0))
            return true;
        const area = (monitor?.width ?? 0) * (monitor?.height ?? 0);
        const tiled = windows.filter(t => !t.lastIpcObject.floating && !t.lastIpcObject.hidden).reduce((sum, t) => sum + (t.lastIpcObject.size?.[0] ?? 0) * (t.lastIpcObject.size?.[1] ?? 0), 0);
        return area > 0 && tiled / area >= 0.75; // The bar, border and gaps keep tiled windows below 100%
    }
    readonly property bool autoPaused: {
        const v = Config.background.video;
        return (v.pauseWhenLocked && (ShellState.locked || ShellState.screenOff)) || (v.pauseOnBattery && UPower.onBattery) || (v.pauseWhenCovered && covered);
    }

    Component.onCompleted: completed = true

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !impl.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Tr.tr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: Tr.tr("Select a wallpaper")
                            filterLabel: Tr.tr("Images and videos")
                            filters: [...Images.validImageExtensions, ...Videos.validVideoExtensions]
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: Tr.tr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    WallpaperImpl {
        id: impl

        anchors.fill: parent
        playing: PersistentState.wallpaperPlaying && !root.autoPaused
        reportFailures: true
    }
}
