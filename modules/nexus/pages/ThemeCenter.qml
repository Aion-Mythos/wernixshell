pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Vaxison.Config
import Vaxison.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.themecenter

PageBase {
    id: root

    readonly property bool dynamicActive: Colours.scheme === "dynamic"
    // Group the flat scheme list by name; "vexilion" first, "dynamic" has its own card
    readonly property var themes: {
        const byName = {};
        for (const s of Schemes.list) {
            if (s.name === "dynamic")
                continue;
            if (!byName[s.name])
                byName[s.name] = [];
            byName[s.name].push({
                flavour: s.flavour,
                colours: s.colours
            });
        }
        const pin = n => n === "vexilion" ? 0 : 1;
        return Object.entries(byName).map(([name, flavours]) => ({
                    name,
                    flavours
                })).sort((a, b) => pin(a.name) - pin(b.name) || a.name.localeCompare(b.name));
    }

    function apply(args: list<string>): void {
        Quickshell.execDetached(["vsm", "scheme", "set", ...args]);
        refresh.restart();
    }

    title: Tr.tr("Theme Center")
    Component.onCompleted: {
        Schemes.reload();
        Schemes.reloadList();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        Timer { // vsm writes the scheme file asynchronously
            id: refresh

            interval: 800
            onTriggered: Schemes.reload()
        }

        SectionHeader {
            first: true
            text: Tr.tr("Dynamic")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            color: root.dynamicActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
            implicitHeight: dynRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: dynRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "wallpaper"
                    color: root.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Tr.tr("Dynamic")
                        color: root.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Colours generated from your wallpaper")
                        color: root.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }

            StateLayer {
                radius: parent.topLeftRadius
                onClicked: root.apply(["-n", "dynamic"])
            }
        }

        SelectRow {
            label: Tr.tr("Variant")
            subtext: Tr.tr("How the wallpaper colours are turned into a palette")
            active: menuItems.find(i => i.modelData?.variant === Schemes.currentVariant) ?? menuItems[0]
            onSelected: item => root.apply(["-v", item.modelData.variant]) // qmllint disable missing-property

            menuItems: variants.instances

            Variants {
                id: variants

                model: M3Variants.list

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    icon: modelData.icon
                }
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        SectionHeader {
            text: Tr.tr("Themes")
        }

        // Shown instead of the grid when vsm gave no themes, so a missing vsm never fails silently
        ConnectedRect {
            Layout.fillWidth: true
            visible: root.themes.length === 0
            first: true
            last: true
            implicitHeight: emptyRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: emptyRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "error"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("No themes found: is vsm installed?")
                        font: Tokens.font.body.large
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: Schemes.error
                        text: Schemes.error
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.Wrap
                    }
                }

                IconTextButton {
                    icon: "refresh"
                    text: Tr.tr("Retry")
                    type: IconTextButton.Tonal
                    onClicked: Schemes.reloadList()
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.themes.length > 0
            columns: Math.max(2, Math.floor(width / 180))
            columnSpacing: Tokens.spacing.large
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: root.themes

                ThemeCard {
                    required property var modelData

                    name: modelData.name
                    flavours: modelData.flavours
                    active: Colours.scheme === modelData.name
                    activeFlavour: Colours.flavour
                    onPicked: flavour => root.apply(["-n", name, "-f", flavour])
                }
            }
        }
    }
}
