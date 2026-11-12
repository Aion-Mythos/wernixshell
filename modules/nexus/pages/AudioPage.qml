pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vaxison.Config
import Vaxison.I18n
import Vaxison.State
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // The cap itself (services.maxVolume) is the only stored setting: above 1 means boost is on
    readonly property bool boostOn: GlobalConfig.services.maxVolume > 1
    property bool confirmingBoost

    function enableBoost(): void {
        PersistentState.volumeBoostConfirmed = true;
        confirmingBoost = false;
        GlobalConfig.services.maxVolume = 1.5;
    }

    title: Tr.tr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
        SliderRow {
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: Tr.trCtx("Output", "audio output")
            valueLabel: Strings.percentOne(value)
            value: Audio.volume
            to: Audio.maxVolume
            warnAbove: 1
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio output muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks
            currentId: Audio.sink?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: Tr.trCtx("No output devices", "no audio outputs")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Volume boost
        SectionHeader {
            text: Tr.tr("Volume boost")
        }

        ToggleRow {
            id: boostToggle

            first: true
            last: !root.boostOn && !root.confirmingBoost
            text: Tr.tr("Allow volume above 100%")
            subtext: Tr.tr("Off limits the output and app volumes to 100%")
            checked: root.boostOn
            onToggled: {
                if (!checked)
                    GlobalConfig.services.maxVolume = 1; // Audio clamps anything louder back to 100%
                else if (PersistentState.volumeBoostConfirmed)
                    root.enableBoost();
                else
                    root.confirmingBoost = true;
            }
        }

        // Asked once, the first time boost is enabled
        ConnectedRect {
            Layout.fillWidth: true
            visible: root.confirmingBoost
            last: true
            implicitHeight: confirmLayout.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: confirmLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Above 100% the sound is digitally amplified and can distort or damage small speakers and hearing at high levels.")
                    color: Colours.palette.m3error
                    font: Tokens.font.body.small
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        icon: "volume_up"
                        text: Tr.tr("Enable")
                        onClicked: root.enableBoost()
                    }

                    IconTextButton {
                        icon: "close"
                        text: Tr.tr("Cancel")
                        type: IconTextButton.Tonal
                        onClicked: {
                            root.confirmingBoost = false;
                            boostToggle.checked = Qt.binding(() => root.boostOn); // Flip the switch back
                        }
                    }
                }
            }
        }

        StepperRow {
            visible: root.boostOn
            last: true
            label: Tr.tr("Limit")
            subtext: Tr.tr("Highest output volume (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 105 // 100 is the same as turning boost off
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        // Input
        SliderRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: Tr.trCtx("Input", "audio input")
            valueLabel: Strings.percentOne(value)
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            text: Tr.trCtx("Muted", "audio input muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            nodes: Audio.sources
            currentId: Audio.source?.id ?? -1
            iconName: "mic"
            placeholderIcon: "mic_off"
            placeholderText: Tr.trCtx("No input devices", "no audio inputs")
            onSelected: node => Audio.setAudioSource(node)
        }

        // Per-app volumes
        NavRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true

            icon: "tune"
            text: Tr.tr("App volumes")
            subtext: Audio.streams.length === 0 ? Tr.tr("No apps playing audio") : Tr.trN("%n app playing audio", "%n apps playing audio", Audio.streams.length)
            onClicked: root.nState.openSubPage(1)
        }
    }
}
