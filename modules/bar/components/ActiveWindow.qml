pragma ComponentBehavior: Bound

import QtQuick
import Vaxison.Config
import Vaxison.I18n
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property bool vertical
    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    // Space left for the title along the bar's axis
    readonly property int maxLength: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherLength = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimLength ?? (vertical ? curr.height : curr.width)), 0);
        // Length - 2 cause repeater counts as a child
        return (vertical ? bar.height : bar.width) - otherLength - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    // Vertical bars stack the icon over rotated text, horizontal ones put the text next to the icon
    implicitWidth: vertical ? Math.max(icon.implicitWidth, current.implicitHeight) : icon.implicitWidth + current.implicitWidth + Tokens.spacing.small
    implicitHeight: vertical ? icon.implicitHeight + current.implicitWidth + Tokens.spacing.small : Math.max(icon.implicitHeight, current.implicitHeight)

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.bar.centre(root);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        x: root.vertical ? (root.width - width) / 2 : 0
        y: root.vertical ? 0 : (root.height - height) / 2

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: root.maxLength - (root.vertical ? icon.height : icon.width)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        enabled: root.vertical

        Anim {}
    }

    Behavior on implicitWidth {
        enabled: !root.vertical

        Anim {}
    }

    component Title: StyledText {
        id: text

        x: root.vertical ? icon.x + (icon.width - width) / 2 : icon.x + icon.width + Tokens.spacing.small
        y: root.vertical ? icon.y + icon.height + Tokens.spacing.small : icon.y + (icon.height - height) / 2

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        // Text runs along the bar: rotated on vertical bars, as is on horizontal ones
        transform: [
            Translate {
                x: root.vertical && root.Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: !root.vertical ? 0 : root.Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: root.vertical ? implicitHeight : implicitWidth
        height: root.vertical ? implicitWidth : implicitHeight

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
