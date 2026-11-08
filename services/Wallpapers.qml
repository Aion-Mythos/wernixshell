pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vaxison.Config
import Vaxison.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        const choices = list.filter(w => w.path !== actualCurrent);
        if (choices.length > 0)
            setWallpaper(choices[Math.floor(Math.random() * choices.length)].path);
    }

    function setWallpaper(path: string): void {
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
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Paths.writeText(pathFile, root.fallback);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images | FileSystemModel.Videos
    }
}
