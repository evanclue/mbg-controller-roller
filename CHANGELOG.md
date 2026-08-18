# Controller Roller — 2026-08-18

Gold times, personal bests, and a rebuilt end-game screen.

Gameplay HUD:
- The level's gold time and your personal best are printed either side of the live timer, in the timer's own font with a black outline so they stay readable over any level. Both follow the UI scale and are repositioned on resize.
- Beating the level's gold time now bursts a gold badge out of the middle of the screen and plays a fanfare.
- The HUD is hidden while the end-game panel is up, since the panel prints the run's time itself, and it comes back on restart.
- The personal best beside the timer is refreshed when a level is restarted, so a run that just moved it shows the new time.

End-game screen:
- Rebuilt around the run's result: a status headline (failed to qualify, beat the gold time, qualified, or level complete), the level's gold and qualify times each carrying a check or cross for how the run did against it, a new personal best banner, and the personal best row.
- The final time is the headline, drawn with the gameplay timer's own digits. Levels that hand out bonus time show the working above it on three lines — elapsed time, minus bonus time, then the final time in the large digits — instead of leading with the elapsed time.
- All three times are derived from whole milliseconds, so the subtraction adds up exactly as printed.
- A single personal best replaces the three-name high score table. A run that beats the stored time is saved under the desktop user name rather than opening a text entry dialog, which a gamepad cannot type into.

Level select:
- The level panel prints Time To Qualify, Gold Time, and Personal Best in its bottom left corner, replacing the placeholder "Nardo Polo" best-times table and the invisible second text control that existed only to align its columns.
- Levels already taken gold show a gold badge over the corner of the preview image and a check beside their gold time, so a glance down the list shows what is left to do.

Audio:
- Replaced the "classic vibe" music track with a properly looping version.
- Added the goal fanfare that plays with the gold badge.

Fixes and internals:
- Centred and right-justified multi-line GUI text was offset twice, once by the text object's position and again by its alignment inside its own width. Only the alignment is applied now.
- The airborne-movement hint, which is worded for a keyboard inside the mission file and carries no bind token to expand, is rewritten for a controller.
- Stored scores are trimmed to three entries, since only the best one is shown.
- The AppImage's writable data copy is keyed on a hash of every file it ships, not on one manifest file, so a build with changed assets always unpacks a fresh copy instead of silently reusing an older one.
- README documents the new HUD, end-game, and level select behaviour, and the data cache location.

# 1.1.14
This update brings the following bugfixes:
- Fixed PowerUp names being incorrect.
- Fixed the absence of camera sensitivity on mobile versions.
- Fixed being able to change resolution on iOS.
- Fixed a crash when pressing the pause button on mobile devices.

# 1.1.13
This update brings feature and bugfix parity with the latest MBP version:
- Fixed a ton of bugs that were fixed in MBP since the last update.
- Updated the options menu to have more meaningful options and add more options for touch controls.
- Added Import and Export Progress to Options menu to transfer game progress between devices.
- Made the game files to be case insensitive to allow running the game on case sensitive filesystems without issues.
- Improved camera sensitivity on touch devices.
- Implemented camera centering for touch controls when free look is disabled.
- Various performance improvements and crash fixes.
- Implemented console cheat commands. DefaultMarble.attribute = value; to change marble attributes.
- Fixed a bug with the timer when playing a replay.
- Fixed gravity changes not rewinding properly.

# 1.1.12
This update fixes the following bugs:
- Fixed marble phasing through interiors when going too fast
- Fixed jittery interaction with marble and moving platforms

# 1.1.11
This update brings the following fixes:
- Minor UI changes.
- Optimized rewind to use memory better.
- Fixed a handful of memory leaks.
- Match with MBG Collision code.

# 1.1.10
This update brings the following fixes:
- Fixed marble finish animation not working.
- Fixed camera movement at varying FPS and sensitivities.
- Minor performance improvements.

# 1.1.9
This update fixes the following bugs:
- Fixed bugs caused by rewinding past the level start.
- Fixed crash caused by traplaunch.
- Removed the ability to rewind if you finished the level.
- Fixed a bug concerning moving platform collisions.
- Made moving platforms rewind correctly in case of traplaunches.

# 1.1.8
This is the first version to support android!
This update adds the following features and bugfixes:
- Adds Rewind feature. Open options to enable rewind and configure its settings!
- Improved traplaunches, they should now be more easily doable.
- Minor physics fixes.
- Fixed broken finish pads

# 1.1.7
This update brings the following changes:
- Added controller support.
- Added support to load and play custom levels. (Native only)
- Improved replay UX flow.
- Improved marble physics a bit.
- Fixed Tornado rendering.
- Fixed some collision bugs.

# 1.1.6
This release backports the fixes from MBP:
This is the first build of MBHaxe Gold that has Mac support.
Changelog:
- FOV is now based on horizontal FOV instead of vertical, matching with original MB.
- Fixed the marble getting stuck in the corners.
- Fixed broken resolution after pressing the back button in Retina display.
- Fixed wrong level order in Intermediate.

# 1.1.5
This release backports the fixes from MBP:
This is the first build of MBHaxe Gold that has Mac support.
Changelog:
- Reduced lag caused by end pad.
- Fixed inactive button hover sounds.
- Fixed OOB animation timings.
- Added HighDPI/Retina support.
- Fixed the color bugs regarding text input.
- Minor performance and physics improvements.
- Fixed tornado rendering.

# 1.1.4
This release backports the fixes from MBP:
- Fixed Pad animations not working
- Fixed bugs relating to powerup pickup on respawn.
- Fixed marble not using the hitbox of the rotated hitbox for item pickups.
- Marble finish animation now matches more closely with the original.
- Fixed camera keys not working.
- Added keyboard shortcuts to certain buttons on certain dialog boxes.
- Fixed lag caused by GJK/Startpad/Endpad.
- Fixed being able to press the end game buttons while typing the name. The input box will be focused.
- Fixed option sliders not updating values

# 1.1.3
This update brings the following changes:
- Updated Particle Rendering (improved performance)
- Fixed lot of marble physics bugs, they should now be smoother.
- Minor performance improvements

# 1.1.2
This update brings the following changes:
- Added basic state based replays.
- Support for asynchronous resource loading on Web target.

# 1.1.0
Touch Controls and Performance Improvements Update:
- Updated the engine to the latest version
- Added touch controls on the web version when it is loaded on mobile, along with its settings.
- Improved level loading speed on web version and reduced WebGL crashes
- Improved font rendering
- Fixed tornado rendering bug
- Minor performance and stability improvements overall

# 1.0.0
Initial release, windows version.