pragma Singleton

import ".."
import QtQuick
import Quickshell
import Vaxison.Config
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentScheme: `${Colours.scheme} ${Colours.flavour}`
    readonly property string currentVariant: Colours.variant

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        model: Themes.flat.slice().sort((a, b) => String(a.name + a.flavour).localeCompare((b.name + b.flavour)))

        Scheme {}
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Themes.apply(name, flavour);
        }
    }
}
