pragma Singleton

import Quickshell

Singleton {
    // Animated wallpapers; gif is played as an animated image, the rest through Qt Multimedia
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv", "mov", "gif"]

    function isVideo(path: string): bool {
        const lower = String(path).toLowerCase();
        return validVideoExtensions.some(e => lower.endsWith(`.${e}`));
    }

    // Whether a wallpaper needs a still frame extracted for colour generation (gif already works as an image)
    function needsFrame(path: string): bool {
        return isVideo(path) && !String(path).toLowerCase().endsWith(".gif");
    }
}
