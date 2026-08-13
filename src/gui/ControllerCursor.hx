package gui;

import h2d.Bitmap;
import h2d.Scene;
import h3d.Vector;
import src.AudioManager;
import src.Gamepad;
import src.ResourceLoader;
import src.Settings;

/**
	Gamepad driven menu highlight. Walks the active screen for `GuiButton`s, moves the
	selection with the stick or dpad, draws a pointer snapped to the bottom right of the
	highlighted button and forces that button to show its hover bitmap.
**/
class ControllerCursor {
	/**
		Size the pointer is drawn at when uiScale is 1, keeping the art's 140x192 aspect.
	**/
	static inline var CURSOR_WIDTH = 46;

	static inline var CURSOR_HEIGHT = 63;

	/**
		Where the fingertip sits inside the art, as a fraction of it. Measured from
		fingerpointer.png: the tip is the topmost opaque pixel, at x 18.5/140 and y 0/192.
		This is a property of the image, not of any button, so it never needs adjusting per
		button - only if the art itself is redrawn.
	**/
	static inline var TIP_FRAC_X = 0.132;

	static inline var TIP_FRAC_Y = 0.0;

	/**
		How far inside the button's bottom right corner the fingertip is planted, in
		unscaled gui units. This is the only placement value to tune, and it behaves the
		same on a tiny arrow as on a wide play button.
	**/
	static inline var TIP_OVERLAP_X = 6;

	static inline var TIP_OVERLAP_Y = 6;

	/** Fraction of the remaining distance covered per second, ie. exponential ease out. **/
	static inline var TWEEN_RATE = 22.0;

	/** Stick deflection needed to count as a direction press. **/
	static inline var STICK_THRESHOLD = 0.5;

	/** Seconds held before a direction starts repeating, and the repeat interval. **/
	static inline var REPEAT_DELAY = 0.42;

	static inline var REPEAT_INTERVAL = 0.14;

	var bmp:Bitmap;
	var scene2d:Scene;

	var focused:GuiControl;
	var focusedScreen:GuiControl;

	var pos:Vector = new Vector();
	var targetPos:Vector = new Vector();
	var hasPos:Bool = false;

	var heldDir:Int = 0;
	var heldTime:Float = 0;
	var repeatTime:Float = 0;

	var confirmHeld:Bool = false;

	public function new(scene2d:Scene) {
		this.scene2d = scene2d;
		var tile = ResourceLoader.getImage("data/ui/fingerpointer.png").resource.toTile();
		// The pointer is smooth line art rather than pixel art, and it sits at arbitrary
		// tweened subpixel positions, so it wants filtering unlike the rest of the ui
		var tex = tile.getTexture();
		if (tex != null)
			tex.filter = Linear;
		this.bmp = new Bitmap(tile, scene2d);
		this.bmp.visible = false;
	}

	public function dispose() {
		if (bmp != null)
			bmp.remove();
	}

	/**
		Collect every button the highlight may land on, in tree order, so the first one is
		the natural default (the play button on the main menu).
	**/
	function collect(ctrl:GuiControl, into:Array<GuiControl>) {
		if (ctrl == null)
			return;
		for (c in ctrl.children) {
			if (c.isControllerTarget())
				into.push(c);
			collect(c, into);
		}
	}

	function centerOf(b:GuiControl) {
		var r = b.getRenderRectangle();
		return new Vector(r.position.x + r.extent.x / 2, r.position.y + r.extent.y / 2);
	}

	/**
		Pick the nearest button in the given direction. Distance along the travel axis
		dominates, with the perpendicular offset weighted heavily so the highlight prefers
		what is genuinely next in line rather than something far off to the side.
	**/
	function findAdjacent(buttons:Array<GuiControl>, dir:Int):GuiControl {
		if (focused == null)
			return buttons.length > 0 ? buttons[0] : null;
		// An explicit neighbour wins over the spatial search, as long as it is currently
		// selectable
		var forced = focused.controllerNavOverride(dir);
		if (forced != null && buttons.indexOf(forced) != -1)
			return forced;
		var from = centerOf(focused);
		var best:GuiControl = null;
		var bestScore = 0.0;
		for (b in buttons) {
			if (b == focused)
				continue;
			var to = centerOf(b);
			var dx = to.x - from.x;
			var dy = to.y - from.y;
			var along = switch (dir) {
				case 0: -dy; // up
				case 1: dy; // down
				case 2: -dx; // left
				case _: dx; // right
			};
			if (along <= 1)
				continue;
			var across = (dir == 0 || dir == 1) ? Math.abs(dx) : Math.abs(dy);
			var score = along + across * 3;
			if (best == null || score < bestScore) {
				best = b;
				bestScore = score;
			}
		}
		return best;
	}

	function readDirection():Int {
		if (Gamepad.isDown(["dpadUp"]))
			return 0;
		if (Gamepad.isDown(["dpadDown"]))
			return 1;
		if (Gamepad.isDown(["dpadLeft"]))
			return 2;
		if (Gamepad.isDown(["dpadRight"]))
			return 3;
		var x = Gamepad.getAxis("analogX");
		var y = Gamepad.getAxis("analogY");
		if (Math.abs(y) > Math.abs(x)) {
			if (y < -STICK_THRESHOLD)
				return 0;
			if (y > STICK_THRESHOLD)
				return 1;
		} else {
			if (x < -STICK_THRESHOLD)
				return 2;
			if (x > STICK_THRESHOLD)
				return 3;
		}
		return -1;
	}

	function setFocus(b:GuiControl, playSound:Bool) {
		if (focused == b)
			return;
		if (focused != null) {
			focused.controllerFocused = false;
			focused.controllerPressed = false;
		}
		focused = b;
		if (focused != null) {
			focused.controllerFocused = true;
			if (playSound)
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonover.wav", ResourceLoader.getAudio, focused.soundResources));
		}
	}

	public function update(dt:Float, screen:GuiControl) {
		if (!Gamepad.gamepad.connected || screen == null) {
			if (focused != null)
				setFocus(null, false);
			bmp.visible = false;
			return;
		}

		var buttons = [];
		collect(screen, buttons);
		// A pushed dialog is its own screen, so the highlight restarts rather than pointing
		// at a button that is no longer reachable
		if (screen != focusedScreen) {
			focusedScreen = screen;
			setFocus(null, false);
			hasPos = false;
		}
		if (buttons.length == 0) {
			if (focused != null)
				setFocus(null, false);
			bmp.visible = false;
			return;
		}
		if (focused == null || buttons.indexOf(focused) == -1)
			setFocus(buttons[0], false);

		// Directional movement, with a hold to repeat so a held stick walks the menu
		var dir = readDirection();
		// A single column screen ignores left and right entirely
		if (screen.controllerVerticalOnly && (dir == 2 || dir == 3))
			dir = -1;
		if (dir == -1) {
			heldDir = -1;
			heldTime = 0;
			repeatTime = 0;
		} else {
			var moved = false;
			if (dir != heldDir) {
				heldDir = dir;
				heldTime = 0;
				repeatTime = REPEAT_DELAY;
				moved = true;
			} else {
				heldTime += dt;
				if (heldTime >= repeatTime) {
					repeatTime = heldTime + REPEAT_INTERVAL;
					moved = true;
				}
			}
			if (moved) {
				var next = findAdjacent(buttons, dir);
				if (next != null)
					setFocus(next, true);
			}
		}

		// Confirm. A is handled here for every button rather than by per button
		// accelerators, so exactly one system owns it
		var confirm = Gamepad.isDown(["A"]);
		if (focused != null)
			focused.controllerPressed = confirm;
		if (!confirm && confirmHeld && focused != null) {
			var target = focused;
			target.controllerPressed = false;
			target.controllerActivate();
		}
		confirmHeld = confirm;

		// The focused button may have gone away with the screen it belonged to
		if (focused == null) {
			bmp.visible = false;
			return;
		}

		var rect = focused.getRenderRectangle();
		var width = CURSOR_WIDTH * Settings.uiScale;
		var height = CURSOR_HEIGHT * Settings.uiScale;

		// Where the fingertip itself should land, either the spot measured for this button
		// or the generic bottom right corner
		var tipX:Float;
		var tipY:Float;
		if (focused.controllerTipOffset != null) {
			tipX = rect.position.x + focused.controllerTipOffset.x * Settings.uiScale;
			tipY = rect.position.y + focused.controllerTipOffset.y * Settings.uiScale;
		} else {
			tipX = rect.position.x + rect.extent.x - TIP_OVERLAP_X * Settings.uiScale;
			tipY = rect.position.y + rect.extent.y - TIP_OVERLAP_Y * Settings.uiScale;
		}

		// Back the bitmap off by where the tip sits within the art
		targetPos.x = tipX - TIP_FRAC_X * width;
		targetPos.y = tipY - TIP_FRAC_Y * height;

		if (!hasPos) {
			pos.x = targetPos.x;
			pos.y = targetPos.y;
			hasPos = true;
		} else {
			// Framerate independent exponential ease toward the target
			var t = 1 - Math.exp(-TWEEN_RATE * dt);
			pos.x += (targetPos.x - pos.x) * t;
			pos.y += (targetPos.y - pos.y) * t;
		}

		bmp.visible = true;
		bmp.x = pos.x;
		bmp.y = pos.y;
		bmp.width = width;
		bmp.height = height;

		// Keep the pointer above the gui, which re-adds its flow to the scene on every render
		if (scene2d.getChildAt(scene2d.numChildren - 1) != bmp)
			scene2d.addChild(bmp);
	}
}
