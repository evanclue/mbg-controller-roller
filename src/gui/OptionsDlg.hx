package gui;

import haxe.DynamicAccess;
import gui.GuiControl.MouseState;
import src.AudioManager;
import hxd.Key;
import src.Settings;
import src.Marble;
import h2d.Tile;
import hxd.res.BitmapFont;
import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;
import src.Util;
import src.Settings;

class OptionsDlg extends GuiImage {
	var musicSliderFunc:(dt:Float, mouseState:MouseState) -> Void;

	public function new() {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var tabs = new GuiControl();
		tabs.horizSizing = Center;
		tabs.vertSizing = Center;
		tabs.position = new Vector(60, 15);
		tabs.extent = new Vector(520, 450);
		this.addChild(tabs);

		var setTab:String->Void = null;

		var graphicsTab = new GuiImage(ResourceLoader.getResource("data/ui/options/graf_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		graphicsTab.position = new Vector(58, 44);
		graphicsTab.extent = new Vector(149, 86);

		var controlsTab = new GuiImage(ResourceLoader.getResource("data/ui/options/cntr_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		controlsTab.position = new Vector(315, 15);
		controlsTab.extent = new Vector(149, 65);

		var rewindTab = new GuiImage(ResourceLoader.getResource("data/ui/options/rwnd_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		rewindTab.position = new Vector(459, 76);
		rewindTab.extent = new Vector(59, 162);

		var boxFrame = new GuiImage(ResourceLoader.getResource("data/ui/options/options_base.png", ResourceLoader.getImage, this.imageResources).toTile());
		boxFrame.position = new Vector(25, 14);
		boxFrame.extent = new Vector(470, 422);
		boxFrame.horizSizing = Center;
		boxFrame.vertSizing = Center;

		var audioTab = new GuiImage(ResourceLoader.getResource("data/ui/options/aud_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		audioTab.position = new Vector(204, 33);
		audioTab.extent = new Vector(114, 75);

		tabs.addChild(audioTab);
		tabs.addChild(controlsTab);
		tabs.addChild(rewindTab);
		tabs.addChild(boxFrame);
		tabs.addChild(graphicsTab);

		var mainPane = new GuiControl();
		mainPane.position = new Vector(60, 15);
		mainPane.extent = new Vector(520, 480);
		mainPane.horizSizing = Center;
		mainPane.vertSizing = Center;
		this.addChild(mainPane);

		// GRAPHICS PANEL
		var graphicsPane = new GuiControl();
		graphicsPane.position = new Vector(35, 110);
		graphicsPane.extent = new Vector(438, 298);

		mainPane.addChild(graphicsPane);
		var applyFunc:Void->Void = null;

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/options/mainm"));
		mainMenuButton.position = new Vector(330, 356);
		mainMenuButton.extent = new Vector(121, 53);
		mainMenuButton.pressedAction = (sender) -> {
			applyFunc();
			MarbleGame.canvas.setContent(new MainMenuGui(), () -> new MainMenuGui());
		}
		mainPane.addChild(mainMenuButton);

		// Hacky radio box logic
		var windowBoxes = [];

		function updateWindowFunc(sender:GuiButton) {
			for (box in windowBoxes) {
				if (box != sender)
					box.pressed = false;
			}
		}

		var gfxWindow = new GuiButton(loadButtonImages("data/ui/options/grafwindo"));
		gfxWindow.position = new Vector(174, 4);
		gfxWindow.extent = new Vector(97, 55);
		gfxWindow.buttonType = Toggle;
		gfxWindow.pressedAction = (sender) -> {
			updateWindowFunc(gfxWindow);
			Settings.optionsSettings.isFullScreen = false;
			Settings.applySettings();
		}
		if (!Settings.optionsSettings.isFullScreen) {
			gfxWindow.pressed = true;
		}
		graphicsPane.addChild(gfxWindow);
		windowBoxes.push(gfxWindow);

		var gfxFull = new GuiButton(loadButtonImages("data/ui/options/grafful"));
		gfxFull.position = new Vector(288, 6);
		gfxFull.extent = new Vector(61, 55);
		gfxFull.buttonType = Toggle;
		gfxFull.pressedAction = (sender) -> {
			updateWindowFunc(gfxFull);
			Settings.optionsSettings.isFullScreen = true;
			Settings.applySettings();
		}
		if (Settings.optionsSettings.isFullScreen) {
			gfxFull.pressed = true;
		}
		graphicsPane.addChild(gfxFull);
		windowBoxes.push(gfxFull);

		// var gfxText = new GuiImage(ResourceLoader.getResource("data/ui/options/graf_txt.png", ResourceLoader.getImage, this.imageResources).toTile());
		// gfxText.horizSizing = Right;
		// gfxText.vertSizing = Bottom;
		// gfxText.position = new Vector(12, 12);
		// gfxText.extent = new Vector(146, 261);
		// graphicsPane.addChild(gfxText);


		var screenStyleLabel = new GuiText(domcasual32);
		screenStyleLabel.position = new Vector(12, 16);
		screenStyleLabel.extent = new Vector(146, 261);
		screenStyleLabel.text.textColor = 0x000000;
		screenStyleLabel.text.text = "Screen Style:";
		screenStyleLabel.justify = Right;
		graphicsPane.addChild(screenStyleLabel);

		var vsyncLabel = new GuiText(domcasual32);
		vsyncLabel.position = new Vector(12, 76);
		vsyncLabel.extent = new Vector(146, 271);
		vsyncLabel.text.textColor = 0x000000;
		vsyncLabel.text.text = "VSync:";
		vsyncLabel.justify = Right;
		graphicsPane.addChild(vsyncLabel);

		var vsyncButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		vsyncButton.position = new Vector(170, 66);
		vsyncButton.extent = new Vector(46, 54);
		vsyncButton.buttonType = Toggle;
		vsyncButton.pressedAction = (sender) -> {
			// pressed still holds the old state when the action runs, see GuiButton.activate
			Settings.optionsSettings.vsync = !vsyncButton.pressed;
			Settings.applySettings();
		}
		graphicsPane.addChild(vsyncButton);
		if (Settings.optionsSettings.vsync) {
			vsyncButton.pressed = true;
		}

		var antiAliasLabel = new GuiText(domcasual32);
		antiAliasLabel.position = new Vector(12, 136);
		antiAliasLabel.extent = new Vector(146, 271);
		antiAliasLabel.text.textColor = 0x000000;
		antiAliasLabel.text.text = "Anti-Aliasing:";
		antiAliasLabel.justify = Right;
		graphicsPane.addChild(antiAliasLabel);

		// Multisampling is chosen when the gl context is made, so this only takes hold on
		// the next launch. It is here to take the edge off the shimmer from unmipmapped
		// level textures.
		var antiAliasButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		antiAliasButton.position = new Vector(170, 126);
		antiAliasButton.extent = new Vector(46, 54);
		antiAliasButton.buttonType = Toggle;
		antiAliasButton.pressedAction = (sender) -> {
			Settings.optionsSettings.antiAliasing = !antiAliasButton.pressed;
			Settings.save();
		};
		graphicsPane.addChild(antiAliasButton);
		if (Settings.optionsSettings.antiAliasing) {
			antiAliasButton.pressed = true;
		}

		var fieldOfViewLabel = new GuiText(domcasual32);
		fieldOfViewLabel.position = new Vector(12, 196);
		fieldOfViewLabel.extent = new Vector(146, 261);
		fieldOfViewLabel.text.textColor = 0x000000;
		fieldOfViewLabel.text.text = "FOV: (" + Settings.optionsSettings.fovX + ")";
		fieldOfViewLabel.justify = Right;
		graphicsPane.addChild(fieldOfViewLabel);

		var fovSlide = new GuiImage(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources).toTile());
		fovSlide.position = new Vector(170, 189);
		fovSlide.extent = new Vector(254, 34);
		graphicsPane.addChild(fovSlide);

		var fovSlider = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage, this.imageResources).toTile());
		fovSlider.position = new Vector(170, 189);
		fovSlider.extent = new Vector(250, 34);
		fovSlider.controllerSteps = 80;
		fovSlider.sliderValue = (Settings.optionsSettings.fovX - 60) / (140 - 60);
		fovSlider.pressedAction = (sender) -> {
			Settings.optionsSettings.fovX = cast(60 + fovSlider.sliderValue * (140 - 60));
			fieldOfViewLabel.text.text = "FOV: (" + Settings.optionsSettings.fovX + ")";
			Settings.save();
		}
		graphicsPane.addChild(fovSlider);



		// var driverBoxes = [];

		// function updateDriverFunc(sender:GuiButton) {
		// 	for (box in driverBoxes) {
		// 		if (box != sender)
		// 			box.pressed = false;
		// 	}
		// }

		// var gfxopengl = new GuiButton(loadButtonImages("data/ui/options/grafopgl"));
		// gfxopengl.position = new Vector(165, 58);
		// gfxopengl.extent = new Vector(97, 54);
		// gfxopengl.buttonType = Radio;
		// driverBoxes.push(gfxopengl);
		// gfxopengl.pressedAction = (sender) -> {
		// 	updateDriverFunc(gfxopengl);
		// }
		// if (Settings.optionsSettings.videoDriver == 0) {
		// 	gfxopengl.pressed = true;
		// }
		// graphicsPane.addChild(gfxopengl);

		// var gfxd3d = new GuiButton(loadButtonImages("data/ui/options/grafdir3d"));
		// gfxd3d.position = new Vector(270, 59);
		// gfxd3d.extent = new Vector(104, 52);
		// gfxd3d.buttonType = Radio;
		// driverBoxes.push(gfxd3d);
		// gfxd3d.pressedAction = (sender) -> {
		// 	updateDriverFunc(gfxd3d);
		// }
		// if (Settings.optionsSettings.videoDriver == 1) {
		// 	gfxd3d.pressed = true;
		// }
		// graphicsPane.addChild(gfxd3d);


		// var bitBoxes = [];

		// function updateBitsFunc(sender:GuiButton) {
		// 	for (box in bitBoxes) {
		// 		if (box != sender)
		// 			box.pressed = false;
		// 	}
		// }

		// var gfx16 = new GuiButton(loadButtonImages("data/ui/options/graf16bt"));
		// gfx16.position = new Vector(179, 170);
		// gfx16.extent = new Vector(79, 54);
		// gfx16.buttonType = Radio;
		// bitBoxes.push(gfx16);
		// gfx16.pressedAction = (sender) -> {
		// 	updateBitsFunc(gfx16);
		// }
		// if (Settings.optionsSettings.colorDepth == 0) {
		// 	gfx16.pressed = true;
		// }
		// graphicsPane.addChild(gfx16);

		// var gfx32 = new GuiButton(loadButtonImages("data/ui/options/graf32bt"));
		// gfx32.position = new Vector(272, 174);
		// gfx32.extent = new Vector(84, 51);
		// gfx32.buttonType = Radio;
		// bitBoxes.push(gfx32);
		// gfx32.pressedAction = (sender) -> {
		// 	updateBitsFunc(gfx32);
		// }
		// if (Settings.optionsSettings.colorDepth == 1) {
		// 	gfx32.pressed = true;
		// }
		// graphicsPane.addChild(gfx32);

		// var shadowsButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		// shadowsButton.position = new Vector(141, 233);
		// shadowsButton.extent = new Vector(46, 54);
		// shadowsButton.buttonType = Toggle;
		// graphicsPane.addChild(shadowsButton);
		// if (Settings.optionsSettings.shadows) {
		// 	shadowsButton.pressed = true;
		// }

		// AUDIO PANEL

		var audioPane = new GuiControl();
		audioPane.position = new Vector(41, 91);
		audioPane.extent = new Vector(425, 281);
		// mainPane.addChild(audioPane);

		var audSndSlide = new GuiImage(ResourceLoader.getResource("data/ui/options/aud_snd_slide.png", ResourceLoader.getImage, this.imageResources).toTile());
		audSndSlide.position = new Vector(14, 92);
		audSndSlide.extent = new Vector(388, 34);
		audioPane.addChild(audSndSlide);

		var audMusSlide = new GuiImage(ResourceLoader.getResource("data/ui/options/aud_mus_slide.png", ResourceLoader.getImage, this.imageResources).toTile());
		audMusSlide.position = new Vector(17, 32);
		audMusSlide.extent = new Vector(381, 40);
		audioPane.addChild(audMusSlide);

		var audMusKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage, this.imageResources).toTile());
		audMusKnob.position = new Vector(137, 37);
		audMusKnob.extent = new Vector(250, 34);
		audMusKnob.sliderValue = Settings.optionsSettings.musicVolume;
		audMusKnob.controllerSteps = 100;
		audMusKnob.pressedAction = (sender) -> {
			Settings.optionsSettings.musicVolume = audMusKnob.sliderValue;
			// Take effect straight away rather than waiting for the pane to be applied
			AudioManager.updateVolumes();
		}
		audioPane.addChild(audMusKnob);

		var audSndKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_snd_knb.png", ResourceLoader.getImage, this.imageResources).toTile());
		audSndKnob.position = new Vector(137, 95);
		audSndKnob.extent = new Vector(254, 37);
		audSndKnob.sliderValue = Settings.optionsSettings.soundVolume;
		var testingSnd = AudioManager.playSound(ResourceLoader.getResource("data/sound/testing.wav", ResourceLoader.getAudio, this.soundResources), null, true);
		testingSnd.pause = true;
		audSndKnob.slidingSound = testingSnd;
		audSndKnob.controllerSteps = 100;
		audSndKnob.pressedAction = (sender) -> {
			Settings.optionsSettings.soundVolume = audSndKnob.sliderValue;
			AudioManager.updateVolumes();
		}
		audioPane.addChild(audSndKnob);

		musicSliderFunc = (dt:Float, mouseState:MouseState) -> {
			if (mouseState.button == Key.MOUSE_LEFT) {
				var musRect = audMusKnob.getRenderRectangle();
				if (musRect.inRect(mouseState.position)) {
					Settings.optionsSettings.musicVolume = audMusKnob.sliderValue;
					AudioManager.updateVolumes();
				}
				var sndRect = audSndKnob.getRenderRectangle();
				if (sndRect.inRect(mouseState.position)) {
					Settings.optionsSettings.soundVolume = audSndKnob.sliderValue;
					AudioManager.updateVolumes();
				}
			}
		}

		var audTxtWndo = new GuiImage(ResourceLoader.getResource("data/ui/options/aud_txt_wndo.png", ResourceLoader.getImage, this.imageResources).toTile());
		audTxtWndo.position = new Vector(26, 130);
		audTxtWndo.extent = new Vector(396, 132);
		audioPane.addChild(audTxtWndo);

		var audInfo = new GuiText(arial14);
		audInfo.position = new Vector(24, 41);
		audInfo.extent = new Vector(330, 56);
		audInfo.text.textColor = 0x000000;
		audInfo.text.text = "Vendor: Creative Labs Inc.
Version: OpenAL 1.0
Renderer: Software
Extensions: EAX 2.0, EAX 3.0, EAX Unified, and EAX-AC3";
		audTxtWndo.addChild(audInfo);

		// Everything applies as it is changed now, this just commits volumes on the way out
		applyFunc = () -> {
			// if (gfx16.pressed)
			// 	Settings.optionsSettings.colorDepth = 0;
			// else
			// 	Settings.optionsSettings.colorDepth = 1;
			// if (gfxopengl.pressed)
			// 	Settings.optionsSettings.videoDriver = 0;
			// else
			// 	Settings.optionsSettings.videoDriver = 1;
			// Settings.optionsSettings.shadows = shadowsButton.pressed;

			Settings.optionsSettings.musicVolume = audMusKnob.sliderValue;
			Settings.optionsSettings.soundVolume = audSndKnob.sliderValue;

			Settings.applySettings();
		}

		// REWIND PANEL

		function getConflictingBinding(bindingName:String, key:Int) {
			if (Settings.controlsSettings.forward == key && bindingName != "Move Forward")
				return "Move Forward";
			if (Settings.controlsSettings.backward == key && bindingName != "Move Backward")
				return "Move Backward";
			if (Settings.controlsSettings.left == key && bindingName != "Move Left")
				return "Move Left";
			if (Settings.controlsSettings.right == key && bindingName != "Move Right")
				return "Move Right";
			if (Settings.controlsSettings.camForward == key && bindingName != "Rotate Camera Up")
				return "Rotate Camera Up";
			if (Settings.controlsSettings.camBackward == key && bindingName != "Rotate Camera Down")
				return "Rotate Camera Down";
			if (Settings.controlsSettings.camLeft == key && bindingName != "Rotate Camera Left")
				return "Rotate Camera Left";
			if (Settings.controlsSettings.camRight == key && bindingName != "Rotate Camera Right")
				return "Rotate Camera Right";
			if (Settings.controlsSettings.jump == key && bindingName != "Jump")
				return "Jump";
			if (Settings.controlsSettings.powerup == key && bindingName != "Use PowerUp")
				return "Use PowerUp";
			if (Settings.controlsSettings.freelook == key && bindingName != "Free Look")
				return "Free Look";
			if (Settings.controlsSettings.rewind == key && bindingName != "Rewind")
				return "Rewind";

			return null;
		}

		function remapFunc(bindingName:String, bindingFunc:Int->Void, ctrl:GuiButtonText) {
			var remapDlg = new RemapDlg(bindingName);
			MarbleGame.canvas.pushDialog(remapDlg);
			remapDlg.remapCallback = (key) -> {
				MarbleGame.canvas.popDialog(remapDlg);

				if (key == Key.ESCAPE)
					return;

				var conflicting = getConflictingBinding(bindingName, key);
				if (conflicting == null) {
					ctrl.txtCtrl.text.text = Util.getKeyForButton2(key);
					bindingFunc(key);
				} else {
					var yesNoDlg = new MessageBoxYesNoDlg('<p align="center">"${Util.getKeyForButton2(key)}" is already bound to "${conflicting}"!<br/>Do you want to undo this mapping?</p>',
						() -> {
							ctrl.txtCtrl.text.text = Util.getKeyForButton2(key);
							bindingFunc(key);
						}, () -> {});
					MarbleGame.canvas.pushDialog(yesNoDlg);
				}
			}
		}

		var rewindPane = new GuiControl();
		rewindPane.position = new Vector(41, 91);
		rewindPane.extent = new Vector(425, 281);

		var rwndTimescaleSlide = new GuiImage(ResourceLoader.getResource("data/ui/options/rwnd_timescale.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		rwndTimescaleSlide.position = new Vector(29, 44);
		rwndTimescaleSlide.extent = new Vector(381, 33);
		rewindPane.addChild(rwndTimescaleSlide);

		var rwndTxt = new GuiImage(ResourceLoader.getResource("data/ui/options/rwnd_txt.png", ResourceLoader.getImage, this.imageResources).toTile());
		rwndTxt.position = new Vector(32, 83);
		rwndTxt.extent = new Vector(146, 261);
		rewindPane.addChild(rwndTxt);

		var rewindTimescaleKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		rewindTimescaleKnob.position = new Vector(144, 44);
		rewindTimescaleKnob.extent = new Vector(250, 34);
		rewindTimescaleKnob.sliderValue = (Settings.optionsSettings.rewindTimescale - 0.1) / (1 - 0.1);
		rewindTimescaleKnob.pressedAction = (sender) -> {
			Settings.optionsSettings.rewindTimescale = cast(0.1 + rewindTimescaleKnob.sliderValue * (1 - 0.1));
		}
		rewindPane.addChild(rewindTimescaleKnob);


		var rwndEnableButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		rwndEnableButton.position = new Vector(112, 72);

		rwndEnableButton.extent = new Vector(46, 54);
		rwndEnableButton.buttonType = Toggle;
		rwndEnableButton.pressedAction = (sender) -> {
			Settings.optionsSettings.rewindEnabled = !rwndEnableButton.pressed;
		}
		rewindPane.addChild(rwndEnableButton);
		if (Settings.optionsSettings.rewindEnabled) {
			rwndEnableButton.pressed = true;
		}

		// CONTROLS PANEL
		var controlsPane = new GuiControl();
		controlsPane.position = new Vector(44, 58);
		controlsPane.extent = new Vector(459, 339);

		var transparentbmp = new hxd.BitmapData(1, 1);
		transparentbmp.setPixel(0, 0, 0);
		var transparentTile = Tile.fromBitmap(transparentbmp);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		if (Util.isTouchDevice()) {
			var buttonCameraFactorLabel = new GuiText(domcasual32);
			buttonCameraFactorLabel.position = new Vector(12, 60);
			buttonCameraFactorLabel.extent = new Vector(200, 50);
			buttonCameraFactorLabel.text.textColor = 0x000000;
			buttonCameraFactorLabel.text.text = "Button-Camera Factor:";
			buttonCameraFactorLabel.justify = Right;
			controlsPane.addChild(buttonCameraFactorLabel);

			var buttonCameraFactorSlider = new GuiImage(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources)
				.toTile());
			buttonCameraFactorSlider.position = new Vector(220, 60);
			buttonCameraFactorSlider.extent = new Vector(200, 34);
			controlsPane.addChild(buttonCameraFactorSlider);

			var buttonCameraFactorKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_snd_knb.png", ResourceLoader.getImage,
				this.imageResources)
				.toTile());
			buttonCameraFactorKnob.position = new Vector(220, 60);
			buttonCameraFactorKnob.extent = new Vector(196, 34);
			buttonCameraFactorKnob.sliderValue = Settings.touchSettings.buttonJoystickMultiplier / 3;
			buttonCameraFactorKnob.pressedAction = (sender) -> {
				Settings.touchSettings.buttonJoystickMultiplier = buttonCameraFactorKnob.sliderValue * 3;
			}
			controlsPane.addChild(buttonCameraFactorKnob);

			var cameraSwipeExtentLabel = new GuiText(domcasual32);
			cameraSwipeExtentLabel.position = new Vector(12, 110);
			cameraSwipeExtentLabel.extent = new Vector(200, 50);
			cameraSwipeExtentLabel.text.textColor = 0x000000;
			cameraSwipeExtentLabel.text.text = "Camera Swipe Extent:";
			cameraSwipeExtentLabel.justify = Right;
			controlsPane.addChild(cameraSwipeExtentLabel);

			var cameraSwipeExtentSlider = new GuiImage(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources)
				.toTile());
			cameraSwipeExtentSlider.position = new Vector(220, 110);
			cameraSwipeExtentSlider.extent = new Vector(200, 34);
			controlsPane.addChild(cameraSwipeExtentSlider);

			var cameraSwipeExtentKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage,
				this.imageResources)
				.toTile());
			cameraSwipeExtentKnob.position = new Vector(220, 110);
			cameraSwipeExtentKnob.extent = new Vector(196, 34);
			cameraSwipeExtentKnob.sliderValue = (Settings.touchSettings.cameraSwipeExtent - 5) / (35 - 5);
			cameraSwipeExtentKnob.pressedAction = (sender) -> {
				Settings.touchSettings.cameraSwipeExtent = 5 + (35 - 5) * cameraSwipeExtentKnob.sliderValue;
			}
			controlsPane.addChild(cameraSwipeExtentKnob);

			var cameraSensitivityLabel = new GuiText(domcasual32);
			cameraSensitivityLabel.position = new Vector(12, 160);
			cameraSensitivityLabel.extent = new Vector(200, 50);
			cameraSensitivityLabel.text.textColor = 0x000000;
			cameraSensitivityLabel.text.text = "Camera Sensitivity:";
			cameraSensitivityLabel.justify = Right;
			controlsPane.addChild(cameraSensitivityLabel);

			var cameraSensitivitySlider = new GuiImage(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources)
				.toTile());
			cameraSensitivitySlider.position = new Vector(220, 160);
			cameraSensitivitySlider.extent = new Vector(200, 34);
			controlsPane.addChild(cameraSensitivitySlider);

			var cameraSensitivityKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage,
				this.imageResources)
				.toTile());
			cameraSensitivityKnob.position = new Vector(220, 160);
			cameraSensitivityKnob.extent = new Vector(196, 34);
			cameraSensitivityKnob.sliderValue = (Settings.controlsSettings.cameraSensitivity - 0.12) / (1.2 - 0.12);
			cameraSensitivityKnob.pressedAction = (sender) -> {
				Settings.controlsSettings.cameraSensitivity = 0.12 + (1.2 - 0.12) * cameraSensitivityKnob.sliderValue;
			}
			controlsPane.addChild(cameraSensitivityKnob);

			var hideControlsLabel = new GuiText(domcasual32);
			hideControlsLabel.position = new Vector(250, 210);
			hideControlsLabel.extent = new Vector(200, 50);
			hideControlsLabel.text.textColor = 0x000000;
			hideControlsLabel.text.text = "Hide Controls:";
			hideControlsLabel.justify = Left;
			controlsPane.addChild(hideControlsLabel);

			var hideControlsButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
			hideControlsButton.position = new Vector(370, 194);
			hideControlsButton.extent = new Vector(46, 54);
			hideControlsButton.buttonType = Toggle;
			hideControlsButton.pressedAction = (sender) -> {
				Settings.touchSettings.hideControls = hideControlsButton.pressed;
			}
			controlsPane.addChild(hideControlsButton);

			var dynamicJoystickLabel = new GuiText(domcasual32);
			dynamicJoystickLabel.position = new Vector(32, 210);
			dynamicJoystickLabel.extent = new Vector(200, 50);
			dynamicJoystickLabel.text.textColor = 0x000000;
			dynamicJoystickLabel.text.text = "Dynamic Joystick:";
			dynamicJoystickLabel.justify = Left;
			controlsPane.addChild(dynamicJoystickLabel);

			var dynamicJoystickButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
			dynamicJoystickButton.position = new Vector(178, 194);
			dynamicJoystickButton.extent = new Vector(46, 54);
			dynamicJoystickButton.buttonType = Toggle;
			dynamicJoystickButton.pressedAction = (sender) -> {
				Settings.touchSettings.dynamicJoystick = dynamicJoystickButton.pressed;
			}
			controlsPane.addChild(dynamicJoystickButton);

			var touchControlsTxt = new GuiText(domcasual32);
			touchControlsTxt.text.text = "Touch Controls:";
			touchControlsTxt.text.textColor = 0x000000;
			touchControlsTxt.justify = Right;
			touchControlsTxt.position = new Vector(12, 260);
			touchControlsTxt.extent = new Vector(200, 40);

			var touchControlsEdit = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_dwn"), domcasual24);
			touchControlsEdit.position = new Vector(82, 300);
			touchControlsEdit.txtCtrl.text.text = "Edit";
			touchControlsEdit.setExtent(new Vector(109, 39));
			touchControlsEdit.pressedAction = (sender) -> {
				MarbleGame.canvas.setContent(new TouchCtrlsEditGui(), () -> new TouchCtrlsEditGui());
			}

			controlsPane.addChild(touchControlsTxt);
			controlsPane.addChild(touchControlsEdit);
		} else {
			// The keyboard and mouse rebinding panels are gone in this fork, so the only
			// control worth exposing here is how fast the right stick swings the camera.
			var padSensitivityLabel = new GuiText(domcasual32);
			padSensitivityLabel.position = new Vector(0, 120);
			padSensitivityLabel.extent = new Vector(459, 50);
			padSensitivityLabel.text.textColor = 0x000000;
			padSensitivityLabel.text.text = "Camera Sensitivity: (" + Math.round(Settings.gamepadSettings.cameraSensitivity * 100) / 100 + ")";
			padSensitivityLabel.justify = Center;
			controlsPane.addChild(padSensitivityLabel);

			var padSensitivitySlider = new GuiImage(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources)
				.toTile());
			padSensitivitySlider.position = new Vector(130, 165);
			padSensitivitySlider.extent = new Vector(200, 34);
			controlsPane.addChild(padSensitivitySlider);

			var padSensitivityKnob = new GuiSlider(ResourceLoader.getResource("data/ui/options/aud_mus_knb.png", ResourceLoader.getImage, this.imageResources)
				.toTile());
			padSensitivityKnob.position = new Vector(130, 165);
			padSensitivityKnob.extent = new Vector(196, 34);
			padSensitivityKnob.controllerSteps = 28;
			padSensitivityKnob.sliderValue = (Settings.gamepadSettings.cameraSensitivity - 0.2) / (3.0 - 0.2);
			padSensitivityKnob.pressedAction = (sender) -> {
				Settings.gamepadSettings.cameraSensitivity = 0.2 + (3.0 - 0.2) * padSensitivityKnob.sliderValue;
				padSensitivityLabel.text.text = "Camera Sensitivity: (" + Math.round(Settings.gamepadSettings.cameraSensitivity * 100) / 100 + ")";
			}
			controlsPane.addChild(padSensitivityKnob);
		}

		// INVISIBLE BUTTON SHIT
		var audioTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		audioTabBtn.position = new Vector(213, 39);
		audioTabBtn.extent = new Vector(92, 42);
		audioTabBtn.pressedAction = (sender) -> setTab("Audio");
		mainPane.addChild(audioTabBtn);

		var controlsTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		controlsTabBtn.position = new Vector(331, 24);
		controlsTabBtn.extent = new Vector(117, 42);
		controlsTabBtn.pressedAction = (sender) -> setTab("Controls");
		mainPane.addChild(controlsTabBtn);

		var graphicsTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		graphicsTabBtn.position = new Vector(70, 48);
		graphicsTabBtn.extent = new Vector(117, 48);
		graphicsTabBtn.pressedAction = (sender) -> setTab("Graphics");
		mainPane.addChild(graphicsTabBtn);

		var rewindTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		rewindTabBtn.position = new Vector(480, 76);
		rewindTabBtn.extent = new Vector(48, 160);
		rewindTabBtn.pressedAction = (sender) -> setTab("Rewind");
		mainPane.addChild(rewindTabBtn);


		// LB/RB cycle the tab row, the same set setTab understands
		var tabOrder = ["Graphics", "Audio", "Controls", "Rewind"];
		var currentTab = "Graphics";
		this.controllerShoulderAction = (dir:Int) -> {
			var i = tabOrder.indexOf(currentTab) + dir;
			if (i < 0)
				i = tabOrder.length - 1;
			if (i >= tabOrder.length)
				i = 0;
			setTab(tabOrder[i]);
		};

		setTab = function(tab:String) {
			currentTab = tab;
			tabs.removeChild(audioTab);
			tabs.removeChild(controlsTab);
			tabs.removeChild(rewindTab);
			tabs.removeChild(boxFrame);
			tabs.removeChild(graphicsTab);
			mainPane.removeChild(graphicsPane);
			mainPane.removeChild(audioPane);
			mainPane.removeChild(controlsPane);
			mainPane.removeChild(rewindPane);
			if (tab == "Graphics") {
				tabs.addChild(audioTab);
				tabs.addChild(controlsTab);
				tabs.addChild(rewindTab);
				tabs.addChild(boxFrame);
				tabs.addChild(graphicsTab);
				mainPane.addChild(graphicsPane);
			}
			if (tab == "Audio") {
				tabs.addChild(graphicsTab);
				tabs.addChild(controlsTab);
				tabs.addChild(rewindTab);
				tabs.addChild(boxFrame);
				tabs.addChild(audioTab);
				mainPane.addChild(audioPane);
			}
			if (tab == "Controls") {
				tabs.addChild(audioTab);
				tabs.addChild(graphicsTab);
				tabs.addChild(rewindTab);
				tabs.addChild(boxFrame);
				tabs.addChild(controlsTab);
				mainPane.addChild(controlsPane);
			}
			if (tab == "Rewind") {
				tabs.addChild(audioTab);
				tabs.addChild(graphicsTab);
				tabs.addChild(controlsTab);
				tabs.addChild(boxFrame);
				tabs.addChild(rewindTab);
				mainPane.addChild(rewindPane);
			}
			this.render(MarbleGame.canvas.scene2d);
		}
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		if (musicSliderFunc != null)
			musicSliderFunc(dt, mouseState);
	}
}
