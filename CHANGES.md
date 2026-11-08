# Changes from upstream

Vaxison is a hard fork of caelestia-shell (https://github.com/caelestia-dots/shell)
at commit f80a98079b19f91f7d8a24218d068e77acc00025. Changes are listed here as required
by GPL-3.0 section 5(a).

## Phase 1: rebrand

- Renamed every `caelestia` identifier to `vaxison` (QML modules `Vaxison.*`, CMake targets
  and `VAXISON_*` variables, XDG paths, layer namespaces) with `scripts/rebrand.sh`;
  `scripts/check-rebrand.sh` verifies nothing is left.
- All calls to the `caelestia` CLI were removed (see Phase 3 for the replacements).
- Replaced the logo with a placeholder (`components/Logo.qml`, `assets/logo.svg`).
- Removed `flake.nix`, `flake.lock` and `nix/` (Arch only).
- Removed upstream badges, donation/Discord links and install docs from the README.

## Phase 2: Settings cleanup

- Removed the "Updates" and "Plugins" placeholder pages from the settings registry,
  and the "Plugins" section from the About page.
- About page shows VexilionOS / Vaxison branding; the CLI version row was removed.
- Removed the colour picker (`ColourSelect.qml`) and its button from "Wallpaper & style".

## Phase 3: Theme Center

- New "Theme Center" settings page (Appearance): Dynamic card with variant picker, dark/light toggle, and a
  grid of theme cards with flavour chips ("vexilion" pinned first).
- New `services/Themes.qml`: scans the bundled schemes in `data/schemes/<name>/<flavour>.json`, applies one by
  writing `scheme.json`, generates the Dynamic scheme from the wallpaper with `matugen`, runs the optional
  `~/.config/vaxison/hooks/on-theme-change` hook, and has an IPC handler (`theme set|mode|variant|get|list`).
- `scripts/gen-scheme.py` builds the bundled schemes from the seeds in `data/seeds/`: vexilion (dark, light),
  catppuccin (mocha, latte) and tokyonight (night). vexilion is the default until a scheme is applied.
- Wallpapers (set, random, preview) no longer call an external CLI; the dynamic scheme follows wallpaper changes.
- Launcher actions "Random" and "Settings" are now internal commands (`randomWallpaper`, `openSettings`).
- Screen recording (`services/Recorder.qml`) used an external CLI that was removed; it is marked TODO and inactive.
- Bar nexus popout now maps pages by explicit index (the new page shifts the others).
- Added the "vexilion" scheme (`data/schemes/vexilion.json`, dark and light, from the VexilionOS
  palette) and made it the default until a scheme file exists.

## Bar position (reverted)

An experiment adding `bar.position` and horizontal bars was built and reverted; the bar stays on the left.

## Phase 1b: logo

- The logo is the official vxs logo (`assets/logo.svg`, drawn with theme colours by `components/Logo.qml`) in the bar, lock screen, dashboard and About page; the `general.logo` config value for the default logo is now `vexilion`.
- README: removed leftover links to upstream repositories.

- Removed the bundled upstream GIFs and picture (`kurukuru.gif`, `bongocat.gif`, `dino.png`); their config
  defaults (`paths.sessionGif`, `mediaGif`, `noNotifsPic`, `lockNoNotifsPic`) are now empty and the UI
  shows nothing there. Users can still point them at their own files.
- Replaced `assets/wallpaper.webp` with a generated VexilionOS-palette gradient.

- Restored the bundled `kurukuru.gif` (power menu) and `bongocat.gif` (dashboard media card) as the defaults of
  `paths.sessionGif` and `paths.mediaGif`.
