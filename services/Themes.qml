pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Vaxison.I18n
import Vaxison.Models
import qs.utils

// Bundled colour schemes (data/schemes/<name>/<flavour>.json) and the dynamic, wallpaper-derived scheme.
// Applying a scheme writes it to scheme.json, which Colours watches.
Singleton {
    id: root

    readonly property list<string> variants: ["tonalspot", "vibrant", "expressive", "neutral", "monochrome", "fidelity"]
    readonly property string statePath: `${Paths.state}/scheme.json`
    readonly property string hookPath: `${Paths.config}/hooks/on-theme-change`

    // Why the last action failed (e.g. matugen missing), shown by the Theme Center
    property string error

    // Every bundled scheme flavour: { name, flavour, mode, colours }
    readonly property var flat: files.instances.filter(f => f.data).map(f => f.data)
    // The same grouped by scheme: { name, flavours: [flat entries] }, "vexilion" first. A flavour that
    // has both a dark and a light version (e.g. gruvbox hard) appears once, as the one for the active mode.
    readonly property var themes: {
        const byName = {};
        for (const s of flat) {
            if (!byName[s.name])
                byName[s.name] = [];
            byName[s.name].push(s);
        }
        const pin = n => n === "vexilion" ? 0 : 1;
        const pick = (name, flavour) => {
            const matches = byName[name].filter(s => s.flavour === flavour);
            return matches.find(s => s.mode === activeMode) ?? matches[0];
        };
        return Object.entries(byName).map(([name, entries]) => ({
                    name,
                    flavours: [...new Set(entries.map(s => s.flavour))].sort().map(flavour => pick(name, flavour))
                })).sort((a, b) => pin(a.name) - pin(b.name) || a.name.localeCompare(b.name));
    }

    readonly property bool dynamicActive: Colours.scheme === "dynamic"
    readonly property string activeMode: Colours.currentLight ? "light" : "dark"

    function apply(name: string, flavour: string, variant = "", mode = ""): void {
        const matches = flat.filter(f => f.name === name && f.flavour === flavour);
        const s = matches.find(f => f.mode === (mode || activeMode)) ?? matches[0];
        if (!s) {
            error = Tr.tr("Unknown theme %1 %2").arg(name).arg(flavour);
            return;
        }
        error = "";
        write({
            name: s.name,
            flavour: s.flavour,
            mode: s.mode,
            variant: variant || Colours.variant,
            colours: s.colours
        });
    }

    // Generate the dynamic scheme from the current wallpaper
    function applyDynamic(variant = "", mode = ""): void {
        const image = Wallpapers.actualCurrent;
        if (!image) {
            error = Tr.tr("No wallpaper is set");
            return;
        }
        error = "";
        dynamicProc.run(image, variant || Colours.variant, mode || activeMode);
    }

    // Colours for the launcher and settings preview of an image, without applying them
    function preview(image: string): void {
        previewProc.run(image, Colours.variant, activeMode);
    }

    function setVariant(variant: string): void {
        if (dynamicActive)
            applyDynamic(variant, activeMode);
        else
            apply(Colours.scheme, Colours.flavour, variant);
    }

    function setMode(mode: string): void {
        if (dynamicActive) {
            applyDynamic(Colours.variant, mode);
            return;
        }
        // The same flavour in the other mode if there is one, else any flavour of the scheme in that mode
        const match = flat.find(f => f.name === Colours.scheme && f.flavour === Colours.flavour && f.mode === mode) ?? flat.find(f => f.name === Colours.scheme && f.mode === mode);
        if (match)
            apply(match.name, match.flavour, "", mode);
        else
            error = Tr.tr("%1 has no %2 flavour").arg(Colours.scheme).arg(mode);
    }

    function write(scheme: var): void {
        Paths.writeText(out, JSON.stringify(scheme));
        hookTest.scheme = scheme;
        hookTest.running = true;
    }

    // Maps matugen's JSON (snake_case Material roles) to the shell's token names
    function fromMatugen(text: string, mode: string): var {
        // matugen 4 nests each role by mode ({role: {dark: {color}, light: {color}}}), older versions are {mode: {role: hex}}
        const json = JSON.parse(text);
        const src = json.colors?.[mode] ?? json.colors ?? {};
        const colours = {};
        for (const [role, value] of Object.entries(src)) {
            const hex = typeof value === "string" ? value : (value?.[mode]?.color ?? value?.default?.color);
            if (hex)
                colours[role.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase())] = hex.replace("#", "").slice(0, 6);
        }
        if (!colours.primary)
            throw new Error(Tr.tr("matugen output has no colours"));

        // Roles matugen doesn't have (success, terminal colours) come from the default scheme
        const base = flat.find(f => f.name === "vexilion" && f.mode === mode)?.colours ?? {};
        for (const [token, value] of Object.entries(base))
            if (!(token in colours))
                colours[token] = value;
        return colours;
    }

    Variants {
        id: files

        model: schemeFiles.entries

        QtObject {
            id: file

            required property var modelData
            property var data

            readonly property FileView view: FileView {
                path: file.modelData.path
                onLoaded: file.data = JSON.parse(text())
            }
        }
    }

    FileSystemModel {
        id: schemeFiles

        path: Quickshell.shellPath("data/schemes")
        recursive: true
        nameFilters: ["*.json"]
    }

    FileView {
        id: out

        path: root.statePath
        atomicWrites: true
        printErrors: false
        onSaved: Colours.reloadScheme() // Colours can't watch a file that didn't exist yet
    }

    // Lets the user theme other things (terminal, GTK, ...) when the scheme changes
    Process {
        id: hookTest

        property var scheme

        command: ["test", "-x", root.hookPath]
        onExited: code => {
            if (code === 0)
                Quickshell.execDetached([root.hookPath, scheme.name, scheme.flavour, scheme.mode]);
        }
    }

    Connections {
        function onActualCurrentChanged(): void {
            if (root.dynamicActive)
                root.applyDynamic();
        }

        target: Wallpapers
    }

    Matugen {
        id: dynamicProc

        onColours: (colours, mode, variant) => root.write({
                name: "dynamic",
                flavour: "default",
                mode,
                variant,
                colours
            })
    }

    Matugen {
        id: previewProc

        onColours: (colours, mode) => {
            Colours.load(JSON.stringify({
                name: "dynamic",
                flavour: "default",
                mode,
                colours
            }), true);
            Colours.showPreview = true;
        }
    }

    IpcHandler {
        function set(name: string, flavour: string): void {
            if (name === "dynamic")
                root.applyDynamic();
            else
                root.apply(name, flavour);
        }

        function mode(mode: string): void {
            root.setMode(mode);
        }

        function variant(variant: string): void {
            root.setVariant(variant);
        }

        function get(): string {
            return `${Colours.scheme} ${Colours.flavour} ${root.activeMode} ${Colours.variant}`;
        }

        function list(): string {
            return root.flat.map(f => `${f.name} ${f.flavour}`).join("\n");
        }

        target: "theme"
    }

    // Runs matugen for an image and reports the mapped colours; failures set `error`
    component Matugen: Process {
        id: proc

        property string requestedMode
        property string requestedVariant
        property bool exited

        signal colours(colours: var, mode: string, variant: string)

        function run(image: string, variant: string, mode: string): void {
            requestedMode = mode;
            requestedVariant = variant;
            exited = false;
            command = ["matugen", "image", image, "--json", "hex", "--type", `scheme-${variant.replace("tonalspot", "tonal-spot")}`, "--mode", mode, "--prefer", "saturation", "--dry-run"];
            running = false;
            running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    proc.colours(root.fromMatugen(text, proc.requestedMode), proc.requestedMode, proc.requestedVariant);
                } catch (e) {
                    root.error = Tr.tr("Could not read matugen's output: %1").arg(e.message);
                }
            }
        }
        stderr: StdioCollector {
            id: errOut
        }
        onExited: code => {
            exited = true;
            if (code !== 0)
                root.error = errOut.text.replace(/\x1b\[[0-9;]*m/g, "").trim() || Tr.tr("matugen exited with code %1").arg(code);
        }
        // Stopping without ever exiting means the process could not be started
        onRunningChanged: {
            if (!running && !exited)
                root.error = Tr.tr("matugen is not installed, so the dynamic theme is unavailable");
        }
    }
}
