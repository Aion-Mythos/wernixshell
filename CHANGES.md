# Changes from upstream

WernixShell is a hard fork of caelestia-shell (https://github.com/caelestia-dots/shell)
at commit f80a98079b19f91f7d8a24218d068e77acc00025. Changes are listed here as required
by GPL-3.0 section 5(a).

## Phase 1: rebrand

- Renamed every `caelestia` identifier to `wernixshell` (QML modules `WernixShell.*`, CMake targets
  and `WERNIXSHELL_*` variables, XDG paths, layer namespaces) with `scripts/rebrand.sh`;
  `scripts/check-rebrand.sh` verifies nothing is left.
- All calls to the `caelestia` CLI were removed (see Phase 3 for the replacements).
- Replaced the logo with a placeholder (`components/Logo.qml`, `assets/logo.svg`).
- Removed `flake.nix`, `flake.lock` and `nix/` (Arch only).
- Removed upstream badges, donation/Discord links and install docs from the README.

## Phase 2: Settings cleanup

- Removed the "Updates" and "Plugins" placeholder pages from the settings registry,
  and the "Plugins" section from the About page.
- About page shows WernixOS / WernixShell branding; the CLI version row was removed.
- Removed the colour picker (`ColourSelect.qml`) and its button from "Wallpaper & style".

## Phase 3: Theme Center

- New "Theme Center" settings page (Appearance): Dynamic card with variant picker, dark/light toggle, and a
  grid of theme cards with flavour chips ("wernixos" pinned first).
- New `services/Themes.qml`: scans the bundled schemes in `data/schemes/<name>/<flavour>.json`, applies one by
  writing `scheme.json`, generates the Dynamic scheme from the wallpaper with `matugen`, runs the optional
  `~/.config/wernixshell/hooks/on-theme-change` hook, and has an IPC handler (`theme set|mode|variant|get|list`).
- `scripts/gen-scheme.py` builds the bundled schemes from the seeds in `data/seeds/`: wernixos (dark, light),
  catppuccin (mocha, latte) and tokyonight (night). wernixos is the default until a scheme is applied.
- Wallpapers (set, random, preview) no longer call an external CLI; the dynamic scheme follows wallpaper changes.
- Launcher actions "Random" and "Settings" are now internal commands (`randomWallpaper`, `openSettings`).
- Screen recording (`services/Recorder.qml`) used an external CLI that was removed; it is marked TODO and inactive.
- Bar nexus popout now maps pages by explicit index (the new page shifts the others).
- Added the "wernixos" scheme (`data/schemes/wernixos.json`, dark and light, from the WernixOS
  palette) and made it the default until a scheme file exists.

## Bar position (reverted)

An experiment adding `bar.position` and horizontal bars was built and reverted; the bar stays on the left.

## Phase 1b: logo

- The logo is the official logo (`assets/logo.svg`, drawn with theme colours by `components/Logo.qml`) in the bar, lock screen, dashboard and About page; the `general.logo` config value for the default logo is now `wernixos`.
- README: removed leftover links to upstream repositories.

- Removed the bundled upstream GIFs and picture (`kurukuru.gif`, `bongocat.gif`, `dino.png`); their config
  defaults (`paths.sessionGif`, `mediaGif`, `noNotifsPic`, `lockNoNotifsPic`) are now empty and the UI
  shows nothing there. Users can still point them at their own files.
- Replaced `assets/wallpaper.webp` with a generated WernixOS-palette gradient.

- Restored the bundled `kurukuru.gif` (power menu) and `bongocat.gif` (dashboard media card) as the defaults of
  `paths.sessionGif` and `paths.mediaGif`.

- The About page plays an animated GIF of the official logo (`assets/wernix-anim.gif`, `wernix-anim-light.gif` on
  light schemes), generated from `assets/logo.svg` by `scripts/make-logo-gif.py`, and no longer shows the
  "WernixShell" title; the other places keep the static logo.

## Bundled themes

- `data/schemes/` now holds 10 themes: `wernixos` (generated from `data/seeds/` by `scripts/gen-scheme.py`)
  and nine copied from caelestia-cli's data with all their variants: catppuccin (frappe, latte, macchiato,
  mocha), gruvbox (hard, medium, soft, each dark and light), rosepine (dawn, main, moon), everforest (hard,
  medium, soft; medium also light), tokyonight, nord, dracula, onedark and solarized. The mode toggle keeps the
  flavour when the scheme has the other mode (gruvbox hard dark <-> hard light), else switches to a flavour that has it.
- Removed my generated catppuccin and tokyonight seeds; darkgreen, shadotheme, oldworld, everblush and the
  upstream default scheme are not included.

## Calmer wernixos dark, more themes

- wernixos dark is now soft and low-contrast (violet-tinted neutrals, muted lavender primary, softened status
  colours); the light variant is unchanged. `gen-scheme.py --report` prints the contrast ratios.
- Added oxocarbon, kanagawa (wave, dragon, lotus), ayu (dark, mirage, light), github (dark, dimmed, light),
  monokai, nightfox (nightfox, carbonfox, dawnfox), flexoki and material-palenight, generated from their
  official palettes (see NOTICE) by `scripts/gen-scheme.py`; 18 themes in total are now bundled.

## Notification icons

- Notifications whose icon can't be found no longer show the magenta/black missing-image tile. Quickshell
  passes the `notify-send -i` name as the notification image, so images of the form `image://icon/<name>` are
  checked first (`Icons.resolveImage`); an unresolved one is dropped. The app icon is the icon name, absolute path
  or `file://` URL if it exists, else the icon of the app's desktop entry (`Icons.notifIcon`), else the Material
  icon. Only symbolic icons are tinted. Used by the popups, the sidebar and the lock screen; sidebar action
  buttons fall back to text when their icon doesn't exist.

## Phase 5: video wallpapers

- mp4, webm, mkv, mov and gif wallpapers (`utils/Videos.qml`); the wallpaper picker and file dialogs accept them.
  Videos play muted and looping through Qt Multimedia (the existing `VisualSource`); gifs play as animated images.
- New `background.wallpaperFill` (fill / fit / stretch) for images and videos, and `background.video` settings in
  Settings > Wallpaper & style: pause when covered (a fullscreen window or tiled windows filling the monitor), pause
  when locked or the screen is off, pause on battery, and a frame-rate limit (default 30 fps).
- Dynamic colours for a video use one frame extracted with ffmpeg (cached under `~/.cache/wernixshell/wallpaper-frames`).
- A missing or undecodable video falls back to the bundled wallpaper with a toast.

## Phase 6: volume boost

- "Max volume" moved from Settings > Services to Settings > Audio as "Volume boost": a toggle
  "Allow volume above 100%" (off by default, with a one-time warning) and a limit (105-200%, 150% when
  first enabled). `services.maxVolume` stays the only stored setting.
- The cap applies to the output, app volumes, the OSD, the bar popout and scroll; the microphone is capped
  at 100%. Volume raised above the cap from outside the shell, or left above it when the cap is lowered,
  is pulled back down.
- Sliders and labels show the part above 100% in the error colour.

## Renamed to WernixShell (for WernixOS)

- The fork was first named Vaxison (for VexilionOS). Every identifier is now `wernixshell` / `WernixShell.*` /
  `WERNIXSHELL_*`, and the XDG directories are `~/.config/wernixshell`, `~/.local/state/wernixshell` and
  `~/.cache/wernixshell`. `scripts/check-rebrand.sh` also fails on the former names.
- The default theme is `wernixos` (dark, light), built from the Wernix OS Colour System: Ebony and Bone
  neutrals with Verdigris as the one brand hue. It replaces the earlier default theme.
- The logo is the WernixOS hexagon logo (`assets/logo.svg`); `scripts/make-logo-gif.py` renders
  `assets/wernix-anim.gif` and `wernix-anim-light.gif` from it for the About page.
