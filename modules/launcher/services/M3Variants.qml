pragma Singleton

import ".."
import QtQuick
import Quickshell
import Vaxison.Config
import Vaxison.I18n
import qs.services
import qs.utils

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}variant `.length);
    }

    list: [
        Variant {
            variant: "vibrant"
            icon: "sentiment_very_dissatisfied"
            name: Tr.trCtx("Vibrant", "M3 scheme variant name")
            description: Tr.tr("A high chroma palette. The primary palette's chroma is at maximum.")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: Tr.trCtx("Tonal Spot", "M3 scheme variant name")
            description: Tr.tr("Default for Material theme colours. A pastel palette with a low chroma.")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: Tr.trCtx("Expressive", "M3 scheme variant name")
            description: Tr.tr("A medium chroma palette. The primary palette's hue is different from the seed colour, for variety.")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: Tr.trCtx("Fidelity", "M3 scheme variant name")
            description: Tr.tr("Matches the seed colour, even if the seed colour is very bright (high chroma).")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: Tr.trCtx("Neutral", "M3 scheme variant name")
            description: Tr.tr("Close to greyscale, a hint of chroma.")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: Tr.trCtx("Monochrome", "M3 scheme variant name")
            description: Tr.tr("All colours are greyscale, no chroma.")
        }
    ]
    useFuzzy: GlobalConfig.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Themes.setVariant(variant);
        }
    }
}
