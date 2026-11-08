import QtQuick
import QtQuick.Effects
import qs.components

// The vxs logo with a short blur and scale in
Item {
    id: root

    property bool skipIntroAnimation: false
    property real blurAmount: skipIntroAnimation ? 0 : 1

    signal animationCompleted

    implicitWidth: 128
    implicitHeight: 90.38

    Component.onCompleted: {
        if (!skipIntroAnimation)
            intro.start();
    }

    Logo {
        id: logo

        anchors.fill: parent
        scale: root.skipIntroAnimation ? 1 : 0
        opacity: root.skipIntroAnimation ? 1 : 0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }
    }

    ParallelAnimation {
        id: intro

        onFinished: root.animationCompleted()

        Anim {
            target: logo
            property: "scale"
            to: 1
            type: Anim.SlowSpatial
        }
        Anim {
            target: logo
            property: "opacity"
            to: 1
            type: Anim.SlowEffects
        }
        Anim {
            target: root
            property: "blurAmount"
            to: 0
            type: Anim.SlowEffects
        }
    }
}
