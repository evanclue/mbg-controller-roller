package gui;

import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MainMenuGui extends GuiImage {
	public function new(?returnFocus:String) {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		// Single column of buttons, so left and right have nowhere sensible to go
		this.controllerVerticalOnly = true;

		var homebase = new GuiImage(ResourceLoader.getResource("data/ui/home/homegui.png", ResourceLoader.getImage, this.imageResources).toTile());
		homebase.horizSizing = Center;
		homebase.vertSizing = Center;
		homebase.extent = new Vector(349, 477);
		homebase.position = new Vector(145, 1);
		this.addChild(homebase);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadStaticButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var playButton = new GuiButton(loadButtonImages("data/ui/home/play"));
		playButton.position = new Vector(50, 113);
		playButton.extent = new Vector(270, 95);
		playButton.controllerTipOffset = new Vector(242, 73);
		playButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new PlayMissionGui(), () -> new PlayMissionGui());
		}
		homebase.addChild(playButton);

		var helpButton = new GuiButton(loadButtonImages("data/ui/home/help"));
		helpButton.position = new Vector(59, 200);
		helpButton.extent = new Vector(242, 84);
		helpButton.controllerTipOffset = new Vector(219, 57);
		helpButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new HelpCreditsGui(), () -> new HelpCreditsGui());
		}
		homebase.addChild(helpButton);

		var optionsButton = new GuiButton(loadButtonImages("data/ui/home/options"));
		optionsButton.position = new Vector(55, 279);
		optionsButton.extent = new Vector(253, 83);
		optionsButton.controllerTipOffset = new Vector(230, 63);
		optionsButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsDlg(), () -> new OptionsDlg());
		}
		homebase.addChild(optionsButton);

		var exitButton = new GuiButton(loadButtonImages("data/ui/home/exit"));
		exitButton.position = new Vector(82, 358);
		exitButton.extent = new Vector(203, 88);
		exitButton.controllerTipOffset = new Vector(178, 51);
		exitButton.pressedAction = (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		};
		homebase.addChild(exitButton);

		// Preserve the user's place when a submenu returns here. Fresh visits still use
		// the normal first target (Play).
		this.controllerDefaultFocus = switch (returnFocus) {
			case "Help": helpButton;
			case "Options": optionsButton;
			default: playButton;
		};

		#if js
		var mbp = new GuiButton(loadStaticButtonImages("data/ui/icon_mbp"));
		mbp.horizSizing = Right;
		mbp.vertSizing = Top;
		mbp.position = new Vector(0, 380);
		mbp.extent = new Vector(76, 76);
		mbp.pressedAction = (sender) -> {
			js.Browser.window.open("https://marbleblast.randomityguy.me");
		}
		this.addChild(mbp);

		var mbu = new GuiButton(loadStaticButtonImages("data/ui/icon_mbu"));
		mbu.horizSizing = Right;
		mbu.vertSizing = Top;
		mbu.position = new Vector(76, 380);
		mbu.extent = new Vector(76, 76);
		mbu.pressedAction = (sender) -> {
			js.Browser.window.open("https://marbleblastultra.randomityguy.me");
		}
		this.addChild(mbu);

		var discord = new GuiButton(loadStaticButtonImages("data/ui/discord"));
		discord.horizSizing = Right;
		discord.vertSizing = Top;
		discord.position = new Vector(0, 320);
		discord.extent = new Vector(152, 60);
		discord.pressedAction = (sender) -> {
			js.Browser.window.open("https://discord.gg/q4JdnRbVhF");
		}
		this.addChild(discord);
		#end

	}
}
