package gui;

import src.Console;
import src.MarbleGame;
import h3d.Vector;
import h2d.Scene;
import gui.GuiControl.MouseState;

@:publicFields
class Canvas extends GuiControl {
	var scene2d:Scene;
	var marbleGame:MarbleGame;
	var content:GuiControl;

	public function new(scene, marbleGame:MarbleGame) {
		super();
		Console.log("Creating canvas");
		this.scene2d = scene;
		this.marbleGame = marbleGame;

		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;
	}

	/**
		Set by screens that can be thrown away and built again from nothing, which lets
		`rebuildContent` re-create them after `Settings.uiScale` changes. Screens that carry
		state worth keeping simply leave this null and keep their old font sizes.
	**/
	var contentFactory:Void->GuiControl = null;

	/** Gamepad menu highlight, created lazily once resources are available. **/
	var cursor:ControllerCursor = null;

	public function setContent(content:GuiControl, ?factory:Void->GuiControl) {
		this.dispose();
		this.content = content;
		this.contentFactory = factory;
		this.addChild(content);
		this.render(scene2d);
	}

	/**
		Rebuild the current screen so it picks up the current `Settings.uiScale`. Fonts bake
		their size in at construction, so re-laying out the existing controls is not enough.
	**/
	public function rebuildContent() {
		if (contentFactory == null)
			return false;
		var factory = contentFactory;
		setContent(factory(), factory);
		return true;
	}

	public function pushDialog(content:GuiControl) {
		this.content.onDormant(scene2d);
		this.addChild(content);
		content.render(scene2d, this._flow);
	}

	public function popDialog(content:GuiControl, dispose:Bool = true) {
		if (dispose)
			content.dispose();
		this.removeChild(content);
		this.render(scene2d);
	}

	public function clearContent() {
		this.dispose();
		this.render(scene2d);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		// Update ONLY the last one
		if (children.length > 0) {
			children[children.length - 1].update(dt, mouseState);
		}
		if (cursor == null)
			cursor = new ControllerCursor(scene2d);
		// The topmost child is the active screen, so a pushed dialog takes the highlight
		cursor.update(dt, children.length > 0 ? children[children.length - 1] : null);
	}

	public override function renderEngine(e:h3d.Engine) {
		if (children.length > 0) {
			children[children.length - 1].renderEngine(e);
		}
	}
}
