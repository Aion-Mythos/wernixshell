pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import WernixShell
import WernixShell.Config
import WernixShell.I18n
import WernixShell.Models
import WernixShell.State
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")
    readonly property string framesDir: `${Paths.cache}/wallpaper-frames`
    // Still frames extracted from video wallpapers (for colours), by video path
    property var readyFrames: ({})
    property int frameTick
    // The current wallpaper as an image: the wallpaper itself, or for a video its extracted frame ("" until ready)
    readonly property string currentStill: {
        frameTick;
        return stillOf(current);
    }

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear
    property var framePending: []

    signal frameReady(path: string)

    function frameName(path: string): string {
        let h = 0;
        for (let i = 0; i < path.length; i++)
            h = (h * 31 + path.charCodeAt(i)) | 0;
        return `${(h >>> 0).toString(16)}.jpg`;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(videoMode: var): void {
        const choices = list.filter(w => (videoMode === undefined || Videos.isVideo(w.path) === videoMode) && w.path !== actualCurrent);
        if (choices.length > 0)
            setWallpaper(choices[Math.floor(Math.random() * choices.length)].path);
    }

    function remove(path: string): void {
        if (!path.startsWith(`${Paths.wallsdir}/`) || path === fallback || removeProc.running)
            return;
        removeProc.path = path;
        removeProc.running = true;
    }

    // An image to take colours from: the path itself, or for a video its frame, or "" if it isn't extracted yet
    function stillOf(path: string): string {
        return Videos.needsFrame(path) ? (readyFrames[path] ?? "") : path;
    }

    function requestFrame(path: string): void {
        if (!Videos.needsFrame(path) || path in readyFrames || framePending.includes(path))
            return;
        framePending = [...framePending, path];
        nextFrame();
    }

    function nextFrame(): void {
        if (frameProc.running || framePending.length === 0)
            return;
        frameProc.path = framePending[0];
        frameProc.running = true;
    }

    // A video that can't be played or found is replaced by the bundled wallpaper
    function videoFailed(path: string, message: string): void {
        if (path !== actualCurrent || path === fallback)
            return;
        Toaster.toast(Tr.tr("Wallpaper unavailable"), message || Tr.tr("Could not play %1").arg(Paths.shortenHome(path)), "warning");
        setWallpaper(fallback);
    }

    function setWallpaper(path: string): void {
        if (Videos.isVideo(path))
            PersistentState.wallpaperPlaying = true; // Picking a live wallpaper plays it, even if the quick toggle paused it
        requestFrame(path);
        actualCurrent = path;
        Paths.writeText(pathFile, path); // The FileView below picks the change up, and the dynamic scheme follows
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            Themes.preview(path);
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        id: pathFile

        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onSaved: reload() // A file that didn't exist yet can't be watched
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Paths.writeText(pathFile, wall);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
            root.requestFrame(wall);
            if (wall !== root.fallback) {
                missingProc.path = wall;
                missingProc.running = true;
            }
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Paths.writeText(pathFile, root.fallback);
        }
    }

    Process {
        id: missingProc

        property string path

        command: ["test", "-e", path]
        onExited: code => {
            if (code !== 0)
                root.videoFailed(path, Tr.tr("%1 is missing").arg(Paths.shortenHome(path)));
        }
    }

    Process {
        id: removeProc

        property string path

        command: ["gio", "trash", path]
        onExited: code => {
            if (code === 0) {
                if (path === root.actualCurrent)
                    root.setWallpaper(root.fallback);
            } else {
                Toaster.toast(Tr.tr("Wallpaper"), Tr.tr("Could not remove %1").arg(Paths.shortenHome(path)), "warning");
            }
        }
    }

    Process {
        id: frameProc

        property string path
        readonly property string out: `${root.framesDir}/${root.frameName(path)}`

        // The frame at 1 s, or the first frame for clips that are shorter
        command: ["sh", "-c", 'mkdir -p "$3" && { [ -s "$2" ] || ffmpeg -y -loglevel error -ss 1 -i "$1" -frames:v 1 -q:v 2 "$2" || ffmpeg -y -loglevel error -i "$1" -frames:v 1 -q:v 2 "$2"; }', "sh", path, out, root.framesDir]
        onExited: code => {
            root.framePending = root.framePending.slice(1);
            if (code === 0) {
                root.readyFrames[path] = out;
                root.frameTick++;
                root.frameReady(path);
            } else {
                Toaster.toast(Tr.tr("Video wallpaper"), Tr.tr("ffmpeg is needed to take colours from a video"), "warning");
            }
            root.nextFrame();
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images | FileSystemModel.Videos
    }
}
