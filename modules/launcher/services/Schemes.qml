pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Vaxison.Config
import Vaxison.I18n
import qs.utils

Searcher {
    id: root

    property string currentScheme
    property string currentVariant
    property string error // Why the list is empty, for the Theme Center to show
    property bool listExited

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        getCurrent.running = true;
    }

    function reloadList(): void {
        error = "";
        listExited = false;
        getSchemes.running = true;
    }

    function parseList(text: string): void {
        let schemeData;
        try {
            schemeData = JSON.parse(text);
        } catch (e) {
            error = text.trim() ? Tr.tr("Invalid JSON from vsm: %1").arg(e.message) : Tr.tr("`vsm scheme list` printed nothing");
            return;
        }

        const list = Object.entries(schemeData).map(([name, f]) => Object.entries(f).map(([flavour, colours]) => ({
                        name,
                        flavour,
                        colours
                    })));

        const flat = [];
        for (const s of list)
            for (const f of s)
                flat.push(f);

        schemes.model = flat.sort((a, b) => String(a.name + a.flavour).localeCompare((b.name + b.flavour)));
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        Scheme {}
    }

    Process {
        id: getSchemes

        running: true
        command: ["vsm", "scheme", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
        stderr: StdioCollector {
            id: listErr
        }
        onExited: code => {
            root.listExited = true;
            if (code !== 0)
                root.error = listErr.text.trim() || Tr.tr("vsm exited with code %1").arg(code);
        }
        // Stopping without ever exiting means the process could not be started
        onRunningChanged: {
            if (!running && !root.listExited)
                root.error = Tr.tr("Could not run `vsm`; it is not on the PATH of this session");
        }
    }

    Process {
        id: getCurrent

        running: true
        command: ["vsm", "scheme", "get", "-nfv"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [name, flavour, variant] = text.trim().split("\n");
                root.currentScheme = `${name} ${flavour}`;
                root.currentVariant = variant;
            }
        }
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Quickshell.execDetached(["vsm", "scheme", "set", "-n", name, "-f", flavour]);
        }
    }
}
