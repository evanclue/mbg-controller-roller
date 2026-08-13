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

The included script generates the C sources, links the native executable, and deploys the finished build:

```bash
./compile-linux.sh
```

By default, it expects the toolchain at `/home/cachy/mbhaxe-toolchain` and deploys to `/home/cachy/Desktop/mrbl/gold`. Both locations can be overridden:

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
