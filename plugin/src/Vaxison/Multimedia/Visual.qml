pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Vaxison.Config
import Vaxison.Multimedia

Item {
    id: root

    property alias source: vis.source
    property alias fillMode: vis.fillMode
    property alias playing: vis.playing
    property alias fpsLimit: vis.fpsLimit
    readonly property alias type: vis.type
    readonly property bool isGif: String(source).toLowerCase().endsWith(".gif")
    property bool animate: true
    readonly property bool ready: vis.videoReady || imageLoader.item?.status === Image.Ready
    // Why the video couldn't be played, "" while it works
    property string error

    onSourceChanged: error = ""

    opacity: !animate || ready ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveDefaultEffects
            easing: Tokens.anim.expressiveDefaultEffects
        }
    }

    VisualSource {
        id: vis

        videoOutput: videoOut.item
        sizeSource: root

        onFailed: message => root.error = message
    }

    Loader {
        id: videoOut

        anchors.fill: parent
        active: vis.type === VisualSource.Live
        sourceComponent: VideoOutput {
            fillMode: vis.fillMode
            endOfStreamPolicy: VideoOutput.KeepLastFrame
        }
    }

    Loader {
        id: imageLoader

        anchors.fill: parent
        sourceComponent: root.isGif ? animatedComp : imageComp
    }

    Component {
        id: imageComp

        Image {
            source: vis.imagePath
            sourceSize: vis.sourceSize
            asynchronous: true
            fillMode: vis.fillMode
        }
    }

    // Animated gifs play as images (QMediaPlayer can't decode them)
    Component {
        id: animatedComp

        AnimatedImage {
            source: Qt.resolvedUrl(root.source)
            playing: root.playing
            asynchronous: true
            fillMode: vis.fillMode
        }
    }
}
