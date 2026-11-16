pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import WernixShell.Components
import WernixShell.Config
import WernixShell.I18n
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // There must be one for each value of the WallpaperFill enum
    readonly property list<MenuItem> fillItems: [
        MenuItem {
            text: Tr.tr("Fill (crop)")
            value: WallpaperFill.Fill
        },
        MenuItem {
            text: Tr.tr("Fit")
            value: WallpaperFill.Fit
        },
        MenuItem {
            text: Tr.tr("Stretch")
            value: WallpaperFill.Stretch
        }
    ]

    title: Tr.tr("Wallpaper & style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        ClipRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            WallpaperImpl {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: Tr.tr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }
        }

        ToggleRow {
            first: true
            text: Tr.tr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Transparency")
            // TRANSLATORS: %1/%2 = opacity values from 0 to 1 for the base surface and layered surfaces
            subtext: Tr.tr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            text: Tr.tr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        SelectRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing

            first: true
            last: true
            label: Tr.tr("Fill mode")
            subtext: Tr.tr("How images and videos fit the screen")
            menuItems: root.fillItems
            active: root.fillItems.find(i => i.value === GlobalConfig.background.wallpaperFill)
            onSelected: item => GlobalConfig.background.wallpaperFill = item.value
        }

        SectionHeader {
            text: Tr.tr("Video wallpapers")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Pause when covered")
            subtext: Tr.tr("A fullscreen window, or windows filling the screen")
            checked: Config.background.video.pauseWhenCovered
            onToggled: GlobalConfig.background.video.pauseWhenCovered = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Pause when locked or idle")
            subtext: Tr.tr("While the lock screen is shown or the screen is off")
            checked: Config.background.video.pauseWhenLocked
            onToggled: GlobalConfig.background.video.pauseWhenLocked = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Pause on battery")
            checked: Config.background.video.pauseOnBattery
            onToggled: GlobalConfig.background.video.pauseOnBattery = checked
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            label: Tr.tr("Frame rate limit")
            subtext: Tr.tr("Frames per second for video wallpapers")
            value: Config.background.video.fpsLimit
            from: 5
            to: 60
            stepSize: 5
            onMoved: v => GlobalConfig.background.video.fpsLimit = v
        }
    }
}
