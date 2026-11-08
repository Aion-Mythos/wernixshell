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
- Added `scripts/vsm-shim`, a dev stand-in for `vsm` that forwards to another CLI and copies its state.
- Bar nexus popout now maps pages by explicit index (the new page shifts the others).
