package gui;

import h2d.Scene;
import hxd.snd.Channel;
import hxd.res.Sound;
import hxd.Key;
import gui.GuiControl.MouseState;
import src.Util;
import src.Settings;

class GuiSlider extends GuiImage {
	public var sliderValue:Float = 0;

	public var slidingSound:Channel;
	public var enabled:Bool = true;

	/**
		How many discrete notches the range is divided into for gamepad adjustment, so one
		nudge moves one unit of whatever the slider represents.
	**/
	public var controllerSteps:Int = 20;

	override function isControllerTarget():Bool {
		return controllerFocusable && enabled && bmp != null && bmp.visible;
	}

	// Left and right drive the value, so they must not move the highlight instead
	override function controllerConsumesHorizontal():Bool {
		return true;
	}

	override function controllerAdjust(dir:Int):Void {
		if (!enabled)
			return;
		var step = 1.0 / (controllerSteps < 1 ? 1 : controllerSteps);
		sliderValue = Util.clamp(sliderValue + (dir == 3 ? step : -step), 0, 1);
		if (this.pressedAction != null)
			this.pressedAction(new GuiEvent(this));
	}

	// A does nothing on a slider, it is adjusted rather than activated
	override function controllerActivate():Void {}

	public override function update(dt:Float, mouseState:MouseState) {
		var renderRect = getHitTestRect();
		if (renderRect.inRect(mouseState.position) && enabled) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				sliderValue = (mouseState.position.x - renderRect.position.x - bmp.width / 2) / renderRect.extent.x;
				sliderValue = Util.clamp(sliderValue, 0, 1);

				if (this.pressedAction != null)
					this.pressedAction(new GuiEvent(this));

				if (slidingSound != null)
					slidingSound.pause = false;
			}
		} else if (slidingSound != null)
			slidingSound.pause = true;
		var off = getOffsetFromParent();
		this.bmp.x = off.x + renderRect.extent.x * sliderValue;
		this.bmp.x = Util.clamp(this.bmp.x, off.x, off.x + renderRect.extent.x - bmp.width / 2);
		this.bmp.width = this.bmp.tile.width * Settings.uiScale;
		super.update(dt, mouseState);
	}
}
