package src;

/**
	Turns the game's keyboard worded control prompts into controller ones while a gamepad
	is connected. Labels follow the Xbox layout and are read back out of
	`Settings.gamepadSettings`, so a remap is reflected in what the prompts say.
**/
class ControlPrompts {
	public static function useController():Bool {
		return Gamepad.gamepad.connected;
	}

	/** Internal pad button ids to the face labels an Xbox pad actually prints. **/
	static function buttonLabel(id:String):String {
		return switch (id) {
			case "A": "A";
			case "B": "B";
			case "X": "X";
			case "Y": "Y";
			case "LB": "LB";
			case "RB": "RB";
			case "LT": "LT";
			case "RT": "RT";
			case "back": "View";
			case "start": "Menu";
			case "analogClick": "the left stick";
			case "ranalogClick": "the right stick";
			case "dpadUp": "D-pad up";
			case "dpadDown": "D-pad down";
			case "dpadLeft": "D-pad left";
			case "dpadRight": "D-pad right";
			case _: id;
		};
	}

	static function firstLabel(binds:Array<String>, fallback:String):String {
		if (binds == null || binds.length == 0)
			return fallback;
		return buttonLabel(binds[0]);
	}

	/**
		Controller wording for a `<func:bind x>` token, or null when there is no pad and the
		caller should fall back to the keyboard name.
	**/
	public static function bindLabel(bind:String):String {
		if (!useController())
			return null;
		var settings = Settings.gamepadSettings;
		return switch (bind) {
			// Movement and camera are sticks rather than buttons
			case "moveforward", "movebackward", "moveleft", "moveright": "the left stick";
			case "panup", "pandown", "turnleft", "turnright", "freelook": "the right stick";
			case "jump": firstLabel(settings.jump, "A");
			case "mousefire": firstLabel(settings.powerup, "B");
			case "useblast": firstLabel(settings.blast, "X");
			case "respawn": firstLabel(settings.respawn, "View");
			case "rewind": firstLabel(settings.rewind, "Y");
			case _: null;
		};
	}

	/**
		Whole sentence replacements for the in game prompts, needed because "press the left
		stick to roll forward" is wrong - a stick is pushed, not pressed. Button prompts are
		left alone, since "Press A to Jump!" already reads correctly once the token expands.
	**/
	public static function rewrite(text:String):String {
		if (!useController())
			return text;
		if (text.indexOf("<func:bind moveforward>") != -1)
			return "Push the left stick forward to roll the marble!";
		if (text.indexOf("<func:bind movebackward>") != -1)
			return "Pull the left stick back to roll the marble backward!";
		if (text.indexOf("<func:bind moveleft>") != -1)
			return "Push the left stick left to roll the marble left!";
		if (text.indexOf("<func:bind moveright>") != -1)
			return "Push the left stick right to roll the marble right!";
		return text;
	}
}
