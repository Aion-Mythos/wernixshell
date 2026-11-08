import QtQuick
import Vaxison.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    // The wide vxs logo fills the bar's width; distro icons are square
    implicitWidth: SysInfo.isDefaultLogo ? Tokens.sizes.bar.innerWidth - Tokens.padding.small : Math.round(Tokens.font.body.large.pointSize * 1.2)
    implicitHeight: SysInfo.isDefaultLogo ? Math.round(implicitWidth * 52 / 160) : Math.round(Tokens.font.body.large.pointSize * 1.2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? vxsLogo : distroIcon
    }

    Component {
        id: vxsLogo

        Logo {
            implicitWidth: root.implicitWidth
            implicitHeight: root.implicitHeight
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source: SysInfo.osLogo
            implicitSize: Math.round(Tokens.font.body.large.pointSize * 1.2)
            colour: Colours.palette.m3tertiary
        }
    }
}
