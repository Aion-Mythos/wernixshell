pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import WernixShell
import WernixShell.Config
import WernixShell.I18n
import qs.services
import qs.utils

// Liquid glass, compositor wide: loads the bundled hyprglass Hyprland plugin (third_party/hyprglass) and makes
// app windows translucent so the glass shows through them.
// shortcut: Lua Hyprland configs only (the toggle is hidden otherwise), add the hyprlang keywords if the legacy format must be supported
Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.appearance.glass.enabled && Hypr.usingLua // usingLua is only known a moment after startup
    readonly property real opacity: GlobalConfig.appearance.glass.opacity

    // Where hyprglass.so is: installed, else in a development checkout's build directory
    readonly property list<string> dirs: [Paths.libdir, `${Quickshell.shellDir}/build/lib`]

    function load(): void {
        plugProc.exec(["sh", "-c", 'hyprctl plugin list | grep -q hyprglass && exit 0; for d in "$1" "$2"; do [ -e "$d/hyprglass.so" ] && exec hyprctl plugin load "$d/hyprglass.so"; done; exit 3', "sh", ...dirs]);
    }

    function configure(): void {
        const hg = "eval hl.plugin.hyprglass";
        // Windows only: glass on the shell's own layer draws a grey bezel along the screen frame.
        // The rule and the plugin's settings last until Hyprland reloads its config, see onConfigReloaded
        Hypr.extras.batchMessage([`${hg}.config({ skip_opaque_windows = false, layers = { enabled = false } })`, `eval hl.window_rule({ match = { fullscreen = false }, opacity = "${opacity} override" })`]);
    }

    onEnabledChanged: {
        if (enabled)
            load();
        else
            plugProc.exec(["sh", "-c", 'for d in "$1" "$2"; do hyprctl plugin unload "$d/hyprglass.so"; done; hyprctl reload', "sh", ...root.dirs]); // The reload drops the opacity rule
    }
    onOpacityChanged: {
        if (enabled)
            Hypr.extras.message("reload");
    }
    Component.onCompleted: {
        if (enabled)
            load();
    }

    Process {
        id: plugProc

        onExited: code => {
            if (!root.enabled)
                return;
            if (code === 0)
                root.configure();
            else
                Toaster.toast(Tr.tr("Liquid glass unavailable"), code === 3 ? Tr.tr("hyprglass.so was not found") : Tr.tr("Hyprland could not load the plugin"), "blur_off");
        }
    }

    Connections {
        function onConfigReloaded(): void {
            if (root.enabled && !plugProc.running)
                root.configure();
        }

        target: Hypr
    }
}
