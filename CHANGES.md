# Changes from upstream

Vaxison is a hard fork of caelestia-shell (https://github.com/caelestia-dots/shell)
at commit f80a98079b19f91f7d8a24218d068e77acc00025. Changes are listed here as required
by GPL-3.0 section 5(a).

## Phase 1: rebrand

- Renamed every `caelestia` identifier to `vaxison` (QML modules `Vaxison.*`, CMake targets
  and `VAXISON_*` variables, XDG paths, layer namespaces) with `scripts/rebrand.sh`;
  `scripts/check-rebrand.sh` verifies nothing is left.
- All calls to the `caelestia` CLI now call `vsm`.
- Replaced the logo with a placeholder (`components/Logo.qml`, `assets/logo.svg`).
- Removed `flake.nix`, `flake.lock` and `nix/` (Arch only).
- Removed upstream badges, donation/Discord links and install docs from the README.

## Phase 2: Settings cleanup

- Removed the "Updates" and "Plugins" placeholder pages from the settings registry,
  and the "Plugins" section from the About page.
- About page shows VexilionOS / Vaxison branding; `vsm --version` is parsed more loosely.
- Removed the colour picker (`ColourSelect.qml`) and its button from "Wallpaper & style".

## Phase 3: Theme Center

- New "Theme Center" settings page (Appearance): Dynamic card with variant picker, dark/light
  toggle, and a grid of theme cards with flavour chips ("vexilion" pinned first when present).
  It drives `vsm scheme list|get|set`; no theming engine in the shell.
- Added `scripts/vsm-shim`, a dev stub faking `vsm scheme list|get|set`.
- Bar nexus popout now maps pages by explicit index (the new page shifts the others).
- Added the "vexilion" scheme (`data/schemes/vexilion.json`, dark and light, from the VexilionOS
  palette) and made it the default until a scheme file exists.

## Bar position (reverted)

An experiment adding `bar.position` and horizontal bars was built and reverted; the bar stays on the left.

## Phase 1b: logo

- The animated About-page logo (`AnimatedLogo.qml`) now animates the shared vxs logo instead of the
  original artwork; the `general.logo` config value for the default logo is now `vexilion`.
- README: removed leftover links to upstream repositories.

- Removed the bundled upstream GIFs and picture (`kurukuru.gif`, `bongocat.gif`, `dino.png`); their config
  defaults (`paths.sessionGif`, `mediaGif`, `noNotifsPic`, `lockNoNotifsPic`) are now empty and the UI
  shows nothing there. Users can still point them at their own files.
- Replaced `assets/wallpaper.webp` with a generated VexilionOS-palette gradient.

- Theme Center: the scheme list is reloaded each time the page opens, and when `vsm` is missing or fails
  the page shows "No themes found: is vsm installed?" with the error and a Retry button.
