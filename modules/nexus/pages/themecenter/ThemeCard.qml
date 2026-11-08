import QtQuick
import QtQuick.Layouts
import Vaxison.Config
import qs.components
import qs.services

Item {
    id: root

    required property string name
    required property var flavours // [{ flavour, colours }]
    property bool active
    property string activeFlavour

    // The flavour shown in the preview: the applied one if this theme is active
    readonly property var shown: flavours.find(f => f.flavour === activeFlavour && active) ?? flavours[0]

    signal picked(flavour: string)

    function colour(key: string, fallback: string): color {
        return `#${shown.colours[key] ?? shown.colours[fallback]}`;
    }

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledRect {
            id: preview

            Layout.fillWidth: true
            implicitHeight: width * 0.6
            radius: Tokens.rounding.largeIncreased
            color: root.colour("background", "surface")

            // Palette strip: primary, secondary, tertiary, accent
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: ["primary", "secondary", "tertiary", "primaryContainer"]

                    StyledRect {
                        required property string modelData

                        width: ((parent?.width ?? 0) - (parent?.spacing ?? 0) * 3) / 4
                        height: Tokens.padding.large
                        radius: Tokens.rounding.full
                        color: root.colour(modelData, "primary")
                    }
                }
            }

            StateLayer {
                radius: preview.radius
                onClicked: root.picked(root.shown.flavour)
            }

            StyledRect { // Active outline
                anchors.fill: parent
                radius: preview.radius
                border.width: 2
                border.color: root.active ? Colours.palette.m3primary : "transparent"

                Behavior on border.color {
                    CAnim {}
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.name
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Flow {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.padding.small
            visible: root.flavours.length > 1
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: root.flavours

                StyledRect {
                    id: chip

                    required property var modelData
                    readonly property bool isActive: root.active && modelData.flavour === root.activeFlavour

                    implicitWidth: chipLabel.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: chipLabel.implicitHeight + Tokens.padding.extraSmall * 2
                    radius: Tokens.rounding.full
                    color: isActive ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    StyledText {
                        id: chipLabel

                        anchors.centerIn: parent
                        text: chip.modelData.flavour
                        color: chip.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    StateLayer {
                        radius: chip.radius
                        onClicked: root.picked(chip.modelData.flavour)
                    }
                }
            }
        }
    }
}
