package gui;

import hxd.res.Image;
import hxd.Window;
import h3d.shader.AlphaMult;
import h3d.shader.ColorKey;
import hxd.snd.WavData;
import gui.GuiControl.HorizSizing;
import src.TimeState;
import format.gif.Data.Block;
import hxd.res.BitmapFont;
import h2d.Text;
import h3d.Vector;
import hxd.fmt.hmd.Data.AnimationEvent;
import h2d.Tile;
import h3d.mat.DepthBuffer;
import h3d.mat.Texture;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import src.DtsObject;
import h2d.Anim;
import h2d.Bitmap;
import src.ResourceLoader;
import src.MarbleGame;
import src.Resource;
import hxd.res.Sound;
import h3d.mat.Texture;
import src.Settings;
import src.Util;
import src.AudioManager;

class PlayGui {
	var scene2d:h2d.Scene;

	public function new() {}

	var timerNumbers:Array<GuiAnim> = [];
	var timerPoint:GuiImage;
	var timerColon:GuiImage;

	var goldTimeText:h2d.Text;
	var personalBestText:h2d.Text;
	var goldTime:Float = 0;
	var personalBest:Float = Math.POSITIVE_INFINITY;

	var goldSplash:Bitmap;
	var goldSplashTime:Float = -1;

	var hudVisible:Bool = true;
	var gemCounterShown:Bool = false;

	var gemCountNumbers:Array<GuiAnim> = [];
	var gemCountSlash:GuiImage;
	var gemImageScene:h3d.scene.Scene;
	var gemImageSceneTarget:Texture;
	var gemImageObject:DtsObject;
	var gemImageSceneTargetBitmap:Bitmap;

	var powerupBox:GuiImage;
	var powerupImageScene:h3d.scene.Scene;
	var powerupImageSceneTarget:Texture;
	var powerupImageSceneTargetBitmap:Bitmap;
	var powerupImageObject:DtsObject;

	var RSGOCenterText:Anim;

	var helpTextForeground:GuiText;
	var helpTextBackground:GuiText;
	var alertTextForeground:GuiText;
	var alertTextBackground:GuiText;

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var playGuiCtrl:GuiControl;

	var resizeEv:Void->Void;

	var _init:Bool;

	public function dispose() {
		if (_init) {
			playGuiCtrl.dispose();
			gemImageScene.dispose();
			gemImageSceneTarget.dispose();
			gemImageSceneTargetBitmap.remove();
			powerupImageScene.dispose();
			powerupImageSceneTarget.dispose();
			powerupImageSceneTargetBitmap.remove();
			RSGOCenterText.remove();
			if (goldSplash != null)
				goldSplash.remove();
			if (goldTimeText != null) {
				goldTimeText.remove();
				personalBestText.remove();
			}

			for (textureResource in textureResources) {
				textureResource.release();
			}
			for (imageResource in imageResources) {
				imageResource.release();
			}
			for (audioResource in soundResources) {
				audioResource.release();
			}

			Window.getInstance().removeResizeEvent(resizeEv);
		}
	}

	public function init(scene2d:h2d.Scene) {
		this.scene2d = scene2d;
		this._init = true;

		playGuiCtrl = new GuiControl();
		playGuiCtrl.position = new Vector();
		playGuiCtrl.extent = new Vector(640, 480);
		playGuiCtrl.horizSizing = Width;
		playGuiCtrl.vertSizing = Height;

		var numberTiles = [];
		for (i in 0...10) {
			var tile = ResourceLoader.getResource('data/ui/game/numbers/${i}.png', ResourceLoader.getImage, this.imageResources).toTile();
			numberTiles.push(tile);
		}

		for (i in 0...7) {
			timerNumbers.push(new GuiAnim(numberTiles));
		}

		for (i in 0...4) {
			gemCountNumbers.push(new GuiAnim(numberTiles));
		}

		var rsgo = [];
		rsgo.push(ResourceLoader.getResource("data/ui/game/ready.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/set.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/go.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/outofbounds.png", ResourceLoader.getImage, this.imageResources).toTile());
		GuiControl.useNearestFilterAll(rsgo);
		RSGOCenterText = new Anim(rsgo, 0, scene2d);

		powerupBox = new GuiImage(ResourceLoader.getResource('data/ui/game/powerup.png', ResourceLoader.getImage, this.imageResources).toTile());
		initTimer();
		initGemCounter();
		initCenterText();
		initPowerupBox();
		initTexts();
		initSideTimers();
		initGoldSplash();

		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.showControls(this.playGuiCtrl, false);
		}

		playGuiCtrl.render(scene2d);

		resizeEv = () -> {
			// Settings recomputes uiScale on its own resize handler, registered first
			rebuildTextFonts();
			rebuildGemTarget();
			rebuildPowerupTarget();
			playGuiCtrl.render(MarbleGame.canvas.scene2d);
			layoutOverlays();
		};

		Window.getInstance().addResizeEvent(resizeEv);
	}

	/**
		Hides the whole play hud, used while the end game panel is up: it reprints the run's
		time itself, so the live timer behind it would only be repeating the same numbers.
	**/
	public function setHudVisible(visible:Bool) {
		hudVisible = visible;
		applyHudVisibility();
	}

	function applyHudVisibility() {
		if (playGuiCtrl != null && playGuiCtrl._flow != null)
			playGuiCtrl._flow.visible = hudVisible;
		if (gemImageSceneTargetBitmap != null)
			gemImageSceneTargetBitmap.visible = hudVisible && gemCounterShown;
		if (powerupImageSceneTargetBitmap != null)
			powerupImageSceneTargetBitmap.visible = hudVisible;
		if (goldTimeText != null) {
			goldTimeText.visible = hudVisible && goldTime > 0;
			personalBestText.visible = hudVisible;
		}
	}

	public function initTimer() {
		var timerCtrl = new GuiControl();
		timerCtrl.horizSizing = HorizSizing.Center;
		timerCtrl.position = new Vector(215, 1);
		timerCtrl.extent = new Vector(234, 58);

		timerNumbers[0].position = new Vector(23, 0);
		timerNumbers[0].extent = new Vector(43, 55);

		timerNumbers[1].position = new Vector(47, 0);
		timerNumbers[1].extent = new Vector(43, 55);

		timerColon = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/colon.png', ResourceLoader.getImage, this.imageResources).toTile());
		timerColon.position = new Vector(67, 0);
		timerColon.extent = new Vector(43, 55);

		timerNumbers[2].position = new Vector(83, 0);
		timerNumbers[2].extent = new Vector(43, 55);

		timerNumbers[3].position = new Vector(107, 0);
		timerNumbers[3].extent = new Vector(43, 55);

		timerPoint = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile());
		timerPoint.position = new Vector(127, 0);
		timerPoint.extent = new Vector(43, 55);

		timerNumbers[4].position = new Vector(143, 0);
		timerNumbers[4].extent = new Vector(43, 55);

		timerNumbers[5].position = new Vector(167, 0);
		timerNumbers[5].extent = new Vector(43, 55);

		timerNumbers[6].position = new Vector(191, 0);
		timerNumbers[6].extent = new Vector(43, 55);

		timerCtrl.addChild(timerNumbers[0]);
		timerCtrl.addChild(timerNumbers[1]);
		timerCtrl.addChild(timerColon);
		timerCtrl.addChild(timerNumbers[2]);
		timerCtrl.addChild(timerNumbers[3]);
		timerCtrl.addChild(timerPoint);
		timerCtrl.addChild(timerNumbers[4]);
		timerCtrl.addChild(timerNumbers[5]);
		timerCtrl.addChild(timerNumbers[6]);

		playGuiCtrl.addChild(timerCtrl);
	}

	static inline var SIDE_TIME_FONT_SIZE = 24;

	// The timer control is 234 wide and centred, but its digits are not centred inside it:
	// the ink runs from 89 left of the middle to 111 right of it
	static inline var TIMER_INK_LEFT = 89;
	static inline var TIMER_INK_RIGHT = 111;
	static inline var TIMER_SIDE_GAP = 16;

	function buildSideTimeFont():h2d.Font {
		var domcasualfontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasualb = new BitmapFont(domcasualfontdata.entry);
		@:privateAccess domcasualb.loader = ResourceLoader.loader;
		return domcasualb.toSdfFont(cast SIDE_TIME_FONT_SIZE * Settings.uiScale, MultiChannel);
	}

	/**
		The gold time and the personal best sit either side of the live timer. They are
		placed straight on the scene rather than inside `playGuiCtrl`, since the gui control
		clips its children to the box it was authored in and these hang outside the timer.
	**/
	function initSideTimers() {
		var font = buildSideTimeFont();

		// A black outline rather than an offset backdrop, so both readouts stay legible over
		// whatever the level puts behind them
		goldTimeText = new Text(font, scene2d);
		goldTimeText.textColor = 0xFFCC00;
		goldTimeText.filter = buildOutline();

		personalBestText = new Text(font, scene2d);
		personalBestText.textColor = 0xFFFFFF;
		personalBestText.filter = buildOutline();

		updateSideTimerText();
	}

	function buildOutline() {
		// Scales with the ui, so it stays the same weight against the text at any resolution
		return new h2d.filter.Outline(Math.max(1, Math.round(Settings.uiScale)), 0x000000);
	}

	/**
		Level times for the readouts beside the live timer. A gold time of 0 means the
		mission has none, and an infinite best means the level has never been finished.
	**/
	public function setLevelTimes(goldTime:Float, personalBest:Float) {
		this.goldTime = goldTime;
		this.personalBest = personalBest;
		updateSideTimerText();
		layoutSideTimers();
	}

	function updateSideTimerText() {
		if (goldTimeText == null)
			return;
		goldTimeText.visible = hudVisible && goldTime > 0;
		goldTimeText.text = 'Gold Time: ${Util.formatTime(goldTime)}';
		personalBestText.text = 'Personal Best: ' + (personalBest == Math.POSITIVE_INFINITY ? "--:--.---" : Util.formatTime(personalBest));
		personalBestText.visible = hudVisible;
	}

	function layoutSideTimers() {
		if (goldTimeText == null)
			return;
		var centerX = scene2d.width / 2;
		// Centre the readouts on the digits themselves, which sit inset in their tiles
		var y = (1 + 26.5) * Settings.uiScale - goldTimeText.font.lineHeight / 2;
		goldTimeText.y = y;
		goldTimeText.x = centerX - (TIMER_INK_LEFT + TIMER_SIDE_GAP) * Settings.uiScale - goldTimeText.textWidth;

		personalBestText.y = y;
		personalBestText.x = centerX + (TIMER_INK_RIGHT + TIMER_SIDE_GAP) * Settings.uiScale;
	}

	public function initCenterText() {
		layoutCenterText();
	}

	/**
		Re-centre and re-scale the ready/set/go/out of bounds art against the current
		`Settings.uiScale`, using whichever frame is showing.
	**/
	public function layoutCenterText() {
		var frame = Std.int(RSGOCenterText.currentFrame);
		if (frame < 0 || frame >= RSGOCenterText.frames.length)
			frame = 0;
		RSGOCenterText.setScale(Settings.uiScale);
		RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[frame].width * Settings.uiScale / 2;
		RSGOCenterText.y = scene2d.height * 0.3;
	}

	public function setCenterText(identifier:String) {
		if (identifier == 'none') {
			this.RSGOCenterText.visible = false;
			return;
		}
		this.RSGOCenterText.visible = true;
		this.RSGOCenterText.currentFrame = switch (identifier) {
			case 'ready': 0;
			case 'set': 1;
			case 'go': 2;
			case 'outofbounds': 3;
			case _: this.RSGOCenterText.currentFrame;
		};
		layoutCenterText();
	}

	public function doStateChangeSound(state:String) {
		static var curState = "none";
		if (curState != state) {
			if (state == "ready") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/ready.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
			if (state == "set") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/set.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
			if (state == "go") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/go.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
		}

		curState = state;
	}

	public function initGemCounter() {
		gemCountNumbers[0].position = new Vector(30, 0);
		gemCountNumbers[0].extent = new Vector(43, 55);

		gemCountNumbers[1].position = new Vector(54, 0);
		gemCountNumbers[1].extent = new Vector(43, 55);

		gemCountSlash = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/slash.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemCountSlash.position = new Vector(75, 0);
		gemCountSlash.extent = new Vector(43, 55);

		gemCountNumbers[2].position = new Vector(96, 0);
		gemCountNumbers[2].extent = new Vector(43, 55);

		gemCountNumbers[3].position = new Vector(120, 0);
		gemCountNumbers[3].extent = new Vector(43, 55);

		playGuiCtrl.addChild(gemCountNumbers[0]);
		playGuiCtrl.addChild(gemCountNumbers[1]);
		playGuiCtrl.addChild(gemCountSlash);
		playGuiCtrl.addChild(gemCountNumbers[2]);
		playGuiCtrl.addChild(gemCountNumbers[3]);

		this.gemImageScene = new h3d.scene.Scene();
		// var gemImageRenderer = cast(this.gemImageScene.renderer, h3d.scene.Renderer);
		// gemImageRenderer.skyMode = Hide;

		rebuildGemTarget();
		gemImageSceneTargetBitmap.x = -8 * Settings.uiScale;
		gemImageSceneTargetBitmap.y = -8 * Settings.uiScale;
		gemImageSceneTargetBitmap.setScale(Settings.uiScale);
		// gemImageSceneTargetBitmap.blendMode = None;
		// gemImageSceneTargetBitmap.addShader(new ColorKey());

		gemImageObject = new DtsObject();
		gemImageObject.dtsPath = "data/shapes/items/gem.dts";
		gemImageObject.ambientRotate = true;
		gemImageObject.showSequences = false;
		// gemImageObject.matNameOverride.set("base.gem", "base.gem.");
		gemImageObject.ambientSpinFactor /= -2;
		// ["base.gem"] = color + ".gem";
		gemImageObject.init(null, () -> {
			for (mat in gemImageObject.materials) {
				mat.mainPass.enableLights = false;

				// Huge hacks
				if (mat.blendMode != Add) {
					var alphaShader = new h3d.shader.AlphaChannel();
					mat.mainPass.addShader(alphaShader);
				}
			}
			gemImageScene.addChild(gemImageObject);
			var gemImageCenter = gemImageObject.getBounds().getCenter();

			gemImageScene.camera.pos = new Vector(0, 3, gemImageCenter.z);
			gemImageScene.camera.target = new Vector(gemImageCenter.x, gemImageCenter.y, gemImageCenter.z);
		});
	}

	function initPowerupBox() {
		powerupBox.position = new Vector(538, 6);
		powerupBox.extent = new Vector(97, 96);
		powerupBox.horizSizing = Left;

		playGuiCtrl.addChild(powerupBox);

		this.powerupImageScene = new h3d.scene.Scene();
		// var powerupImageRenderer = cast(this.powerupImageScene.renderer, h3d.scene.pbr.Renderer);
		// powerupImageRenderer.skyMode = Hide;

		rebuildPowerupTarget();
		layoutOverlays();
	}

	// Shared with the end game score text, see GuiControl.TEXT_SHADOW_OFFSET
	static inline var TEXT_SHADOW_OFFSET = GuiControl.TEXT_SHADOW_OFFSET;

	// Size the gem and powerup icons are drawn at when uiScale is 1
	static inline var GEM_TARGET_SIZE = 60;
	static inline var POWERUP_TARGET_WIDTH = 68;
	static inline var POWERUP_TARGET_HEIGHT = 67;

	/**
		The gem and powerup icons are small 3d scenes rendered to a texture. Size that
		texture by `Settings.uiScale` so they are rendered at the resolution they are
		actually shown at, instead of rendering at 1x and scaling the result up.
	**/
	function rebuildGemTarget() {
		var size = Math.ceil(GEM_TARGET_SIZE * Settings.uiScale);
		if (gemImageSceneTarget != null && gemImageSceneTarget.width == size)
			return;
		if (gemImageSceneTarget != null) {
			if (gemImageSceneTarget.depthBuffer != null)
				gemImageSceneTarget.depthBuffer.dispose();
			gemImageSceneTarget.dispose();
		}
		gemImageSceneTarget = new Texture(size, size, [Target]);
		gemImageSceneTarget.depthBuffer = new DepthBuffer(size, size);
		if (gemImageSceneTargetBitmap == null)
			gemImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(gemImageSceneTarget), scene2d);
		else
			gemImageSceneTargetBitmap.tile = Tile.fromTexture(gemImageSceneTarget);
	}

	function rebuildPowerupTarget() {
		var width = Math.ceil(POWERUP_TARGET_WIDTH * Settings.uiScale);
		var height = Math.ceil(POWERUP_TARGET_HEIGHT * Settings.uiScale);
		if (powerupImageSceneTarget != null && powerupImageSceneTarget.width == width && powerupImageSceneTarget.height == height)
			return;
		if (powerupImageSceneTarget != null) {
			if (powerupImageSceneTarget.depthBuffer != null)
				powerupImageSceneTarget.depthBuffer.dispose();
			powerupImageSceneTarget.dispose();
		}
		powerupImageSceneTarget = new Texture(width, height, [Target]);
		powerupImageSceneTarget.depthBuffer = new DepthBuffer(width, height);
		if (powerupImageSceneTargetBitmap == null)
			powerupImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(powerupImageSceneTarget), scene2d);
		else
			powerupImageSceneTargetBitmap.tile = Tile.fromTexture(powerupImageSceneTarget);
	}

	/**
		Position and scale the pieces that live directly on the scene rather than inside
		`playGuiCtrl`, so they are not covered by the gui control re-layout.
	**/
	function layoutOverlays() {
		if (gemImageSceneTargetBitmap != null) {
			gemImageSceneTargetBitmap.x = -8 * Settings.uiScale;
			gemImageSceneTargetBitmap.y = -8 * Settings.uiScale;
			// The target is already uiScale sized, so this only corrects the ceil rounding
			gemImageSceneTargetBitmap.setScale(GEM_TARGET_SIZE * Settings.uiScale / gemImageSceneTarget.width);
		}
		if (powerupImageSceneTargetBitmap != null) {
			powerupImageSceneTargetBitmap.x = scene2d.width - 88 * Settings.uiScale;
			powerupImageSceneTargetBitmap.y = 18 * Settings.uiScale;
			powerupImageSceneTargetBitmap.scaleX = POWERUP_TARGET_WIDTH * Settings.uiScale / powerupImageSceneTarget.width;
			powerupImageSceneTargetBitmap.scaleY = POWERUP_TARGET_HEIGHT * Settings.uiScale / powerupImageSceneTarget.height;
		}
		if (RSGOCenterText != null)
			layoutCenterText();
		layoutSideTimers();
		layoutGoldSplash();
	}

	/**
		Fonts bake their size in when they are built, so the help and alert text needs a
		fresh one whenever `Settings.uiScale` changes rather than just a re-layout.
	**/
	function buildTextFont():h2d.Font {
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		return domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
	}

	function rebuildTextFonts() {
		if (helpTextForeground == null)
			return;
		var bfont = buildTextFont();
		helpTextForeground.text.font = bfont;
		helpTextBackground.text.font = bfont;
		alertTextForeground.text.font = bfont;
		alertTextBackground.text.font = bfont;

		if (goldTimeText != null) {
			var sidefont = buildSideTimeFont();
			goldTimeText.font = sidefont;
			personalBestText.font = sidefont;
			// The outline width is baked against the scale it was built at
			goldTimeText.filter = buildOutline();
			personalBestText.filter = buildOutline();
		}
	}

	function initTexts() {
		var bfont = buildTextFont();

		var helpTextCtrl = new GuiControl();
		helpTextCtrl.position = new Vector(0, 210);
		helpTextCtrl.extent = new Vector(640, 60);
		helpTextCtrl.vertSizing = Center;
		helpTextCtrl.horizSizing = Width;

		helpTextBackground = new GuiText(bfont);
		helpTextBackground.text.textColor = 0x000000;
		helpTextBackground.position = new Vector(TEXT_SHADOW_OFFSET, TEXT_SHADOW_OFFSET);
		helpTextBackground.extent = new Vector(640, 14);
		helpTextBackground.vertSizing = Height;
		helpTextBackground.horizSizing = Width;
		helpTextBackground.justify = Center;

		helpTextForeground = new GuiText(bfont);
		helpTextForeground.text.textColor = 0xFFFFFF;
		helpTextForeground.position = new Vector(0, 0);
		helpTextForeground.extent = new Vector(640, 16);
		helpTextForeground.vertSizing = Height;
		helpTextForeground.horizSizing = Width;
		helpTextForeground.justify = Center;

		helpTextCtrl.addChild(helpTextBackground);
		helpTextCtrl.addChild(helpTextForeground);

		var alertTextCtrl = new GuiControl();
		alertTextCtrl.position = new Vector(0, 418);
		alertTextCtrl.extent = new Vector(640, 58);
		alertTextCtrl.vertSizing = Top;
		alertTextCtrl.horizSizing = Width;

		alertTextBackground = new GuiText(bfont);
		alertTextBackground.text.textColor = 0x000000;
		alertTextBackground.position = new Vector(TEXT_SHADOW_OFFSET, TEXT_SHADOW_OFFSET);
		alertTextBackground.extent = new Vector(640, 32);
		alertTextBackground.vertSizing = Height;
		alertTextBackground.horizSizing = Width;
		alertTextBackground.justify = Center;

		alertTextForeground = new GuiText(bfont);
		alertTextForeground.text.textColor = 0xFFFF00;
		alertTextForeground.position = new Vector(0, 0);
		alertTextForeground.extent = new Vector(640, 32);
		alertTextForeground.vertSizing = Height;
		alertTextForeground.horizSizing = Width;
		alertTextForeground.justify = Center;

		alertTextCtrl.addChild(alertTextBackground);
		alertTextCtrl.addChild(alertTextForeground);

		playGuiCtrl.addChild(helpTextCtrl);
		playGuiCtrl.addChild(alertTextCtrl);
	}

	public function setHelpTextOpacity(value:Float) {
		@:privateAccess helpTextForeground.text._textColorVec.a = value;
		@:privateAccess helpTextBackground.text._textColorVec.a = value;
	}

	public function setAlertTextOpacity(value:Float) {
		@:privateAccess alertTextForeground.text._textColorVec.a = value;
		@:privateAccess alertTextBackground.text._textColorVec.a = value;
	}

	public function setAlertText(text:String) {
		this.alertTextForeground.text.text = text;
		this.alertTextBackground.text.text = text;
		// alertTextBackground.render(scene2d);
		// alertTextForeground.x = scene2d.width / 2 - alertTextForeground.textWidth / 2;
		// alertTextForeground.y = scene2d.height - 102;
		// alertTextBackground.x = scene2d.width / 2 - alertTextBackground.textWidth / 2 + 1;
		// alertTextBackground.y = scene2d.height - 102 + 1;
	}

	public function setHelpText(text:String) {
		this.helpTextForeground.text.text = text;
		this.helpTextBackground.text.text = text;
		// helpTextBackground.render(scene2d);
		// helpTextForeground.x = scene2d.width / 2 - helpTextForeground.textWidth / 2;
		// helpTextForeground.y = scene2d.height * 0.45;
		// helpTextBackground.x = scene2d.width / 2 - helpTextBackground.textWidth / 2 + 1;
		// helpTextBackground.y = scene2d.height * 0.45 + 1;
	}

	public function setPowerupImage(powerupIdentifier:String) {
		this.powerupImageScene.removeChildren();
		if (powerupIdentifier == "SuperJump") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superjump.dts";
		} else if (powerupIdentifier == "SuperSpeed") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superspeed.dts";
		} else if (powerupIdentifier == "ShockAbsorber") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/shockabsorber.dts";
		} else if (powerupIdentifier == "SuperBounce") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superbounce.dts";
		} else if (powerupIdentifier == "Helicopter") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/images/helicopter.dts";
		} else if (powerupIdentifier == "MegaMarble") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/megamarble.dts";
		} else {
			powerupIdentifier = "";
			this.powerupImageObject = null;
		}

		if (powerupIdentifier != "") {
			powerupImageObject.ambientRotate = true;
			powerupImageObject.ambientSpinFactor /= 2;
			powerupImageObject.showSequences = false;
			powerupImageObject.init(null, () -> {
				for (mat in powerupImageObject.materials) {
					mat.mainPass.enableLights = false;
					if (mat.blendMode != Alpha && mat.blendMode != Add)
						mat.mainPass.addShader(new h3d.shader.AlphaChannel());
				}
				powerupImageScene.addChild(powerupImageObject);
				var powerupImageCenter = powerupImageObject.getBounds().getCenter();

				powerupImageScene.camera.pos = new Vector(0, 4, powerupImageCenter.z);
				powerupImageScene.camera.target = new Vector(powerupImageCenter.x, powerupImageCenter.y, powerupImageCenter.z);
			});
		}
	}

	public function formatGemCounter(collected:Int, total:Int) {
		gemCounterShown = total != 0;
		for (number in gemCountNumbers) {
			number.anim.visible = gemCounterShown;
		}
		gemCountSlash.bmp.visible = gemCounterShown;
		gemImageSceneTargetBitmap.visible = hudVisible && gemCounterShown;

		var totalTenths = Math.floor(total / 10);
		var totalOnes = total % 10;

		var collectedTenths = Math.floor(collected / 10);
		var collectedOnes = collected % 10;

		gemCountNumbers[0].anim.currentFrame = collectedTenths;
		gemCountNumbers[1].anim.currentFrame = collectedOnes;
		gemCountNumbers[2].anim.currentFrame = totalTenths;
		gemCountNumbers[3].anim.currentFrame = totalOnes;
	}

	public function formatTimer(time:Float) {
		var et = time * 1000;
		var thousandth = et % 10;
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = (minutes - minutesOne) / 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		timerNumbers[0].anim.currentFrame = minutesTen;
		timerNumbers[1].anim.currentFrame = minutesOne;
		timerNumbers[2].anim.currentFrame = secondsTen;
		timerNumbers[3].anim.currentFrame = secondsOne;
		timerNumbers[4].anim.currentFrame = hundredthTen;
		timerNumbers[5].anim.currentFrame = hundredthOne;
		timerNumbers[6].anim.currentFrame = thousandth;
	}

	// Long enough for the whole burst to land inside the two second wait between touching
	// the finish and the end game screen appearing
	static inline var GOLD_SPLASH_DURATION = 1.35;

	// Width the badge settles at, in the 640 wide authored layout space
	static inline var GOLD_SPLASH_WIDTH = 300;

	/**
		The gold badge burst shown when a run beats the level's gold time, blown up out of
		the middle of the screen and faded out alongside the goal jingle.
	**/
	public function playGoldSplash() {
		if (goldSplash == null)
			return;
		// Re-adding lifts it above everything else already on the scene
		scene2d.addChild(goldSplash);
		goldSplash.visible = true;
		goldSplashTime = 0;
		layoutGoldSplash();
		AudioManager.playSound(ResourceLoader.getResource('data/sound/goal.ogg', ResourceLoader.getAudio, this.soundResources));
	}

	public function hideGoldSplash() {
		goldSplashTime = -1;
		if (goldSplash != null)
			goldSplash.visible = false;
	}

	function initGoldSplash() {
		var tile = ResourceLoader.getResource("data/ui/game/gold.png", ResourceLoader.getImage, this.imageResources).toTile();
		// Drawn well above its source size and never pixel aligned, so nearest sampling
		// would show its edges
		var tex = tile.getTexture();
		if (tex != null)
			tex.filter = Linear;
		goldSplash = new Bitmap(tile, scene2d);
		goldSplash.visible = false;
	}

	function layoutGoldSplash() {
		if (goldSplash == null || goldSplashTime < 0)
			return;
		var t = Util.clamp(goldSplashTime / GOLD_SPLASH_DURATION, 0, 1);
		// Exponential ease out, so it snaps out to size and then drifts
		var grow = 1 - Math.pow(2, -10 * t);
		var scale = (0.55 + 0.7 * grow) * GOLD_SPLASH_WIDTH * Settings.uiScale / goldSplash.tile.width;
		goldSplash.setScale(scale);
		goldSplash.alpha = t < 0.5 ? 1 : Math.max(0, 1 - (t - 0.5) / 0.5);
		goldSplash.x = scene2d.width / 2 - goldSplash.tile.width * scale / 2;
		goldSplash.y = scene2d.height / 2 - goldSplash.tile.height * scale / 2;
	}

	public function render(engine:h3d.Engine) {
		engine.pushTarget(this.gemImageSceneTarget);

		engine.clear(0, 1);
		this.gemImageScene.render(engine);

		engine.popTarget();
		engine.pushTarget(this.powerupImageSceneTarget);

		engine.clear(0, 1);
		this.powerupImageScene.render(engine);

		engine.popTarget();
	}

	public function update(timeState:TimeState) {
		if (goldSplashTime >= 0) {
			goldSplashTime += timeState.dt;
			if (goldSplashTime >= GOLD_SPLASH_DURATION)
				hideGoldSplash();
			else
				layoutGoldSplash();
		}
		this.gemImageObject.update(timeState);
		this.gemImageScene.setElapsedTime(timeState.dt);
		if (this.powerupImageObject != null)
			this.powerupImageObject.update(timeState);
		this.powerupImageScene.setElapsedTime(timeState.dt);
	}
}
