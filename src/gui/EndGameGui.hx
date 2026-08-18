package gui;

import src.MarbleGame;
import src.Settings.Score;
import src.Settings.Settings;
import src.Mission;
import src.MissionList;
import h2d.filter.DropShadow;
import h2d.filter.Outline;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.TimeState;
import src.Util;

class EndGameGui extends GuiControl {
	// Drawn at the panel art's own 610x351 ratio
	static inline var PANEL_WIDTH = 700;
	static inline var PANEL_HEIGHT = 403;

	// Text blocks are inset from the panel edge and spread between these two rows
	static inline var TEXT_MARGIN = 35;
	static inline var CONTENT_TOP = 24.0;
	static inline var CONTENT_BOTTOM = 304.0;

	static inline var BUTTON_ROW = 318;

	// The gameplay timer, rebuilt here: 43x55 tiles whose ink runs from 28 to 228 inside
	// the 234 wide block, centred on 26.5
	static inline var TIMER_HEIGHT = 55;
	static inline var TIMER_INK_START = 28.0;
	static inline var TIMER_INK_END = 228.0;
	static inline var TIMER_INK_MIDDLE = 26.5;
	static inline var TIMER_LABEL_GAP = 18.0;

	// Space between a time and the mark that follows it
	static inline var MARK_GAP = 8.0;

	// The lines of the elapsed - bonus = final equation are kept tight against each other
	static inline var EQUATION_LINE_GAP = 4.0;

	var mission:Mission;

	var scoreSubmitted:Bool = false;

	public function new(continueFunc:GuiControl->Void, restartFunc:GuiControl->Void, mission:Mission, timeState:TimeState,
			?nextFunc:GuiControl->Void) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);
		this.mission = mission;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		// The panel art is 610x351, so it is drawn at that ratio rather than stretched tall
		var pg = new GuiImage(ResourceLoader.getResource("data/ui/play/playgui.png", ResourceLoader.getImage, this.imageResources).toTile());
		pg.horizSizing = Center;
		pg.vertSizing = Center;
		pg.position = new Vector(0, 0);
		pg.extent = new Vector(PANEL_WIDTH, PANEL_HEIGHT);

		function loadButtonImagesDisabled(path:String) {
			var tiles = loadButtonImages(path);
			tiles.push(ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile());
			return tiles;
		}

		// Returns to the level select, sat midway between replay and next
		var continueButton = new GuiButton(loadButtonImages("data/ui/endgame/continue"));
		continueButton.horizSizing = Right;
		continueButton.vertSizing = Bottom;
		continueButton.position = new Vector(309, BUTTON_ROW + 1);
		continueButton.extent = new Vector(123, 58);
		continueButton.controllerTipOffset = new Vector(112, 43);
		continueButton.accelerator = hxd.Key.ENTER;
		continueButton.pressedAction = (e) -> continueFunc(this);

		// Straight into the following level, so a run can be played back to back
		var nextMission = MissionList.getNextMission(mission);
		var nextButton = new GuiButton(loadButtonImagesDisabled("data/ui/endgame/next"));
		nextButton.horizSizing = Right;
		nextButton.vertSizing = Bottom;
		nextButton.position = new Vector(565, BUTTON_ROW);
		nextButton.extent = new Vector(75, 60);
		nextButton.controllerTipOffset = new Vector(56, 41);
		nextButton.disabled = nextMission == null || nextFunc == null;
		nextButton.pressedAction = (e) -> {
			if (nextFunc != null)
				nextFunc(this);
		};

		var restartButton = new GuiButton(loadButtonImages("data/ui/endgame/replay"));
		restartButton.horizSizing = Right;
		restartButton.vertSizing = Bottom;
		restartButton.position = new Vector(60, BUTTON_ROW + 1);
		restartButton.extent = new Vector(116, 58);
		restartButton.controllerTipOffset = new Vector(99, 40);
		restartButton.gamepadAccelerator = ["B"];
		restartButton.pressedAction = (e) -> restartFunc(this);

		// Carrying on to the next level is the common case after finishing one
		this.controllerDefaultFocus = nextButton;

		function setButtonStates(enabled:Bool) {
			continueButton.disabled = !enabled;
			restartButton.disabled = !enabled;
			nextButton.disabled = !enabled || nextMission == null || nextFunc == null;
		}

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);
		var expo32 = expo50b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32;
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				case "Expo32":
					return expo32;
				default:
					return null;
			}
		}

		// The gold badge is printed inline in the status line, and the level's targets carry
		// a mark saying whether this run met them
		var goldTile = ResourceLoader.getResource("data/ui/game/gold.png", ResourceLoader.getImage, this.imageResources).toTile();
		var goldTex = goldTile.getTexture();
		if (goldTex != null)
			goldTex.filter = Linear;
		var goldHeight = expo50.lineHeight * 0.95;
		goldTile.scaleToSize((270 / 122) * goldHeight, goldHeight);
		// Images sit on the baseline, which rides high against a badge this tall
		goldTile.dy = expo50.lineHeight * 0.22;

		// 41x39 marks, sized against the row they are printed on
		function loadMark(path:String) {
			var tile = ResourceLoader.getResource(path, ResourceLoader.getImage, this.imageResources).toTile();
			var tex = tile.getTexture();
			if (tex != null)
				tex.filter = Linear;
			var height = domcasual24.lineHeight * 0.85;
			tile.scaleToSize((41 / 39) * height, height);
			return tile;
		}
		var checkMark = loadMark("data/ui/endgame/check.png");
		var crossMark = loadMark("data/ui/endgame/cross.png");

		function loadInlineImage(name:String) {
			return goldTile;
		}

		// Fonts are built against the ui scale, while positions are in the panel's own
		// space, so heights have to come back out of that scale to lay blocks out
		function layoutHeight(font:h2d.Font)
			return font.lineHeight / Settings.uiScale;

		function centeredText(font:h2d.Font, height:Float, ?parent:GuiControl) {
			var ctrl = new GuiMLText(font, mlFontLoader);
			ctrl.justify = Center;
			ctrl.text.loadImage = loadInlineImage;
			ctrl.text.lineHeightMode = TextOnly;
			ctrl.position = new Vector(TEXT_MARGIN, 0);
			ctrl.extent = new Vector(PANEL_WIDTH - 2 * TEXT_MARGIN, height);
			(parent == null ? pg : parent).addChild(ctrl);
			return ctrl;
		}

		// The time rows are printed the way the hud prints them, down to the outline, so the
		// panel reads as the same screen the run was played on. The mark is a sibling of the
		// text rather than an inline image, since the outline filter would otherwise wrap the
		// art as well and the check and cross carry their own outline already.
		function hudRow(color:Int, text:String, ?mark:h2d.Tile, ?parent:GuiControl) {
			var rowHeight = layoutHeight(domcasual24);
			var ctrl = centeredText(domcasual24, rowHeight, parent);
			ctrl.text.textColor = color;
			ctrl.text.text = text;
			ctrl.text.filter = new Outline(Math.max(1, Math.round(Settings.uiScale)), 0x000000);
			if (mark != null) {
				var markWidth = mark.width / Settings.uiScale;
				var markHeight = mark.height / Settings.uiScale;
				var textWidth = ctrl.text.textWidth / Settings.uiScale;
				// Shift the line so the text and its mark sit centred as one unit
				ctrl.position.x -= (markWidth + MARK_GAP) / 2;
				var img = new GuiImage(mark);
				// GuiImage forces nearest sampling, which these downscaled marks do not want
				var markTex = mark.getTexture();
				if (markTex != null)
					markTex.filter = Linear;
				img.position = new Vector((ctrl.extent.x + textWidth) / 2 + MARK_GAP, rowHeight * 0.55 - markHeight / 2);
				img.extent = new Vector(markWidth, markHeight);
				ctrl.addChild(img);
			}
			return ctrl;
		}

		var shadowDistance = GuiControl.textShadowDistance();
		var blocks:Array<{ctrl:GuiControl, height:Float}> = [];

		var elapsedTime = Math.max(timeState.currentAttemptTime - 3.5, 0);
		var finalTime = timeState.gameplayClock;
		var elapsedMs = Std.int(elapsedTime * 1000);
		var finalMs = Std.int(finalTime * 1000);
		var bonusMs = elapsedMs - finalMs > 0 ? elapsedMs - finalMs : 0;

		// The digits and the lines above them are both printed out of whole milliseconds, using
		// the same decomposition Util.formatTime uses, so the equation adds up on screen and the
		// panel and the hud agree
		function timeDigits(ms:Int) {
			var minutes = Std.int(ms / 60000);
			var seconds = Std.int(ms / 1000) % 60;
			return [
				Std.int(minutes / 10) % 10,
				minutes % 10,
				Std.int(seconds / 10),
				seconds % 10,
				Std.int(ms / 100) % 10,
				Std.int(ms / 10) % 10,
				ms % 10
			];
		}
		function formatMs(ms:Int) {
			var d = timeDigits(ms);
			return '${d[0]}${d[1]}:${d[2]}${d[3]}.${d[4]}${d[5]}${d[6]}';
		}

		// ---- The time the run is judged on, drawn with the gameplay timer's own digits. Levels
		// that hand out bonus time subtract it from the elapsed time to get there, so those show
		// the working above the result rather than the result alone.
		var timeGroup = new GuiControl();
		timeGroup.position = new Vector(0, 0);
		timeGroup.extent = new Vector(PANEL_WIDTH, 0);

		var groupY = 0.0;
		if (bonusMs > 0) {
			var rowHeight = layoutHeight(domcasual24);
			var elapsedLine = hudRow(0xFFFFFF, 'Elapsed Time: ${formatMs(elapsedMs)}', null, timeGroup);
			elapsedLine.position.y = groupY;
			groupY += rowHeight + EQUATION_LINE_GAP;
			var bonusLine = hudRow(0xFFFFFF, '- Bonus Time: ${formatMs(bonusMs)}', null, timeGroup);
			bonusLine.position.y = groupY;
			groupY += rowHeight + EQUATION_LINE_GAP;
		}

		var finalRow = new GuiControl();
		finalRow.extent = new Vector(0, TIMER_HEIGHT);
		finalRow.position = new Vector(0, groupY);

		var finalLabel = new GuiText(expo50);
		finalLabel.text.text = "Final Time:";
		finalLabel.text.textColor = 0xFFFF00;
		finalLabel.text.filter = new DropShadow(shadowDistance, 0.785, 0, 1, 0, 0.4, 1, true);
		// Centred against the digits, which sit inset in their own tiles
		finalLabel.position = new Vector(0, TIMER_INK_MIDDLE - layoutHeight(expo50) / 2);
		finalLabel.extent = new Vector(0, layoutHeight(expo50));
		finalRow.addChild(finalLabel);

		var labelWidth = finalLabel.text.textWidth / Settings.uiScale;
		var rowWidth = labelWidth + TIMER_LABEL_GAP + (TIMER_INK_END - TIMER_INK_START);
		finalRow.position.x = (PANEL_WIDTH - rowWidth) / 2;
		finalRow.extent.x = rowWidth;
		// The digits are laid out in the timer's own space, which starts left of its ink
		var digitsX = labelWidth + TIMER_LABEL_GAP - TIMER_INK_START;

		function timerTile(name:String) {
			return ResourceLoader.getResource('data/ui/game/numbers/${name}.png', ResourceLoader.getImage, this.imageResources).toTile();
		}

		function placeTimerPart(tile:h2d.Tile, x:Float) {
			var part = new GuiImage(tile);
			part.position = new Vector(digitsX + x, 0);
			part.extent = new Vector(43, TIMER_HEIGHT);
			finalRow.addChild(part);
		}

		var digits = timeDigits(finalMs);
		var digitOffsets = [23, 47, 83, 107, 143, 167, 191];
		for (i in 0...digits.length)
			placeTimerPart(timerTile(Std.string(digits[i])), digitOffsets[i]);
		placeTimerPart(timerTile("colon"), 67);
		placeTimerPart(timerTile("point"), 127);

		timeGroup.addChild(finalRow);
		var groupHeight = groupY + TIMER_HEIGHT;
		timeGroup.extent.y = groupHeight;
		pg.addChild(timeGroup);
		blocks.push({ctrl: timeGroup, height: groupHeight});

		// ---- How the run went
		var qualified = mission.qualifyTime > finalTime;
		var beatGold = mission.goldTime > 0 && finalTime < mission.goldTime;
		// A level with no qualify time carries 99:59.999, which is not worth printing
		var hasQualifyTime = mission.qualifyTime != Math.POSITIVE_INFINITY && mission.qualifyTime < 5999.999;

		var status = centeredText(expo50, layoutHeight(expo50));
		if (!qualified) {
			status.text.textColor = 0xFF0000;
			status.text.text = "You failed to qualify!";
		} else if (beatGold) {
			status.text.textColor = 0x00FF00;
			status.text.text = 'You beat the <img src="gold"></img> time!';
		} else if (hasQualifyTime) {
			status.text.textColor = 0x00FF00;
			status.text.text = "You've qualified!";
		} else {
			// Nothing to qualify against on this level, so finishing is the whole story
			status.text.textColor = 0x00FF00;
			status.text.text = "Level complete!";
		}
		status.text.filter = new DropShadow(shadowDistance, 0.785, 0, 1, 0, 0.4, 1, true);
		blocks.push({ctrl: status, height: layoutHeight(expo50)});

		// ---- The level's targets, each with the mark for how this run did against it
		if (mission.goldTime > 0) {
			var goldRow = hudRow(0xFFCC00, 'Gold Time: ${Util.formatTime(mission.goldTime)}', beatGold ? checkMark : crossMark);
			blocks.push({ctrl: goldRow, height: layoutHeight(domcasual24)});
		}

		if (hasQualifyTime) {
			var qualifyRow = hudRow(0x00FF00, 'Qualify Time: ${Util.formatTime(mission.qualifyTime)}', qualified ? checkMark : crossMark);
			blocks.push({ctrl: qualifyRow, height: layoutHeight(domcasual24)});
		}

		// ---- The record this run was measured against
		var scoreData:Array<Score> = Settings.getScores(mission.path);
		// One personal best rather than a high score table, since this build is played by
		// whoever is holding the pad rather than by a named list of people
		var previousBest:Float = scoreData.length > 0 ? scoreData[0].time : Math.POSITIVE_INFINITY;
		var newBest = finalTime < previousBest;
		var personalBest = newBest ? finalTime : previousBest;

		if (newBest) {
			var bestBanner = centeredText(expo32, layoutHeight(expo32));
			bestBanner.text.textColor = 0xFFFF00;
			bestBanner.text.text = "New personal best!";
			bestBanner.text.filter = new DropShadow(shadowDistance, 0.785, 0, 1, 0, 0.4, 1, true);
			blocks.push({ctrl: bestBanner, height: layoutHeight(expo32)});
		}

		var bestRow = hudRow(0xFFFFFF, 'Personal Best: '
			+ (personalBest == Math.POSITIVE_INFINITY ? "--:--.---" : Util.formatTime(personalBest)));
		blocks.push({ctrl: bestRow, height: layoutHeight(domcasual24)});

		// Spread the blocks evenly down the panel, so the screen stays filled out whether or
		// not the optional lines are there
		var contentTop = CONTENT_TOP;
		var contentBottom = CONTENT_BOTTOM;
		var contentHeight = 0.0;
		for (block in blocks)
			contentHeight += block.height;
		var gap = (contentBottom - contentTop - contentHeight) / (blocks.length - 1);
		var y = contentTop;
		for (block in blocks) {
			block.ctrl.position.y = y;
			y += block.height + gap;
		}

		pg.addChild(continueButton);
		pg.addChild(nextButton);
		pg.addChild(restartButton);

		this.addChild(pg);

		if (mission.difficultyIndex != -1) {
			if (Settings.progression[mission.difficultyIndex] == mission.index && qualified) {
				Settings.progression[mission.difficultyIndex]++;
			}
		}
		Settings.save();

		// Only a run that beats the stored time is worth keeping, since the screen shows a
		// single personal best rather than a table. Gamepad players cannot type, so it is
		// filed under the desktop user name instead of opening a text entry dialog.
		if (newBest && !scoreSubmitted) {
			setButtonStates(true);
			Settings.saveScore(mission.path, {name: Settings.highscoreName, time: finalTime});
			scoreSubmitted = true;
		}
	}
}
