# Marble Blast Gold: Controller Roller

Marble Blast Gold with full controller support.

Controller Roller is an opinionated desktop Linux fork of [MBHaxe](https://github.com/RandomityGuy/MBHaxe), designed for playing Marble Blast Gold from a couch and TV, a handheld, or a controller-first desktop setup. Every menu and gameplay action is accessible without needing a keyboard or mouse.

![Main menu with controller cursor](docs/screenshots/main-menu.png)

## Features

- Full controller navigation across the menus, dialogs, level selector, options, gameplay, and high score screens
- Xbox-based button prompts that replace keyboard instructions when a controller is active
- A pointer-finger cursor designed to fit the original game's art style
- Fractional GUI scaling based on monitor resolution, affecting UI and HUD
- A redesigned controller-only options menu with camera sensitivity, Y-axis inversion, anti-aliasing, display, audio, field-of-view, and rewind controls
- Borderless fullscreen, windowed play, controller-adjustable sliders, and gamepad-friendly rewind controls
- Improved texture filtering that reduces distant level shimmer while retaining detail
- Sequential level play from the end-game screen without needing to return to the level select menu each time
- Continuous level browsing across Beginner, Intermediate, and Advanced categories, stopping only at the end of the game
- Level names moved below the preview image for improved readability

![Level selector](docs/screenshots/level-select.png)

The level selector can move continuously through every level in the game, instead of abruptly stopping at the end of a difficulty set. Completing a level also offers the next level directly, making a full playthrough feel like one uninterrupted sequence.

## Controller-first options

![Graphics options](docs/screenshots/graphics-options.png)

The options interface has been simplified around the settings relevant to controller play. All navigation paths are explicit, instead of relying on approximate spatial selection.

![Controller options](docs/screenshots/controller-options.png)

Camera sensitivity supports fine adjustment across a wide range, including very slow movement at the low end. Y-axis inversion is available directly beside it.

## In-game prompts

![Xbox controller prompt shown during gameplay](docs/screenshots/controller-prompts.png)

Help messages automatically use Xbox-style controller labels, such as A, B, X, Y, shoulder buttons, and triggers, instead of displaying keyboard bindings.
At some point down the line I may add controller type detection and PlayStation prompt support.

## Building on Linux

This fork targets desktop Linux with HashLink and SDL. It requires the MBHaxe Haxe, Heaps, HashLink, and native library toolchain.

The included script generates the C sources, links the native executable, and deploys a self-contained directory containing the executable, game data, HashLink plugins, and their non-system shared-library dependencies:

```bash
./compile-linux.sh
```

Run the packaged build with `run-mbg.sh`. Keep the extracted directory together; the launcher and executable load the bundled libraries relative to their own location. Linux's C ABI and the host graphics-driver libraries remain supplied by the operating system so GPU driver discovery continues to work.

Release builds also produce `MBG-Controller-Roller-x86_64.AppImage`, a single executable containing that entire portable directory. To create it locally, install `appimagetool` and run:

```bash
MBG_BUILD_APPIMAGE=1 ./compile-linux.sh
```

This one-command local route requires a baseline x86-64 build environment. Architecture-optimized distributions such as CachyOS should use the Steam Linux Runtime release environment/CI described below.

The AppImage keeps settings under `$XDG_CONFIG_HOME/controller-roller` (default: `~/.config/controller-roller`). On first launch, it extracts a versioned writable copy of the packaged game data and converted-resource cache under `$XDG_CACHE_HOME/controller-roller` (default: `~/.cache/controller-roller`); later launches reuse it.

To override the desktop account name used for local high scores, edit `settings.ini` in that settings directory and set `username=YourName`. This value takes priority over the saved JSON setting and the `USER`, `LOGNAME`, and `USERNAME` environment variables.

The packaging stages can also be run independently. `build-portable.sh` takes an already compiled executable and recursively collects its non-system ELF dependencies; `build-appimage.sh` turns that portable directory into a single AppImage:

```bash
MBG_BINARY=/path/to/marblegame \
MBG_LIBRARY_DIR=/path/to/hashlink/lib \
MBG_DIST_DIR="$PWD/dist/MBHaxe-Gold-Linux" \
./build-portable.sh

APPIMAGETOOL=/path/to/appimagetool \
MBG_PORTABLE_DIR="$PWD/dist/MBHaxe-Gold-Linux" \
MBG_APPIMAGE_OUTPUT="$PWD/dist/MBG-Controller-Roller-x86_64.AppImage" \
./build-appimage.sh
```

`build-portable.sh` rejects executables or libraries whose ELF metadata requires x86-64-v2, v3, or v4. This prevents a build made on an architecture-optimized distribution from crashing with `SIGILL` on an older computer. It also detects Steam Runtime's SDL2 compatibility layer and includes its dynamically loaded SDL3 dependency. The release build links the data-channel module's C++ runtime internally while leaving graphics-driver support libraries to the host, avoiding runtime mismatches with the target computer's GPU driver. Official release artifacts are built in the Steam Linux Runtime container used by CI; use that environment for broadly compatible releases. A local CachyOS build is suitable for testing on the build computer but may intentionally fail this portability check because its system startup objects require x86-64-v3.

By default, it expects the toolchain at `/home/cachy/mbhaxe-toolchain` and packages to `dist/MBHaxe-Gold-Linux`. Both locations can be overridden:

```bash
MBHAXE_TOOLCHAIN=/path/to/toolchain \
MBG_DEPLOY_DIR=/path/to/game \
./compile-linux.sh
```

The underlying dependencies are:

- Haxe 4.3 or newer
- [RandomityGuy's Heaps fork](https://github.com/RandomityGuy/heaps)
- [RandomityGuy's HashLink fork and SDL bindings](https://github.com/RandomityGuy/hashlink)
- [hxDatachannel](https://github.com/RandomityGuy/hxDatachannel)
- SDL2 and libuv development libraries

I have not tested Windows, Mac, Android, or WebGL building, but they should function?? ymmv

## Project background

Controller Roller is forked from MBHaxe and remains built on its Haxe port of Marble Blast Gold. MBHaxe incorporates marble physics work from [OpenMBU](https://github.com/MBU-Team/OpenMBU), along with game logic developed independently and adapted with permission from the [Marble Blast web port](https://github.com/Vanilagy/MarbleBlast).

This personal fork was developed with some AI assistance, but with extensive care and attention put towards QA. don't like, don't use!

## Reporting issues

If you find an issue that's specific to this fork (i.e. something related to controller support), please [open an issue](https://github.com/evanclue/mbg-controller-roller/issues) with a short description, reproduction steps, and a screenshot or log when useful.

Feel free to open a PR if you wanna contribute :3
