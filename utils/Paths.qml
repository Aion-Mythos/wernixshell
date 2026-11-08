pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vaxison
import Vaxison.Config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || `${home}/Pictures`
    readonly property string videos: Quickshell.env("XDG_VIDEOS_DIR") || `${home}/Videos`

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/vaxison`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/vaxison`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/vaxison`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/vaxison`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: Quickshell.env("VAXISON_WALLPAPERS_DIR") || absolutePath(GlobalConfig.paths.wallpaperDir)
    readonly property string recsdir: Quickshell.env("VAXISON_RECORDINGS_DIR") || `${videos}/Recordings`
    readonly property string libdir: Quickshell.env("VAXISON_LIB_DIR") || "/usr/lib/vaxison"

    property var pendingWrites: []

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        return toLocalFile(path.replace(/~|(\$({?)HOME(}?))+/, home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }

    // Writes to a FileView in the state dir, creating the dir first (FileView doesn't)
    function writeText(view: FileView, text: string): void {
        pendingWrites.push([view, text]);
        mkdirState.running = true;
    }

    Process {
        id: mkdirState

        command: ["mkdir", "-p", `${root.state}/wallpaper`]
        onExited: {
            for (const [view, text] of root.pendingWrites)
                view.setText(text);
            root.pendingWrites = [];
        }
    }
}
