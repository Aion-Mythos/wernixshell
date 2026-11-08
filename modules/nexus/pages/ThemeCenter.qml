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

    title: Tr.tr("Theme Center")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        SectionHeader {
            first: true
            text: Tr.tr("Dynamic")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            color: Themes.dynamicActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
            implicitHeight: dynRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: dynRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "wallpaper"
                    color: Themes.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Tr.tr("Dynamic")
                        color: Themes.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.large
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Colours generated from your wallpaper")
                        color: Themes.dynamicActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }
            }

            StateLayer {
                radius: parent.topLeftRadius
                onClicked: Themes.applyDynamic()
            }
        }

        SelectRow {
            label: Tr.tr("Variant")
            subtext: Tr.tr("How the wallpaper colours are turned into a palette")
            active: menuItems.find(i => i.modelData?.variant === Colours.variant) ?? menuItems[0]
            onSelected: item => Themes.setVariant(item.modelData.variant) // qmllint disable missing-property

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
            onToggled: Themes.setMode(checked ? "dark" : "light")
        }

        // Why the last action failed, e.g. matugen missing for the dynamic theme
        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            visible: Themes.error
            first: true
            last: true
            implicitHeight: errRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: errRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "error"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Themes.error
                    wrapMode: Text.Wrap
                    font: Tokens.font.body.small
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Themes")
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: Themes.themes.length === 0
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
                    text: "palette"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("No themes found: the data/schemes folder is missing or empty")
                    wrapMode: Text.Wrap
                    font: Tokens.font.body.large
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: Themes.themes.length > 0
            columns: Math.max(2, Math.floor(width / 180))
            columnSpacing: Tokens.spacing.large
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: Themes.themes

                ThemeCard {
                    required property var modelData

                    name: modelData.name
                    flavours: modelData.flavours
                    active: Colours.scheme === modelData.name
                    activeFlavour: Colours.flavour
                    onPicked: flavour => Themes.apply(name, flavour)
                }
            }
        }
    }
}
