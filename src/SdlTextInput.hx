package src;

/**
	SDL keeps text input enabled for the whole lifetime of the window, which makes
	Wayland compositors route keystrokes through the active input method before the
	application sees them. Plasma's virtual keyboard (`plasma-keyboard`) uses that to
	implement its long-press character picker, so holding a letter that has accented
	variants - A, S, D, E, ... - opens the picker and the key event never reaches the
	game, while letters without variants (W, Q, ...) still work. Keep text input off
	unless something is actually being typed into.
**/
class SdlTextInput {
	static var enabled:Null<Bool> = null;

	public static function set(enable:Bool) {
		if (enabled == enable)
			return;
		enabled = enable;
		#if (hl && hlsdl)
		textInput(enable);
		#end
	}

	#if (hl && hlsdl)
	@:hlNative("sdl", "text_input")
	static function textInput(enable:Bool):Void {}
	#end
}
