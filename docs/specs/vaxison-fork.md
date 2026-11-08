# Vaxison: hard fork of caelestia-shell

Vaxison is the Hyprland desktop shell of VexilionOS (Quickshell + Hyprland).
Hard fork of https://github.com/caelestia-dots/shell (GPLv3) at commit
`f80a98079b19f91f7d8a24218d068e77acc00025`. Upstream is not tracked after the fork.
All new files are GPLv3.

Work is split in 4 phases. Each phase ends with a STOP for manual testing.

## Baseline (measured on the fork commit)

- 543 tracked files; `caelestia` (any case) appears 1166 times in 435 files.
- Variants found: `caelestia` (499), `Caelestia.*` QML modules (Config, I18n, Components,
  Services, State, Multimedia, Models, Blobs, Settings, Images, Shaders),
  `caelestia-{core,util,config,pch,state,settings,shaders,components,blobs}` CMake targets,
  `CAELESTIA_{VERSION,LIB_DIR,XKB_RULES_PATH,WALLPAPERS_DIR,TEST_TRS}`, `caelestia-drawers`
  namespace, `caelestiaLogo` (7), notify-send app names `caelestia-cli` / `caelestia-shell`,
  `caelestia-dots` URLs (27), Nix leftovers (`programs.caelestia`, `systemd.user.services...`).
- The directory `plugin/src/Caelestia/` (and 100+ files under it) is itself named Caelestia.
- CLI calls: `modules/launcher/services/{Schemes,M3Variants}.qml`, `modules/nexus/pages/AboutPage.qml`
  (`caelestia --version`), others to be found by the rebrand check.
- Nexus pages: `modules/nexus/pages/` (WallpaperAndStyle.qml, wallandstyle/ColourSelect.qml,
  WallpaperSelect.qml, AboutPage.qml, panels/, ...). Registry: `modules/nexus/PageRegistry.qml`.
- Drawers: `modules/drawers/{Regions,Interactions,Exclusions,Panels,ContentWindow,Drawers}.qml`.
  Bar: `modules/bar/{Bar,BarWrapper}.qml`, `components/`, `popouts/`.

## Phase 1: Rename / rebrand

Mapping (applied most-specific first by `scripts/rebrand.sh`):

| From | To |
|---|---|
| `Caelestia.<Mod>` (QML import/URI) | `Vaxison.<Mod>` |
| dir `plugin/src/Caelestia` | `plugin/src/Vaxison` (`git mv`) |
| `caelestia-<x>` CMake targets | `vaxison-<x>` |
| `CAELESTIA_*` | `VAXISON_*` |
| `caelestia-drawers` etc. layer namespaces | `vaxison-*` |
| `["caelestia", ...]` / `caelestia ...` CLI calls | `vsm` |
| notify-send app `caelestia-cli` / `caelestia-shell` | `vsm` / `vaxison` |
| XDG `.../caelestia` (utils/Paths.qml) | `.../vaxison` |
| `caelestiaLogo`, `components/Logo.qml` | VexilionOS `vxs` logo, placeholder SVG |
| any remaining `caelestia`/`Caelestia`/`CAELESTIA` | `vaxison`/`Vaxison`/`VAXISON` |

Rules:
- Script is idempotent and re-runnable; also renames files/dirs containing the name.
- `scripts/check-rebrand.sh` fails if `caelestia` (case-insensitive) remains anywhere except
  `LICENSE`, `NOTICE`, `CHANGES.md` (the rebrand/check scripts themselves are exempt since
  they must contain the patterns).
- Keep `LICENSE` and upstream copyright notices. Add `NOTICE` and `CHANGES.md`.
- Delete `flake.nix`, `flake.lock`, `nix/`. Strip Ko-fi/Discord badges and upstream install docs from README.
- Done when: plugin CMake build succeeds and `qs -p .` launches with no QML import errors.

## Phase 2: Settings (nexus) cleanup

- Remove "Updates" and "Plugins" from `PageRegistry.qml` and every reference (e.g. page
  components registry, ListEditor/ServicesPage hits to be checked, not blindly removed).
- About page: VexilionOS / Vaxison branding, version from `vsm --version`.
- Wallpaper & style: keep wallpaper picker, remove the colour/scheme picker
  (`wallandstyle/ColourSelect.qml` deleted, its sub-page and button removed). Page description "Wallpaper, fonts, colours" updated.

## Phase 3: Theme Center

- New Appearance page. `vsm scheme list|get -nfv|set [-n -f -v -m --notify]`, same interface
  as the caelestia CLI; shell keeps watching the scheme file via `services/Colours.qml`.
- `scripts/vsm-shim`: sh script forwarding `vsm scheme ...` to the installed `caelestia`
  (until real `vsm` exists). Not installed by the shell; for dev use via PATH.
- UI: Dynamic card (variant picker + dark/light toggle) on top, then grid of theme cards
  (mini preview: background + primary/secondary/tertiary/accent strip, name, flavour chips),
  "vexilion" pinned first, active scheme highlighted from `scheme get`, click applies
  `scheme set -n -f`. Reuses nexus components and Anim/CAnim.
- Launcher `>scheme` / `>variant` keep working (they only change CLI name in phase 1).
- No theming engine in the shell.

## Phase 4: Bar position

- New config `bar.position` = left|right|top|bottom (default left), exposed in Settings > Panels > Taskbar.
- Horizontal layout for top/bottom; popouts, drawers border/frame (Regions, Interactions,
  Exclusions, Panels) and exclusive zones follow the edge; live change, no restart.
- Out of scope: floating bar, free placement, bar-only mode.

## Constraints

Upstream code style and animation components. Small focused commits per step.
Nothing outside the listed deletions is removed without asking.

## Open questions (need your answer before Phase 1)

1. **Where should the repo live?** I only have a throwaway scratch folder. Give me a path
   (e.g. `~/code/vaxison`) and I will clone there.
2. **History:** keep upstream git history (clone, drop `origin`, new initial branch) or squash
   to one initial commit? Recommended: keep history, so the NOTICE commit hash is verifiable.
3. **Repo URL** for Vaxison (README/links currently point to `caelestia-dots/*`). Placeholder
   `github.com/Aion-Mythos/-vexilion-vexison` until you tell me.
4. **`daemons/`, `extras/`, `assets/`** in upstream may contain caelestia-specific or
   non-Arch things. Rebrand them in place (default) unless you want something removed.
5. Notify app names: `vsm` for former `caelestia-cli`, `vaxison` for former `caelestia-shell`. OK?
