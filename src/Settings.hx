package src;

import net.Uuid;
import h3d.Vector;
import haxe.ds.Option;
import gui.Canvas;
import src.AudioManager;
import hxd.Key;
import src.MarbleGame;
import hxd.Window;
import haxe.DynamicAccess;
#if hl
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
#end
import src.ResourceLoader;
import haxe.Json;
import src.Util;
import src.Console;

typedef Score = {
	var name:String;
	var time:Float;
}

typedef OptionsSettings = {
	var screenWidth:Int;
	var screenHeight:Int;
	var isFullScreen:Bool;
	var videoDriver:Int;
	var colorDepth:Int;
	var shadows:Bool;
	var musicVolume:Float;
	var soundVolume:Float;
	var vsync:Bool;
	var fpsLimit:Float;
	var fovX:Int;
	var frameRateVis:Bool;
	var oobInsults:Bool;
	var reflectiveMarble:Bool;
	var marbleIndex:Int;
	var marbleCategoryIndex:Int;
	var marbleSkin:String;
	var marbleModel:String;
	var marbleShader:String;
	var rewindEnabled:Bool;
	var rewindTimescale:Float;
	var antiAliasing:Bool;
}

typedef ControlsSettings = {
	var forward:Int;
	var backward:Int;
	var left:Int;
	var right:Int;
	var camForward:Int;
	var camBackward:Int;
	var camLeft:Int;
	var camRight:Int;
	var jump:Int;
	var powerup:Int;
	var freelook:Int;
	var alwaysFreeLook:Bool;
	var cameraSensitivity:Float;
	var invertYAxis:Bool;
	var respawn:Int;
	var blast:Int;
	var rewind:Int;
}

typedef TouchSettings = {
	var joystickPos:Array<Float>;
	var joystickSize:Float;
	var jumpButtonPos:Array<Float>;
	var jumpButtonSize:Float;
	var powerupButtonPos:Array<Float>;
	var powerupButtonSize:Float;
	var blastButtonPos:Array<Float>;
	var blastButtonSize:Float;
	var rewindButtonPos:Array<Float>;
	var rewindButtonSize:Float;
	var buttonJoystickMultiplier:Float;
	var hideControls:Bool;
	var cameraSwipeExtent:Float;
	var dynamicJoystick:Bool;
}

typedef GamepadSettings = {
	var moveXAxis:String;
	var moveYAxis:String;
	var cameraXAxis:String;
	var cameraYAxis:String;
	var jump:Array<String>;
	var powerup:Array<String>;
	var cameraSensitivity:Float;
	var invertXAxis:Bool;
	var invertYAxis:Bool;
	var axisDeadzone:Float;
	var respawn:Array<String>;
	var blast:Array<String>;
	var rewind:Array<String>;
}

typedef ServerSettings = {
	var name:String;
	var description:String;
	var maxPlayers:Int;
	var password:String;
	var forceSpectators:Bool;
	var quickRespawn:Bool;
	var competitiveMode:Bool;
	var oldSpawns:Bool;
}

typedef PlayStatistics = {
	var oobs:Int;
	var respawns:Int;
	var totalTime:Float;
}

class Settings {
	public static var highScores:Map<String, Array<Score>> = [];

	public static var easterEggs:Map<String, Float> = [];

	public static var optionsSettings:OptionsSettings = {
		screenWidth: 1280,
		screenHeight: 720,
		isFullScreen: false,
		videoDriver: 0,
		colorDepth: 1,
		shadows: false,
		musicVolume: 1,
		soundVolume: 0.7,
		fovX: 90,
		frameRateVis: true,
		oobInsults: true,
		reflectiveMarble: false,
		marbleIndex: 0,
		marbleCategoryIndex: 0,
		marbleSkin: "base",
		marbleModel: "data/shapes/balls/ball-superball.dts",
		marbleShader: "Default",
		rewindEnabled: false,
		rewindTimescale: 1,
		antiAliasing: false,
		fpsLimit: -1,
		vsync: #if js true #end
		#if hl
		false
		#end
	};

	public static var controlsSettings:ControlsSettings = {
		forward: Key.W,
		backward: Key.S,
		left: Key.A,
		right: Key.D,
		camForward: Key.UP,
		camBackward: Key.DOWN,
		camLeft: Key.LEFT,
		camRight: Key.RIGHT,
		jump: Key.SPACE,
		powerup: Key.MOUSE_LEFT,
		freelook: Key.MOUSE_RIGHT,
		alwaysFreeLook: true,
		cameraSensitivity: 0.6,
		invertYAxis: false,
		respawn: Key.BACKSPACE,
		blast: Key.E,
		rewind: Key.R,
	};

	public static var touchSettings:TouchSettings = {
		joystickPos: [100, 40],
		joystickSize: 50,
		jumpButtonPos: [440, 320],
		jumpButtonSize: 60,
		powerupButtonPos: [440, 180],
		powerupButtonSize: 60,
		blastButtonPos: [300, 240],
		blastButtonSize: 60,
		rewindButtonPos: [300, 100],
		rewindButtonSize: 60,
		buttonJoystickMultiplier: 2.5,
		hideControls: false,
		cameraSwipeExtent: 10.0,
		dynamicJoystick: false
	}

	public static var gamepadSettings:GamepadSettings = {
		moveXAxis: "analogX",
		moveYAxis: "analogY",
		cameraXAxis: "ranalogX",
		cameraYAxis: "ranalogY",
		jump: ["A", "LT"],
		powerup: ["B", "RT"],
		cameraSensitivity: 0.6,
		invertXAxis: false,
		invertYAxis: false,
		axisDeadzone: 0.15,
		respawn: ["back"],
		blast: ["X", "LB", "RB"],
		rewind: ["Y"],
	}

	public static var playStatistics:PlayStatistics = {
		oobs: 0,
		respawns: 0,
		totalTime: 0,
	}

	public static var serverSettings:ServerSettings = {
		name: "Multiplayer Server",
		password: "",
		maxPlayers: 8,
		description: "My cool server",
		forceSpectators: false,
		quickRespawn: true,
		competitiveMode: false,
		oldSpawns: false
	}

	public static var levelStatistics:Map<String, PlayStatistics> = [];

	public static var progression = [24, 24, 52];
	public static var highscoreName = "";
	public static var userId = "";

	public static var uiScale = 1.0;

	public static var zoomRatio = 1.0;

	public static var isTouch:Option<Bool> = Option.None;

	#if hl
	#if MACOS_BUNDLE
	public static var settingsDir = Path.join([Sys.getEnv("HOME"), "Library", "Application Support", "MBHaxe-MBG"]);
	#elseif linux
	public static var settingsDir = getLinuxSettingsDir();

	static function getLinuxSettingsDir():String {
		var configHome = Sys.getEnv("XDG_CONFIG_HOME");
		if (configHome == null || configHome == "") {
			var home = Sys.getEnv("HOME");
			configHome = home == null || home == "" ? "." : Path.join([home, ".config"]);
		}
		return Path.join([configHome, "controller-roller"]);
	}
	#else
	public static var settingsDir = ".";
	#end
	#end
	public static function applySettings() {
		#if hl
		var wnd = Window.getInstance();
		if (optionsSettings.isFullScreen) {
			// Borderless takes the whole screen at its native resolution, so no resize
			wnd.displayMode = Borderless;
		} else {
			// A stored size at or above the current screen is left over from a fullscreen
			// session, so fall back to something that is visibly a window
			if (optionsSettings.screenWidth >= wnd.width || optionsSettings.screenHeight >= wnd.height) {
				optionsSettings.screenWidth = 1280;
				optionsSettings.screenHeight = 720;
			}
			wnd.displayMode = Windowed;
			wnd.resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		}

		wnd.vsync = optionsSettings.vsync;
		#end
		AudioManager.updateVolumes();

		MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		save();
	}

	public static function saveScore(mapPath:String, score:Score) {
		if (highScores.exists(mapPath)) {
			var scoreList = highScores.get(mapPath);
			scoreList.push(score);
			scoreList.sort((a, b) -> a.time == b.time ? 0 : (a.time > b.time ? 1 : -1));
			// Only the best time is shown now, so there is no reason to keep a growing tail
			if (scoreList.length > 3)
				scoreList.splice(3, scoreList.length - 3);
		} else {
			highScores.set(mapPath, [score]);
		}
		save();
	}

	public static function getScores(mapPath:String) {
		if (highScores.exists(mapPath)) {
			return highScores.get(mapPath).copy();
		} else {
			return [];
		}
	}

	public static function save() {
		var outputData:Dynamic = {
			options: optionsSettings,
			controls: controlsSettings,
			touch: touchSettings,
			gamepad: gamepadSettings,
			progression: progression,
			stats: playStatistics,
			server: serverSettings,
			highscoreName: highscoreName,
			userId: userId,
			marbleIndex: optionsSettings.marbleIndex,
			marbleSkin: optionsSettings.marbleSkin,
			marbleModel: optionsSettings.marbleModel,
			marbleCategoryIndex: optionsSettings.marbleCategoryIndex,
			marbleShader: optionsSettings.marbleShader,
		};
		var scoreCount = 0;
		var eggCount = 0;
		var statCount = 0;
		for (key => value in highScores) {
			scoreCount++;
		}
		for (key => value in easterEggs) {
			eggCount++;
		}
		for (key => value in levelStatistics) {
			statCount++;
		}
		#if hl
		if (scoreCount != 0)
			outputData.highScores = highScores;
		else
			outputData.highScores = {};
		if (eggCount != 0) {
			outputData.easterEggs = easterEggs;
		} else {
			outputData.easterEggs = {};
		}
		if (statCount != 0) {
			outputData.levelStatistics = levelStatistics;
		} else {
			outputData.levelStatistics = {};
		}
		#end
		#if js
		var kvps:Array<Dynamic> = [];
		for (key => value in highScores)
			kvps.push([key, value]);
		var jobj = js.lib.Object.fromEntries(kvps);
		outputData.highScores = jobj;
		kvps = [];
		for (key => value in easterEggs)
			kvps.push([key, value]);
		jobj = js.lib.Object.fromEntries(kvps);
		outputData.easterEggs = jobj;
		kvps = [];
		for (key => value in levelStatistics)
			kvps.push([key, value]);
		jobj = js.lib.Object.fromEntries(kvps);
		outputData.levelStatistics = jobj;
		#end
		var json = Json.stringify(outputData);
		#if (hl && !android)
		if (!FileSystem.exists(settingsDir)) {
			FileSystem.createDirectory(settingsDir);
		}
		File.saveContent(Path.join([settingsDir, "settings.json"]), json);
		Console.log("Saved settings to " + Path.join([settingsDir, "settings.json"]));
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			localStorage.setItem("MBHaxeSettings", json);
		}
		#end
	}

	public static function load() {
		Console.log("Loading settings");
		var settingsExists = false;
		#if hl
		settingsExists = FileSystem.exists(Path.join([settingsDir, "settings.json"]));
		#end
		#if js
		var localStorage = js.Browser.getLocalStorage();
		if (localStorage != null) {
			settingsExists = localStorage.getItem("MBHaxeSettings") != null;
		}
		#end

		if (settingsExists) {
			#if hl
			var json = Json.parse(File.getContent(Path.join([settingsDir, "settings.json"])));
			#end
			#if js
			var json = Json.parse(localStorage.getItem("MBHaxeSettings"));
			#end
			var highScoreData:DynamicAccess<Array<Score>> = json.highScores;
			for (key => value in highScoreData) {
				highScores.set(key, value);
			}
			var easterEggData:DynamicAccess<Float> = json.easterEggs;
			if (easterEggData != null) {
				for (key => value in easterEggData) {
					easterEggs.set(key, value);
				}
			}
			optionsSettings = json.options;
			if (optionsSettings.fovX == 0 #if js || optionsSettings.fovX == null #end)
				optionsSettings.fovX = 90;
			if (optionsSettings.rewindEnabled == false #if js || optionsSettings.rewindEnabled == null #end)
				optionsSettings.rewindEnabled = false;
			if (optionsSettings.rewindTimescale == 0 #if js || optionsSettings.rewindTimescale == null #end)
				optionsSettings.rewindTimescale = 1;
			if (optionsSettings.fpsLimit == 0 #if js || optionsSettings.fpsLimit == null #end)
				optionsSettings.fpsLimit = -1;
			if (optionsSettings.reflectiveMarble == false #if js || optionsSettings.reflectiveMarble == null #end)
				optionsSettings.reflectiveMarble = false;
			controlsSettings = json.controls;
			if (json.touch != null) {
				touchSettings = json.touch;
			}
			if (controlsSettings.rewind == 0) {
				controlsSettings.rewind = Key.R;
			}
			if (controlsSettings.blast == 0) {
				controlsSettings.blast = Key.E;
			}
			if (controlsSettings.respawn == 0) {
				controlsSettings.respawn = Key.BACKSPACE;
			}
			if (touchSettings.blastButtonPos == null) {
				touchSettings.blastButtonPos = [300, 240];
				touchSettings.blastButtonSize = 60;
			}
			if (touchSettings.rewindButtonPos == null) {
				touchSettings.rewindButtonPos = [300, 100];
				touchSettings.rewindButtonSize = 60;
			}
			#if js
			if (touchSettings.hideControls == null) {
				touchSettings.hideControls = false;
			}
			if (touchSettings.cameraSwipeExtent == null) {
				touchSettings.cameraSwipeExtent = 10.0;
			}
			if (touchSettings.dynamicJoystick == null) {
				touchSettings.dynamicJoystick = false;
			}
			#end
			if (touchSettings.cameraSwipeExtent == 0) {
				touchSettings.cameraSwipeExtent = 10.0;
			}
			if (json.gamepad != null) {
				gamepadSettings = json.gamepad;
			}
			if (gamepadSettings.rewind == null) {
				gamepadSettings.rewind = ["Y"];
			}
			if (gamepadSettings.blast == null) {
				gamepadSettings.blast = ["X", "LB", "RB"];
			}
			if (gamepadSettings.respawn == null) {
				gamepadSettings.respawn = ["back"];
			}
			if (json.stats != null) {
				playStatistics = json.stats;
			}
			if (json.levelStatistics != null) {
				var levelStatData:DynamicAccess<PlayStatistics> = json.levelStatistics;
				for (key => value in levelStatData) {
					levelStatistics.set(key, value);
				}
			}
			if (json.server != null) {
				serverSettings = json.server;
			}
			#if js
			if (serverSettings.oldSpawns == null) {
				serverSettings.oldSpawns = false;
			}
			if (optionsSettings.marbleIndex == null) {
				optionsSettings.marbleIndex = 0;
				optionsSettings.marbleSkin = "base";
				optionsSettings.marbleModel = "data/shapes/balls/ball-superball.dts";
			}
			if (optionsSettings.marbleCategoryIndex == null) {
				optionsSettings.marbleCategoryIndex = 0;
			}
			if (optionsSettings.marbleShader == null) {
				optionsSettings.marbleShader = "Default";
			}
			if (controlsSettings.blast == null) {
				controlsSettings.blast = Key.E;
			}
			if (controlsSettings.rewind == null) {
				controlsSettings.rewind = Key.R;
			}
			if (optionsSettings.rewindEnabled == null) {
				optionsSettings.rewindEnabled = false;
			}
			if (optionsSettings.rewindTimescale == null) {
				optionsSettings.rewindTimescale = 1;
			}
			if (optionsSettings.antiAliasing == null) {
				optionsSettings.antiAliasing = false;
			}
			#end
			progression = json.progression;
			highscoreName = json.highscoreName;
			if (highscoreName == null || highscoreName == "") {
				highscoreName = defaultPlayerName();
			}
			userId = json.userId;
			if (userId == null || userId == "") {
				userId = Uuid.v4();
			}
		} else {
			Console.warn("Settings file does not exist");
			save();
		}
		#if hl
		Window.getInstance().vsync = optionsSettings.vsync;
		#end
	}

	/**
		Resolution at which the menu and HUD draw at 1x. Half of 1080p, so a 1080p screen
		gets a 2x ui and everything above scales up proportionally from there.
	**/
	public static inline var UI_REFERENCE_WIDTH = 960.0;

	public static inline var UI_REFERENCE_HEIGHT = 540.0;

	/**
		The multiplier every gui position, extent, image and font size is built against
		(see `gui.GuiControl.getRenderRectangle`). It combines the display's backing scale
		with a fractional factor derived from the window resolution, so the ui keeps the
		same apparent size at 1440p, 4K and beyond instead of staying pinned to 1x pixels.
	**/
	/**
		Name used for high score entries. This build targets gamepad play, where there is no
		practical way to type, so it comes from the desktop user account instead of asking.
	**/
	public static function defaultPlayerName():String {
		#if hl
		for (key in ["USER", "LOGNAME", "USERNAME"]) {
			var value = Sys.getEnv(key);
			if (value != null && StringTools.trim(value) != "")
				return StringTools.trim(value);
		}
		#end
		return "Player";
	}

	/**
		Optional desktop-only player name override. This is deliberately separate from
		settings.json so a player can set it by hand without the normal settings save
		rewriting their choice. Section headers are accepted but optional.
	**/
	static function loadPlayerNameOverride():String {
		#if (hl && !android)
		var iniPath = Path.join([settingsDir, "settings.ini"]);
		if (!FileSystem.exists(settingsDir))
			FileSystem.createDirectory(settingsDir);
		if (!FileSystem.exists(iniPath)) {
			File.saveContent(iniPath, "# Player name shown on local high scores.\nusername=\n");
			return null;
		}
		try {
			for (line in File.getContent(iniPath).split("\n")) {
				var trimmed = StringTools.trim(line);
				if (trimmed == "" || StringTools.startsWith(trimmed, "#") || StringTools.startsWith(trimmed, ";")
					|| StringTools.startsWith(trimmed, "["))
					continue;
				var equals = trimmed.indexOf("=");
				if (equals == -1)
					continue;
				var key = StringTools.trim(trimmed.substr(0, equals)).toLowerCase();
				if (key != "username")
					continue;
				var value = StringTools.trim(trimmed.substr(equals + 1));
				if (value != "")
					return value;
			}
		} catch (e:Dynamic) {
			Console.warn('Could not read $iniPath: $e');
		}
		#end
		return null;
	}

	public static function computeUiScale():Float {
		var wnd = Window.getInstance();
		#if hl
		// windowToPixelRatio is window/pixel, so its inverse is the display backing scale
		var backingScale = 1 / wnd.windowToPixelRatio;
		#else
		var backingScale = 1.0;
		#end
		// Take the smaller axis so the 4:3 authored layout never overflows a short window
		var resolutionScale = Math.min(wnd.width / UI_REFERENCE_WIDTH, wnd.height / UI_REFERENCE_HEIGHT);
		// The assets have no sub-1x source, and shrinking them would break small windows
		if (resolutionScale < 1)
			resolutionScale = 1;
		return backingScale * resolutionScale;
	}

	public static function init() {
		load();
		var playerNameOverride = loadPlayerNameOverride();
		if (playerNameOverride != null)
			highscoreName = playerNameOverride;
		// Covers a missing settings file, where load() never reaches the name
		else if (highscoreName == null || highscoreName == "")
			highscoreName = defaultPlayerName();
		#if hl
		if (optionsSettings.isFullScreen) {
			Window.getInstance().displayMode = Borderless;
		} else {
			Window.getInstance().displayMode = Windowed;
			Window.getInstance().resize(optionsSettings.screenWidth, optionsSettings.screenHeight);
		}
		uiScale = computeUiScale();
		#end
		#if js
		Window.getInstance().propagateKeyEvents = true;
		#end

		// @:privateAccess Window.getInstance().window.center();
		Window.getInstance().addResizeEvent(() -> {
			var wnd = Window.getInstance();
			var zoomRatio = Window.getInstance().windowToPixelRatio;
			#if js
			var zoomRatio = (Util.isTouchDevice() && !Util.isTablet()) ? js.Browser.window.screen.height * js.Browser.window.devicePixelRatio / 768 : js.Browser.window.devicePixelRatio; // 768 / js.Browser.window.innerHeight; // js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio / 768;
			if (Util.isIPhone())
				zoomRatio = 2;
			if (Util.isIPhone() && js.Browser.window.devicePixelRatio == 2)
				zoomRatio = 1.0;
			Settings.zoomRatio = zoomRatio;
			#end
			#if android
			var zoomRatio = Window.getInstance().height / 600;
			Settings.zoomRatio = zoomRatio;
			#end
			#if hl
			// Only record a genuine windowed size. Storing the fullscreen dimensions here
			// meant leaving fullscreen resized the window to fill the screen, which looked
			// like the toggle had done nothing.
			if (!Settings.optionsSettings.isFullScreen) {
				Settings.optionsSettings.screenWidth = cast wnd.width;
				Settings.optionsSettings.screenHeight = cast wnd.height;
			}
			var newUiScale = computeUiScale();
			if (newUiScale != uiScale) {
				uiScale = newUiScale;
				// Positions, extents and images pick this up on the render below, but font
				// sizes are baked when a screen is constructed, so the screen has to be
				// rebuilt. Defer it - we may be inside a gui handler that resized us.
				MarbleGame.uiScaleDirty = true;
			}
			#end
			#if js
			Settings.optionsSettings.screenWidth = cast Math.max(js.Browser.window.screen.width,
				js.Browser.window.screen.height); // 1024; // cast(js.Browser.window.innerWidth / js.Browser.window.innerHeight) * 768; // cast js.Browser.window.innerWidth * js.Browser.window.devicePixelRatio * 0.5;
			Settings.optionsSettings.screenHeight = cast Math.min(js.Browser.window.screen.width,
				js.Browser.window.screen.height); // 768; // cast js.Browser.window.innerHeight * js.Browser.window.devicePixelRatio * 0.5;

			var canvasElement = js.Browser.document.getElementById("webgl");
			canvasElement.style.width = "100%";
			canvasElement.style.height = "100%";
			#end

			Console.log("Window resized to " + Settings.optionsSettings.screenWidth + "x" + Settings.optionsSettings.screenHeight + " (Zoom " + zoomRatio +
				")");

			MarbleGame.canvas.scene2d.scaleMode = Zoom(zoomRatio);

			if (MarbleGame.instance.world != null) {
				MarbleGame.instance.world.scene.camera.setFovX(Settings.optionsSettings.fovX,
					Settings.optionsSettings.screenWidth / Settings.optionsSettings.screenHeight);
			}

			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		});
	}
}
