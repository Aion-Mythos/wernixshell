<h1 align=center>WernixShell</h1>

<p align=center>The desktop shell of WernixOS: a bar, panels and settings for Hyprland, built with Quickshell.</p>

WernixShell is a hard fork of [caelestia-shell](https://github.com/caelestia-dots/shell). See [NOTICE](NOTICE)
for credits and [CHANGES.md](CHANGES.md) for everything changed since the fork.

## Features

- **Theme Center** (Settings): bundled light and dark themes, led by the `wernixos` theme, plus a dynamic theme
  taken from the wallpaper. No external CLI; the shell applies themes itself.
- **Wallpapers**: still and live (video) wallpapers with fill modes, an FPS cap, and pausing when covered, locked
  or on battery. Ships with the WernixOS wallpaper in both versions.
- **Liquid glass**: an optional compositor-wide glass effect behind every window, through the bundled
  [hyprglass](https://github.com/hyprnux/hyprglass) Hyprland plugin.
- **Volume boost**: raise output volume above 100%, up to a limit you set.
- Bar, launcher, dashboard, notifications, lock screen, OSD, sidebar and a Settings app, inherited from upstream.

## Installation

Dependencies:

- [`qt6-multimedia-ffmpeg`](https://archlinux.org/packages/extra/x86_64/qt6-multimedia-ffmpeg/) (decodes video wallpapers; the `qt6-multimedia` backend for ffmpeg)
- [`ffmpeg`](https://ffmpeg.org) (takes a still frame of a video wallpaper for the dynamic theme)
- [`hyprland`](https://hypr.land) headers, `make`, `wayland-scanner` (build the bundled [hyprglass](https://github.com/hyprnux/hyprglass) plugin for the Liquid glass setting; skip with `-DENABLE_GLASS=OFF`)
- [`matugen`](https://github.com/InioX/matugen) (generates the dynamic, wallpaper-based theme)
- [`quickshell-git`](https://git.outfoxxed.me/quickshell/quickshell) - this has to be the git version, not the latest tagged version
- `glibc`
- `gcc-libs`
- [`ddcutil`](https://github.com/rockowitz/ddcutil)
- [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
- [`libcava`](https://github.com/LukashonakV/cava)
- [`networkmanager`](https://gitlab.freedesktop.org/NetworkManager/NetworkManager)
- [`lm_sensors`](https://github.com/lm-sensors/lm-sensors)
- [`aubio`](https://github.com/aubio/aubio)
- [`libpipewire`](https://github.com/PipeWire/pipewire)
- [`libqalculate`](https://github.com/Qalculate/libqalculate)
- [`power-profiles-daemon`](https://gitlab.freedesktop.org/upower/power-profiles-daemon)
- [`ttf-material-symbols-variable`](https://github.com/google/material-design-icons)
- [`ttf-rubik-vf`](https://github.com/googlefonts/rubik)
- [`ttf-cascadia-code-nerd`](https://github.com/ryanoasis/nerd-fonts)
- `qt6-base`
- `qt6-declarative`
- `qt6-imageformats`
- `qt6-multimedia`
- [`qt6-m3shapes-git`](https://github.com/soramanew/m3shapes)
- [`swappy`](https://github.com/jtheoof/swappy)
- [`fish`](https://github.com/fish-shell/fish-shell)
- [`bash`](https://www.gnu.org/software/bash)

Build dependencies:

- [`cmake`](https://gitlab.kitware.com/cmake/cmake)
- [`ninja`](https://github.com/ninja-build/ninja)
- `qt6-shadertools`

Build dependencies:

- [`cmake`](https://gitlab.kitware.com/cmake/cmake)
- [`ninja`](https://github.com/ninja-build/ninja)
- `qt6-shadertools`

Clone with submodules (hyprglass is one), then build and install:

```sh
git clone --recurse-submodules https://github.com/Aion-Mythos/wernixshell.git ~/.config/quickshell/wernixshell
cd ~/.config/quickshell/wernixshell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

Build without Liquid glass with `-DENABLE_GLASS=OFF`. The install paths can be changed with `INSTALL_LIBDIR`,
`INSTALL_QMLDIR` and `INSTALL_QSCONFDIR`; if you change `INSTALL_LIBDIR`, set `WERNIXSHELL_LIB_DIR` to the same
directory in your environment.

To update, `git pull --recurse-submodules` in the checkout and build and install again.

## Usage

Start the shell with `qs -c wernixshell -n -d` (leave out `-d` to keep it attached to the terminal).

- **Keybinds**: the shell registers Hyprland [global shortcuts](https://wiki.hypr.land/Configuring/Basics/Binds/#dbus-global-shortcuts)
  under the `wernixshell` appid, e.g. `hl.dsp.global("wernixshell:launcher")`.
- **IPC**: `qs -c wernixshell ipc show` lists every command; call one with `qs -c wernixshell ipc call ...`.
- **Wallpapers** are read from `~/Pictures/Wallpapers` (`paths.wallpaperDir`). Set one in Settings, with
  `>wallpaper` in the launcher, or with `qs -c wernixshell ipc call wallpaper set <path>`.
- **Themes**: `qs -c wernixshell ipc call theme set <name> <flavour>`, `theme mode <dark|light>`, `theme list`.
  The dynamic theme needs `matugen`. An executable `~/.config/wernixshell/hooks/on-theme-change` runs after every
  theme change with the scheme name, flavour and mode as arguments.
- **Profile picture**: `~/.face`, or click it in the dashboard.

## Configuration

Most options are in Settings. All of them live in `~/.config/wernixshell/shell.json`, which only needs the
options you change. See [docs/config.md](docs/config.md) for per-monitor configs and the full list of options.

## Credits

- [caelestia-shell](https://github.com/caelestia-dots/shell) and its contributors, which this is a fork of
  (GPL-3.0).
- [Quickshell](https://quickshell.outfoxxed.me) by [@outfoxxed](https://github.com/outfoxxed).
- [hyprglass](https://github.com/hyprnux/hyprglass) by Jeremy Trufier (BSD-3-Clause), bundled for Liquid glass.
- Upstream also credits [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) and
  [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell) as inspiration.
- Theme palettes from their original projects, listed in [NOTICE](NOTICE) and [CHANGES.md](CHANGES.md).

## License

GPL-3.0, see [LICENSE](LICENSE).
