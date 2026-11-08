pragma ComponentBehavior: Bound

import QtQuick
import Vaxison.Config
import qs.components
import qs.components.effects
import qs.services

// Horizontal counterpart of ActiveIndicator: the pill stretches towards the new workspace
StyledRect {
    id: root

    required property Item mask // The row of workspaces
    required property var starts // Target start of each workspace along the row
    required property var lengths // Target length of each workspace
    required property int activeIdx
    property alias contentColour: colouriser.colorizationColor

    property real start
    property real end

    function runAnim(): void {
        if (activeIdx < 0 || activeIdx >= starts.length)
            return;

        const newStart = starts[activeIdx];
        const goingLeft = newStart < start;
        const leadingDuration = Tokens.anim.durations.expressiveDefaultSpatial;
        const trailingDuration = leadingDuration * (Config.bar.workspaces.activeTrail ? 1.5 : 1);

        startAnim.stop();
        endAnim.stop();
        startAnim.to = newStart;
        endAnim.to = newStart + lengths[activeIdx];
        startAnim.duration = goingLeft ? leadingDuration : trailingDuration;
        endAnim.duration = goingLeft ? trailingDuration : leadingDuration;
        startAnim.start();
        endAnim.start();
    }

    onActiveIdxChanged: runAnim()
    onStartsChanged: runAnim()
    onLengthsChanged: runAnim()
    Component.onCompleted: runAnim()

    clip: true
    x: start + mask.x
    implicitWidth: end - start
    radius: Tokens.rounding.full
    color: Colours.palette.m3primary

    Anim on start {
        id: startAnim
    }

    Anim on end {
        id: endAnim
    }

    // Recolours the part of the workspaces under the pill
    Colouriser {
        id: colouriser

        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: -parent.start
        y: 0
        implicitWidth: root.mask.width
        implicitHeight: root.mask.height

        anchors.verticalCenter: parent.verticalCenter
    }
}
