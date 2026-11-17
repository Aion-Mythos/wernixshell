pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import WernixShell.Components
import WernixShell.Config
import WernixShell.I18n
import WernixShell.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    property bool videoMode: false

    title: videoMode ? Tr.tr("Live wallpapers") : Tr.tr("Wallpapers")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "add"
                text: Tr.tr("Add")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: root.videoMode ? Tr.tr("Select a video wallpaper") : Tr.tr("Select a wallpaper")
                    filterLabel: root.videoMode ? Tr.tr("Videos") : Tr.tr("Images")
                    filters: root.videoMode ? Videos.validVideoExtensions : Images.validImageExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: Tr.tr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom(root.videoMode);
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            readonly property string path: Quickshell.shellPath(root.videoMode ? "assets/wallpaper-live.mp4" : "assets/wallpaper.webp")

            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: path
            text: root.videoMode ? Tr.tr("Featured live wallpaper") : Tr.tr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(path);
                root.nState.closeSubPage();
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: root.videoMode ? Tr.tr("Local videos") : Tr.tr("Local wallpapers")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: localWalls.count > 0

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                id: localWalls

                model: {
                    const walls = Wallpapers.list.filter(w => Videos.isVideo(w.path) === root.videoMode);
                    const baseDir = Paths.wallsdir;
                    const categories = {};
                    const list = [];
                    for (const w of walls) {
                        if (w.parentDir !== baseDir) {
                            const category = Wallpapers.getCategoryFor(w);
                            if (category && (!(category in categories) || categories[category].name.localeCompare(w.name) > 0))
                                categories[category] = w;
                        } else {
                            list.push(w);
                        }
                    }
                    list.push(...Object.values(categories));
                    list.sort((a, b) => ((a.parentDir === baseDir) - (b.parentDir === baseDir)) || a.name.localeCompare(b.name));
                    while (list.length < Config.nexus.wallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property FileSystemEntry modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    source: String(modelData?.path ?? "")
                    text: {
                        if (!modelData)
                            return "";

                        if (modelData.parentDir !== Paths.wallsdir) {
                            const category = Wallpapers.getCategoryFor(modelData);
                            return category.slice(0, 1).toUpperCase() + category.slice(1);
                        }
                        return modelData.name;
                    }
                    removable: !!modelData && modelData.parentDir === Paths.wallsdir
                    onRemoveRequested: Wallpapers.remove(modelData.path)
                    onClicked: {
                        if (modelData.parentDir !== Paths.wallsdir) {
                            root.nState.selectedWallpaperCategory = Wallpapers.getCategoryFor(modelData);
                            root.nState.selectedWallpaperVideoMode = root.videoMode;
                            root.nState.openSubPage(3); // Category page
                        } else {
                            Wallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: localWalls.count === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.videoMode ? Tr.tr("No local videos found") : Tr.tr("No local wallpapers found")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }
}
